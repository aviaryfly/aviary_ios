import SwiftUI

struct CustomerHomeScreen: View {
    @Environment(\.theme) private var t
    @EnvironmentObject private var demoStore: DemoModeStore
    let profile: UserProfile
    var onPostJob: () -> Void = {}

    var body: some View {
        ZStack {
            t.bg.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    header
                    greeting
                    postJobCallout
                        .padding(.horizontal, 16)
                        .padding(.top, 6)
                    statsRow
                        .padding(.horizontal, 20)
                        .padding(.top, 16)
                    SectionTitle(text: "Recent activity")
                        .padding(.horizontal, 20)
                        .padding(.top, 22)
                        .padding(.bottom, 8)
                    if demoStore.isOn {
                        recentActivityList
                            .padding(.horizontal, 16)
                            .padding(.bottom, 24)
                    } else {
                        emptyActivity
                            .padding(.horizontal, 16)
                            .padding(.bottom, 24)
                    }
                }
            }
        }
    }

    private var header: some View {
        HStack {
            HStack(spacing: 8) {
                AviaryLogo(size: 22, color: t.accent)
                Text("aviary")
                    .font(AviaryFont.body(17, weight: .bold))
                    .tracking(-0.02 * 17)
                    .foregroundStyle(t.ink)
            }
            Spacer()
            Avatar(size: 32,
                   initials: profile.initials,
                   background: t.accentSoft,
                   imageUrl: profile.avatarUrl.flatMap(URL.init(string:)))
        }
        .padding(.horizontal, 22)
        .padding(.top, 12)
    }

    private var greeting: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Welcome")
                .font(AviaryFont.body(13, weight: .medium))
                .foregroundStyle(t.ink3)
            Text(greetingTitle)
                .font(AviaryFont.display(32, weight: .bold))
                .tracking(-0.03 * 32)
                .lineSpacing(-2)
                .foregroundStyle(t.ink)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 22)
        .padding(.top, 20)
        .padding(.bottom, 10)
    }

    private var greetingTitle: String {
        if let name = profile.fullName?.split(separator: " ").first {
            return "Hi \(name) — need a pilot?"
        }
        return "Need a pilot?"
    }

    private var postJobCallout: some View {
        Button(action: onPostJob) {
            VStack(alignment: .leading, spacing: 0) {
                Text("POST A JOB")
                    .font(AviaryFont.body(11, weight: .semibold))
                    .tracking(0.08 * 11)
                    .foregroundStyle(t.accentInk.opacity(0.85))
                Text("Get a pilot in 4 minutes")
                    .font(AviaryFont.display(24, weight: .bold))
                    .tracking(-0.02 * 24)
                    .foregroundStyle(t.accentInk)
                    .padding(.top, 6)
                Text("Real estate, inspection, event, mapping — describe what you need shot and a vetted Part 107 pilot accepts.")
                    .font(AviaryFont.body(13))
                    .foregroundStyle(t.accentInk.opacity(0.85))
                    .lineSpacing(2)
                    .padding(.top, 8)
                HStack {
                    Spacer()
                    HStack(spacing: 6) {
                        Text("Start")
                            .font(AviaryFont.body(13, weight: .semibold))
                        AviaryIcon(name: "arrow-right", size: 14, color: t.accentInk)
                    }
                    .foregroundStyle(t.accentInk)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(Capsule().fill(t.accentInk.opacity(0.18)))
                }
                .padding(.top, 14)
            }
            .padding(18)
            .background(
                RoundedRectangle(cornerRadius: Radius.md, style: .continuous).fill(t.accent)
            )
            .shadow(color: t.accent.opacity(0.4), radius: 24, y: 12)
        }
        .buttonStyle(PressableButtonStyle())
    }

    private var statsRow: some View {
        HStack(spacing: 10) {
            stat(label: "Active jobs", value: demoStore.isOn ? "2" : "0")
            stat(label: "Total spend", value: demoStore.isOn ? "$3,420" : "$0")
            stat(label: "Pilots used", value: demoStore.isOn ? "5" : "0")
        }
    }

    private func stat(label: String, value: String) -> some View {
        AviaryCard(padding: 12) {
            VStack(spacing: 2) {
                Text(value)
                    .font(AviaryFont.mono(20, weight: .semibold))
                    .foregroundStyle(t.ink)
                Text(label)
                    .font(AviaryFont.body(11))
                    .foregroundStyle(t.ink3)
            }
            .frame(maxWidth: .infinity)
        }
    }

    private var emptyActivity: some View {
        AviaryCard(padding: 20) {
            VStack(alignment: .leading, spacing: 8) {
                AviaryIcon(name: "clock", size: 22, color: t.ink3)
                Text("No jobs yet")
                    .font(AviaryFont.body(15, weight: .semibold))
                    .foregroundStyle(t.ink)
                Text("Post your first job to see it here. We'll notify you the moment a pilot accepts.")
                    .font(AviaryFont.body(13))
                    .foregroundStyle(t.ink3)
                    .lineSpacing(2)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private struct DemoActivityRow {
        let icon: String
        let title: String
        let subtitle: String
        let amount: String
        let chip: String
        let chipStyle: Chip.Style
    }

    private var demoActivity: [DemoActivityRow] {
        [
            DemoActivityRow(icon: "camera",
                            title: "Real estate · 1247 Vine St",
                            subtitle: "Casey Park · today, 3:30 PM",
                            amount: "$340",
                            chip: "En route",
                            chipStyle: .accent),
            DemoActivityRow(icon: "cert",
                            title: "Roof inspection · 22 Hillside Ave",
                            subtitle: "Casey Park · 2 days ago",
                            amount: "$220",
                            chip: "Completed",
                            chipStyle: .good),
            DemoActivityRow(icon: "star",
                            title: "Wedding aerial · Tilden Park",
                            subtitle: "M. Hartley · last Saturday",
                            amount: "$780",
                            chip: "Completed",
                            chipStyle: .good),
            DemoActivityRow(icon: "altitude",
                            title: "Vineyard mapping · Stags Leap",
                            subtitle: "L. Tan · scheduled Wed",
                            amount: "$1,250",
                            chip: "Scheduled",
                            chipStyle: .neutral)
        ]
    }

    private var recentActivityList: some View {
        VStack(spacing: 10) {
            ForEach(Array(demoActivity.enumerated()), id: \.offset) { _, row in
                AviaryCard(padding: 14, shadowed: true) {
                    HStack(spacing: 12) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 12).fill(t.surface2)
                            AviaryIcon(name: row.icon, size: 20, stroke: 2, color: t.accent)
                        }
                        .frame(width: 44, height: 44)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(row.title)
                                .font(AviaryFont.body(14, weight: .semibold))
                                .foregroundStyle(t.ink)
                                .lineLimit(1)
                            Text(row.subtitle)
                                .font(AviaryFont.body(12))
                                .foregroundStyle(t.ink3)
                                .lineLimit(1)
                            Chip(text: row.chip, style: row.chipStyle)
                                .padding(.top, 4)
                        }
                        Spacer(minLength: 0)
                        Text(row.amount)
                            .font(AviaryFont.mono(15, weight: .semibold))
                            .foregroundStyle(t.ink)
                    }
                }
            }
        }
    }
}
