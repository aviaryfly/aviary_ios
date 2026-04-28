import SwiftUI

// MARK: - Gig list

struct GigListScreen: View {
    @Environment(\.theme) private var t
    @EnvironmentObject private var demoStore: DemoModeStore
    @State private var sortIdx: Int = 0
    var onOpenGig: () -> Void = {}

    private let sorts = ["Best match", "Highest pay", "Closest", "Soonest"]
    private let gigs: [GigRow] = [
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
                PageHeader(title: "Gigs", subtitle: demoStore.isOn ? "14 within 10 mi" : "0 within 10 mi") {
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
                    if demoStore.isOn {
                        LazyVStack(spacing: 10) {
                            ForEach(gigs) { gig in
                                Button { onOpenGig() } label: {
                                    gigCard(gig)
                                }
                                .buttonStyle(PressableButtonStyle())
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 24)
                    } else {
                        emptyState
                            .padding(.horizontal, 16)
                            .padding(.bottom, 24)
                    }
                }
            }
        }
    }

    private var emptyState: some View {
        AviaryCard(padding: 22) {
            VStack(alignment: .leading, spacing: 10) {
                AviaryIcon(name: "compass", size: 24, color: t.ink3)
                Text("No gigs nearby right now")
                    .font(AviaryFont.body(17, weight: .semibold))
                    .foregroundStyle(t.ink)
                Text("Check back later or expand your search radius. We'll send a push when something matches.")
                    .font(AviaryFont.body(13))
                    .foregroundStyle(t.ink3)
                    .lineSpacing(2)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
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

    struct GigRow: Identifiable {
        let id = UUID()
        var title: String
        var addr: String
        var dist: String
        var price: String
        var time: String
        var icon: String
        var color: GigColor?
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
    var onAccept: () -> Void = {}

    var body: some View {
        ZStack(alignment: .top) {
            t.surface.ignoresSafeArea()

            VStack(spacing: 0) {
                ZStack(alignment: .top) {
                    MapBackground(pins: [.init(x: 195, y: 150, label: "$340", pulse: true)])
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
                    Chip(text: "★ Premium gig", style: .accent)
                    Text("Real estate aerials")
                        .font(AviaryFont.display(22, weight: .bold))
                        .tracking(-0.02 * 22)
                        .foregroundStyle(t.ink)
                    Text("1247 Vine St, Berkeley · 1.2 mi")
                        .font(AviaryFont.body(13))
                        .foregroundStyle(t.ink3)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 1) {
                    Text("$340")
                        .font(AviaryFont.mono(28, weight: .semibold))
                        .foregroundStyle(t.accent)
                    Text("est. payout")
                        .font(AviaryFont.body(11))
                        .foregroundStyle(t.ink4)
                }
            }
            .padding(.bottom, 18)

            HStack(spacing: 8) {
                stat(label: "Duration", value: "~45 min", color: t.ink)
                stat(label: "Start", value: "3:30 PM", color: t.ink)
                stat(label: "Airspace", value: "Class G ✓", color: t.good)
            }
            .padding(.bottom, 18)

            SectionTitle(text: "Deliverables")
                .padding(.bottom, 4)

            ForEach(deliverables.indices, id: \.self) { i in
                let d = deliverables[i]
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
                Avatar(size: 36, initials: "MR", background: t.accentSoft)
                VStack(alignment: .leading, spacing: 1) {
                    Text("Marin Realty Co.")
                        .font(AviaryFont.body(14, weight: .semibold))
                        .foregroundStyle(t.ink)
                    Text("★ 4.9 · 28 gigs posted")
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

            HStack(spacing: 10) {
                SecondaryButton(title: "Save")
                    .frame(maxWidth: 110)
                PrimaryButton(title: "Accept gig", systemTrailing: "arrow.right",
                              action: onAccept)
            }
            .padding(.top, 20)
        }
    }

    private struct Deliverable { var label: String; var icon: String }
    private let deliverables: [Deliverable] = [
        .init(label: "12 exterior photos · 4K", icon: "camera"),
        .init(label: "60-sec cinematic flyover", icon: "play"),
        .init(label: "Twilight shot (post-sunset)", icon: "sun"),
    ]

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
