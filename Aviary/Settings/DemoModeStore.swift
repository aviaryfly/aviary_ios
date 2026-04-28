import Combine
import Foundation

@MainActor
final class DemoModeStore: ObservableObject {
    static let defaultsKey = "demoMode.isOn"

    @Published var isOn: Bool {
        didSet {
            guard oldValue != isOn else { return }
            defaults.set(isOn, forKey: Self.defaultsKey)
        }
    }

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.isOn = defaults.bool(forKey: Self.defaultsKey)
    }
}
