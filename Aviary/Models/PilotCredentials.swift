import Foundation

// MARK: - Certifications

struct PilotCertification: Codable, Equatable, Identifiable {
    let id: UUID
    let pilotId: UUID
    let kind: String
    let title: String
    let identifier: String?
    let issuedOn: Date?
    let expiresOn: Date?
    let verified: Bool
    let documentUrl: String?
    let notes: String?
    let createdAt: Date?
    let updatedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case pilotId = "pilot_id"
        case kind
        case title
        case identifier
        case issuedOn = "issued_on"
        case expiresOn = "expires_on"
        case verified
        case documentUrl = "document_url"
        case notes
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

extension PilotCertification {
    enum Kind: String, CaseIterable, Identifiable {
        case part_107
        case trust
        case aloft
        case faa_other
        case other

        var id: String { rawValue }
        var label: String {
            switch self {
            case .part_107: return "FAA Part 107"
            case .trust:    return "TRUST recreational"
            case .aloft:    return "Aloft / LAANC"
            case .faa_other: return "Other FAA credential"
            case .other:    return "Other"
            }
        }
    }

    var kindLabel: String {
        Kind(rawValue: kind)?.label ?? kind.replacingOccurrences(of: "_", with: " ").capitalized
    }

    var expiresText: String? {
        guard let expiresOn else { return nil }
        return Self.dateFormatter.string(from: expiresOn)
    }

    var isExpired: Bool {
        guard let expiresOn else { return false }
        return expiresOn < Date()
    }

    static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "MMM d, yyyy"
        return f
    }()
}

// MARK: - Equipment

struct PilotEquipment: Codable, Equatable, Identifiable {
    let id: UUID
    let pilotId: UUID
    let kind: String
    let make: String
    let model: String
    let serialNumber: String?
    let nickname: String?
    let isPrimary: Bool
    let notes: String?
    let createdAt: Date?
    let updatedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case pilotId = "pilot_id"
        case kind
        case make
        case model
        case serialNumber = "serial_number"
        case nickname
        case isPrimary = "is_primary"
        case notes
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

extension PilotEquipment {
    enum Kind: String, CaseIterable, Identifiable {
        case drone, camera, controller, battery, accessory, other

        var id: String { rawValue }
        var label: String {
            switch self {
            case .drone:      return "Drone"
            case .camera:     return "Camera / payload"
            case .controller: return "Controller"
            case .battery:    return "Battery"
            case .accessory:  return "Accessory"
            case .other:      return "Other"
            }
        }
    }

    var kindLabel: String {
        Kind(rawValue: kind)?.label ?? kind.capitalized
    }

    var displayName: String {
        let trimmedMake = make.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedModel = model.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedMake.isEmpty { return trimmedModel }
        if trimmedModel.isEmpty { return trimmedMake }
        return "\(trimmedMake) \(trimmedModel)"
    }
}

// MARK: - Insurance

struct PilotInsurance: Codable, Equatable, Identifiable {
    let id: UUID
    let pilotId: UUID
    let provider: String
    let policyNumber: String?
    let coverageCents: Int64?
    let effectiveOn: Date?
    let expiresOn: Date?
    let documentUrl: String?
    let notes: String?
    let createdAt: Date?
    let updatedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case pilotId = "pilot_id"
        case provider
        case policyNumber = "policy_number"
        case coverageCents = "coverage_cents"
        case effectiveOn = "effective_on"
        case expiresOn = "expires_on"
        case documentUrl = "document_url"
        case notes
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

extension PilotInsurance {
    var isExpired: Bool {
        guard let expiresOn else { return false }
        return expiresOn < Date()
    }

    var coverageText: String? {
        guard let coverageCents else { return nil }
        let dollars = Double(coverageCents) / 100
        return Self.currencyFormatter.string(from: NSNumber(value: dollars))
    }

    var expiresText: String? {
        guard let expiresOn else { return nil }
        return PilotCertification.dateFormatter.string(from: expiresOn)
    }

    static let currencyFormatter: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.maximumFractionDigits = 0
        return f
    }()
}
