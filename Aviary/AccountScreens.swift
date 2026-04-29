import CoreLocation
import MapKit
import PhotosUI
import SwiftUI

// MARK: - Earnings sheet wrapper

struct EarningsSheet: View {
    @Environment(\.theme) private var t
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack(alignment: .top) {
            t.bg.ignoresSafeArea()
            EarningsScreen()
                .padding(.top, 44)
            HStack(spacing: 12) {
                Button { dismiss() } label: {
                    AviaryIcon(name: "arrow-left", size: 22, color: t.ink)
                }
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
        }
    }
}

// MARK: - Earnings

struct EarningsScreen: View {
    @Environment(\.theme) private var t
    @EnvironmentObject private var demoStore: DemoModeStore

    private struct Day: Identifiable { let id = UUID(); var d: String; var h: CGFloat; var active: Bool = false }
    private let days: [Day] = [
        .init(d: "M", h: 28), .init(d: "T", h: 52), .init(d: "W", h: 70),
        .init(d: "T", h: 38), .init(d: "F", h: 92),
        .init(d: "S", h: 110, active: true), .init(d: "S", h: 18),
    ]

    var body: some View {
        ZStack {
            t.bg.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 0) {
                    PageHeader(title: "Earnings") {
                        Chip(text: "This week ▾")
                    }

                    if demoStore.isOn {
                        weeklyCard
                            .padding(.horizontal, 20)
                            .padding(.bottom, 14)

                        HStack(spacing: 10) {
                            balanceCard(label: "Available", amount: "$1,484.00",
                                        sub: "Cash out →", subColor: t.accent)
                            balanceCard(label: "In review", amount: "$664.50",
                                        sub: "2 gigs pending", subColor: t.ink4)
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 18)

                        SectionTitle(text: "Recent gigs")
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 20)
                            .padding(.bottom, 8)

                        VStack(spacing: 0) {
                            recentRow(title: "Wedding aerial · Tilden Park", date: "Sat 5:00 PM",
                                      amt: "$780.00", icon: "check-circle", color: t.good, divider: true)
                            recentRow(title: "Construction · 500 Folsom", date: "Fri 9:00 AM",
                                      amt: "$485.00", icon: "check-circle", color: t.good, divider: true)
                            recentRow(title: "Roof inspection · 22 Hillside", date: "Thu 4:30 PM",
                                      amt: "$220.00", icon: "clock", color: t.warn, divider: false)
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 24)
                    } else {
                        emptyWeeklyCard
                            .padding(.horizontal, 20)
                            .padding(.bottom, 14)

                        HStack(spacing: 10) {
                            balanceCard(label: "Available", amount: "$0.00",
                                        sub: "Nothing to cash out", subColor: t.ink4)
                            balanceCard(label: "In review", amount: "$0.00",
                                        sub: "0 gigs pending", subColor: t.ink4)
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 18)

                        SectionTitle(text: "Recent gigs")
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 20)
                            .padding(.bottom, 8)

                        AviaryCard(padding: 22) {
                            VStack(alignment: .leading, spacing: 10) {
                                AviaryIcon(name: "wallet", size: 24, color: t.ink3)
                                Text("No completed gigs yet")
                                    .font(AviaryFont.body(15, weight: .semibold))
                                    .foregroundStyle(t.ink)
                                Text("Earnings show up here once a gig wraps and clears review.")
                                    .font(AviaryFont.body(13))
                                    .foregroundStyle(t.ink3)
                                    .lineSpacing(2)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 24)
                    }
                }
            }
        }
    }

    private func balanceCard(label: String, amount: String, sub: String, subColor: Color) -> some View {
        AviaryCard(padding: 14) {
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(AviaryFont.body(12))
                    .foregroundStyle(t.ink3)
                Text(amount)
                    .font(AviaryFont.mono(22, weight: .semibold))
                    .foregroundStyle(t.ink)
                Text(sub)
                    .font(AviaryFont.body(11, weight: .semibold))
                    .foregroundStyle(subColor)
                    .padding(.top, 4)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var emptyWeeklyCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("EARNED THIS WEEK")
                .font(AviaryFont.body(12, weight: .medium))
                .tracking(0.04 * 12)
                .foregroundStyle(t.accentInk.opacity(0.85))
            HStack(alignment: .lastTextBaseline, spacing: 0) {
                Text("$0")
                    .font(AviaryFont.mono(42, weight: .semibold))
                    .tracking(-0.03 * 42)
                    .foregroundStyle(t.accentInk)
                Text(".00")
                    .font(AviaryFont.mono(22, weight: .semibold))
                    .foregroundStyle(t.accentInk.opacity(0.7))
            }
            .padding(.top, 4)
            Text("0 gigs this week")
                .font(AviaryFont.body(12))
                .foregroundStyle(t.accentInk.opacity(0.7))
                .padding(.top, 12)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(colors: [t.accent, Color(hex: 0x6B5BFF).mix(with: t.accent, by: 0.7)],
                           startPoint: .topLeading, endPoint: .bottomTrailing)
        )
        .clipShape(RoundedRectangle(cornerRadius: Radius.md, style: .continuous))
    }

    private var weeklyCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("EARNED THIS WEEK")
                .font(AviaryFont.body(12, weight: .medium))
                .tracking(0.04 * 12)
                .foregroundStyle(t.accentInk.opacity(0.85))
            HStack(alignment: .lastTextBaseline, spacing: 0) {
                Text("$2,148")
                    .font(AviaryFont.mono(42, weight: .semibold))
                    .tracking(-0.03 * 42)
                    .foregroundStyle(t.accentInk)
                Text(".50")
                    .font(AviaryFont.mono(22, weight: .semibold))
                    .foregroundStyle(t.accentInk.opacity(0.7))
            }
            .padding(.top, 4)

            HStack(spacing: 18) {
                Text("6 gigs")
                    .font(AviaryFont.body(12))
                    .foregroundStyle(t.accentInk.opacity(0.7))
                Text("↑ 24% vs last week")
                    .font(AviaryFont.body(12))
                    .foregroundStyle(t.accentInk.opacity(0.7))
            }
            .padding(.top, 12)

            HStack(alignment: .bottom, spacing: 6) {
                ForEach(days) { day in
                    VStack(spacing: 6) {
                        Spacer(minLength: 0)
                        RoundedRectangle(cornerRadius: 4)
                            .fill(day.active ? Color.white : Color.white.opacity(0.35))
                            .frame(width: 16, height: day.h)
                        Text(day.d)
                            .font(AviaryFont.body(10))
                            .foregroundStyle(t.accentInk.opacity(0.7))
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .frame(height: 130)
            .padding(.top, 18)
            .overlay(
                Rectangle().fill(Color.white.opacity(0.18)).frame(height: 1),
                alignment: .top
            )
            .padding(.top, 8)
        }
        .padding(18)
        .background(
            LinearGradient(colors: [t.accent, Color(hex: 0x6B5BFF).mix(with: t.accent, by: 0.7)],
                           startPoint: .topLeading, endPoint: .bottomTrailing)
        )
        .clipShape(RoundedRectangle(cornerRadius: Radius.md, style: .continuous))
    }

    private func recentRow(title: String, date: String, amt: String,
                           icon: String, color: Color, divider: Bool) -> some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10).fill(t.surface2)
                AviaryIcon(name: icon, size: 18, color: color)
            }
            .frame(width: 36, height: 36)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(AviaryFont.body(14, weight: .medium))
                    .foregroundStyle(t.ink)
                Text(date)
                    .font(AviaryFont.body(12))
                    .foregroundStyle(t.ink3)
            }
            Spacer()
            Text(amt)
                .font(AviaryFont.mono(15, weight: .semibold))
                .foregroundStyle(t.ink)
        }
        .padding(.vertical, 12)
        .overlay(
            divider ? Rectangle().fill(t.line).frame(height: 1) : nil,
            alignment: .bottom
        )
    }
}

