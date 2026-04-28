import Foundation

struct UserProfile: Codable, Equatable, Identifiable {
    let id: UUID
    let email: String
    let role: UserRole
    let firstName: String?
    let lastName: String?
    let createdAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case email
        case role
        case firstName = "first_name"
        case lastName = "last_name"
        case createdAt = "created_at"
    }
}

extension UserProfile {
    var fullName: String? {
        let parts = [firstName, lastName]
            .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        return parts.isEmpty ? nil : parts.joined(separator: " ")
    }

    var initials: String {
        let letters = [firstName, lastName]
            .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .compactMap { $0.first }
        if !letters.isEmpty {
            return String(letters.prefix(2)).uppercased()
        }
        return email.prefix(2).uppercased()
    }

    var displayName: String {
        if let name = fullName { return name }
        return email
    }
}
