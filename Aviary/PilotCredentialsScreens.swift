import SwiftUI

// MARK: - Shared sheet header

private struct CredentialsHeader: View {
    @Environment(\.theme) private var t
    @Environment(\.dismiss) private var dismiss
    let title: String
    var trailing: AnyView? = nil

    var body: some View {
        HStack(spacing: 12) {
            Button { dismiss() } label: {
                AviaryIcon(name: "arrow-left", size: 22, color: t.ink)
            }
            Text(title)
                .font(AviaryFont.body(16, weight: .semibold))
                .foregroundStyle(t.ink)
            Spacer()
            if let trailing { trailing }
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 14)
    }
}

private struct CredentialsField: View {
    @Environment(\.theme) private var t
    let label: String
    @Binding var text: String
    var placeholder: String = ""
    var keyboard: UIKeyboardType = .default
    var capitalization: TextInputAutocapitalization = .sentences

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label.uppercased())
                .font(AviaryFont.body(11, weight: .semibold))
                .tracking(0.06 * 11)
                .foregroundStyle(t.ink3)
            TextField(placeholder, text: $text)
                .textInputAutocapitalization(capitalization)
                .keyboardType(keyboard)
                .autocorrectionDisabled(keyboard != .default)
                .font(AviaryFont.body(15, weight: .medium))
                .foregroundStyle(t.ink)
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous).fill(t.surface)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous).strokeBorder(t.line)
                )
        }
    }
}

private struct OptionalDateField: View {
    @Environment(\.theme) private var t
    let label: String
    @Binding var date: Date?
    @State private var localDate: Date = Date()

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label.uppercased())
                .font(AviaryFont.body(11, weight: .semibold))
                .tracking(0.06 * 11)
                .foregroundStyle(t.ink3)
            HStack(spacing: 10) {
                DatePicker("",
                           selection: Binding(
                            get: { date ?? localDate },
                            set: { date = $0; localDate = $0 }
                           ),
                           displayedComponents: .date)
                    .labelsHidden()
                    .tint(t.accent)
                if date != nil {
                    Button {
                        date = nil
                    } label: {
                        AviaryIcon(name: "x", size: 16, color: t.ink3)
                    }
                    .buttonStyle(.plain)
                } else {
                    Text("Not set")
                        .font(AviaryFont.body(13))
                        .foregroundStyle(t.ink3)
                }
                Spacer()
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous).fill(t.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous).strokeBorder(t.line)
            )
        }
    }
}

private struct PickerChips<T: Hashable & Identifiable>: View {
    @Environment(\.theme) private var t
    let label: String
    let options: [T]
    let labelFor: (T) -> String
    @Binding var selection: T

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label.uppercased())
                .font(AviaryFont.body(11, weight: .semibold))
                .tracking(0.06 * 11)
                .foregroundStyle(t.ink3)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(options) { option in
                        Button { selection = option } label: {
                            Text(labelFor(option))
                                .font(AviaryFont.body(13, weight: .medium))
                                .foregroundStyle(option == selection ? t.accentInk : t.ink2)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(
                                    Capsule().fill(option == selection ? t.accent : t.surface2)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }
}

private struct InlineErrorBanner: View {
    @Environment(\.theme) private var t
    let message: String
    var body: some View {
        HStack(spacing: 8) {
            AviaryIcon(name: "x", size: 14, color: t.warn)
            Text(message)
                .font(AviaryFont.body(12, weight: .medium))
                .foregroundStyle(t.warn)
            Spacer()
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 10).fill(t.warn.opacity(0.1))
        )
    }
}

// MARK: - Certifications screen

struct CertificationsScreen: View {
    @Environment(\.theme) private var t
    let pilotID: UUID

    @State private var items: [PilotCertification] = []
    @State private var isLoading: Bool = false
    @State private var errorMessage: String?
    @State private var editingItem: PilotCertification?
    @State private var showingNew: Bool = false

