import Combine
import CoreLocation
import Foundation
import SwiftUI

struct WeatherSnapshot: Equatable {
    let dayName: String          // "Tuesday"
    let condition: String        // "Clear", "Sunny", "Light Rain", etc.
    let windSpeedMph: Int        // 9
    let temperatureF: Int?       // 68
    let isFavorable: Bool        // friendly headline hint
}

enum WeatherService {
    private static let userAgent = "Aviary iOS App (support@aviary.app)"

    static func fetchSnapshot(at coordinate: CLLocationCoordinate2D) async throws -> WeatherSnapshot {
        let pointsURL = URL(string: "https://api.weather.gov/points/\(String(format: "%.4f", coordinate.latitude)),\(String(format: "%.4f", coordinate.longitude))")!
        let points: PointsResponse = try await get(pointsURL)

        guard let forecastURL = URL(string: points.properties.forecast) else {
            throw WeatherError.invalidForecastURL
        }
        let forecast: ForecastResponse = try await get(forecastURL)

        guard let period = forecast.properties.periods.first else {
            throw WeatherError.noPeriods
        }

        let wind = parseWindMph(from: period.windSpeed)
        let condition = period.shortForecast
        let favorable = isFavorable(condition: condition, windMph: wind)

        return WeatherSnapshot(
            dayName: period.name,
            condition: condition,
            windSpeedMph: wind,
            temperatureF: period.temperature,
            isFavorable: favorable
        )
    }

    private static func get<T: Decodable>(_ url: URL) async throws -> T {
        var request = URLRequest(url: url)
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        request.setValue("application/geo+json", forHTTPHeaderField: "Accept")
        let (data, response) = try await URLSession.shared.data(for: request)
        if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
            throw WeatherError.httpStatus(http.statusCode)
        }
        return try JSONDecoder().decode(T.self, from: data)
    }

    private static func parseWindMph(from raw: String) -> Int {
        // api.weather.gov returns strings like "9 mph" or "5 to 10 mph"
        let pattern = #"(\d+)"#
        let range = NSRange(raw.startIndex..<raw.endIndex, in: raw)
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return 0 }
        let matches = regex.matches(in: raw, range: range)
        let numbers: [Int] = matches.compactMap { match in
            guard let r = Range(match.range, in: raw) else { return nil }
            return Int(raw[r])
        }
        // Use the highest figure for "5 to 10 mph" (gust-aware)
        return numbers.max() ?? 0
    }

    private static func isFavorable(condition: String, windMph: Int) -> Bool {
        let lower = condition.lowercased()
        let badKeywords = ["rain", "storm", "thunder", "snow", "sleet", "hail", "fog", "blizzard", "ice"]
        if badKeywords.contains(where: { lower.contains($0) }) { return false }
        if windMph > 20 { return false }
        return true
    }

    enum WeatherError: LocalizedError {
        case invalidForecastURL
        case noPeriods
        case httpStatus(Int)
        case outOfCoverage

        var errorDescription: String? {
            switch self {
            case .invalidForecastURL: return "Couldn't find a forecast for your location."
            case .noPeriods: return "No forecast periods available."
            case .httpStatus(let code) where code == 404: return "Weather data isn't available for this location."
            case .httpStatus(let code): return "Weather service returned \(code)."
            case .outOfCoverage: return "Weather data isn't available outside the U.S."
            }
        }
    }

    private struct PointsResponse: Decodable {
        let properties: Properties
        struct Properties: Decodable {
            let forecast: String
        }
    }

    private struct ForecastResponse: Decodable {
        let properties: Properties
        struct Properties: Decodable {
            let periods: [Period]
        }
        struct Period: Decodable {
            let name: String
            let temperature: Int?
            let windSpeed: String
            let shortForecast: String
        }
    }
}

@MainActor
final class WeatherViewModel: ObservableObject {
    @Published private(set) var snapshot: WeatherSnapshot?
    @Published private(set) var errorMessage: String?
    @Published private(set) var isLoading: Bool = false

    private var lastFetch: Date?

    func loadIfNeeded() {
        if let last = lastFetch, Date().timeIntervalSince(last) < 600, snapshot != nil { return }
        Task { await refresh() }
    }

    func refresh() async {
        isLoading = true
        defer { isLoading = false }
        do {
            let coord = try await LocationProvider.shared.currentCoordinate()
            let snap = try await WeatherService.fetchSnapshot(at: coord)
            snapshot = snap
            errorMessage = nil
            lastFetch = Date()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
