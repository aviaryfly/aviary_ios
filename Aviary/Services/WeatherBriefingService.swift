import CoreLocation
import Foundation

// MARK: - Models

struct AviationStation: Equatable {
    let icaoId: String
    let name: String
    let coordinate: CLLocationCoordinate2D
    let elevationMeters: Int?

    static func == (lhs: AviationStation, rhs: AviationStation) -> Bool {
        lhs.icaoId == rhs.icaoId
            && lhs.name == rhs.name
            && lhs.coordinate.latitude == rhs.coordinate.latitude
            && lhs.coordinate.longitude == rhs.coordinate.longitude
            && lhs.elevationMeters == rhs.elevationMeters
    }
}

struct CloudLayer: Equatable, Identifiable {
    let id = UUID()
    let cover: String          // SKC, CLR, FEW, SCT, BKN, OVC
    let baseFeetAGL: Int?
}

enum FlightCategory: String {
    case vfr = "VFR"
    case mvfr = "MVFR"
    case ifr = "IFR"
    case lifr = "LIFR"
    case unknown = "—"

    static func compute(ceilingFt: Int?, visibilitySm: Double?) -> FlightCategory {
        let ceiling = ceilingFt ?? 99_999
        let visibility = visibilitySm ?? 99
        if ceiling < 500 || visibility < 1 { return .lifr }
        if ceiling < 1_000 || visibility < 3 { return .ifr }
        if ceiling <= 3_000 || visibility <= 5 { return .mvfr }
        return .vfr
    }

    var summary: String {
        switch self {
        case .vfr:  return "VFR — Suitable for visual flight rules."
        case .mvfr: return "MVFR — Marginal visual conditions."
        case .ifr:  return "IFR — Instrument conditions."
        case .lifr: return "LIFR — Low instrument conditions, expect minimums."
        case .unknown: return "Flight category unavailable."
        }
    }
}

struct MetarObservation: Equatable {
    let stationId: String
    let stationName: String
    let observationTime: Date?
    let rawText: String
    let temperatureC: Double?
    let dewpointC: Double?
    let windDirectionDeg: Int?
    let windSpeedKt: Int?
    let windGustKt: Int?
    let visibilityStatuteMiles: Double?
    let visibilityRaw: String?
    let altimeterInHg: Double?
    let weather: String?
    let cloudLayers: [CloudLayer]
    let flightCategory: FlightCategory

    var ceilingFeet: Int? {
        let ceilingCovers: Set<String> = ["BKN", "OVC", "VV"]
        return cloudLayers
            .filter { ceilingCovers.contains($0.cover.uppercased()) }
            .compactMap(\.baseFeetAGL)
            .min()
    }
}

struct TafPeriod: Equatable, Identifiable {
    let id = UUID()
    let from: Date?
    let to: Date?
    let changeIndicator: String?   // FM, BECMG, TEMPO, PROB30, PROB40
    let probability: Int?
    let windDirectionDeg: Int?
    let windSpeedKt: Int?
    let windGustKt: Int?
    let visibilitySm: Double?
    let visibilityRaw: String?
    let weather: String?
    let cloudLayers: [CloudLayer]
}

struct TafForecast: Equatable {
    let stationId: String
    let rawText: String
    let issueTime: Date?
    let validFrom: Date?
    let validTo: Date?
    let periods: [TafPeriod]
}

struct AviationBriefing: Equatable {
    let label: String
    let coordinate: CLLocationCoordinate2D
    let station: AviationStation
    let metar: MetarObservation?
    let taf: TafForecast?
    let distanceMiles: Double

    static func == (lhs: AviationBriefing, rhs: AviationBriefing) -> Bool {
        lhs.label == rhs.label
            && lhs.coordinate.latitude == rhs.coordinate.latitude
            && lhs.coordinate.longitude == rhs.coordinate.longitude
            && lhs.station == rhs.station
            && lhs.metar == rhs.metar
            && lhs.taf == rhs.taf
            && lhs.distanceMiles == rhs.distanceMiles
    }
}

// MARK: - Service

enum WeatherBriefingService {
    private static let baseURL = "https://aviationweather.gov/api/data"
    private static let userAgent = "Aviary iOS App (support@aviary.app)"

    static func briefing(at coordinate: CLLocationCoordinate2D, label: String) async throws -> AviationBriefing {
        let metars = try await fetchNearbyMetars(around: coordinate, radiusDegrees: 1.0)
        let candidates: [MetarStationRaw]
        if metars.isEmpty {
            candidates = try await fetchNearbyMetars(around: coordinate, radiusDegrees: 2.5)
        } else {
            candidates = metars
        }
        guard let nearest = candidates.min(by: {
            distance(from: coordinate, to: $0.coordinate) < distance(from: coordinate, to: $1.coordinate)
        }) else {
            throw BriefingError.noStations
        }

        let station = AviationStation(
            icaoId: nearest.icaoId,
            name: nearest.name ?? nearest.icaoId,
            coordinate: nearest.coordinate,
            elevationMeters: nearest.elev
        )
        let metar = nearest.toObservation()
        let taf = try? await fetchTaf(stationId: nearest.icaoId)
        let distMeters = distance(from: coordinate, to: nearest.coordinate)
        return AviationBriefing(
            label: label,
            coordinate: coordinate,
            station: station,
            metar: metar,
            taf: taf,
            distanceMiles: distMeters / 1_609.34
        )
    }

