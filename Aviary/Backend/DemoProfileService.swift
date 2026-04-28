import Foundation
import Supabase

@MainActor
final class DemoProfileService {
    static let shared = DemoProfileService()

    private let client = Backend.client
    private var cache: [UserRole: UserProfile] = [:]

    private init() {}

    func demoProfile(for role: UserRole) async throws -> UserProfile {
        if let cached = cache[role] { return cached }
        let row: DemoProfileRow = try await client
            .from("demo_profiles")
            .select()
            .eq("role", value: role.rawValue)
            .single()
            .execute()
            .value
        let profile = row.asUserProfile()
        cache[role] = profile
        return profile
    }

    func clearCache() {
        cache.removeAll()
    }

    private struct DemoProfileRow: Decodable {
        let id: UUID
        let role: UserRole
        let email: String
        let first_name: String?
        let last_name: String?
        let avatar_url: String?
        let created_at: Date?

        func asUserProfile() -> UserProfile {
            UserProfile(
                id: id,
                email: email,
                role: role,
                firstName: first_name,
                lastName: last_name,
                avatarUrl: avatar_url,
                createdAt: created_at
            )
        }
    }
}
