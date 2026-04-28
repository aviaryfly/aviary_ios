import SwiftUI

// MARK: - Gig list

struct GigListScreen: View {
    @Environment(\.theme) private var t
    @EnvironmentObject private var demoStore: DemoModeStore
    let profile: UserProfile
    @State private var sortIdx: Int = 0
    @State private var jobs: [AviaryJob] = []
    @State private var isLoading: Bool = false
    @State private var errorMessage: String?
    var onOpenGig: (AviaryJob?) -> Void = { _ in }

    private let sorts = ["Best match", "Highest pay", "Closest", "Soonest"]
    private let demoGigs: [GigRow] = [
        .init(title: "Construction site progress", addr: "500 Folsom St", dist: "0.8 mi",
              price: "$485", time: "Tomorrow · 9:00am · 90 min", icon: "briefcase", color: nil),
        .init(title: "Roof inspection — duplex", addr: "22 Hillside Ave", dist: "2.4 mi",
              price: "$220", time: "Today · 4:30pm · 30 min", icon: "cert", color: nil),
        .init(title: "Wedding aerial coverage", addr: "Tilden Park", dist: "3.1 mi",
              price: "$780", time: "Sat · 5:00pm · 2 hr", icon: "star", color: .good),
        .init(title: "Real estate listing", addr: "1247 Vine St", dist: "1.2 mi",
              price: "$340", time: "Today · 3:30pm · 45 min", icon: "camera", color: nil),
        .init(title: "Vineyard mapping", addr: "Napa, CA", dist: "42 mi",
              price: "$1,250", time: "Wed · 8:00am · 4 hr", icon: "altitude", color: nil),
    ]

    var body: some View {
        ZStack {
            t.bg.ignoresSafeArea()
            VStack(spacing: 0) {
                PageHeader(title: "Gigs", subtitle: subtitle) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12).fill(t.surface2)
                            .frame(width: 40, height: 40)
                        AviaryIcon(name: "sliders", size: 20, color: t.ink)
                    }
                }

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(Array(sorts.enumerated()), id: \.0) { idx, label in
                            Button { sortIdx = idx } label: {
                                Text(label)
                                    .font(AviaryFont.body(12, weight: .semibold))
                                    .foregroundStyle(idx == sortIdx ? t.bg : t.ink2)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 7)
                                    .background(
                                        Capsule().fill(idx == sortIdx ? t.ink : t.surface)
                                    )
                                    .overlay(
                                        Capsule().strokeBorder(idx == sortIdx ? .clear : t.line)
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 12)
                }

