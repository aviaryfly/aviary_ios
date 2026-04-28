import SwiftUI

// MARK: - Logo

struct AviaryLogo: View {
    var size: CGFloat = 28
    var color: Color

    var body: some View {
        Path { p in
            let s = size / 32
            p.move(to: CGPoint(x: 16 * s, y: 4 * s))
            p.addLine(to: CGPoint(x: 28 * s, y: 26 * s))
            p.addLine(to: CGPoint(x: 20 * s, y: 22 * s))
            p.addLine(to: CGPoint(x: 16 * s, y: 28 * s))
            p.addLine(to: CGPoint(x: 12 * s, y: 22 * s))
            p.addLine(to: CGPoint(x: 4 * s, y: 26 * s))
            p.closeSubpath()
        }
        .fill(color)
        .frame(width: size, height: size)
    }
}

// MARK: - Avatar

struct Avatar: View {
    var size: CGFloat = 36
    var initials: String = "JD"
    var background: Color
    @Environment(\.theme) private var t

    var body: some View {
        ZStack {
            Circle().fill(background)
            Text(initials)
                .font(AviaryFont.body(size * 0.36, weight: .semibold))
                .foregroundStyle(t.ink2)
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Mode switch (Pilot ↔ Client)

struct ModeSwitch: View {
    enum Mode: String { case pilot = "Pilot", client = "Client" }
    @Binding var mode: Mode
    @Environment(\.theme) private var t

    var body: some View {
        HStack(spacing: 0) {
            pill(for: .pilot)
            pill(for: .client)
        }
        .padding(3)
        .background(
            Capsule().fill(t.surface2)
        )
    }

    @ViewBuilder
    private func pill(for m: Mode) -> some View {
        let active = m == mode
        Button {
            withAnimation(.spring(response: 0.25, dampingFraction: 0.85)) { mode = m }
        } label: {
            Text(m.rawValue)
                .font(AviaryFont.body(12, weight: .semibold))
                .foregroundStyle(active ? t.ink : t.ink3)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(active ? t.surface : .clear)
                        .shadow(color: active ? .black.opacity(0.05) : .clear, radius: 2, y: 1)
                )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Chip

struct Chip: View {
    var text: String
    var icon: String? = nil
    var systemIcon: String? = nil
    var style: Style = .neutral
    @Environment(\.theme) private var t

    enum Style { case neutral, accent, good, warn, dark, surface }

    var body: some View {
        HStack(spacing: 4) {
            if let s = systemIcon {
                Image(systemName: s).font(.system(size: 11, weight: .semibold))
            } else if let i = icon {
                AviaryIcon(name: i, size: 12, color: fg)
            }
            Text(text)
                .font(AviaryFont.body(12, weight: .medium))
        }
        .foregroundStyle(fg)
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(Capsule().fill(bg))
    }

    private var bg: Color {
        switch style {
        case .neutral: return t.surface2
        case .accent:  return t.accentSoft
        case .good:    return t.good.opacity(0.14)
        case .warn:    return t.warn.opacity(0.14)
        case .dark:    return t.ink
        case .surface: return t.surface
        }
    }
    private var fg: Color {
        switch style {
        case .neutral: return t.ink2
        case .accent:  return t.accent
        case .good:    return t.good
        case .warn:    return t.warn
        case .dark:    return t.bg
        case .surface: return t.ink2
        }
    }
}

// MARK: - Card

struct AviaryCard<Content: View>: View {
    var padding: CGFloat = 16
    var radius: CGFloat = Radius.md
    var shadowed: Bool = false
    @Environment(\.theme) private var t
    @ViewBuilder var content: () -> Content

    var body: some View {
        content()
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .fill(t.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .strokeBorder(t.line, lineWidth: 1)
            )
            .shadow(color: shadowed ? Color.black.opacity(0.06) : .clear, radius: 16, y: 4)
    }
}

// MARK: - Buttons

struct PrimaryButton: View {
    var title: String
    var systemTrailing: String? = nil
    var fullWidth: Bool = true
    var enabled: Bool = true
    var action: () -> Void = {}
    @Environment(\.theme) private var t

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Text(title)
                    .font(AviaryFont.body(17, weight: .semibold))
                if let s = systemTrailing {
                    Image(systemName: s).font(.system(size: 16, weight: .semibold))
                }
            }
            .foregroundStyle(t.accentInk)
            .padding(.vertical, 18)
            .padding(.horizontal, 20)
            .frame(maxWidth: fullWidth ? .infinity : nil)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(t.accent)
            )
            .opacity(enabled ? 1 : 0.55)
        }
        .buttonStyle(PressableButtonStyle())
        .disabled(!enabled)
    }
}

struct SecondaryButton: View {
    var title: String
    var systemTrailing: String? = nil
    var fullWidth: Bool = false
    var action: () -> Void = {}
    @Environment(\.theme) private var t

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Text(title)
                    .font(AviaryFont.body(17, weight: .semibold))
                if let s = systemTrailing {
                    Image(systemName: s).font(.system(size: 16, weight: .semibold))
                }
            }
            .foregroundStyle(t.ink)
            .padding(.vertical, 18)
            .padding(.horizontal, 20)
            .frame(maxWidth: fullWidth ? .infinity : nil)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(t.surface2)
            )
        }
        .buttonStyle(PressableButtonStyle())
    }
}

