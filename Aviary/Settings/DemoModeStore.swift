import Combine
import Foundation

@MainActor
final class DemoModeStore: ObservableObject {
    static let defaultsKey = "demoMode.isOn"
    static let roleOverrideKey = "demoMode.roleOverride"

    @Published var isOn: Bool {
        didSet {
            guard oldValue != isOn else { return }
            defaults.set(isOn, forKey: Self.defaultsKey)
        }
    }

    @Published var roleOverride: UserRole? {
        didSet {
            guard oldValue != roleOverride else { return }
            if let role = roleOverride {
                defaults.set(role.rawValue, forKey: Self.roleOverrideKey)
            } else {
                defaults.removeObject(forKey: Self.roleOverrideKey)
            }
        }
    }

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        let env = ProcessInfo.processInfo.environment
        if let envOn = env["AVIARY_DEMO_ON"] {
            self.isOn = (envOn as NSString).boolValue
        } else {
            self.isOn = defaults.bool(forKey: Self.defaultsKey)
        }
        if let envRole = env["AVIARY_DEMO_ROLE"], let role = UserRole(rawValue: envRole) {
            self.roleOverride = role
        } else if let raw = defaults.string(forKey: Self.roleOverrideKey),
           let role = UserRole(rawValue: raw) {
            self.roleOverride = role
        } else {
            self.roleOverride = nil
        }
    }
}
