import Foundation
import Supabase

final class PilotCredentialsService {
    static let shared = PilotCredentialsService()

    private let client = Backend.client

    private init() {}

    // MARK: - Certifications

    func certifications(for pilotID: UUID) async throws -> [PilotCertification] {
        guard SupabaseConfig.isConfigured else { throw AviaryDataError.notConfigured }
        let rows: [PilotCertification] = try await client
            .from("pilot_certifications")
            .select()
            .eq("pilot_id", value: pilotID)
            .execute()
            .value
        return rows.sorted { ($0.createdAt ?? .distantPast) > ($1.createdAt ?? .distantPast) }
    }

    func createCertification(_ draft: CertificationDraft, pilotID: UUID) async throws -> PilotCertification {
        guard SupabaseConfig.isConfigured else { throw AviaryDataError.notConfigured }
        let row = CertificationInsert(
            pilot_id: pilotID,
            kind: draft.kind,
            title: draft.title,
            identifier: draft.identifier,
            issued_on: draft.issuedOn,
            expires_on: draft.expiresOn,
            notes: draft.notes
        )
        let cert: PilotCertification = try await client
            .from("pilot_certifications")
            .insert(row)
            .select()
            .single()
            .execute()
            .value
        return cert
    }

    func updateCertification(id: UUID, draft: CertificationDraft) async throws -> PilotCertification {
        guard SupabaseConfig.isConfigured else { throw AviaryDataError.notConfigured }
        let row = CertificationUpdate(
            kind: draft.kind,
            title: draft.title,
            identifier: draft.identifier,
            issued_on: draft.issuedOn,
            expires_on: draft.expiresOn,
            notes: draft.notes
        )
        let cert: PilotCertification = try await client
            .from("pilot_certifications")
            .update(row)
            .eq("id", value: id)
            .select()
            .single()
            .execute()
            .value
        return cert
    }

    func deleteCertification(id: UUID) async throws {
        guard SupabaseConfig.isConfigured else { throw AviaryDataError.notConfigured }
        try await client
            .from("pilot_certifications")
            .delete()
            .eq("id", value: id)
            .execute()
    }

    // MARK: - Equipment

    func equipment(for pilotID: UUID) async throws -> [PilotEquipment] {
        guard SupabaseConfig.isConfigured else { throw AviaryDataError.notConfigured }
        let rows: [PilotEquipment] = try await client
            .from("pilot_equipment")
            .select()
            .eq("pilot_id", value: pilotID)
            .execute()
            .value
        return rows.sorted { lhs, rhs in
            if lhs.isPrimary != rhs.isPrimary { return lhs.isPrimary }
            return (lhs.createdAt ?? .distantPast) > (rhs.createdAt ?? .distantPast)
        }
    }

    func createEquipment(_ draft: EquipmentDraft, pilotID: UUID) async throws -> PilotEquipment {
        guard SupabaseConfig.isConfigured else { throw AviaryDataError.notConfigured }
        let row = EquipmentInsert(
            pilot_id: pilotID,
            kind: draft.kind,
            make: draft.make,
            model: draft.model,
            serial_number: draft.serialNumber,
            nickname: draft.nickname,
            is_primary: draft.isPrimary,
            notes: draft.notes
        )
        let item: PilotEquipment = try await client
            .from("pilot_equipment")
            .insert(row)
            .select()
            .single()
            .execute()
            .value
        return item
    }

    func updateEquipment(id: UUID, draft: EquipmentDraft) async throws -> PilotEquipment {
        guard SupabaseConfig.isConfigured else { throw AviaryDataError.notConfigured }
        let row = EquipmentUpdate(
            kind: draft.kind,
            make: draft.make,
            model: draft.model,
            serial_number: draft.serialNumber,
            nickname: draft.nickname,
            is_primary: draft.isPrimary,
            notes: draft.notes
        )
        let item: PilotEquipment = try await client
            .from("pilot_equipment")
            .update(row)
            .eq("id", value: id)
            .select()
            .single()
            .execute()
            .value
        return item
    }