    // MARK: - Networking

    private static func fetchNearbyMetars(around coord: CLLocationCoordinate2D,
                                          radiusDegrees: Double) async throws -> [MetarStationRaw] {
        // bbox order in this API: minLat,minLon,maxLat,maxLon
        let bbox = String(
            format: "%.4f,%.4f,%.4f,%.4f",
            coord.latitude - radiusDegrees,
            coord.longitude - radiusDegrees,
            coord.latitude + radiusDegrees,
            coord.longitude + radiusDegrees
        )
        var components = URLComponents(string: "\(baseURL)/metar")!
        components.queryItems = [
            URLQueryItem(name: "format", value: "json"),
            URLQueryItem(name: "bbox", value: bbox),
            URLQueryItem(name: "hours", value: "2"),
        ]
        guard let url = components.url else { throw BriefingError.invalidURL }
        let raws: [MetarStationRaw] = try await get(url)
        // De-duplicate to most-recent per station
        var byStation: [String: MetarStationRaw] = [:]
        for raw in raws {
            if let existing = byStation[raw.icaoId],
               (existing.obsTime ?? 0) >= (raw.obsTime ?? 0) {
                continue
            }
            byStation[raw.icaoId] = raw
        }
        return Array(byStation.values)
    }

    private static func fetchTaf(stationId: String) async throws -> TafForecast? {
        var components = URLComponents(string: "\(baseURL)/taf")!
        components.queryItems = [
            URLQueryItem(name: "format", value: "json"),
            URLQueryItem(name: "ids", value: stationId),
        ]
        guard let url = components.url else { throw BriefingError.invalidURL }
        let raws: [TafRaw] = try await get(url)
        return raws.first?.toForecast()
    }

    private static func get<T: Decodable>(_ url: URL) async throws -> T {
        var request = URLRequest(url: url)
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.timeoutInterval = 15
        let (data, response) = try await URLSession.shared.data(for: request)
        if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
            throw BriefingError.httpStatus(http.statusCode)
        }
        let decoder = JSONDecoder()
        return try decoder.decode(T.self, from: data)
    }

    private static func distance(from a: CLLocationCoordinate2D,
                                 to b: CLLocationCoordinate2D) -> Double {
        let la = CLLocation(latitude: a.latitude, longitude: a.longitude)
        let lb = CLLocation(latitude: b.latitude, longitude: b.longitude)
        return la.distance(from: lb)
    }

    // MARK: - Errors

    enum BriefingError: LocalizedError {
        case invalidURL
        case noStations
        case httpStatus(Int)

        var errorDescription: String? {
            switch self {
            case .invalidURL:    return "Couldn't build the briefing request."
            case .noStations:    return "No reporting stations near this location."
            case .httpStatus(let code) where code == 404: return "Aviation weather isn't available here."
            case .httpStatus(let code): return "Aviation weather service returned \(code)."
            }
        }
    }
}

// MARK: - Raw API decoding

private struct MetarStationRaw: Decodable {
    let icaoId: String
    let name: String?
    let lat: Double
    let lon: Double
    let elev: Int?
    let obsTime: TimeInterval?
    let temp: Double?
    let dewp: Double?
    let wdir: WindDir?
    let wspd: Int?
    let wgst: Int?
    let visib: FlexibleNumber?
    let altim: Double?
    let wxString: String?
    let rawOb: String?
    let clouds: [CloudRaw]?

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: lat, longitude: lon)
    }

    func toObservation() -> MetarObservation {
        let layers = (clouds ?? []).map {
            CloudLayer(cover: $0.cover ?? "—", baseFeetAGL: $0.base)
        }
        let visib = visibilityStatuteMiles()
        let ceiling = layers
            .filter { ["BKN", "OVC", "VV"].contains($0.cover.uppercased()) }
            .compactMap(\.baseFeetAGL)
            .min()
        let category = FlightCategory.compute(ceilingFt: ceiling, visibilitySm: visib)
        return MetarObservation(
            stationId: icaoId,
            stationName: name ?? icaoId,
            observationTime: obsTime.map { Date(timeIntervalSince1970: $0) },
            rawText: rawOb ?? "",
            temperatureC: temp,
            dewpointC: dewp,
            windDirectionDeg: wdir?.degrees,
            windSpeedKt: wspd,
            windGustKt: wgst,
            visibilityStatuteMiles: visib,
            visibilityRaw: visib_raw,
            altimeterInHg: altim.map { hpaToInHg($0) },
            weather: wxString,
            cloudLayers: layers,
            flightCategory: category
        )
    }

    private var visib_raw: String? {
        guard let visib else { return nil }
        switch visib {
        case .number(let n):
            if n == n.rounded() { return "\(Int(n)) SM" }
            return String(format: "%.1f SM", n)
        case .string(let s): return s.contains("SM") ? s : "\(s) SM"
        }
    }

    private func visibilityStatuteMiles() -> Double? {
        guard let visib else { return nil }
        switch visib {
        case .number(let n): return n
        case .string(let s):
            // "10+", "P6SM", "6SM", "1 1/2SM", "1/2SM"
            let upper = s.uppercased().replacingOccurrences(of: "SM", with: "")
            let trimmed = upper.replacingOccurrences(of: "P", with: "")
                .replacingOccurrences(of: "+", with: "")
                .trimmingCharacters(in: .whitespaces)
            if let direct = Double(trimmed) { return direct }
            // mixed fraction "1 1/2"
            let parts = trimmed.split(separator: " ")
            var total: Double = 0
            for part in parts {
                if let n = Double(part) {
                    total += n
                } else if part.contains("/") {
                    let halves = part.split(separator: "/")
                    if halves.count == 2,
                       let num = Double(halves[0]),
                       let den = Double(halves[1]),
                       den != 0 {
                        total += num / den
                    }
                }
            }
            return total > 0 ? total : nil
        }
    }

    private func hpaToInHg(_ hpa: Double) -> Double {
        // METAR JSON's altim is in millibars/hPa.
        hpa * 0.0295299830714
    }
}

