import SwiftUI

struct HomeScreen: View {
    @Environment(\.theme) private var t
    @State private var mode: ModeSwitch.Mode = .pilot
    var onOpenAcceptPing: () -> Void = {}
    var onOpenGigDetail: () -> Void = {}

    var body: some View {
        ZStack {
            t.bg.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    header
                    greeting
                    todaySnapshot
                        .padding(.horizontal, 16)
                        .padding(.top, 6)
                    quickActions
                        .padding(.horizontal, 22)
                        .padding(.top, 12)
                    upNextHeader
                        .padding(.horizontal, 22)
                        .padding(.top, 8)
                    upNextCard
                        .padding(.horizontal, 16)
                        .padding(.top, 6)
                    editorialBanner
                        .padding(.horizontal, 22)
                        .padding(.top, 14)
                        .padding(.bottom, 24)
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
            HStack(spacing: 14) {
                ModeSwitch(mode: $mode)
                Avatar(size: 32, initials: "JD", background: t.accentSoft)
            }
        }
        .padding(.horizontal, 22)
        .padding(.top, 12)
    }

    private var greeting: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Tuesday · clear · 9 mph")
                .font(AviaryFont.body(13, weight: .medium))
                .foregroundStyle(t.ink3)
            Text("Good flying weather, Jordan.")
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

    private var todaySnapshot: some View {
        Button {
            onOpenGigDetail()
        } label: {
            VStack(alignment: .leading, spacing: 0) {
                Text("TODAY")
                    .font(AviaryFont.body(11, weight: .semibold))
                    .tracking(0.08 * 11)
                    .foregroundStyle(t.accentInk.opacity(0.85))
                HStack(alignment: .lastTextBaseline) {
                    HStack(alignment: .lastTextBaseline, spacing: 0) {
                        Text("$625")
                            .font(AviaryFont.mono(36, weight: .semibold))
                            .tracking(-0.025 * 36)
                            .foregroundStyle(t.accentInk)
                        Text(".00")
                            .font(AviaryFont.mono(18, weight: .semibold))
                            .foregroundStyle(t.accentInk.opacity(0.7))
                    }
                    Spacer()
                    Text("2 of 3 gigs done")
                        .font(AviaryFont.body(12))
                        .foregroundStyle(t.accentInk.opacity(0.85))
                }
                .padding(.top, 4)

                HStack(spacing: 4) {
                    ForEach(0..<3) { i in
                        RoundedRectangle(cornerRadius: 3)
                            .fill(i < 2 ? t.accentInk.opacity(0.95) : t.accentInk.opacity(0.25))
                            .frame(height: 5)
                    }
                }
                .padding(.top, 14)

                HStack {
                    Text("Next at 3:30 PM · 1247 Vine St")
                        .font(AviaryFont.body(12))
                        .foregroundStyle(t.accentInk.opacity(0.85))
                    Spacer()
                    Text("+$340 →")
                        .font(AviaryFont.body(12, weight: .semibold))
                        .foregroundStyle(t.accentInk)
                }
                .padding(.top, 12)
                .padding(.top, 12)
                .overlay(
                    Rectangle().fill(t.accentInk.opacity(0.2)).frame(height: 1),
                    alignment: .top
                )
            }
            .padding(18)
            .background(
                RoundedRectangle(cornerRadius: Radius.md, style: .continuous)
                    .fill(t.accent)
            )
            .shadow(color: t.accent.opacity(0.4), radius: 24, y: 12)
        }
        .buttonStyle(PressableButtonStyle())
    }

    private var quickActions: some View {
        HStack(spacing: 10) {
            quickAction(iconBg: t.good, iconColor: .white, icon: "navigation",
                        title: "Go online", subtitle: "Accept pings")
            quickAction(iconBg: t.surface2, iconColor: t.accent, icon: "compass",
                        title: "Browse", subtitle: "14 nearby")
        }
    }

    private func quickAction(iconBg: Color, iconColor: Color, icon: String,
                             title: String, subtitle: String) -> some View {
        HStack(spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 10).fill(iconBg)
                AviaryIcon(name: icon, size: 18, stroke: 2, color: iconColor)
            }
            .frame(width: 36, height: 36)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(AviaryFont.body(13, weight: .semibold))
                    .foregroundStyle(t.ink)
                    .lineLimit(1)
                Text(subtitle)
                    .font(AviaryFont.body(11))
                    .foregroundStyle(t.ink3)
                    .lineLimit(1)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous).fill(t.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous).strokeBorder(t.line)
        )
    }

    private var upNextHeader: some View {
        HStack(alignment: .firstTextBaseline) {
            Text("Up next")
                .font(AviaryFont.display(18, weight: .bold))
                .tracking(-0.02 * 18)
                .foregroundStyle(t.ink)
            Spacer()
            Text("See all →")
                .font(AviaryFont.body(12, weight: .semibold))
                .foregroundStyle(t.accent)
        }
    }

    private var upNextCard: some View {
        Button {
            onOpenGigDetail()
        } label: {
            AviaryCard(padding: 14, shadowed: true) {
                HStack(spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(LinearGradient(
                                colors: [t.accentSoft, t.surface2],
                                startPoint: .topLeading, endPoint: .bottomTrailing))
                        AviaryIcon(name: "camera", size: 24, stroke: 2, color: t.accent)
                    }
                    .frame(width: 56, height: 56)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous).strokeBorder(t.line)
                    )
                    VStack(alignment: .leading, spacing: 2) {
                        Text("IN 1 HR 12 MIN")
                            .font(AviaryFont.body(11, weight: .semibold))
                            .tracking(0.04 * 11)
                            .foregroundStyle(t.ink3)
                        Text("Real estate · 1247 Vine St")
                            .font(AviaryFont.body(15, weight: .semibold))
                            .foregroundStyle(t.ink)
                            .lineLimit(1)
                        Text("Marin Realty Co · 1.2 mi · ~45 min")
                            .font(AviaryFont.body(12))
                            .foregroundStyle(t.ink3)
                            .lineLimit(1)
                    }
                    Spacer(minLength: 0)
                    Text("$340")
                        .font(AviaryFont.mono(18, weight: .semibold))
                        .foregroundStyle(t.accent)
                }
            }
        }
        .buttonStyle(PressableButtonStyle())
    }

    private var editorialBanner: some View {
        HStack(spacing: 10) {
            AviaryIcon(name: "gift", size: 18, color: t.accent)
            (Text("Vineyard run, Wed 8am. ").bold()
             + Text("$1,250 mapping gig — pilots in your area only."))
                .font(AviaryFont.body(13))
                .foregroundStyle(t.ink2)
                .lineSpacing(2)
            Spacer(minLength: 0)
            AviaryIcon(name: "chevron-right", size: 16, color: t.ink3)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous).fill(t.surface2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous).strokeBorder(t.line)
        )
    }
}