    func deleteEquipment(id: UUID) async throws {
        guard SupabaseConfig.isConfigured else { throw AviaryDataError.notConfigured }
        try await client
            .from("pilot_equipment")
            .delete()
            .eq("id", value: id)
            .execute()
    }

    // MARK: - Insurance

    func insurance(for pilotID: UUID) async throws -> [PilotInsurance] {
        guard SupabaseConfig.isConfigured else { throw AviaryDataError.notConfigured }
        let rows: [PilotInsurance] = try await client
            .from("pilot_insurance")
            .select()
            .eq("pilot_id", value: pilotID)
            .execute()
            .value
        return rows.sorted { ($0.createdAt ?? .distantPast) > ($1.createdAt ?? .distantPast) }
    }

    func createInsurance(_ draft: InsuranceDraft, pilotID: UUID) async throws -> PilotInsurance {
        guard SupabaseConfig.isConfigured else { throw AviaryDataError.notConfigured }
        let row = InsuranceInsert(
            pilot_id: pilotID,
            provider: draft.provider,
            policy_number: draft.policyNumber,
            coverage_cents: draft.coverageCents,
            effective_on: draft.effectiveOn,
            expires_on: draft.expiresOn,
            notes: draft.notes
        )
        let item: PilotInsurance = try await client
            .from("pilot_insurance")
            .insert(row)
            .select()
            .single()
            .execute()
            .value
        return item
    }

    func updateInsurance(id: UUID, draft: InsuranceDraft) async throws -> PilotInsurance {
        guard SupabaseConfig.isConfigured else { throw AviaryDataError.notConfigured }
        let row = InsuranceUpdate(
            provider: draft.provider,
            policy_number: draft.policyNumber,
            coverage_cents: draft.coverageCents,
            effective_on: draft.effectiveOn,
            expires_on: draft.expiresOn,
            notes: draft.notes
        )
        let item: PilotInsurance = try await client
            .from("pilot_insurance")
            .update(row)
            .eq("id", value: id)
            .select()
            .single()
            .execute()
            .value
        return item
    }

    func deleteInsurance(id: UUID) async throws {
        guard SupabaseConfig.isConfigured else { throw AviaryDataError.notConfigured }
        try await client
            .from("pilot_insurance")
            .delete()
            .eq("id", value: id)
            .execute()
    }
}

extension PilotCredentialsService {
    struct CertificationDraft {
        var kind: String
        var title: String
        var identifier: String?
        var issuedOn: Date?
        var expiresOn: Date?
        var notes: String?
    }

    struct EquipmentDraft {
        var kind: String
        var make: String
        var model: String
        var serialNumber: String?
        var nickname: String?
        var isPrimary: Bool
        var notes: String?
    }

    struct InsuranceDraft {
        var provider: String
        var policyNumber: String?
        var coverageCents: Int64?
        var effectiveOn: Date?
        var expiresOn: Date?
        var notes: String?
    }
}

// MARK: - Insert/Update payloads

private struct CertificationInsert: Encodable {
    let pilot_id: UUID
    let kind: String
    let title: String
    let identifier: String?
    let issued_on: Date?
    let expires_on: Date?
    let notes: String?
}

private struct CertificationUpdate: Encodable {
    let kind: String
    let title: String
    let identifier: String?
    let issued_on: Date?
    let expires_on: Date?
    let notes: String?
}

private struct EquipmentInsert: Encodable {
    let pilot_id: UUID
    let kind: String
    let make: String
    let model: String
    let serial_number: String?
    let nickname: String?
    let is_primary: Bool
    let notes: String?
}

private struct EquipmentUpdate: Encodable {
    let kind: String
    let make: String
    let model: String
    let serial_number: String?
    let nickname: String?
    let is_primary: Bool
    let notes: String?
}

private struct InsuranceInsert: Encodable {
    let pilot_id: UUID
    let provider: String
    let policy_number: String?
    let coverage_cents: Int64?
    let effective_on: Date?
    let expires_on: Date?
    let notes: String?
}

private struct InsuranceUpdate: Encodable {
    let provider: String
    let policy_number: String?
    let coverage_cents: Int64?
    let effective_on: Date?
    let expires_on: Date?
    let notes: String?
}
