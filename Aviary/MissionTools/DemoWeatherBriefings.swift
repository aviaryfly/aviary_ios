import CoreLocation
import Foundation

/// Hardcoded METAR / TAF briefings used while demo mode is on, so the weather
/// briefing screen renders identically without any network access.
enum DemoWeatherBriefings {

    // MARK: - Current location (Berkeley, CA — KOAK is the nearest reporting station)

    static let currentLocation: AviationBriefing = {
        let coordinate = CLLocationCoordinate2D(latitude: 37.8716, longitude: -122.2727)
        let station = AviationStation(
            icaoId: "KOAK",
            name: "Oakland Metro Intl",
            coordinate: CLLocationCoordinate2D(latitude: 37.7213, longitude: -122.2207),
            elevationMeters: 2
        )
        let metar = MetarObservation(
            stationId: "KOAK",
            stationName: "Oakland Metro Intl",
            observationTime: timeAgo(minutes: 12),
            rawText: "KOAK 232153Z 27009KT 10SM FEW040 SCT250 19/12 A3001 RMK AO2 SLP163 T01940122",
            temperatureC: 19,
            dewpointC: 12,
            windDirectionDeg: 270,
            windSpeedKt: 9,
            windGustKt: nil,
            visibilityStatuteMiles: 10,
            visibilityRaw: "10SM",
            altimeterInHg: 30.01,
            weather: nil,
            cloudLayers: [
                CloudLayer(cover: "FEW", baseFeetAGL: 4_000),
                CloudLayer(cover: "SCT", baseFeetAGL: 25_000)
            ],
            flightCategory: .vfr
        )
        let taf = TafForecast(
            stationId: "KOAK",
            rawText: """
            TAF KOAK 231720Z 2318/2418 28010KT P6SM FEW050 \
            FM240200 27006KT P6SM SCT025 \
            FM241400 28012KT P6SM FEW040
            """,
            issueTime: timeAgo(hours: 4),
            validFrom: hoursFromNow(-1),
            validTo: hoursFromNow(23),
            periods: [
                TafPeriod(from: hoursFromNow(-1),
                          to: hoursFromNow(8),
                          changeIndicator: "FM",
                          probability: nil,
                          windDirectionDeg: 280,
                          windSpeedKt: 10,
                          windGustKt: nil,
                          visibilitySm: 6,
                          visibilityRaw: "P6SM",
                          weather: nil,
                          cloudLayers: [CloudLayer(cover: "FEW", baseFeetAGL: 5_000)]),
                TafPeriod(from: hoursFromNow(8),
                          to: hoursFromNow(20),
                          changeIndicator: "FM",
                          probability: nil,
                          windDirectionDeg: 270,
                          windSpeedKt: 6,
                          windGustKt: nil,
                          visibilitySm: 6,
                          visibilityRaw: "P6SM",
                          weather: nil,
                          cloudLayers: [CloudLayer(cover: "SCT", baseFeetAGL: 2_500)]),
                TafPeriod(from: hoursFromNow(20),
                          to: hoursFromNow(23),
                          changeIndicator: "FM",
                          probability: nil,
                          windDirectionDeg: 280,
                          windSpeedKt: 12,
                          windGustKt: nil,
                          visibilitySm: 6,
                          visibilityRaw: "P6SM",
                          weather: nil,
                          cloudLayers: [CloudLayer(cover: "FEW", baseFeetAGL: 4_000)])
            ]
        )
        return AviationBriefing(
            label: "Your position · Berkeley, CA",
            coordinate: coordinate,
            station: station,
            metar: metar,
            taf: taf,
            distanceMiles: 9.4
        )
    }()

    // MARK: - Mission (1247 Vine St — also covered by KOAK)

    static func mission(label: String) -> AviationBriefing {
        let coordinate = CLLocationCoordinate2D(latitude: 37.8814, longitude: -122.2683)
        let station = AviationStation(
            icaoId: "KOAK",
            name: "Oakland Metro Intl",
            coordinate: CLLocationCoordinate2D(latitude: 37.7213, longitude: -122.2207),
            elevationMeters: 2
        )
        let metar = MetarObservation(
            stationId: "KOAK",
            stationName: "Oakland Metro Intl",
            observationTime: timeAgo(minutes: 12),
            rawText: "KOAK 232153Z 27009KT 10SM FEW040 SCT250 19/12 A3001 RMK AO2 SLP163 T01940122",
            temperatureC: 19,
            dewpointC: 12,
            windDirectionDeg: 270,
            windSpeedKt: 9,
            windGustKt: nil,
            visibilityStatuteMiles: 10,
            visibilityRaw: "10SM",
            altimeterInHg: 30.01,
            weather: nil,
            cloudLayers: [
                CloudLayer(cover: "FEW", baseFeetAGL: 4_000),
                CloudLayer(cover: "SCT", baseFeetAGL: 25_000)
            ],
            flightCategory: .vfr
        )
        let taf = TafForecast(
            stationId: "KOAK",
            rawText: """
            TAF KOAK 231720Z 2318/2418 28010KT P6SM FEW050 \
            FM240200 27006KT P6SM SCT025 \
            FM241400 28012KT P6SM FEW040
            """,
            issueTime: timeAgo(hours: 4),
            validFrom: hoursFromNow(-1),
            validTo: hoursFromNow(23),
            periods: [
                TafPeriod(from: hoursFromNow(0),
                          to: hoursFromNow(3),
                          changeIndicator: "FM",
                          probability: nil,
                          windDirectionDeg: 280,
                          windSpeedKt: 9,
                          windGustKt: 14,
                          visibilitySm: 6,
                          visibilityRaw: "P6SM",
                          weather: nil,
                          cloudLayers: [CloudLayer(cover: "FEW", baseFeetAGL: 5_000)]),
                TafPeriod(from: hoursFromNow(3),
                          to: hoursFromNow(10),
                          changeIndicator: "FM",
                          probability: nil,
                          windDirectionDeg: 280,
                          windSpeedKt: 7,
                          windGustKt: nil,
                          visibilitySm: 6,
                          visibilityRaw: "P6SM",
                          weather: nil,
                          cloudLayers: [CloudLayer(cover: "SCT", baseFeetAGL: 2_500)])
            ]
        )
        return AviationBriefing(
            label: label,
            coordinate: coordinate,
            station: station,
            metar: metar,
            taf: taf,
            distanceMiles: 10.6
        )
    }

    // MARK: - Helpers

    private static func timeAgo(minutes: Int = 0, hours: Int = 0) -> Date {
        Date().addingTimeInterval(-Double(hours * 3_600 + minutes * 60))
    }

    private static func hoursFromNow(_ hours: Int) -> Date {
        Date().addingTimeInterval(Double(hours * 3_600))
    }
}