                ScrollView {
                    content
                }
            }
        }
        .task(id: "\(profile.id.uuidString)-\(demoStore.isOn)") {
            await loadJobs()
        }
    }

    @ViewBuilder
    private var content: some View {
        if demoStore.isOn {
            LazyVStack(spacing: 10) {
                ForEach(sortedDemoGigs) { gig in
                    Button { onOpenGig(nil) } label: {
                        gigCard(gig)
                    }
                    .buttonStyle(PressableButtonStyle())
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 24)
        } else if isLoading {
            FeatureStateCard(icon: "compass",
                             title: "Loading nearby gigs",
                             message: "Checking open customer requests that match your service area.")
                .padding(.horizontal, 16)
                .padding(.bottom, 24)
        } else if let errorMessage {
            FeatureStateCard(icon: "cloud",
                             title: "Couldn't load gigs",
                             message: errorMessage,
                             buttonTitle: "Try again",
                             action: { Task { await loadJobs() } })
                .padding(.horizontal, 16)
                .padding(.bottom, 24)
        } else if sortedJobs.isEmpty {
            emptyState
                .padding(.horizontal, 16)
                .padding(.bottom, 24)
        } else {
            LazyVStack(spacing: 10) {
                ForEach(sortedJobs) { job in
                    Button { onOpenGig(job) } label: {
                        gigCard(job)
                    }
                    .buttonStyle(PressableButtonStyle())
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 24)
        }
    }

    private var subtitle: String {
        if demoStore.isOn { return "14 within 10 mi" }
        if isLoading { return "Loading nearby requests" }
        if jobs.isEmpty { return "0 open requests" }
        return "\(jobs.count) open request\(jobs.count == 1 ? "" : "s")"
    }

    private var sortedJobs: [AviaryJob] {
        switch sortIdx {
        case 1:
            return jobs.sorted { ($0.payoutCents ?? 0) > ($1.payoutCents ?? 0) }
        case 2:
            return jobs.sorted { ($0.distanceMiles ?? .greatestFiniteMagnitude) < ($1.distanceMiles ?? .greatestFiniteMagnitude) }
        case 3:
            return jobs.sorted { $0.sortDate < $1.sortDate }
        default:
            return jobs.sorted { lhs, rhs in
                let lhsPayout = lhs.payoutCents ?? 0
                let rhsPayout = rhs.payoutCents ?? 0
                if lhsPayout != rhsPayout { return lhsPayout > rhsPayout }
                return (lhs.distanceMiles ?? 999) < (rhs.distanceMiles ?? 999)
            }
        }
    }

    private var sortedDemoGigs: [GigRow] {
        switch sortIdx {
        case 1:
            return demoGigs.sorted { $0.priceValue > $1.priceValue }
        case 2:
            return demoGigs.sorted { $0.distanceValue < $1.distanceValue }
        case 3:
            return Array(demoGigs.reversed())
        default:
            return demoGigs
        }
    }

    private func loadJobs() async {
        guard !demoStore.isOn else {
            jobs = []
            isLoading = false
            errorMessage = nil
            return
        }
        isLoading = true
        errorMessage = nil
        do {
            jobs = try await AviaryDataService.shared.availableGigs()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    private var emptyState: some View {
        FeatureStateCard(icon: "compass",
                         title: "No gigs nearby right now",
                         message: "Check back later or expand your search radius. We'll send a push when something matches.")
    }

    private func gigCard(_ g: GigRow) -> some View {
        AviaryCard(padding: 14, shadowed: true) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12).fill(t.surface2)
                    AviaryIcon(name: g.icon, size: 22, stroke: 2, color: g.color?.color(t) ?? t.accent)
                }
                .frame(width: 48, height: 48)
                VStack(alignment: .leading, spacing: 2) {
                    HStack(alignment: .firstTextBaseline) {
                        Text(g.title)
                            .font(AviaryFont.body(15, weight: .semibold))
                            .foregroundStyle(t.ink)
                            .lineLimit(1)
                        Spacer()
                        Text(g.price)
                            .font(AviaryFont.mono(16, weight: .semibold))
                            .foregroundStyle(t.ink)
                    }
                    Text("\(g.addr) · \(g.dist)")
                        .font(AviaryFont.body(13))
                        .foregroundStyle(t.ink3)
                    Text(g.time)
                        .font(AviaryFont.body(12))
                        .foregroundStyle(t.ink4)
                        .padding(.top, 4)
                }
            }
        }
    }

    private func gigCard(_ job: AviaryJob) -> some View {
        AviaryCard(padding: 14, shadowed: true) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12).fill(t.surface2)
                    AviaryIcon(name: icon(for: job), size: 22, stroke: 2, color: t.accent)
                }
                .frame(width: 48, height: 48)
                VStack(alignment: .leading, spacing: 2) {
                    HStack(alignment: .firstTextBaseline) {
                        Text(job.displayTitle)
                            .font(AviaryFont.body(15, weight: .semibold))
                            .foregroundStyle(t.ink)
                            .lineLimit(1)
                        Spacer()
                        Text(job.payoutText)
                            .font(AviaryFont.mono(16, weight: .semibold))
                            .foregroundStyle(t.ink)
                    }
                    Text("\(job.displayAddress) · \(job.distanceText)")
                        .font(AviaryFont.body(13))
                        .foregroundStyle(t.ink3)
                        .lineLimit(1)
                    Text("\(job.scheduledText) · \(job.durationText)")
                        .font(AviaryFont.body(12))
                        .foregroundStyle(t.ink4)
                        .padding(.top, 4)
                }
            }
        }
    }

    private func icon(for job: AviaryJob) -> String {
        switch job.jobType?.lowercased() {
        case "inspection": return "cert"
        case "event": return "star"
        case "mapping": return "altitude"
        default: return "camera"
        }
    }

    struct GigRow: Identifiable {
        let id = UUID()
        var title: String
        var addr: String
        var dist: String
        var price: String
        var time: String
        var icon: String
        var color: GigColor?

        var priceValue: Int {
            Int(price.filter(\.isNumber)) ?? 0
        }

        var distanceValue: Double {
            Double(dist.replacingOccurrences(of: " mi", with: "")) ?? .greatestFiniteMagnitude
        }
    }
    enum GigColor {
        case good
        func color(_ t: ThemeTokens) -> Color {
            switch self { case .good: return t.good }
        }
    }
}

