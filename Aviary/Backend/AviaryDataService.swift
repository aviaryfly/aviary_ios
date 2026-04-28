import Foundation
import Supabase

final class AviaryDataService {
    static let shared = AviaryDataService()

    private let client = Backend.client

    private init() {}

    func availableGigs() async throws -> [AviaryJob] {
        guard SupabaseConfig.isConfigured else { throw AviaryDataError.notConfigured }
        let jobs: [AviaryJob] = try await client
            .from("jobs")
            .select()
            .eq("status", value: "open")
            .execute()
            .value
        return sortUpcoming(jobs)
    }

    func activePilotJob(for pilotID: UUID) async throws -> AviaryJob? {
        guard SupabaseConfig.isConfigured else { throw AviaryDataError.notConfigured }
        let jobs: [AviaryJob] = try await client
            .from("jobs")
            .select()
            .eq("pilot_id", value: pilotID)
            .execute()
            .value
        return sortUpcoming(jobs).first(where: \.isActiveForPilot)
    }

    func customerJobs(for customerID: UUID) async throws -> [AviaryJob] {
        guard SupabaseConfig.isConfigured else { throw AviaryDataError.notConfigured }
        let jobs: [AviaryJob] = try await client
            .from("jobs")
            .select()
            .eq("customer_id", value: customerID)
            .execute()
            .value
        return sortUpcoming(jobs)
    }

    func createJob(_ draft: JobDraft, customerID: UUID) async throws -> AviaryJob {
        guard SupabaseConfig.isConfigured else { throw AviaryDataError.notConfigured }
        let row = JobInsert(
            customer_id: customerID,
            status: "open",
            job_type: draft.jobType,
            title: draft.title,
            address: draft.address,
            client_name: draft.clientName,
            distance_miles: draft.distanceMiles,
            payout_cents: draft.payoutCents,
            scheduled_at: draft.scheduledAt,
            duration_minutes: draft.durationMinutes,
            deliverables: draft.deliverables
        )
        let job: AviaryJob = try await client
            .from("jobs")
            .insert(row)
            .select()
            .single()
            .execute()
            .value
        return job
    }

    func accept(job: AviaryJob, pilotID: UUID) async throws {
        guard SupabaseConfig.isConfigured else { throw AviaryDataError.notConfigured }
        let update = JobAssignmentUpdate(pilot_id: pilotID, status: "accepted")
        try await client
            .from("jobs")
            .update(update)
            .eq("id", value: job.id)
            .execute()

        guard let customerID = job.customerId else { return }
        let conversation = ConversationInsert(
            job_id: job.id,
            customer_id: customerID,
            pilot_id: pilotID,
            title: job.displayClient,
            subtitle: "\(job.displayType) · \(job.displayAddress)",
            last_message: "Pilot accepted the job.",
            last_message_at: Date()
        )
        try? await client
            .from("conversations")
            .insert(conversation)
            .execute()
    }

    func conversations(for profile: UserProfile) async throws -> [AviaryConversation] {
        guard SupabaseConfig.isConfigured else { throw AviaryDataError.notConfigured }
        let conversations: [AviaryConversation]
        switch profile.role {
        case .pilot:
            conversations = try await client
                .from("conversations")
                .select()
                .eq("pilot_id", value: profile.id)
                .execute()
                .value
        case .customer:
            conversations = try await client
                .from("conversations")
                .select()
                .eq("customer_id", value: profile.id)
                .execute()
                .value
        }
        return conversations.sorted { $0.sortDate > $1.sortDate }
    }

    func messages(for conversationID: UUID) async throws -> [AviaryMessage] {
        guard SupabaseConfig.isConfigured else { throw AviaryDataError.notConfigured }
        let messages: [AviaryMessage] = try await client
            .from("messages")
            .select()
            .eq("conversation_id", value: conversationID)
            .execute()
            .value
        return messages.sorted { ($0.createdAt ?? .distantPast) < ($1.createdAt ?? .distantPast) }
    }

    func sendMessage(body: String, conversationID: UUID, senderID: UUID) async throws -> AviaryMessage {
        guard SupabaseConfig.isConfigured else { throw AviaryDataError.notConfigured }
        let row = MessageInsert(
            conversation_id: conversationID,
            sender_id: senderID,
            body: body
        )
        let message: AviaryMessage = try await client
            .from("messages")
            .insert(row)
            .select()
            .single()
            .execute()
            .value

        try? await client
            .from("conversations")
            .update(ConversationLastMessageUpdate(last_message: body, last_message_at: Date()))
            .eq("id", value: conversationID)
            .execute()
        return message
    }

    private func sortUpcoming(_ jobs: [AviaryJob]) -> [AviaryJob] {
        jobs.sorted { lhs, rhs in
            if lhs.isCompleted != rhs.isCompleted {
                return !lhs.isCompleted
            }
            return lhs.sortDate < rhs.sortDate
        }
    }
}

extension AviaryDataService {
    struct JobDraft {
        let jobType: String
        let title: String
        let address: String
        let clientName: String?
        let distanceMiles: Double?
        let payoutCents: Int?
        let scheduledAt: Date?
        let durationMinutes: Int?
        let deliverables: [String]
    }
}

enum AviaryDataError: LocalizedError {
    case notConfigured

    var errorDescription: String? {
        switch self {
        case .notConfigured:
            return "Supabase is not configured for this build."
        }
    }
}

private struct JobInsert: Encodable {
    let customer_id: UUID
    let status: String
    let job_type: String
    let title: String
    let address: String
    let client_name: String?
    let distance_miles: Double?
    let payout_cents: Int?
    let scheduled_at: Date?
    let duration_minutes: Int?
    let deliverables: [String]
}

private struct JobAssignmentUpdate: Encodable {
    let pilot_id: UUID
    let status: String
}

private struct ConversationInsert: Encodable {
    let job_id: UUID
    let customer_id: UUID
    let pilot_id: UUID
    let title: String
    let subtitle: String
    let last_message: String
    let last_message_at: Date
}

private struct ConversationLastMessageUpdate: Encodable {
    let last_message: String
    let last_message_at: Date
}

private struct MessageInsert: Encodable {
    let conversation_id: UUID
    let sender_id: UUID
    let body: String
}

