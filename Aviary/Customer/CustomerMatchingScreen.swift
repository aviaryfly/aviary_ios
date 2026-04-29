import SwiftUI

/// Full-screen "finding your pilot" matching state — the Uber-style beat between
/// posting a job and seeing it appear in My Jobs. Plays automatically while the
/// `customerMatching` showcase step is active.
struct CustomerMatchingScreen: View {
    @Environment(\.theme) private var t

    @State private var stage: Stage = .searching
    @State private var pulse1: CGFloat = 0
    @State private var pulse2: CGFloat = 0
    @State private var pulse3: CGFloat = 0

    private enum Stage { case searching, found }

    var body: some View {
        ZStack {
            t.bg.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                ZStack {
                    Group {
                        radarRing(scale: pulse1, opacity: 0.45)
                        radarRing(scale: pulse2, opacity: 0.30)
                        radarRing(scale: pulse3, opacity: 0.18)
                    }
                    .opacity(stage == .searching ? 1 : 0)

                    avatarPuck
                }
                .frame(width: 220, height: 220)
                .padding(.bottom, 40)

                if stage == .searching {
                    searchingCard
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                } else {
                    foundCard
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                }

                Spacer()
            }
            .padding(.horizontal, 28)
        }
        .onAppear { start() }
    }

    // MARK: Sub-views

    private func radarRing(scale: CGFloat, opacity: Double) -> some View {
        Circle()
            .stroke(t.accent, lineWidth: 1.6)
            .frame(width: 220, height: 220)
            .scaleEffect(scale)
            .opacity(opacity * (1 - Double(min(scale, 1.4) / 1.4)))
    }

    private var avatarPuck: some View {
        ZStack {
            Circle()
                .fill(t.accentSoft)
                .frame(width: 96, height: 96)
            Circle()
                .strokeBorder(t.accent.opacity(stage == .found ? 1 : 0.55), lineWidth: 2)
                .frame(width: 96, height: 96)
            if stage == .found {
                Avatar(size: 80, initials: "CP", background: t.surface)
                    .transition(.scale.combined(with: .opacity))
            } else {
                AviaryIcon(name: "drone", size: 38, color: t.accent)
                    .transition(.opacity)
            }
        }
    }

    private var searchingCard: some View {
        VStack(spacing: 10) {
            Text("Finding your pilot")
                .font(AviaryFont.display(26, weight: .bold))
                .tracking(-0.02 * 26)
                .foregroundStyle(t.ink)
            Text("Pinging Part-107 pilots near 1247 Vine St…")
                .font(AviaryFont.body(14))
                .foregroundStyle(t.ink3)
                .multilineTextAlignment(.center)
            HStack(spacing: 10) {
                stat(label: "Avg accept", value: "2 min")
                stat(label: "Pilots near", value: "9")
                stat(label: "Posted", value: "just now")
            }
            .padding(.top, 14)
        }
    }

    private var foundCard: some View {
        VStack(spacing: 14) {
            Chip(text: "PILOT ACCEPTED", style: .good)
            Text("Casey Park is on the way.")
                .font(AviaryFont.display(24, weight: .bold))
                .tracking(-0.02 * 24)
                .foregroundStyle(t.ink)
                .multilineTextAlignment(.center)

            HStack(spacing: 10) {
                stat(label: "Rating", value: "★ 4.94")
                stat(label: "Drone", value: "DJI Mavic 3")
                stat(label: "ETA", value: "22 min")
            }
        }
    }

    private func stat(label: String, value: String) -> some View {
        VStack(spacing: 2) {
            Text(label)
                .font(AviaryFont.body(11))
                .foregroundStyle(t.ink3)
            Text(value)
                .font(AviaryFont.mono(14, weight: .semibold))
                .foregroundStyle(t.ink)
        }
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity)
        .background(RoundedRectangle(cornerRadius: 12).fill(t.surface2))
    }

    // MARK: Animation engine

    private func start() {
        animateRing($pulse1, delay: 0)
        animateRing($pulse2, delay: 0.55)
        animateRing($pulse3, delay: 1.10)
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 3_400_000_000)
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                stage = .found
            }
        }
    }

    private func animateRing(_ binding: Binding<CGFloat>, delay: Double) {
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            binding.wrappedValue = 0.4
            withAnimation(.easeOut(duration: 1.65).repeatForever(autoreverses: false)) {
                binding.wrappedValue = 1.5
            }
        }
    }
}