extension Color {
    func mix(with other: Color, by amount: Double) -> Color {
        let amount = max(0, min(1, amount))
        let a = UIColor(self).cgColor.components ?? [0,0,0,1]
        let b = UIColor(other).cgColor.components ?? [0,0,0,1]
        return Color(red: a[0] * (1-amount) + b[0] * amount,
                     green: a[1] * (1-amount) + b[1] * amount,
                     blue: a[2] * (1-amount) + b[2] * amount,
                     opacity: 1)
    }
}

// MARK: - Profile

struct ProfileScreen: View {
    @Environment(\.theme) private var t
    @ObservedObject var themeManager: ThemeManager
    let profile: UserProfile
    var onOpenMessages: () -> Void = {}
    @EnvironmentObject private var auth: AuthViewModel
    @EnvironmentObject private var demoStore: DemoModeStore
    @State private var pickerItem: PhotosPickerItem?
    @State private var isUploadingAvatar: Bool = false
    @State private var avatarErrorMessage: String?
    @State private var showSettings: Bool = false
    @State private var showEarnings: Bool = false
    @State private var showCertifications: Bool = false
    @State private var showEquipment: Bool = false
    @State private var showInsurance: Bool = false
    @State private var certCount: Int = 0
    @State private var equipmentCount: Int = 0
    @State private var insuranceCount: Int = 0
    @State private var primaryEquipmentName: String?
    @State private var primaryInsurance: PilotInsurance?
    @State private var primaryCertification: PilotCertification?
    @State private var hasLoadedCredentials: Bool = false

    private var avatarURL: URL? {
        profile.avatarUrl.flatMap(URL.init(string:))
    }