// MARK: - Map home (alternate / pilot map view)

struct MapHomeScreen: View {
    @Environment(\.theme) private var t
    var onOpenAcceptPing: () -> Void = {}

    var body: some View {
        ZStack {
            MapBackground(
                pins: [
                    .init(x: 90, y: 220, label: "$340", pulse: true),
                    .init(x: 280, y: 180, label: "$185"),
                    .init(x: 320, y: 460, label: "$520", color: t.good),
                    .init(x: 60, y: 480, label: "$95"),
                    .init(x: 200, y: 580, label: "$410"),
                ],
                showPilot: true,
                pilotPos: .init(x: 195, y: 380)
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                topBar
                filterChips
                Spacer()
                bottomSheet
            }
        }
    }

    private var topBar: some View {
        HStack(spacing: 10) {
            HStack(spacing: 10) {
                AviaryIcon(name: "search", size: 18, color: t.ink3)
                Text("Search area, gig type…")
                    .font(AviaryFont.body(15))
                    .foregroundStyle(t.ink3)
                Spacer()
                AviaryIcon(name: "filter", size: 18, color: t.ink2)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(Capsule().fill(t.surface))
            .overlay(Capsule().strokeBorder(t.line))
            .shadow(color: .black.opacity(0.06), radius: 16, y: 4)

            ZStack {
                Circle().fill(t.surface)
                AviaryIcon(name: "bell", size: 20, color: t.ink)
            }
            .frame(width: 44, height: 44)
            .overlay(Circle().strokeBorder(t.line))
            .shadow(color: .black.opacity(0.06), radius: 16, y: 4)
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }

    private var filterChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                Chip(text: "All gigs", style: .accent)
                Chip(text: "Real estate", style: .surface)
                Chip(text: "Inspections", style: .surface)
                Chip(text: "Mapping", style: .surface)
            }
            .padding(.horizontal, 16)
        }
        .padding(.top, 12)
    }

    private var bottomSheet: some View {
        VStack(spacing: 0) {
            RoundedRectangle(cornerRadius: 2)
                .fill(t.lineStrong)
                .frame(width: 36, height: 4)
                .padding(.top, 12)
                .padding(.bottom, 14)

            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("5 gigs nearby")
                        .font(AviaryFont.display(20, weight: .bold))
                        .tracking(-0.02 * 20)
                        .foregroundStyle(t.ink)
                    Text("You're online · Berkeley, CA")
                        .font(AviaryFont.body(13))
                        .foregroundStyle(t.ink3)
                }
                Spacer()
                HStack(spacing: 6) {
                    Circle().fill(t.good).frame(width: 8, height: 8)
                    Text("Live")
                        .font(AviaryFont.body(13, weight: .semibold))
                        .foregroundStyle(t.good)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 14)

            Button { onOpenAcceptPing() } label: {
                AviaryCard(padding: 14, shadowed: true) {
                    HStack(spacing: 12) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 12).fill(t.surface2)
                            AviaryIcon(name: "camera", size: 24, stroke: 2, color: t.accent)
                        }
                        .frame(width: 56, height: 56)
                        VStack(alignment: .leading, spacing: 2) {
                            HStack(alignment: .firstTextBaseline) {
                                Text("Real estate aerials")
                                    .font(AviaryFont.body(15, weight: .semibold))
                                    .foregroundStyle(t.ink)
                                Spacer()
                                Text("$340")
                                    .font(AviaryFont.mono(17, weight: .semibold))
                                    .foregroundStyle(t.accent)
                            }
                            Text("1247 Vine St · 1.2 mi away")
                                .font(AviaryFont.body(13))
                                .foregroundStyle(t.ink3)
                            HStack(spacing: 8) {
                                Chip(text: "~45 min")
                                Chip(text: "Today, 3:30pm")
                                Chip(text: "★ Premium", style: .good)
                            }
                            .padding(.top, 4)
                        }
                    }
                }
            }
            .buttonStyle(PressableButtonStyle())
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
        .background(
            UnevenRoundedRectangle(
                topLeadingRadius: 24,
                bottomLeadingRadius: 0,
                bottomTrailingRadius: 0,
                topTrailingRadius: 24,
                style: .continuous
            )
            .fill(t.surface)
            .shadow(color: .black.opacity(0.06), radius: 24, y: -8)
        )
    }
}