struct PressableButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.spring(response: 0.2, dampingFraction: 0.85), value: configuration.isPressed)
    }
}

// MARK: - Section title (small caps)

struct SectionTitle: View {
    var text: String
    @Environment(\.theme) private var t
    var body: some View {
        Text(text.uppercased())
            .font(AviaryFont.body(13, weight: .semibold))
            .tracking(0.04 * 13)
            .foregroundStyle(t.ink3)
    }
}

// MARK: - Custom tab bar

struct AviaryTabBar: View {
    @Binding var selection: AppTab
    @Environment(\.theme) private var t

    var body: some View {
        HStack {
            ForEach(AppTab.allCases) { tab in
                Button {
                    selection = tab
                } label: {
                    VStack(spacing: 3) {
                        AviaryIcon(name: tab.icon, size: 24, stroke: selection == tab ? 2.2 : 1.7,
                                   color: selection == tab ? t.accent : t.ink4)
                        Text(tab.title)
                            .font(AviaryFont.body(10, weight: .medium))
                            .foregroundStyle(selection == tab ? t.accent : t.ink4)
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.top, 8)
        .padding(.bottom, 6)
        .background(
            t.surface.opacity(0.92)
                .background(.ultraThinMaterial)
                .overlay(Rectangle().fill(t.line).frame(height: 1), alignment: .top)
                .ignoresSafeArea(edges: .bottom)
        )
    }
}

enum AppTab: String, CaseIterable, Identifiable {
    case home, gigs, fly, earn, me
    var id: String { rawValue }
    var title: String {
        switch self {
        case .home: return "Home"
        case .gigs: return "Gigs"
        case .fly:  return "Fly"
        case .earn: return "Earnings"
        case .me:   return "Profile"
        }
    }
    var icon: String {
        switch self {
        case .home: return "home"
        case .gigs: return "compass"
        case .fly:  return "drone"
        case .earn: return "wallet"
        case .me:   return "user"
        }
    }
}

// MARK: - Page header

struct PageHeader<Trailing: View>: View {
    var title: String
    var subtitle: String? = nil
    @ViewBuilder var trailing: () -> Trailing
    @Environment(\.theme) private var t

    var body: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(AviaryFont.display(32, weight: .bold))
                    .tracking(-0.025 * 32)
                    .foregroundStyle(t.ink)
                if let s = subtitle {
                    Text(s)
                        .font(AviaryFont.body(13))
                        .foregroundStyle(t.ink3)
                }
            }
            Spacer()
            trailing()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 8)
    }
}

extension PageHeader where Trailing == EmptyView {
    init(title: String, subtitle: String? = nil) {
        self.init(title: title, subtitle: subtitle, trailing: { EmptyView() })
    }
}