    var body: some View {
        ZStack {
            t.bg.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    HStack(spacing: 14) {
                        avatarHeader
                        VStack(alignment: .leading, spacing: 2) {
                            Text(profile.displayName)
                                .font(AviaryFont.body(19, weight: .bold))
                                .tracking(-0.01 * 19)
                                .foregroundStyle(t.ink)
                                .lineLimit(1)
                            Text(roleSubtitle)
                                .font(AviaryFont.body(13))
                                .foregroundStyle(t.ink3)
                            if let err = avatarErrorMessage {
                                Text(err)
                                    .font(AviaryFont.body(12))
                                    .foregroundStyle(t.warn)
                                    .padding(.top, 2)
                            }
                            if demoStore.isOn {
                                HStack(spacing: 6) {
                                    if profile.role == .pilot {
                                        Chip(text: "4.92", icon: "star", style: .good)
                                        Chip(text: "137 gigs")
                                    } else {
                                        Chip(text: "12 jobs")
                                        Chip(text: "$3,420 spent", style: .good)
                                    }
                                }
                                .padding(.top, 4)
                            }
                        }
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .padding(.bottom, 16)

                    if profile.role == .pilot {
                        AviaryCard(padding: 0) {
                            VStack(spacing: 0) {
                                Button { showCertifications = true } label: {
                                    profileRow(icon: "cert", label: "Certifications",
                                               value: certificationsValue,
                                               isGood: !demoStore.isOn && (primaryCertification?.verified ?? false),
                                               tappable: true,
                                               divider: true)
                                }
                                .buttonStyle(.plain)
                                Button { showEquipment = true } label: {
                                    profileRow(icon: "drone", label: "Equipment",
                                               value: equipmentValue, tappable: true, divider: true)
                                }
                                .buttonStyle(.plain)
                                Button { showInsurance = true } label: {
                                    profileRow(icon: "shield", label: "Insurance",
                                               value: insuranceValue, tappable: true, divider: true)
                                }
                                .buttonStyle(.plain)
                                profileRow(icon: "card", label: "Payouts",
                                           value: demoStore.isOn ? "Chase ••4471" : "Not set up", divider: true)
                                Button { showEarnings = true } label: {
                                    profileRow(icon: "wallet", label: "Earnings",
                                               value: demoStore.isOn ? "$2,148.50 this week" : "No earnings yet",
                                               tappable: true,
                                               divider: false)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 16)

                        SectionTitle(text: "Performance")
                            .padding(.horizontal, 20)
                            .padding(.bottom, 8)
                        HStack(spacing: 10) {
                            perfStat(label: "On-time", value: demoStore.isOn ? "99%" : "—")
                            perfStat(label: "Accept",  value: demoStore.isOn ? "87%" : "—")
                            perfStat(label: "Re-hires", value: demoStore.isOn ? "42%" : "—")
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 16)
                    } else {
                        AviaryCard(padding: 0) {
                            VStack(spacing: 0) {
                                profileRow(icon: "card", label: "Payment method",
                                           value: demoStore.isOn ? "Visa ••4471" : "Add a card to post jobs",
                                           divider: true)
                                profileRow(icon: "pin", label: "Saved addresses",
                                           value: demoStore.isOn ? "3 saved · Home, Office, Studio" : "0 saved",
                                           divider: true)
                                profileRow(icon: "wallet", label: "Spend",
                                           value: demoStore.isOn ? "$3,420 lifetime · 12 jobs" : "$0 lifetime",
                                           divider: true)
                                profileRow(icon: "bell", label: "Notifications",
                                           value: "Push, email", divider: false)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 16)

                        if demoStore.isOn {
                            SectionTitle(text: "Activity")
                                .padding(.horizontal, 20)
                                .padding(.bottom, 8)
                            HStack(spacing: 10) {
                                perfStat(label: "On-time", value: "4 of 5")
                                perfStat(label: "Avg job", value: "$285")
                                perfStat(label: "Pilots", value: "5")
                            }
                            .padding(.horizontal, 20)
                            .padding(.bottom, 16)
                        }
                    }

                    Button {
                        onOpenMessages()
                    } label: {
                        navRow(icon: "message", label: "Messages", iconColor: t.accent)
                    }
                    .buttonStyle(PressableButtonStyle())
                    .padding(.horizontal, 16)
                    .padding(.top, 8)

                    Button {
                        showSettings = true
                    } label: {
                        navRow(icon: "sliders", label: "Settings", iconColor: t.accent)
                    }
                    .buttonStyle(PressableButtonStyle())
                    .padding(.horizontal, 16)
                    .padding(.top, 8)

                    Button {
                        Task { await auth.signOut() }
                    } label: {
                        HStack(spacing: 12) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 10).fill(t.surface2)
                                AviaryIcon(name: "arrow-right", size: 18, color: t.warn)
                            }
                            .frame(width: 34, height: 34)
                            Text("Sign out")
                                .font(AviaryFont.body(14, weight: .medium))
                                .foregroundStyle(t.warn)
                            Spacer()
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: Radius.md).fill(t.surface)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: Radius.md).strokeBorder(t.line)
                        )
                    }
                    .buttonStyle(PressableButtonStyle())
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .padding(.bottom, 24)
                }
            }
        }
        .sheet(isPresented: $showSettings) {
            SettingsScreen(themeManager: themeManager, profile: profile)
                .environment(\.theme, t)
                .environmentObject(demoStore)
        }
        .sheet(isPresented: $showEarnings) {
            EarningsSheet()
                .environment(\.theme, t)
                .environmentObject(demoStore)
        }
        .sheet(isPresented: $showCertifications, onDismiss: { Task { await reloadCredentialsSummary() } }) {
            CertificationsScreen(pilotID: realPilotID ?? profile.id)
                .environment(\.theme, t)
        }
        .sheet(isPresented: $showEquipment, onDismiss: { Task { await reloadCredentialsSummary() } }) {
            EquipmentScreen(pilotID: realPilotID ?? profile.id)
                .environment(\.theme, t)
        }
        .sheet(isPresented: $showInsurance, onDismiss: { Task { await reloadCredentialsSummary() } }) {
            InsuranceScreen(pilotID: realPilotID ?? profile.id)
                .environment(\.theme, t)
        }
        .onChange(of: pickerItem) { _, newItem in
            guard let newItem else { return }
            Task { await handlePickedItem(newItem) }
        }
        .task(id: credentialsLoadKey) {
            await reloadCredentialsSummary()
        }
        .onAppear {
            applyShowcaseStep(demoStore.showcaseStep)
        }
        .onChange(of: demoStore.showcaseStep) { _, step in
            applyShowcaseStep(step)
        }
    }

    private var realPilotID: UUID? {
        if case .signedIn(let realProfile) = auth.state {
            return realProfile.id
        }
        return nil
    }

    private var credentialsLoadKey: String {
        "\(profile.role.rawValue)-\(realPilotID?.uuidString ?? "none")-\(demoStore.isOn)"
    }

    private func applyShowcaseStep(_ step: DemoShowcaseStep?) {
        guard let step else {
            showEarnings = false
            return
        }

        switch step {
        case .pilotProfile, .customerProfile:
            showSettings = false
            showEarnings = false
            showCertifications = false
            showEquipment = false
            showInsurance = false
        case .pilotEarnings:
            showSettings = false
            showCertifications = false
            showEquipment = false
            showInsurance = false
            showEarnings = true
        default:
            break
        }
    }

    private var certificationsValue: String {
        if demoStore.isOn { return "Part 107 · verified" }
        guard hasLoadedCredentials else { return "—" }
        guard let primary = primaryCertification else { return "Not added" }
        if certCount > 1 {
            return "\(primary.title) +\(certCount - 1) more"
        }
        return primary.title
    }

    private var equipmentValue: String {
        if demoStore.isOn { return "Mavic 3 Pro · DJI Mini 4" }
        guard hasLoadedCredentials else { return "—" }
        guard let primary = primaryEquipmentName, !primary.isEmpty else {
            return equipmentCount == 0 ? "Not added" : "\(equipmentCount) item\(equipmentCount == 1 ? "" : "s")"
        }
        if equipmentCount > 1 {
            return "\(primary) +\(equipmentCount - 1) more"
        }
        return primary
    }

    private var insuranceValue: String {
        if demoStore.isOn { return "$2M Aviary Cover" }
        guard hasLoadedCredentials else { return "—" }
        guard let primary = primaryInsurance else { return "Not added" }
        if let coverage = primary.coverageText {
            return "\(coverage) · \(primary.provider)"
        }
        return primary.provider
    }

    private func reloadCredentialsSummary() async {
        guard !demoStore.isOn,
              profile.role == .pilot,
              let pilotID = realPilotID,
              SupabaseConfig.isConfigured else {
            hasLoadedCredentials = true
            return
        }
        async let certsTask = PilotCredentialsService.shared.certifications(for: pilotID)
        async let equipTask = PilotCredentialsService.shared.equipment(for: pilotID)
        async let insTask = PilotCredentialsService.shared.insurance(for: pilotID)
        do {
            let (certs, equip, ins) = try await (certsTask, equipTask, insTask)
            certCount = certs.count
            primaryCertification = certs.first
            equipmentCount = equip.count
            primaryEquipmentName = equip.first(where: { $0.isPrimary })?.displayName ?? equip.first?.displayName
            insuranceCount = ins.count
            primaryInsurance = ins.first(where: { !$0.isExpired }) ?? ins.first
            hasLoadedCredentials = true
        } catch {
            hasLoadedCredentials = true
        }
    }

    @ViewBuilder
    private var avatarHeader: some View {
        if demoStore.isOn {
            ZStack {
                Avatar(size: 64,
                       initials: profile.initials,
                       background: t.accentSoft,
                       imageUrl: avatarURL)
                if isUploadingAvatar {
                    Circle().fill(Color.black.opacity(0.35))
                        .frame(width: 64, height: 64)
                    ProgressView().tint(.white)
                }
            }
            .opacity(0.85)
        } else {
            PhotosPicker(selection: $pickerItem,
                         matching: .images,
                         photoLibrary: .shared()) {
                ZStack {
                    Avatar(size: 64,
                           initials: profile.initials,
                           background: t.accentSoft,
                           imageUrl: avatarURL)
                    if isUploadingAvatar {
                        Circle().fill(Color.black.opacity(0.35))
                            .frame(width: 64, height: 64)
                        ProgressView().tint(.white)
                    }
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            ZStack {
                                Circle().fill(t.accent)
                                AviaryIcon(name: "camera", size: 12, stroke: 2, color: t.accentInk)
                            }
                            .frame(width: 22, height: 22)
                            .overlay(Circle().strokeBorder(t.bg, lineWidth: 2))
                        }
                    }
                    .frame(width: 64, height: 64)
                }
            }
            .buttonStyle(.plain)
        }
    }

    private func navRow(icon: String, label: String, iconColor: Color) -> some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10).fill(t.accentSoft)
                AviaryIcon(name: icon, size: 18, color: iconColor)
            }
            .frame(width: 34, height: 34)
            Text(label)
                .font(AviaryFont.body(14, weight: .medium))
                .foregroundStyle(t.ink)
            Spacer()
            AviaryIcon(name: "chevron-right", size: 16, color: t.ink4)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: Radius.md).fill(t.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: Radius.md).strokeBorder(t.line)
        )
        .contentShape(Rectangle())
    }

    private func handlePickedItem(_ item: PhotosPickerItem) async {
        avatarErrorMessage = nil
        guard case .signedIn(let realProfile) = auth.state else { return }
        isUploadingAvatar = true
        defer {
            isUploadingAvatar = false
            pickerItem = nil
        }
        do {
            guard let data = try await item.loadTransferable(type: Data.self),
                  let uiImage = UIImage(data: data) else {
                avatarErrorMessage = "Couldn't read that image."
                return
            }
            _ = try await AvatarService.uploadAvatar(image: uiImage, for: realProfile.id)
            await auth.refreshProfile()
        } catch {
            avatarErrorMessage = error.localizedDescription
        }
    }

    private var roleSubtitle: String {
        switch profile.role {
        case .pilot:    return "Pilot · Berkeley, CA"
        case .customer: return "Customer · Berkeley, CA"
        }
    }

    private func profileRow(icon: String, label: String, value: String,
                            isGood: Bool = false, tappable: Bool = false,
                            divider: Bool) -> some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10).fill(t.accentSoft)
                AviaryIcon(name: icon, size: 18, color: t.accent)
            }
            .frame(width: 34, height: 34)
            VStack(alignment: .leading, spacing: 1) {
                Text(label)
                    .font(AviaryFont.body(14, weight: .medium))
                    .foregroundStyle(t.ink)
                Text(value)
                    .font(AviaryFont.body(12))
                    .foregroundStyle(isGood ? t.good : t.ink3)
            }
            Spacer()
            if tappable {
                AviaryIcon(name: "chevron-right", size: 16, color: t.ink4)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
        .overlay(
            divider ? Rectangle().fill(t.line).frame(height: 1) : nil,
            alignment: .bottom
        )
    }

    private func perfStat(label: String, value: String) -> some View {
        AviaryCard(padding: 12) {
            VStack(spacing: 2) {
                Text(value)
                    .font(AviaryFont.mono(22, weight: .semibold))
                    .foregroundStyle(t.ink)
                Text(label)
                    .font(AviaryFont.body(11))
                    .foregroundStyle(t.ink3)
            }
            .frame(maxWidth: .infinity)
        }
    }
}

