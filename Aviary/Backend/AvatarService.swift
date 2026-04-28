import Foundation
import Supabase
import UIKit

enum AvatarService {
    static let bucket = "avatars"

    static func uploadAvatar(image: UIImage, for userID: UUID) async throws -> URL {
        guard let data = image.jpegData(compressionQuality: 0.85) else {
            throw AvatarError.encodingFailed
        }
        let client = Backend.client
        let path = "users/\(userID.uuidString.lowercased())/avatar.jpg"

        _ = try await client.storage
            .from(bucket)
            .upload(
                path,
                data: data,
                options: FileOptions(contentType: "image/jpeg", upsert: true)
            )

        let publicURL = try client.storage.from(bucket).getPublicURL(path: path)
        let bustedURL = appendCacheBuster(to: publicURL)

        try await client
            .from("profiles")
            .update(["avatar_url": bustedURL.absoluteString])
            .eq("id", value: userID)
            .execute()

        return bustedURL
    }

    private static func appendCacheBuster(to url: URL) -> URL {
        var components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        var items = components?.queryItems ?? []
        items.removeAll { $0.name == "v" }
        items.append(URLQueryItem(name: "v", value: String(Int(Date().timeIntervalSince1970))))
        components?.queryItems = items
        return components?.url ?? url
    }

    enum AvatarError: LocalizedError {
        case encodingFailed
        var errorDescription: String? {
            switch self {
            case .encodingFailed: return "Couldn't prepare that image for upload."
            }
        }
    }
}
