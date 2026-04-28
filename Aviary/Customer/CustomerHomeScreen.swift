import SwiftUI

struct CustomerHomeScreen: View {
    @Environment(\.theme) private var t
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
                    emptyActivity
                        .padding(.horizontal, 16)
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
            Avatar(size: 32, initials: profile.initials, background: t.accentSoft)
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
            stat(label: "Active jobs", value: "0")
            stat(label: "Total spend", value: "$0")
            stat(label: "Pilots used", value: "0")
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
}