// MARK: - Messages

struct MessagesScreen: View {
    @Environment(\.theme) private var t
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var demoStore: DemoModeStore
    let profile: UserProfile?
    let showsCloseButton: Bool

    @State private var conversations: [AviaryConversation] = []
    @State private var selectedConversation: AviaryConversation?
    @State private var messages: [AviaryMessage] = []
    @State private var isLoadingConversations: Bool = false
    @State private var isLoadingMessages: Bool = false
    @State private var isSending: Bool = false
    @State private var errorMessage: String?
    @State private var draftMessage: String = ""

    // Showcase: simulated typing in the demo composer + an extra outgoing bubble after "send".
    @State private var showcaseDraft: String = ""
    @State private var showcaseSentMessages: [String] = []
    @State private var showcaseComposerTask: Task<Void, Never>?

    var body: some View {
        ZStack {
            t.bg.ignoresSafeArea()
            VStack(spacing: 0) {
                if demoStore.isOn {
                    demoThread
                } else if let selectedConversation {
                    thread(for: selectedConversation)
                } else {
                    conversationList
                }
            }
        }
        .task(id: "\(profile?.id.uuidString ?? "none")-\(demoStore.isOn)") {
            await loadConversations()
        }
        .onAppear { startComposerShowcaseIfNeeded() }
        .onDisappear {
            showcaseComposerTask?.cancel()
            showcaseComposerTask = nil
        }
        .onChange(of: demoStore.showcaseStep) { _, _ in
            startComposerShowcaseIfNeeded()
        }
    }

