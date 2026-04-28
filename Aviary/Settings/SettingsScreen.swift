import SwiftUI

struct SettingsScreen: View {
    @Environment(\.theme) private var t
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var demoStore: DemoModeStore

    var body: some View {
        ZStack {
            t.bg.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    header
                    SectionTitle(text: "Developer")
                        .padding(.horizontal, 20)
                        .padding(.top, 8)
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
}
