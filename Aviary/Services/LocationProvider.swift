import CoreLocation
import Foundation

@MainActor
final class LocationProvider: NSObject, CLLocationManagerDelegate {
    static let shared = LocationProvider()

    private let manager = CLLocationManager()
    private var continuation: CheckedContinuation<CLLocationCoordinate2D, Error>?

    private override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyKilometer
    }

    func currentCoordinate() async throws -> CLLocationCoordinate2D {
        if let existing = continuation {
            existing.resume(throwing: LocationError.cancelled)
            continuation = nil
        }
        return try await withCheckedThrowingContinuation { c in
            self.continuation = c
            switch manager.authorizationStatus {
            case .notDetermined:
                manager.requestWhenInUseAuthorization()
            case .restricted, .denied:
                self.continuation = nil
                c.resume(throwing: LocationError.denied)
            case .authorizedAlways, .authorizedWhenInUse:
                manager.requestLocation()
            @unknown default:
                self.continuation = nil
                c.resume(throwing: LocationError.unknown)
            }
        }
    }

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        Task { @MainActor in
            switch status {
            case .authorizedAlways, .authorizedWhenInUse:
                if continuation != nil {
                    manager.requestLocation()
                }
            case .denied, .restricted:
                continuation?.resume(throwing: LocationError.denied)
                continuation = nil
            default:
                break
            }
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let last = locations.last else { return }
        Task { @MainActor in
            continuation?.resume(returning: last.coordinate)
            continuation = nil
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in
            continuation?.resume(throwing: error)
            continuation = nil
        }
    }

    enum LocationError: LocalizedError {
        case denied
        case cancelled
        case unknown

        var errorDescription: String? {
            switch self {
            case .denied: return "Location access is turned off. Enable it in Settings to see local weather."
            case .cancelled: return "Location request was cancelled."
            case .unknown: return "Couldn't get your location."
            }
        }
    }
}