    var body: some View {
        ZStack {
            t.bg.ignoresSafeArea()
            VStack(spacing: 0) {
                CredentialsHeader(
                    title: "Certifications",
                    trailing: AnyView(
                        Button { showingNew = true } label: {
                            HStack(spacing: 4) {
                                AviaryIcon(name: "plus", size: 14, color: t.accent)
                                Text("Add").font(AviaryFont.body(13, weight: .semibold))
                                    .foregroundStyle(t.accent)
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Capsule().fill(t.accentSoft))
                        }
                    )
                )

                content
            }
        }
        .task { await reload() }
        .sheet(isPresented: $showingNew) {
            CertificationEditor(pilotID: pilotID, existing: nil) { saved in
                items.insert(saved, at: 0)
            }
            .environment(\.theme, t)
        }
        .sheet(item: $editingItem) { cert in
            CertificationEditor(pilotID: pilotID, existing: cert) { saved in
                if let idx = items.firstIndex(where: { $0.id == saved.id }) {
                    items[idx] = saved
                }
            } onDelete: { id in
                items.removeAll { $0.id == id }
            }
            .environment(\.theme, t)
        }
    }

    @ViewBuilder
    private var content: some View {
        if isLoading {
            Spacer()
            FeatureStateCard(icon: "cert", title: "Loading", message: "Fetching your certifications.")
                .padding(.horizontal, 24)
            Spacer()
        } else if let errorMessage {
            Spacer()
            FeatureStateCard(icon: "cloud", title: "Couldn't load",
                             message: errorMessage,
                             buttonTitle: "Try again",
                             action: { Task { await reload() } })
                .padding(.horizontal, 24)
            Spacer()
        } else if items.isEmpty {
            Spacer()
            FeatureStateCard(icon: "cert",
                             title: "No certifications yet",
                             message: "Add your Part 107, TRUST, or other credentials so customers know you're cleared to fly.",
                             buttonTitle: "Add credential",
                             action: { showingNew = true })
                .padding(.horizontal, 24)
            Spacer()
        } else {
            ScrollView {
                LazyVStack(spacing: 10) {
                    ForEach(items) { cert in
                        Button { editingItem = cert } label: {
                            certRow(cert)
                        }
                        .buttonStyle(PressableButtonStyle())
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 32)
            }
        }
    }

    private func certRow(_ cert: PilotCertification) -> some View {
        AviaryCard(padding: 14) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10).fill(t.accentSoft)
                    AviaryIcon(name: "cert", size: 18, color: t.accent)
                }
                .frame(width: 38, height: 38)
                VStack(alignment: .leading, spacing: 2) {
                    Text(cert.title)
                        .font(AviaryFont.body(15, weight: .semibold))
                        .foregroundStyle(t.ink)
                        .lineLimit(1)
                    HStack(spacing: 6) {
                        Text(cert.kindLabel)
                            .font(AviaryFont.body(12))
                            .foregroundStyle(t.ink3)
                        if let id = cert.identifier, !id.isEmpty {
                            Text("· \(id)")
                                .font(AviaryFont.body(12))
                                .foregroundStyle(t.ink3)
                                .lineLimit(1)
                        }
                    }
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    if cert.verified {
                        Chip(text: "Verified", icon: "check", style: .good)
                    } else if cert.isExpired {
                        Chip(text: "Expired", style: .warn)
                    } else if let exp = cert.expiresText {
                        Chip(text: "Exp \(exp)")
                    }
                }
            }
        }
    }

    private func reload() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            items = try await PilotCredentialsService.shared.certifications(for: pilotID)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

// MARK: - Certification editor

private struct CertificationEditor: View {
    @Environment(\.theme) private var t
    @Environment(\.dismiss) private var dismiss
    let pilotID: UUID
    let existing: PilotCertification?
    var onSave: (PilotCertification) -> Void
    var onDelete: ((UUID) -> Void)? = nil

    @State private var kind: PilotCertification.Kind = .part_107
    @State private var title: String = ""
    @State private var identifier: String = ""
    @State private var issuedOn: Date?
    @State private var expiresOn: Date?
    @State private var notes: String = ""
    @State private var isSaving: Bool = false
    @State private var isDeleting: Bool = false
    @State private var errorMessage: String?