    /// In a messages showcase step, type a follow-up message into the composer
    /// character-by-character, then "send" so a new outgoing bubble appears in the thread.
    private func startComposerShowcaseIfNeeded() {
        guard demoStore.isOn else { return }
        let body: String
        switch demoStore.showcaseStep {
        case .customerMessages:
            body = "Sounds great — see you at 3:30!"
        case .pilotMessages:
            body = "Just landed. Twilight set turned out clean — uploading now."
        default:
            return
        }
        let activeStep = demoStore.showcaseStep
        showcaseComposerTask?.cancel()
        showcaseDraft = ""
        showcaseSentMessages = []
        showcaseComposerTask = Task { @MainActor in
            do {
                try await Task.sleep(nanoseconds: 1_400_000_000)
                guard demoStore.showcaseStep == activeStep else { return }
                for ch in body {
                    guard demoStore.showcaseStep == activeStep else { return }
                    showcaseDraft.append(ch)
                    try await Task.sleep(nanoseconds: 36_000_000)
                }
                try await Task.sleep(nanoseconds: 480_000_000)
                guard demoStore.showcaseStep == activeStep else { return }
                withAnimation(.easeOut(duration: 0.3)) {
                    showcaseSentMessages.append(body)
                    showcaseDraft = ""
                }
            } catch {
                return
            }
        }
    }