// MARK: - Gig detail

struct GigDetailScreen: View {
    @Environment(\.theme) private var t
    @Environment(\.dismiss) private var dismiss
    let job: AviaryJob?
    let pilotProfile: UserProfile?
    @State private var isAccepting: Bool = false
    @State private var errorMessage: String?
    var onAccept: () -> Void = {}

    var body: some View {
        ZStack(alignment: .top) {
            t.surface.ignoresSafeArea()

            VStack(spacing: 0) {
                ZStack(alignment: .top) {
                    MapBackground(pins: [.init(x: 195, y: 150, label: job?.payoutText ?? "$340", pulse: true)])
                        .frame(height: 260)
                    HStack {
                        circleBtn(icon: "arrow-left") { dismiss() }
                        Spacer()
                        circleBtn(icon: "upload") {}
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                }

                ScrollView {
                    bodyContent
                        .padding(.horizontal, 22)
                        .padding(.top, 20)
                        .padding(.bottom, 24)
                        .background(
                            UnevenRoundedRectangle(
                                topLeadingRadius: 28, bottomLeadingRadius: 0,
                                bottomTrailingRadius: 0, topTrailingRadius: 28,
                                style: .continuous
                            )
                            .fill(t.surface)
                        )
                }
                .padding(.top, -24)
            }
        }
    }

    private var bodyContent: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Chip(text: job?.displayType ?? "Premium gig", style: .accent)
                    Text(job?.displayTitle ?? "Real estate aerials")
                        .font(AviaryFont.display(22, weight: .bold))
                        .tracking(-0.02 * 22)
                        .foregroundStyle(t.ink)
                    Text("\(job?.displayAddress ?? "1247 Vine St, Berkeley") · \(job?.distanceText ?? "1.2 mi")")
                        .font(AviaryFont.body(13))
                        .foregroundStyle(t.ink3)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 1) {
                    Text(job?.payoutText ?? "$340")
                        .font(AviaryFont.mono(28, weight: .semibold))
                        .foregroundStyle(t.accent)
                    Text("est. payout")
                        .font(AviaryFont.body(11))
                        .foregroundStyle(t.ink4)
                }
            }
            .padding(.bottom, 18)

            HStack(spacing: 8) {
                stat(label: "Duration", value: job?.durationText ?? "~45 min", color: t.ink)
                stat(label: "Start", value: job?.scheduledText ?? "3:30 PM", color: t.ink)
                stat(label: "Airspace", value: "Class G ✓", color: t.good)
            }
            .padding(.bottom, 18)

            SectionTitle(text: "Deliverables")
                .padding(.bottom, 4)

            ForEach(displayDeliverables.indices, id: \.self) { i in
                let d = displayDeliverables[i]
                HStack(spacing: 12) {
                    AviaryIcon(name: d.icon, size: 18, color: t.ink3)
                    Text(d.label)
                        .font(AviaryFont.body(14))
                        .foregroundStyle(t.ink)
                }
                .padding(.vertical, 10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .overlay(
                    Rectangle().fill(t.line).frame(height: 1),
                    alignment: .bottom
                )
                .opacity(1)
            }
            .padding(.bottom, 6)

            HStack(spacing: 10) {
                Avatar(size: 36, initials: initials(for: job?.displayClient ?? "MR"), background: t.accentSoft)
                VStack(alignment: .leading, spacing: 1) {
                    Text(job?.displayClient ?? "Marin Realty Co.")
                        .font(AviaryFont.body(14, weight: .semibold))
                        .foregroundStyle(t.ink)
                    Text(job == nil ? "★ 4.9 · 28 gigs posted" : "\(job?.statusLabel ?? "Open") · customer request")
                        .font(AviaryFont.body(12))
                        .foregroundStyle(t.ink3)
                }
                Spacer()
                ZStack {
                    Circle().fill(t.surface2)
                    AviaryIcon(name: "message", size: 18, color: t.ink)
                }
                .frame(width: 36, height: 36)
            }
            .padding(.top, 12)

            if let errorMessage {
                Text(errorMessage)
                    .font(AviaryFont.body(12))
                    .foregroundStyle(t.warn)
                    .padding(.top, 14)
            }

            HStack(spacing: 10) {
                SecondaryButton(title: "Save")
                    .frame(maxWidth: 110)
                PrimaryButton(title: isAccepting ? "Accepting..." : "Accept gig",
                              systemTrailing: "arrow.right",
                              enabled: !isAccepting,
                              action: acceptGig)
            }
            .padding(.top, 20)
        }
    }

    private struct Deliverable { var label: String; var icon: String }

    private var displayDeliverables: [Deliverable] {
        let labels = job?.displayDeliverables ?? [
            "12 exterior photos · 4K",
            "60-sec cinematic flyover",
            "Twilight shot (post-sunset)"
        ]
        return labels.enumerated().map { idx, label in
            switch idx {
            case 1: return .init(label: label, icon: "play")
            case 2: return .init(label: label, icon: "sun")
            default: return .init(label: label, icon: "camera")
            }
        }
    }

    private func acceptGig() {
        guard let job, let pilotProfile else {
            onAccept()
            return
        }
        isAccepting = true
        errorMessage = nil
        Task {
            do {
                try await AviaryDataService.shared.accept(job: job, pilotID: pilotProfile.id)
                await MainActor.run {
                    isAccepting = false
                    onAccept()
                }
            } catch {
                await MainActor.run {
                    isAccepting = false
                    errorMessage = error.localizedDescription
                }
            }
        }
    }

    private func initials(for name: String) -> String {
        let initials = name
            .split(separator: " ")
            .compactMap(\.first)
            .prefix(2)
        return initials.isEmpty ? "CL" : String(initials).uppercased()
    }

    private func stat(label: String, value: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(AviaryFont.body(11))
                .foregroundStyle(t.ink3)
            Text(value)
                .font(AviaryFont.body(14, weight: .semibold))
                .foregroundStyle(color)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12).fill(t.surface2)
        )
    }

    private func circleBtn(icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            ZStack {
                Circle().fill(t.surface)
                AviaryIcon(name: icon, size: 18, color: t.ink)
            }
            .frame(width: 40, height: 40)
            .overlay(Circle().strokeBorder(t.line))
            .shadow(color: .black.opacity(0.08), radius: 10, y: 3)
        }
        .buttonStyle(PressableButtonStyle())
    }
}