    var body: some View {
        ZStack(alignment: .top) {
            t.bg.ignoresSafeArea()
            VStack(spacing: 0) {
                CredentialsHeader(title: existing == nil ? "New certification" : "Edit certification")
                ScrollView {
                    VStack(alignment: .leading, spacing: 14) {
                        if let errorMessage { InlineErrorBanner(message: errorMessage) }

                        PickerChips(label: "Type",
                                    options: PilotCertification.Kind.allCases,
                                    labelFor: { $0.label },
                                    selection: $kind)

                        CredentialsField(label: "Title",
                                         text: $title,
                                         placeholder: "Part 107 Remote Pilot")
                        CredentialsField(label: "License / certificate #",
                                         text: $identifier,
                                         placeholder: "1234567",
                                         capitalization: .characters)

                        OptionalDateField(label: "Issued", date: $issuedOn)
                        OptionalDateField(label: "Expires", date: $expiresOn)

                        CredentialsField(label: "Notes (optional)",
                                         text: $notes,
                                         placeholder: "Anything else customers should know")

                        PrimaryButton(title: existing == nil ? "Add certification" : "Save changes",
                                      enabled: canSave && !isSaving) {
                            Task { await save() }
                        }
                        .padding(.top, 4)

                        if existing != nil {
                            Button(role: .destructive) {
                                Task { await delete() }
                            } label: {
                                HStack {
                                    Spacer()
                                    Text(isDeleting ? "Deleting…" : "Delete")
                                        .font(AviaryFont.body(15, weight: .semibold))
                                        .foregroundStyle(t.bad)
                                    Spacer()
                                }
                                .padding(.vertical, 14)
                            }
                            .disabled(isDeleting || isSaving)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 32)
                }
            }
        }
        .onAppear(perform: load)
    }

    private var canSave: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func load() {
        guard let existing else { return }
        kind = PilotCertification.Kind(rawValue: existing.kind) ?? .other
        title = existing.title
        identifier = existing.identifier ?? ""
        issuedOn = existing.issuedOn
        expiresOn = existing.expiresOn
        notes = existing.notes ?? ""
    }

    private func save() async {
        errorMessage = nil
        isSaving = true
        defer { isSaving = false }
        let draft = PilotCredentialsService.CertificationDraft(
            kind: kind.rawValue,
            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
            identifier: optional(identifier),
            issuedOn: issuedOn,
            expiresOn: expiresOn,
            notes: optional(notes)
        )
        do {
            let saved: PilotCertification
            if let existing {
                saved = try await PilotCredentialsService.shared.updateCertification(id: existing.id, draft: draft)
            } else {
                saved = try await PilotCredentialsService.shared.createCertification(draft, pilotID: pilotID)
            }
            onSave(saved)
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func delete() async {
        guard let existing else { return }
        errorMessage = nil
        isDeleting = true
        defer { isDeleting = false }
        do {
            try await PilotCredentialsService.shared.deleteCertification(id: existing.id)
            onDelete?(existing.id)
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func optional(_ text: String) -> String? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}

// MARK: - Equipment screen

struct EquipmentScreen: View {
    @Environment(\.theme) private var t
    let pilotID: UUID

    @State private var items: [PilotEquipment] = []
    @State private var isLoading: Bool = false
    @State private var errorMessage: String?
    @State private var editingItem: PilotEquipment?
    @State private var showingNew: Bool = false

    var body: some View {
        ZStack {
            t.bg.ignoresSafeArea()
            VStack(spacing: 0) {
                CredentialsHeader(
                    title: "Equipment",
                    trailing: AnyView(
                        Button { showingNew = true } label: {
                            HStack(spacing: 4) {
                                AviaryIcon(name: "plus", size: 14, color: t.accent)
                                Text("Add").font(AviaryFont.body(13, weight: .semibold))
                                    .foregroundStyle(t.accent)
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Capsule().fill(t.accentSoft))
                        }
                    )
                )

                content
            }
        }
        .task { await reload() }
        .sheet(isPresented: $showingNew) {
            EquipmentEditor(pilotID: pilotID, existing: nil) { saved in
                items.insert(saved, at: 0)
                items = items.sorted { lhs, rhs in
                    if lhs.isPrimary != rhs.isPrimary { return lhs.isPrimary }
                    return (lhs.createdAt ?? .distantPast) > (rhs.createdAt ?? .distantPast)
                }
            }
            .environment(\.theme, t)
        }
        .sheet(item: $editingItem) { item in
            EquipmentEditor(pilotID: pilotID, existing: item) { saved in
                if let idx = items.firstIndex(where: { $0.id == saved.id }) {
                    items[idx] = saved
                }
            } onDelete: { id in
                items.removeAll { $0.id == id }
            }
            .environment(\.theme, t)
        }
    }

    @ViewBuilder
    private var content: some View {
        if isLoading {
            Spacer()
            FeatureStateCard(icon: "drone", title: "Loading", message: "Fetching your equipment.")
                .padding(.horizontal, 24)
            Spacer()
        } else if let errorMessage {
            Spacer()
            FeatureStateCard(icon: "cloud", title: "Couldn't load",
                             message: errorMessage,
                             buttonTitle: "Try again",
                             action: { Task { await reload() } })
                .padding(.horizontal, 24)
            Spacer()
        } else if items.isEmpty {
            Spacer()
            FeatureStateCard(icon: "drone",
                             title: "No equipment yet",
                             message: "Add the drones, cameras, and gear you fly with so customers can match you to the right job.",
                             buttonTitle: "Add equipment",
                             action: { showingNew = true })
                .padding(.horizontal, 24)
            Spacer()
        } else {
            ScrollView {
                LazyVStack(spacing: 10) {
                    ForEach(items) { item in
                        Button { editingItem = item } label: {
                            equipmentRow(item)
                        }
                        .buttonStyle(PressableButtonStyle())
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 32)
            }
        }
    }

    private func equipmentRow(_ item: PilotEquipment) -> some View {
        AviaryCard(padding: 14) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10).fill(t.accentSoft)
                    AviaryIcon(name: iconFor(item.kind), size: 18, color: t.accent)
                }
                .frame(width: 38, height: 38)
                VStack(alignment: .leading, spacing: 2) {
                    Text(item.displayName)
                        .font(AviaryFont.body(15, weight: .semibold))
                        .foregroundStyle(t.ink)
                        .lineLimit(1)
                    HStack(spacing: 6) {
                        Text(item.kindLabel)
                            .font(AviaryFont.body(12))
                            .foregroundStyle(t.ink3)
                        if let nickname = item.nickname, !nickname.isEmpty {
                            Text("· \(nickname)")
                                .font(AviaryFont.body(12))
                                .foregroundStyle(t.ink3)
                                .lineLimit(1)
                        }
                    }
                }
                Spacer()
                if item.isPrimary {
                    Chip(text: "Primary", icon: "star", style: .accent)
                }
            }
        }
    }

    private func iconFor(_ kind: String) -> String {
        switch PilotEquipment.Kind(rawValue: kind) ?? .other {
        case .drone:      return "drone"
        case .camera:     return "camera"
        case .controller: return "sliders"
        case .battery:    return "battery"
        case .accessory:  return "briefcase"
        case .other:      return "briefcase"
        }
    }

    private func reload() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            items = try await PilotCredentialsService.shared.equipment(for: pilotID)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

// MARK: - Equipment editor

private struct EquipmentEditor: View {
    @Environment(\.theme) private var t
    @Environment(\.dismiss) private var dismiss
    let pilotID: UUID
    let existing: PilotEquipment?
    var onSave: (PilotEquipment) -> Void
    var onDelete: ((UUID) -> Void)? = nil

    @State private var kind: PilotEquipment.Kind = .drone
    @State private var make: String = ""
    @State private var model: String = ""
    @State private var serialNumber: String = ""
    @State private var nickname: String = ""
    @State private var isPrimary: Bool = false
    @State private var notes: String = ""
    @State private var isSaving: Bool = false
    @State private var isDeleting: Bool = false
    @State private var errorMessage: String?

    var body: some View {
        ZStack(alignment: .top) {
            t.bg.ignoresSafeArea()
            VStack(spacing: 0) {
                CredentialsHeader(title: existing == nil ? "New equipment" : "Edit equipment")
                ScrollView {
                    VStack(alignment: .leading, spacing: 14) {
                        if let errorMessage { InlineErrorBanner(message: errorMessage) }

                        PickerChips(label: "Type",
                                    options: PilotEquipment.Kind.allCases,
                                    labelFor: { $0.label },
                                    selection: $kind)

                        CredentialsField(label: "Make", text: $make, placeholder: "DJI",
                                         capitalization: .words)
                        CredentialsField(label: "Model", text: $model, placeholder: "Mavic 3 Pro",
                                         capitalization: .words)
                        CredentialsField(label: "Nickname (optional)", text: $nickname,
                                         placeholder: "Lead bird", capitalization: .words)
                        CredentialsField(label: "Serial number (optional)", text: $serialNumber,
                                         placeholder: "SN-…", capitalization: .characters)

                        Toggle(isOn: $isPrimary) {
                            Text("Mark as primary")
                                .font(AviaryFont.body(14, weight: .medium))
                                .foregroundStyle(t.ink)
                        }
                        .tint(t.accent)
                        .padding(.horizontal, 4)

                        CredentialsField(label: "Notes (optional)", text: $notes,
                                         placeholder: "Anything else worth noting")

                        PrimaryButton(title: existing == nil ? "Add equipment" : "Save changes",
                                      enabled: canSave && !isSaving) {
                            Task { await save() }
                        }
                        .padding(.top, 4)

                        if existing != nil {
                            Button(role: .destructive) {
                                Task { await delete() }
                            } label: {
                                HStack {
                                    Spacer()
                                    Text(isDeleting ? "Deleting…" : "Delete")
                                        .font(AviaryFont.body(15, weight: .semibold))
                                        .foregroundStyle(t.bad)
                                    Spacer()
                                }
                                .padding(.vertical, 14)
                            }
                            .disabled(isDeleting || isSaving)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 32)
                }
            }
        }
        .onAppear(perform: load)
    }

    private var canSave: Bool {
        !make.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !model.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func load() {
        guard let existing else { return }
        kind = PilotEquipment.Kind(rawValue: existing.kind) ?? .other
        make = existing.make
        model = existing.model
        serialNumber = existing.serialNumber ?? ""
        nickname = existing.nickname ?? ""
        isPrimary = existing.isPrimary
        notes = existing.notes ?? ""
    }

    private func save() async {
        errorMessage = nil
        isSaving = true
        defer { isSaving = false }
        let draft = PilotCredentialsService.EquipmentDraft(
            kind: kind.rawValue,
            make: make.trimmingCharacters(in: .whitespacesAndNewlines),
            model: model.trimmingCharacters(in: .whitespacesAndNewlines),
            serialNumber: optional(serialNumber),
            nickname: optional(nickname),
            isPrimary: isPrimary,
            notes: optional(notes)
        )
        do {
            let saved: PilotEquipment
            if let existing {
                saved = try await PilotCredentialsService.shared.updateEquipment(id: existing.id, draft: draft)
            } else {
                saved = try await PilotCredentialsService.shared.createEquipment(draft, pilotID: pilotID)
            }
            onSave(saved)
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func delete() async {
        guard let existing else { return }
        errorMessage = nil
        isDeleting = true
        defer { isDeleting = false }
        do {
            try await PilotCredentialsService.shared.deleteEquipment(id: existing.id)
            onDelete?(existing.id)
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func optional(_ text: String) -> String? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}

// MARK: - Insurance screen

struct InsuranceScreen: View {
    @Environment(\.theme) private var t
    let pilotID: UUID

    @State private var items: [PilotInsurance] = []
    @State private var isLoading: Bool = false
    @State private var errorMessage: String?
    @State private var editingItem: PilotInsurance?
    @State private var showingNew: Bool = false

    var body: some View {
        ZStack {
            t.bg.ignoresSafeArea()
            VStack(spacing: 0) {
                CredentialsHeader(
                    title: "Insurance",
                    trailing: AnyView(
                        Button { showingNew = true } label: {
                            HStack(spacing: 4) {
                                AviaryIcon(name: "plus", size: 14, color: t.accent)
                                Text("Add").font(AviaryFont.body(13, weight: .semibold))
                                    .foregroundStyle(t.accent)
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Capsule().fill(t.accentSoft))
                        }
                    )
                )

                content
            }
        }
        .task { await reload() }
        .sheet(isPresented: $showingNew) {
            InsuranceEditor(pilotID: pilotID, existing: nil) { saved in
                items.insert(saved, at: 0)
            }
            .environment(\.theme, t)
        }
        .sheet(item: $editingItem) { item in
            InsuranceEditor(pilotID: pilotID, existing: item) { saved in
                if let idx = items.firstIndex(where: { $0.id == saved.id }) {
                    items[idx] = saved
                }
            } onDelete: { id in
                items.removeAll { $0.id == id }
            }
            .environment(\.theme, t)
        }
    }

    @ViewBuilder
    private var content: some View {
        if isLoading {
            Spacer()
            FeatureStateCard(icon: "shield", title: "Loading", message: "Fetching your insurance.")
                .padding(.horizontal, 24)
            Spacer()
        } else if let errorMessage {
            Spacer()
            FeatureStateCard(icon: "cloud", title: "Couldn't load",
                             message: errorMessage,
                             buttonTitle: "Try again",
                             action: { Task { await reload() } })
                .padding(.horizontal, 24)
            Spacer()
        } else if items.isEmpty {
            Spacer()
            FeatureStateCard(icon: "shield",
                             title: "No insurance on file",
                             message: "Add a liability policy so customers can verify you're covered before assigning gigs.",
                             buttonTitle: "Add policy",
                             action: { showingNew = true })
                .padding(.horizontal, 24)
            Spacer()
        } else {
            ScrollView {
                LazyVStack(spacing: 10) {
                    ForEach(items) { item in
                        Button { editingItem = item } label: {
                            insuranceRow(item)
                        }
                        .buttonStyle(PressableButtonStyle())
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 32)
            }
        }
    }

    private func insuranceRow(_ item: PilotInsurance) -> some View {
        AviaryCard(padding: 14) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10).fill(t.accentSoft)
                    AviaryIcon(name: "shield", size: 18, color: t.accent)
                }
                .frame(width: 38, height: 38)
                VStack(alignment: .leading, spacing: 2) {
                    Text(item.provider)
                        .font(AviaryFont.body(15, weight: .semibold))
                        .foregroundStyle(t.ink)
                        .lineLimit(1)
                    HStack(spacing: 6) {
                        if let coverage = item.coverageText {
                            Text(coverage)
                                .font(AviaryFont.body(12, weight: .medium))
                                .foregroundStyle(t.ink2)
                        }
                        if let policy = item.policyNumber, !policy.isEmpty {
                            Text("· \(policy)")
                                .font(AviaryFont.body(12))
                                .foregroundStyle(t.ink3)
                                .lineLimit(1)
                        }
                    }
                }
                Spacer()
                if item.isExpired {
                    Chip(text: "Expired", style: .warn)
                } else if let exp = item.expiresText {
                    Chip(text: "Exp \(exp)")
                }
            }
        }
    }

    private func reload() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            items = try await PilotCredentialsService.shared.insurance(for: pilotID)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

// MARK: - Insurance editor

private struct InsuranceEditor: View {
    @Environment(\.theme) private var t
    @Environment(\.dismiss) private var dismiss
    let pilotID: UUID
    let existing: PilotInsurance?
    var onSave: (PilotInsurance) -> Void
    var onDelete: ((UUID) -> Void)? = nil

    @State private var provider: String = ""
    @State private var policyNumber: String = ""
    @State private var coverageDollars: String = ""
    @State private var effectiveOn: Date?
    @State private var expiresOn: Date?
    @State private var notes: String = ""
    @State private var isSaving: Bool = false
    @State private var isDeleting: Bool = false
    @State private var errorMessage: String?

    var body: some View {
        ZStack(alignment: .top) {
            t.bg.ignoresSafeArea()
            VStack(spacing: 0) {
                CredentialsHeader(title: existing == nil ? "New policy" : "Edit policy")
                ScrollView {
                    VStack(alignment: .leading, spacing: 14) {
                        if let errorMessage { InlineErrorBanner(message: errorMessage) }

                        CredentialsField(label: "Provider", text: $provider,
                                         placeholder: "SkyWatch.AI", capitalization: .words)
                        CredentialsField(label: "Policy number (optional)", text: $policyNumber,
                                         placeholder: "POL-12345", capitalization: .characters)
                        CredentialsField(label: "Coverage amount (USD, optional)",
                                         text: $coverageDollars,
                                         placeholder: "2000000",
                                         keyboard: .numberPad,
                                         capitalization: .never)

                        OptionalDateField(label: "Effective", date: $effectiveOn)
                        OptionalDateField(label: "Expires", date: $expiresOn)

                        CredentialsField(label: "Notes (optional)", text: $notes,
                                         placeholder: "Anything else customers should see")

                        PrimaryButton(title: existing == nil ? "Add policy" : "Save changes",
                                      enabled: canSave && !isSaving) {
                            Task { await save() }
                        }
                        .padding(.top, 4)

                        if existing != nil {
                            Button(role: .destructive) {
                                Task { await delete() }
                            } label: {
                                HStack {
                                    Spacer()
                                    Text(isDeleting ? "Deleting…" : "Delete")
                                        .font(AviaryFont.body(15, weight: .semibold))
                                        .foregroundStyle(t.bad)
                                    Spacer()
                                }
                                .padding(.vertical, 14)
                            }
                            .disabled(isDeleting || isSaving)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 32)
                }
            }
        }
        .onAppear(perform: load)
    }

    private var canSave: Bool {
        !provider.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func load() {
        guard let existing else { return }
        provider = existing.provider
        policyNumber = existing.policyNumber ?? ""
        if let cents = existing.coverageCents {
            coverageDollars = String(cents / 100)
        }
        effectiveOn = existing.effectiveOn
        expiresOn = existing.expiresOn
        notes = existing.notes ?? ""
    }

    private func save() async {
        errorMessage = nil
        isSaving = true
        defer { isSaving = false }
        let trimmedDollars = coverageDollars.trimmingCharacters(in: .whitespacesAndNewlines)
        let cents: Int64?
        if trimmedDollars.isEmpty {
            cents = nil
        } else if let dollars = Int64(trimmedDollars) {
            cents = dollars * 100
        } else {
            errorMessage = "Coverage must be a whole number in dollars."
            return
        }

        let draft = PilotCredentialsService.InsuranceDraft(
            provider: provider.trimmingCharacters(in: .whitespacesAndNewlines),
            policyNumber: optional(policyNumber),
            coverageCents: cents,
            effectiveOn: effectiveOn,
            expiresOn: expiresOn,
            notes: optional(notes)
        )

        do {
            let saved: PilotInsurance
            if let existing {
                saved = try await PilotCredentialsService.shared.updateInsurance(id: existing.id, draft: draft)
            } else {
                saved = try await PilotCredentialsService.shared.createInsurance(draft, pilotID: pilotID)
            }
            onSave(saved)
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func delete() async {
        guard let existing else { return }
        errorMessage = nil
        isDeleting = true
        defer { isDeleting = false }
        do {
            try await PilotCredentialsService.shared.deleteInsurance(id: existing.id)
            onDelete?(existing.id)
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func optional(_ text: String) -> String? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