    private var conversationList: some View {
        VStack(spacing: 0) {
            listHeader
            if isLoadingConversations {
                Spacer()
                FeatureStateCard(icon: "message",
                                 title: "Loading conversations",
                                 message: "Checking active job threads.")
                    .padding(.horizontal, 24)
                Spacer()
            } else if let errorMessage {
                Spacer()
                FeatureStateCard(icon: "cloud",
                                 title: "Couldn't load messages",
                                 message: errorMessage,
                                 buttonTitle: "Try again",
                                 action: { Task { await loadConversations() } })
                    .padding(.horizontal, 24)
                Spacer()
            } else if conversations.isEmpty {
                Spacer()
                FeatureStateCard(icon: "message",
                                 title: "No conversations yet",
                                 message: "Threads appear here once a gig has a customer and pilot assigned.")
                    .padding(.horizontal, 24)
                Spacer()
            } else {
                ScrollView {
                    LazyVStack(spacing: 10) {
                        ForEach(conversations) { conversation in
                            Button { select(conversation) } label: {
                                conversationRow(conversation)
                            }
                            .buttonStyle(PressableButtonStyle())
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 24)
                }
            }
        }
    }

    private var listHeader: some View {
        HStack(spacing: 12) {
            if showsCloseButton {
                Button { dismiss() } label: {
                    AviaryIcon(name: "arrow-left", size: 22, color: t.ink)
                }
            }
            Text("Messages")
                .font(AviaryFont.body(16, weight: .semibold))
                .foregroundStyle(t.ink)
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
        .padding(.bottom, 14)
    }

    private func thread(for conversation: AviaryConversation) -> some View {
        VStack(spacing: 0) {
            threadHeader(conversation)
            pinnedContext(conversation)
                .padding(.horizontal, 16)
                .padding(.bottom, 12)

            ScrollView {
                if isLoadingMessages {
                    FeatureStateCard(icon: "message",
                                     title: "Loading thread",
                                     message: "Fetching the latest messages.")
                        .padding(.horizontal, 8)
                        .padding(.top, 12)
                } else if messages.isEmpty {
                    FeatureStateCard(icon: "message",
                                     title: "No messages yet",
                                     message: "Send the first note about this job.")
                        .padding(.horizontal, 8)
                        .padding(.top, 12)
                } else {
                    VStack(alignment: .leading, spacing: 10) {
                        ForEach(messages) { message in
                            bubble(text: message.body,
                                   time: message.timeText,
                                   incoming: message.isIncoming(for: profile))
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 4)
                    .padding(.bottom, 12)
                }
            }

            liveComposer
        }
    }

    private func threadHeader(_ conversation: AviaryConversation) -> some View {
        HStack(spacing: 12) {
            if conversations.count > 1 || showsCloseButton {
                Button {
                    if conversations.count > 1 {
                        selectedConversation = nil
                        messages = []
                    } else {
                        dismiss()
                    }
                } label: {
                    AviaryIcon(name: "arrow-left", size: 22, color: t.ink)
                }
            }
            Avatar(size: 36, initials: initials(for: conversation.displayTitle), background: t.accentSoft)
            VStack(alignment: .leading, spacing: 0) {
                Text(conversation.displayTitle)
                    .font(AviaryFont.body(15, weight: .semibold))
                    .foregroundStyle(t.ink)
                    .lineLimit(1)
                Text(conversation.lastMessageTimeText.isEmpty ? "Job thread" : conversation.lastMessageTimeText)
                    .font(AviaryFont.body(11))
                    .foregroundStyle(t.good)
            }
            Spacer()
            AviaryIcon(name: "phone", size: 20, color: t.ink)
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
        .padding(.bottom, 14)
    }

    private func conversationRow(_ conversation: AviaryConversation) -> some View {
        AviaryCard(padding: 14, shadowed: true) {
            HStack(spacing: 12) {
                Avatar(size: 42, initials: initials(for: conversation.displayTitle), background: t.accentSoft)
                VStack(alignment: .leading, spacing: 3) {
                    HStack(alignment: .firstTextBaseline) {
                        Text(conversation.displayTitle)
                            .font(AviaryFont.body(15, weight: .semibold))
                            .foregroundStyle(t.ink)
                            .lineLimit(1)
                        Spacer()
                        Text(conversation.lastMessageTimeText)
                            .font(AviaryFont.body(11))
                            .foregroundStyle(t.ink4)
                    }
                    Text(conversation.displaySubtitle)
                        .font(AviaryFont.body(12))
                        .foregroundStyle(t.ink3)
                        .lineLimit(1)
                    Text(conversation.previewText)
                        .font(AviaryFont.body(13))
                        .foregroundStyle(t.ink2)
                        .lineLimit(1)
                }
            }
        }
    }

    private func pinnedContext(_ conversation: AviaryConversation) -> some View {
        HStack(spacing: 10) {
            AviaryIcon(name: "pin", size: 16, color: t.accent)
            Text(conversation.displaySubtitle)
                .font(AviaryFont.body(12))
                .foregroundStyle(t.ink2)
                .lineLimit(1)
            Spacer()
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 12).fill(t.accentSoft)
        )
    }

    private var isCustomerDemo: Bool {
        profile?.role == .customer
    }

    private var demoThread: some View {
        VStack(spacing: 0) {
            demoHeader

            demoPinnedContext
                .padding(.horizontal, 16)
                .padding(.bottom, 12)

            ScrollView {
                VStack(alignment: .leading, spacing: 10) {
                    if isCustomerDemo {
                        bubble(text: "Hey Casey — gate code is 4471. Owner asked for a sunset shot too if light's good.",
                               time: "2:14 PM ✓✓", incoming: false)
                        bubble(text: "Got it. ETA 22 min. Sunset is 7:48 — happy to add a twilight set for $40.",
                               time: "2:16 PM", incoming: true)
                        bubble(text: "Perfect — go for it. Approving the add-on now.",
                               time: nil, incoming: false)
                    } else {
                        bubble(text: "Hey Jordan — gate code is 4471. Owner asked for a sunset shot too if light's good.",
                               time: "2:14 PM", incoming: true)
                        bubble(text: "Got it. ETA 22 min. Sunset is 7:48 — happy to add a twilight set for $40.",
                               time: "2:16 PM ✓✓", incoming: false)
                        bubble(text: "Done. Sending the add-on now.",
                               time: nil, incoming: true)
                    }
                    ForEach(Array(showcaseSentMessages.enumerated()), id: \.offset) { _, body in
                        bubble(text: body, time: "now ✓", incoming: false)
                            .transition(.move(edge: .trailing).combined(with: .opacity))
                    }
                    typingBubble
                }
                .padding(.horizontal, 16)
                .padding(.top, 4)
                .padding(.bottom, 12)
            }

            demoComposer
        }
    }

    private var demoHeader: some View {
        HStack(spacing: 12) {
            if showsCloseButton {
                Button { dismiss() } label: {
                    AviaryIcon(name: "arrow-left", size: 22, color: t.ink)
                }
            }
            Avatar(size: 36,
                   initials: isCustomerDemo ? "CP" : "MR",
                   background: t.accentSoft)
            VStack(alignment: .leading, spacing: 0) {
                Text(isCustomerDemo ? "Casey Park" : "Marin Realty")
                    .font(AviaryFont.body(15, weight: .semibold))
                    .foregroundStyle(t.ink)
                Text("Online")
                    .font(AviaryFont.body(11))
                    .foregroundStyle(t.good)
            }
            Spacer()
            AviaryIcon(name: "phone", size: 20, color: t.ink)
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
        .padding(.bottom, 14)
    }

    private var demoPinnedContext: some View {
        HStack(spacing: 10) {
            AviaryIcon(name: "pin", size: 16, color: t.accent)
            (Text("Real estate · 1247 Vine St · ").foregroundColor(t.ink2)
             + Text("$340 · today 3:30pm").foregroundColor(t.accent).bold())
                .font(AviaryFont.body(12))
            Spacer()
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 12).fill(t.accentSoft)
        )
    }

    private func bubble(text: String, time: String?, incoming: Bool) -> some View {
        HStack {
            if !incoming { Spacer() }
            VStack(alignment: incoming ? .leading : .trailing, spacing: 4) {
                Text(text)
                    .font(AviaryFont.body(14))
                    .lineSpacing(2)
                    .padding(.horizontal, 14).padding(.vertical, 10)
                    .foregroundStyle(incoming ? t.ink : t.accentInk)
                    .background(
                        UnevenRoundedRectangle(
                            topLeadingRadius: 18,
                            bottomLeadingRadius: incoming ? 6 : 18,
                            bottomTrailingRadius: incoming ? 18 : 6,
                            topTrailingRadius: 18,
                            style: .continuous
                        )
                        .fill(incoming ? t.surface2 : t.accent)
                    )
                if let tm = time {
                    Text(tm)
                        .font(AviaryFont.body(10))
                        .foregroundStyle(t.ink4)
                        .padding(.horizontal, 10)
                }
            }
            .frame(maxWidth: 260, alignment: incoming ? .leading : .trailing)
            if incoming { Spacer() }
        }
    }

    private var typingBubble: some View {
        HStack {
            Text("...")
                .font(AviaryFont.body(12))
                .foregroundStyle(t.ink3)
                .padding(.horizontal, 14).padding(.vertical, 10)
                .background(
                    UnevenRoundedRectangle(
                        topLeadingRadius: 18, bottomLeadingRadius: 6,
                        bottomTrailingRadius: 18, topTrailingRadius: 18,
                        style: .continuous
                    )
                    .fill(t.surface2)
                )
            Spacer()
        }
    }

    private var liveComposer: some View {
        HStack(spacing: 10) {
            AviaryIcon(name: "plus", size: 22, color: t.ink3)
            TextField("Message...", text: $draftMessage)
                .font(AviaryFont.body(14))
                .foregroundStyle(t.ink)
                .padding(.horizontal, 16).padding(.vertical, 10)
                .background(Capsule().fill(t.surface2))
            Button { sendMessage() } label: {
                ZStack {
                    Circle().fill(canSend ? t.accent : t.surface2)
                    AviaryIcon(name: "arrow-right", size: 18, color: canSend ? t.accentInk : t.ink4)
                }
                .frame(width: 36, height: 36)
            }
            .buttonStyle(.plain)
            .disabled(!canSend)
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
        .padding(.bottom, 20)
        .background(
            t.surface
                .overlay(Rectangle().fill(t.line).frame(height: 1), alignment: .top)
                .ignoresSafeArea(edges: .bottom)
        )
    }

    private var demoComposer: some View {
        let isTyping = !showcaseDraft.isEmpty
        return HStack(spacing: 10) {
            AviaryIcon(name: "plus", size: 22, color: t.ink3)
            HStack {
                if isTyping {
                    Text(showcaseDraft)
                        .font(AviaryFont.body(14))
                        .foregroundStyle(t.ink)
                    Rectangle()
                        .fill(t.accent)
                        .frame(width: 1.5, height: 16)
                        .opacity(0.85)
                } else {
                    Text("Message...")
                        .font(AviaryFont.body(14))
                        .foregroundStyle(t.ink4)
                }
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 16).padding(.vertical, 10)
            .background(Capsule().fill(t.surface2))
            .animation(.easeOut(duration: 0.06), value: showcaseDraft)
            ZStack {
                Circle().fill(isTyping ? t.accent : t.surface2)
                AviaryIcon(name: "arrow-right",
                           size: 18,
                           color: isTyping ? t.accentInk : t.ink4)
            }
            .frame(width: 36, height: 36)
            .animation(.easeInOut(duration: 0.18), value: isTyping)
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
        .padding(.bottom, 20)
        .background(
            t.surface
                .overlay(Rectangle().fill(t.line).frame(height: 1), alignment: .top)
                .ignoresSafeArea(edges: .bottom)
        )
    }

    private var canSend: Bool {
        selectedConversation != nil &&
        !draftMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !isSending
    }

    private func loadConversations() async {
        guard !demoStore.isOn, let profile else {
            conversations = []
            selectedConversation = nil
            messages = []
            isLoadingConversations = false
            errorMessage = nil
            return
        }
        isLoadingConversations = true
        errorMessage = nil
        do {
            conversations = try await AviaryDataService.shared.conversations(for: profile)
            if conversations.count == 1, let only = conversations.first {
                selectedConversation = only
                await loadMessages(for: only)
            } else if let selectedConversation,
                      !conversations.contains(where: { $0.id == selectedConversation.id }) {
                self.selectedConversation = nil
                messages = []
            }
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoadingConversations = false
    }

    private func select(_ conversation: AviaryConversation) {
        selectedConversation = conversation
        Task { await loadMessages(for: conversation) }
    }

    private func loadMessages(for conversation: AviaryConversation) async {
        isLoadingMessages = true
        do {
            messages = try await AviaryDataService.shared.messages(for: conversation.id)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoadingMessages = false
    }

    private func sendMessage() {
        guard let profile, let selectedConversation else { return }
        let body = draftMessage.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !body.isEmpty else { return }
        isSending = true
        errorMessage = nil
        Task {
            do {
                let message = try await AviaryDataService.shared.sendMessage(
                    body: body,
                    conversationID: selectedConversation.id,
                    senderID: profile.id
                )
                await MainActor.run {
                    messages.append(message)
                    draftMessage = ""
                    isSending = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isSending = false
                }
            }
        }
    }

    private func initials(for name: String) -> String {
        let chars = name
            .split(separator: " ")
            .compactMap(\.first)
            .prefix(2)
        return chars.isEmpty ? "AV" : String(chars).uppercased()
    }
}

// MARK: - Client request a flight

struct ClientRequestScreen: View {
    @Environment(\.theme) private var t
    @EnvironmentObject private var demoStore: DemoModeStore
    let profile: UserProfile
    var onPosted: (AviaryJob) -> Void = { _ in }
    @State private var typeIdx: Int = 0
    @State private var isPosting: Bool = false
    @State private var errorMessage: String?
    @State private var showcaseTypeTask: Task<Void, Never>?

    private struct GigType {
        let label: String
        let icon: String
        let address: String
        let scheduleText: String
        let scheduledHoursFromNow: Int
        let durationMinutes: Int
        let deliverablesSummary: String
        let deliverables: [String]
        let estimateText: String
        let payoutCents: Int
        let distanceMiles: Double
        let coordinate: CLLocationCoordinate2D
    }

    private let types: [GigType] = [
        GigType(label: "Real estate", icon: "camera",
                address: "1247 Vine St, Berkeley",
                scheduleText: "Today, 3:30 PM",
                scheduledHoursFromNow: 3, durationMinutes: 45,
                deliverablesSummary: "12 photos + 60s flyover",
                deliverables: ["12 exterior photos", "60-sec cinematic flyover", "Edited delivery set"],
                estimateText: "$320–$380", payoutCents: 35000, distanceMiles: 1.2,
                coordinate: CLLocationCoordinate2D(latitude: 37.8814, longitude: -122.2683)),
        GigType(label: "Inspection", icon: "cert",
                address: "88 Industrial Way, Oakland",
                scheduleText: "Tomorrow, 10:00 AM",
                scheduledHoursFromNow: 22, durationMinutes: 30,
                deliverablesSummary: "Roof scan + thermal pass",
                deliverables: ["Tight roof orbit (4K)", "Thermal pass + damage call-outs", "PDF report"],
                estimateText: "$420–$480", payoutCents: 45000, distanceMiles: 6.4,
                coordinate: CLLocationCoordinate2D(latitude: 37.7942, longitude: -122.2510)),
        GigType(label: "Event", icon: "star",
                address: "Tilden Park, Berkeley",
                scheduleText: "Saturday, 4:00 PM",
                scheduledHoursFromNow: 52, durationMinutes: 120,
                deliverablesSummary: "90s aerial reel + stills",
                deliverables: ["Ceremony aerial coverage", "Cinematic flyover", "60-sec highlight reel"],
                estimateText: "$560–$640", payoutCents: 60000, distanceMiles: 3.1,
                coordinate: CLLocationCoordinate2D(latitude: 37.8956, longitude: -122.2429)),
        GigType(label: "Mapping", icon: "altitude",
                address: "Stags Leap District, Napa",
                scheduleText: "Friday, 8:00 AM",
                scheduledHoursFromNow: 40, durationMinutes: 240,
                deliverablesSummary: "12-acre orthomosaic",
                deliverables: ["Orthomosaic at 2 cm/px", "NDVI multispectral map", "Boundary KML"],
                estimateText: "$780–$880", payoutCents: 83000, distanceMiles: 42.0,
                coordinate: CLLocationCoordinate2D(latitude: 38.4090, longitude: -122.3206))
    ]

    @State private var camera: MapCameraPosition = .region(MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.8814, longitude: -122.2683),
        latitudinalMeters: 1400, longitudinalMeters: 1400
    ))

    var body: some View {
        ZStack(alignment: .top) {
            t.bg.ignoresSafeArea()
            VStack(spacing: 0) {
                postJobMap
                    .frame(height: 280)

                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        Text("What do you need shot?")
                            .font(AviaryFont.display(24, weight: .bold))
                            .tracking(-0.02 * 24)
                            .foregroundStyle(t.ink)
                        Text("Pilots usually accept within 4 minutes.")
                            .font(AviaryFont.body(13))
                            .foregroundStyle(t.ink3)
                            .padding(.bottom, 16)
                            .padding(.top, 4)

                        LazyVGrid(columns: [GridItem(.flexible(), spacing: 8),
                                            GridItem(.flexible(), spacing: 8)],
                                  spacing: 8) {
                            ForEach(Array(types.enumerated()), id: \.0) { idx, item in
                                Button { withAnimation(.easeInOut(duration: 0.2)) { typeIdx = idx } } label: {
                                    typeTile(label: item.label, icon: item.icon, active: idx == typeIdx)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.bottom, 12)

                        AviaryCard(padding: 0) {
                            VStack(spacing: 0) {
                                detailRow(icon: "pin", text: selected.address, divider: true)
                                detailRow(icon: "clock", text: selected.scheduleText, divider: true)
                                detailRow(icon: selected.icon, text: selected.deliverablesSummary, divider: false)
                            }
                        }
                        .padding(.bottom, 12)

                        HStack {
                            VStack(alignment: .leading, spacing: 1) {
                                Text("Estimated")
                                    .font(AviaryFont.body(12))
                                    .foregroundStyle(t.ink3)
                                Text(selected.estimateText)
                                    .font(AviaryFont.mono(24, weight: .semibold))
                                    .foregroundStyle(t.ink)
                            }
                            Spacer()
                            PrimaryButton(title: isPosting ? "Posting..." : "Post gig",
                                          systemTrailing: "arrow.right",
                                          fullWidth: false,
                                          enabled: !isPosting) {
                                postGig()
                            }
                        }
                        .padding(.vertical, 14)

                        if let errorMessage {
                            Text(errorMessage)
                                .font(AviaryFont.body(12))
                                .foregroundStyle(t.warn)
                                .lineSpacing(2)
                                .padding(.top, 4)
                        }
                    }
                    .padding(.horizontal, 22)
                    .padding(.top, 20)
                    .padding(.bottom, 24)
                }
                .background(
                    UnevenRoundedRectangle(
                        topLeadingRadius: 28, bottomLeadingRadius: 0,
                        bottomTrailingRadius: 0, topTrailingRadius: 28,
                        style: .continuous
                    )
                    .fill(t.surface)
                    .shadow(color: .black.opacity(0.08), radius: 24, y: -8)
                )
                .padding(.top, -28)
            }
        }
        .onAppear {
            runShowcaseTypePicker()
        }
        .onChange(of: demoStore.showcaseStep) { _, _ in
            runShowcaseTypePicker()
        }
        .onDisappear {
            showcaseTypeTask?.cancel()
        }
    }

    private var selected: GigType { types[typeIdx] }

    private var postJobMap: some View {
        Map(position: $camera) {
            Annotation(selected.label, coordinate: selected.coordinate, anchor: .bottom) {
                ZStack {
                    Circle().fill(t.accent.opacity(0.16)).frame(width: 56, height: 56)
                    Circle().fill(t.accent.opacity(0.28)).frame(width: 36, height: 36)
                    Capsule()
                        .fill(t.accent)
                        .frame(width: max(40, CGFloat(selected.estimateText.count) * 7 + 18), height: 26)
                        .overlay(Capsule().strokeBorder(.white, lineWidth: 2))
                        .shadow(color: .black.opacity(0.18), radius: 6, y: 2)
                    Text(selected.estimateText)
                        .font(AviaryFont.body(11, weight: .bold))
                        .foregroundStyle(.white)
                }
            }
        }
        .mapStyle(.standard(elevation: .flat, emphasis: .muted, pointsOfInterest: .excludingAll))
        .mapControls { }
        .overlay(
            (t.mapBg.opacity(0.42).blendMode(.multiply)).allowsHitTesting(false)
        )
        .onChange(of: typeIdx) { _, _ in
            withAnimation(.easeInOut(duration: 0.5)) {
                camera = .region(MKCoordinateRegion(
                    center: selected.coordinate,
                    latitudinalMeters: 1400, longitudinalMeters: 1400
                ))
            }
        }
    }

    private func postGig() {
        guard !isPosting else { return }
        isPosting = true
        errorMessage = nil
        let type = selected
        let draft = AviaryDataService.JobDraft(
            jobType: type.label.lowercased().replacingOccurrences(of: " ", with: "_"),
            title: type.label == "Real estate" ? "Real estate listing" : "\(type.label) request",
            address: type.address,
            clientName: profile.fullName ?? profile.email,
            distanceMiles: type.distanceMiles,
            payoutCents: type.payoutCents,
            scheduledAt: Calendar.current.date(byAdding: .hour, value: type.scheduledHoursFromNow, to: Date()),
            durationMinutes: type.durationMinutes,
            deliverables: type.deliverables
        )
        Task {
            do {
                let job = try await AviaryDataService.shared.createJob(draft, customerID: profile.id)
                await MainActor.run {
                    isPosting = false
                    onPosted(job)
                }
            } catch {
                await MainActor.run {
                    isPosting = false
                    errorMessage = error.localizedDescription
                }
            }
        }
    }

    private func runShowcaseTypePicker() {
        showcaseTypeTask?.cancel()
        guard demoStore.showcaseStep == .customerPostJob else { return }
        showcaseTypeTask = Task { @MainActor in
            do {
                let sequence = [0, 1, 2, 3, 0]
                for idx in sequence {
                    guard demoStore.showcaseStep == .customerPostJob else { return }
                    withAnimation(.easeInOut(duration: 0.35)) {
                        typeIdx = idx
                    }
                    try await Task.sleep(nanoseconds: 700_000_000)
                }
                // After surveying the types, dwell briefly on the chosen one,
                // then auto-tap "Post gig" so the showcase advances to My Jobs.
                try await Task.sleep(nanoseconds: 600_000_000)
                guard demoStore.showcaseStep == .customerPostJob, !isPosting else { return }
                postGig()
            } catch {
                return
            }
        }
    }

    private func typeTile(label: String, icon: String, active: Bool) -> some View {
        HStack(spacing: 10) {
            AviaryIcon(name: icon, size: 20, color: active ? t.accent : t.ink2)
            Text(label)
                .font(AviaryFont.body(14, weight: .semibold))
                .foregroundStyle(active ? t.accent : t.ink)
            Spacer()
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14).fill(active ? t.accentSoft : t.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(active ? t.accent : t.line, lineWidth: active ? 1.5 : 1)
        )
    }

    private func detailRow(icon: String, text: String, divider: Bool) -> some View {
        HStack(spacing: 10) {
            AviaryIcon(name: icon, size: 18, color: t.ink3)
            Text(text)
                .font(AviaryFont.body(14))
                .foregroundStyle(t.ink)
            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .overlay(
            divider ? Rectangle().fill(t.line).frame(height: 1) : nil,
            alignment: .bottom
        )
    }
}
