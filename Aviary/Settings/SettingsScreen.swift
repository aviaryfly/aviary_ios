import SwiftUI

struct SettingsScreen: View {
    @Environment(\.theme) private var t
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var demoStore: DemoModeStore
    @ObservedObject var themeManager: ThemeManager
    let profile: UserProfile

    var body: some View {
        ZStack {
            t.bg.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    header

                    SectionTitle(text: "Account")
                        .padding(.horizontal, 20)
                        .padding(.bottom, 8)
                    AviaryCard(padding: 0) {
                        VStack(spacing: 0) {
                            settingsRow(icon: "user", label: "Email",
                                        value: profile.email, divider: true)
                            settingsRow(icon: "compass", label: "Role",
                                        value: profile.role.displayName, divider: false)
                        }
                    }
                    .padding(.horizontal, 16)
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
                    .padding(.bottom, 20)

                    SectionTitle(text: "Developer")
                        .padding(.horizontal, 20)
                        .padding(.bottom, 8)

                    AviaryCard(padding: 0) {
                        VStack(spacing: 0) {
                            demoToggleRow
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 12)

                    Text("When demo mode is on, the app shows a canonical demo profile for your role. Your real account is untouched.")
                        .font(AviaryFont.body(12))
                        .foregroundStyle(t.ink3)
                        .lineSpacing(2)
                        .padding(.horizontal, 22)
                        .padding(.bottom, 24)
                }
            }
        }
    }

    private var header: some View {
        HStack(spacing: 12) {
            Button { dismiss() } label: {
                AviaryIcon(name: "arrow-left", size: 22, color: t.ink)
            }
            Text("Settings")
                .font(AviaryFont.body(16, weight: .semibold))
                .foregroundStyle(t.ink)
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
        .padding(.bottom, 14)
    }

    private var demoToggleRow: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10).fill(t.accentSoft)
                AviaryIcon(name: "sliders", size: 18, color: t.accent)
            }
            .frame(width: 34, height: 34)
            VStack(alignment: .leading, spacing: 1) {
                Text("Demo mode")
                    .font(AviaryFont.body(14, weight: .medium))
                    .foregroundStyle(t.ink)
                Text(demoStore.isOn ? "On — showing demo profile" : "Off — showing your account")
                    .font(AviaryFont.body(12))
                    .foregroundStyle(t.ink3)
            }
            Spacer()
            Toggle("", isOn: $demoStore.isOn)
                .labelsHidden()
                .tint(t.accent)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private func settingsRow(icon: String, label: String, value: String, divider: Bool) -> some View {
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
                    .foregroundStyle(t.ink3)
            }
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .overlay(
            divider ? Rectangle().fill(t.line).frame(height: 1) : nil,
            alignment: .bottom
        )
    }
}
