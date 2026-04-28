import Foundation

struct AviaryJob: Codable, Equatable, Identifiable {
    let id: UUID
    let customerId: UUID?
    let pilotId: UUID?
    let status: String?
    let jobType: String?
    let title: String?
    let address: String?
    let clientName: String?
    let pilotName: String?
    let distanceMiles: Double?
    let payoutCents: Int?
    let scheduledAt: Date?
    let durationMinutes: Int?
    let deliverables: [String]?
    let createdAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case customerId = "customer_id"
        case pilotId = "pilot_id"
        case status
        case jobType = "job_type"
        case title
        case address
        case clientName = "client_name"
        case pilotName = "pilot_name"
        case distanceMiles = "distance_miles"
        case payoutCents = "payout_cents"
        case scheduledAt = "scheduled_at"
        case durationMinutes = "duration_minutes"
        case deliverables
        case createdAt = "created_at"
    }
}

extension AviaryJob {
    var normalizedStatus: String {
        status?.lowercased().replacingOccurrences(of: " ", with: "_") ?? "open"
    }

    var isCompleted: Bool {
        ["completed", "closed", "paid", "cancelled"].contains(normalizedStatus)
    }

    var isActiveForPilot: Bool {
        ["accepted", "assigned", "en_route", "in_progress", "active"].contains(normalizedStatus)
    }

    var displayTitle: String {
        if let title, !title.isEmpty { return title }
        switch jobType?.lowercased() {
        case "inspection": return "Inspection flight"
        case "event": return "Event aerial coverage"
        case "mapping": return "Mapping flight"
        default: return "Real estate aerials"
        }
    }

    var displayType: String {
        guard let jobType, !jobType.isEmpty else { return "Real estate" }
        return jobType
            .split(separator: "_")
            .map { $0.prefix(1).uppercased() + $0.dropFirst() }
            .joined(separator: " ")
    }

    var displayAddress: String {
        guard let address, !address.isEmpty else { return "Address not set" }
        return address
    }

    var displayClient: String {
        guard let clientName, !clientName.isEmpty else { return "Client" }
        return clientName
    }

    var displayPilot: String {
        guard let pilotName, !pilotName.isEmpty else { return "Pilot pending" }
        return pilotName
    }

    var payoutText: String {
        guard let payoutCents else { return "Quote pending" }
        return Self.currencyFormatter.string(from: NSNumber(value: Double(payoutCents) / 100)) ?? "$0"
    }

    var distanceText: String {
        guard let distanceMiles else { return "Nearby" }
        return String(format: "%.1f mi", distanceMiles)
    }

    var durationText: String {
        guard let durationMinutes else { return "45 min" }
        if durationMinutes >= 60 {
            let hours = Double(durationMinutes) / 60
            return String(format: "%.1f hr", hours)
        }
        return "\(durationMinutes) min"
    }

    var scheduledText: String {
        guard let scheduledAt else { return "Schedule pending" }
        if Calendar.current.isDateInToday(scheduledAt) {
            return "Today, \(Self.timeFormatter.string(from: scheduledAt))"
        }
        if Calendar.current.isDateInTomorrow(scheduledAt) {
            return "Tomorrow, \(Self.timeFormatter.string(from: scheduledAt))"
        }
        return Self.dateFormatter.string(from: scheduledAt)
    }

    var sortDate: Date {
        scheduledAt ?? createdAt ?? .distantFuture
    }

    var displayDeliverables: [String] {
        if let deliverables, !deliverables.isEmpty { return deliverables }
        return ["12 exterior photos", "60-sec cinematic flyover", "Edited delivery set"]
    }

    var statusLabel: String {
        switch normalizedStatus {
        case "accepted", "assigned": return "Accepted"
        case "en_route": return "En route"
        case "in_progress", "active": return "In flight"
        case "completed", "closed", "paid": return "Completed"
        case "cancelled": return "Cancelled"
        default: return "Open"
        }
    }

    private static let currencyFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 0
        return formatter
    }()

    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter
    }()

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE, MMM d, h:mm a"
        return formatter
    }()
}

