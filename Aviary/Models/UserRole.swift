import Foundation

enum UserRole: String, Codable, CaseIterable, Identifiable {
    case pilot
    case customer

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .pilot:    return "Pilot"
        case .customer: return "Customer"
        }
    }
}
