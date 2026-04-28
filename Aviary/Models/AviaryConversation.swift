import Foundation

struct AviaryConversation: Codable, Equatable, Identifiable {
    let id: UUID
    let jobId: UUID?
    let customerId: UUID?
    let pilotId: UUID?
    let title: String?
    let subtitle: String?
    let lastMessage: String?
    let lastMessageAt: Date?
    let createdAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case jobId = "job_id"
        case customerId = "customer_id"
        case pilotId = "pilot_id"
        case title
        case subtitle
        case lastMessage = "last_message"
        case lastMessageAt = "last_message_at"
        case createdAt = "created_at"
    }
}

extension AviaryConversation {
    var displayTitle: String {
        guard let title, !title.isEmpty else { return "Job conversation" }
        return title
    }

    var displaySubtitle: String {
        guard let subtitle, !subtitle.isEmpty else { return "Aviary job thread" }
        return subtitle
    }

    var previewText: String {
        guard let lastMessage, !lastMessage.isEmpty else { return "No messages yet" }
        return lastMessage
    }

    var lastMessageTimeText: String {
        guard let lastMessageAt else { return "" }
        if Calendar.current.isDateInToday(lastMessageAt) {
            return Self.timeFormatter.string(from: lastMessageAt)
        }
        return Self.dateFormatter.string(from: lastMessageAt)
    }

    var sortDate: Date {
        lastMessageAt ?? createdAt ?? .distantPast
    }

    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter
    }()

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter
    }()
}

struct AviaryMessage: Codable, Equatable, Identifiable {
    let id: UUID
    let conversationId: UUID?
    let senderId: UUID?
    let body: String
    let createdAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case conversationId = "conversation_id"
        case senderId = "sender_id"
        case body
        case createdAt = "created_at"
    }
}

extension AviaryMessage {
    func isIncoming(for profile: UserProfile?) -> Bool {
        guard let profile else { return true }
        return senderId != profile.id
    }

    var timeText: String? {
        guard let createdAt else { return nil }
        return Self.timeFormatter.string(from: createdAt)
    }

    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter
    }()
}