private struct CloudRaw: Decodable {
    let cover: String?
    let base: Int?
}

private enum FlexibleNumber: Decodable, Equatable {
    case number(Double)
    case string(String)

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let v = try? container.decode(Double.self) {
            self = .number(v); return
        }
        if let v = try? container.decode(Int.self) {
            self = .number(Double(v)); return
        }
        if let v = try? container.decode(String.self) {
            self = .string(v); return
        }
        throw DecodingError.dataCorruptedError(in: container,
            debugDescription: "Expected number or string for visibility.")
    }
}

private struct WindDir: Decodable, Equatable {
    let degrees: Int?

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let i = try? container.decode(Int.self) { degrees = i; return }
        if let d = try? container.decode(Double.self) { degrees = Int(d); return }
        if let s = try? container.decode(String.self) {
            degrees = Int(s)   // "VRB" → nil
            return
        }
        degrees = nil
    }
}

private struct TafRaw: Decodable {
    let icaoId: String
    let rawTAF: String?
    let issueTime: TimeInterval?
    let validTimeFrom: TimeInterval?
    let validTimeTo: TimeInterval?
    let fcsts: [TafForecastRaw]?

    func toForecast() -> TafForecast {
        let periods: [TafPeriod] = (fcsts ?? []).map { f in
            let layers = (f.clouds ?? []).map {
                CloudLayer(cover: $0.cover ?? "—", baseFeetAGL: $0.base)
            }
            return TafPeriod(
                from: f.timeFrom.map { Date(timeIntervalSince1970: $0) },
                to: f.timeTo.map { Date(timeIntervalSince1970: $0) },
                changeIndicator: f.fcstChange,
                probability: f.probability,
                windDirectionDeg: f.wdir?.degrees,
                windSpeedKt: f.wspd,
                windGustKt: f.wgst,
                visibilitySm: f.visibilityStatuteMiles(),
                visibilityRaw: f.visibilityRaw(),
                weather: f.wxString,
                cloudLayers: layers
            )
        }
        return TafForecast(
            stationId: icaoId,
            rawText: rawTAF ?? "",
            issueTime: issueTime.map { Date(timeIntervalSince1970: $0) },
            validFrom: validTimeFrom.map { Date(timeIntervalSince1970: $0) },
            validTo: validTimeTo.map { Date(timeIntervalSince1970: $0) },
            periods: periods
        )
    }
}

private struct TafForecastRaw: Decodable {
    let timeFrom: TimeInterval?
    let timeTo: TimeInterval?
    let fcstChange: String?
    let probability: Int?
    let wdir: WindDir?
    let wspd: Int?
    let wgst: Int?
    let visib: FlexibleNumber?
    let wxString: String?
    let clouds: [CloudRaw]?

    func visibilityStatuteMiles() -> Double? {
        guard let visib else { return nil }
        switch visib {
        case .number(let n): return n
        case .string(let s):
            let upper = s.uppercased().replacingOccurrences(of: "SM", with: "")
            let trimmed = upper.replacingOccurrences(of: "P", with: "")
                .replacingOccurrences(of: "+", with: "")
                .trimmingCharacters(in: .whitespaces)
            if let direct = Double(trimmed) { return direct }
            let parts = trimmed.split(separator: " ")
            var total: Double = 0
            for part in parts {
                if let n = Double(part) {
                    total += n
                } else if part.contains("/") {
                    let halves = part.split(separator: "/")
                    if halves.count == 2,
                       let num = Double(halves[0]),
                       let den = Double(halves[1]),
                       den != 0 {
                        total += num / den
                    }
                }
            }
            return total > 0 ? total : nil
        }
    }

    func visibilityRaw() -> String? {
        guard let visib else { return nil }
        switch visib {
        case .number(let n):
            if n == n.rounded() { return "\(Int(n)) SM" }
            return String(format: "%.1f SM", n)
        case .string(let s): return s.contains("SM") ? s : "\(s) SM"
        }
    }
}
