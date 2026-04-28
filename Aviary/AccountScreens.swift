import SwiftUI

// MARK: - Earnings

struct EarningsScreen: View {
    @Environment(\.theme) private var t

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

                    weeklyCard
                        .padding(.horizontal, 20)
                        .padding(.bottom, 14)

                    HStack(spacing: 10) {
                        AviaryCard(padding: 14) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Available")
                                    .font(AviaryFont.body(12))
                                    .foregroundStyle(t.ink3)
                                Text("$1,484.00")
                                    .font(AviaryFont.mono(22, weight: .semibold))
                                    .foregroundStyle(t.ink)
                                Text("Cash out →")
                                    .font(AviaryFont.body(11, weight: .semibold))
                                    .foregroundStyle(t.accent)
                                    .padding(.top, 4)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        AviaryCard(padding: 14) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("In review")
                                    .font(AviaryFont.body(12))
                                    .foregroundStyle(t.ink3)
                                Text("$664.50")
                                    .font(AviaryFont.mono(22, weight: .semibold))
                                    .foregroundStyle(t.ink)
                                Text("2 gigs pending")
                                    .font(AviaryFont.body(11))
                                    .foregroundStyle(t.ink4)
                                    .padding(.top, 4)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
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
                }
            }
        }
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
    @State private var mode: ModeSwitch.Mode = .pilot
    @ObservedObject var themeManager: ThemeManager
    var onOpenMessages: () -> Void = {}

    var body: some View {
        ZStack {
            t.bg.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    HStack(spacing: 14) {
                        Avatar(size: 64, initials: "JD", background: t.accentSoft)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Jordan Daly")
                                .font(AviaryFont.body(19, weight: .bold))
                                .tracking(-0.01 * 19)
                                .foregroundStyle(t.ink)
                            Text("Pilot · Berkeley, CA")
                                .font(AviaryFont.body(13))
                                .foregroundStyle(t.ink3)
                            HStack(spacing: 6) {
                                Chip(text: "4.92", icon: "star", style: .good)
                                Chip(text: "137 gigs")
                            }
                            .padding(.top, 4)
                        }
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .padding(.bottom, 16)

                    HStack {
                        ModeSwitch(mode: $mode)
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 12)

                    AviaryCard(padding: 0) {
                        VStack(spacing: 0) {
                            profileRow(icon: "cert", label: "Certifications",
                                       value: "Part 107 · verified", isGood: true, divider: true)
                            profileRow(icon: "drone", label: "Equipment",
                                       value: "Mavic 3 Pro · DJI Mini 4", divider: true)
                            profileRow(icon: "shield", label: "Insurance",
                                       value: "$2M Aviary Cover", divider: true)
                            profileRow(icon: "card", label: "Payouts",
                                       value: "Chase ••4471", divider: false)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)

                    SectionTitle(text: "Performance")
                        .padding(.horizontal, 20)
                        .padding(.bottom, 8)
                    HStack(spacing: 10) {
                        perfStat(label: "On-time", value: "99%")
                        perfStat(label: "Accept", value: "87%")
                        perfStat(label: "Re-hires", value: "42%")
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 16)

                    SectionTitle(text: "Theme")
                        .padding(.horizontal, 20)
                        .padding(.bottom, 8)
                    HStack(spacing: 8) {
                        ForEach(AviaryTheme.allCases) { th in
                            Button {
                                themeManager.theme = th
                            } label: {
                                Text(th.label)
                                    .font(AviaryFont.body(13, weight: .semibold))
                                    .foregroundStyle(themeManager.theme == th ? t.accentInk : t.ink2)
                                    .padding(.horizontal, 14).padding(.vertical, 8)
                                    .background(
                                        Capsule().fill(themeManager.theme == th ? t.accent : t.surface)
                                    )
                                    .overlay(
                                        Capsule().strokeBorder(t.line)
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 8)

                    Button {
                        onOpenMessages()
                    } label: {
                        HStack(spacing: 12) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 10).fill(t.accentSoft)
                                AviaryIcon(name: "message", size: 18, color: t.accent)
                            }
                            .frame(width: 34, height: 34)
                            Text("Messages")
                                .font(AviaryFont.body(14, weight: .medium))
                                .foregroundStyle(t.ink)
                            Spacer()
                            AviaryIcon(name: "chevron-right", size: 16, color: t.ink4)
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
    }

    private func profileRow(icon: String, label: String, value: String,
                            isGood: Bool = false, divider: Bool) -> some View {
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
            AviaryIcon(name: "chevron-right", size: 16, color: t.ink4)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
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

    var body: some View {
        ZStack {
            t.bg.ignoresSafeArea()
            VStack(spacing: 0) {
                header

                pinnedContext
                    .padding(.horizontal, 16)
                    .padding(.bottom, 12)

                ScrollView {
                    VStack(alignment: .leading, spacing: 10) {
                        bubble(text: "Hey Jordan — gate code is 4471. Owner asked for a sunset shot too if light's good.",
                               time: "2:14 PM", incoming: true)
                        bubble(text: "Got it. ETA 22 min. Sunset is 7:48 — happy to add a twilight set for $40.",
                               time: "2:16 PM ✓✓", incoming: false)
                        bubble(text: "Done. Sending the add-on now 👍",
                               time: nil, incoming: true)
                        typingBubble
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 4)
                    .padding(.bottom, 12)
                }

                composer
            }
        }
    }

    private var header: some View {
        HStack(spacing: 12) {
            Button { dismiss() } label: {
                AviaryIcon(name: "arrow-left", size: 22, color: t.ink)
            }
            Avatar(size: 36, initials: "MR", background: t.accentSoft)
            VStack(alignment: .leading, spacing: 0) {
                Text("Marin Realty")
                    .font(AviaryFont.body(15, weight: .semibold))
                    .foregroundStyle(t.ink)
                Text("● Online")
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

    private var pinnedContext: some View {
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
            Text("● ● ●")
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

    private var composer: some View {
        HStack(spacing: 10) {
            AviaryIcon(name: "plus", size: 22, color: t.ink3)
            HStack {
                Text("Message…")
                    .font(AviaryFont.body(14))
                    .foregroundStyle(t.ink4)
                Spacer()
            }
            .padding(.horizontal, 16).padding(.vertical, 10)
            .background(Capsule().fill(t.surface2))
            ZStack {
                Circle().fill(t.accent)
                AviaryIcon(name: "arrow-right", size: 18, color: t.accentInk)
            }
            .frame(width: 36, height: 36)
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
}

// MARK: - Client request a flight

struct ClientRequestScreen: View {
    @Environment(\.theme) private var t
    @Environment(\.dismiss) private var dismiss
    @State private var typeIdx: Int = 0
    @State private var mode: ModeSwitch.Mode = .client

    private let types: [(label: String, icon: String)] = [
        ("Real estate", "camera"), ("Inspection", "cert"),
        ("Event", "star"), ("Mapping", "altitude")
    ]

    var body: some View {
        ZStack(alignment: .top) {
            t.bg.ignoresSafeArea()
            VStack(spacing: 0) {
                ZStack(alignment: .top) {
                    MapBackground(pins: [.init(x: 195, y: 140, label: "📍")])
                        .frame(height: 280)
                    HStack {
                        Button { dismiss() } label: {
                            ZStack {
                                Circle().fill(t.surface)
                                AviaryIcon(name: "arrow-left", size: 18, color: t.ink)
                            }
                            .frame(width: 40, height: 40)
                            .overlay(Circle().strokeBorder(t.line))
                            .shadow(color: .black.opacity(0.06), radius: 12, y: 4)
                        }
                        Spacer()
                        ModeSwitch(mode: $mode)
                            .padding(8)
                            .background(.ultraThinMaterial, in: Capsule())
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                }

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
                                Button { typeIdx = idx } label: {
                                    typeTile(label: item.label, icon: item.icon, active: idx == typeIdx)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.bottom, 12)

                        AviaryCard(padding: 0) {
                            VStack(spacing: 0) {
                                detailRow(icon: "pin", text: "1247 Vine St, Berkeley", divider: true)
                                detailRow(icon: "clock", text: "Today, 3:30 PM", divider: true)
                                detailRow(icon: "camera", text: "12 photos + 60s flyover", divider: false)
                            }
                        }
                        .padding(.bottom, 12)

                        HStack {
                            VStack(alignment: .leading, spacing: 1) {
                                Text("Estimated")
                                    .font(AviaryFont.body(12))
                                    .foregroundStyle(t.ink3)
                                Text("$320–$380")
                                    .font(AviaryFont.mono(24, weight: .semibold))
                                    .foregroundStyle(t.ink)
                            }
                            Spacer()
                            PrimaryButton(title: "Post gig",
                                          systemTrailing: "arrow.right",
                                          fullWidth: false) { dismiss() }
                        }
                        .padding(.vertical, 14)
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
            AviaryIcon(name: "chevron-right", size: 16, color: t.ink4)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .overlay(
            divider ? Rectangle().fill(t.line).frame(height: 1) : nil,
            alignment: .bottom
        )
    }
}
