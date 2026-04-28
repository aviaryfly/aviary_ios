import SwiftUI

struct HeroFlowView: View {
    @Environment(\.theme) private var t
    @Environment(\.dismiss) private var dismiss

    enum Stage { case ping, accepting, confirmed, enRoute, expired }
    @State private var stage: Stage = .ping
    @State private var seconds: Int = 15
    @State private var timer: Timer?

    var body: some View {
        ZStack {
            MapBackground(
                pins: [.init(x: 195, y: 220, label: "$340", pulse: stage == .ping)],
                routes: stage != .ping ? [
                    MapRoute(path: routePath, dashed: true)
                ] : [],
                showPilot: true,
                pilotPos: .init(x: 195, y: 480)
            )
            .ignoresSafeArea()

            if stage == .ping {
                GeometryReader { geo in
                    pulseRing
                        .position(x: geo.size.width / 2,
                                  y: geo.size.height * 0.30)
                }
                .allowsHitTesting(false)
            }

            VStack {
                topBar
                Spacer()
                bottomCard
            }
        }
        .onAppear { startTimer() }
        .onDisappear { timer?.invalidate() }
    }

    private var routePath: Path {
        var p = Path()
        p.move(to: .init(x: 195, y: 480))
        p.addQuadCurve(to: .init(x: 195, y: 240), control: .init(x: 220, y: 360))
        return p
    }

    private var topBar: some View {
        HStack {
            Button { dismiss() } label: {
                ZStack {
                    Circle().fill(t.surface)
                    AviaryIcon(name: "x", size: 18, color: t.ink)
                }
                .frame(width: 40, height: 40)
                .overlay(Circle().strokeBorder(t.line))
                .shadow(color: .black.opacity(0.08), radius: 10, y: 3)
            }
            .buttonStyle(PressableButtonStyle())
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }

    @ViewBuilder
    private var bottomCard: some View {
        switch stage {
        case .ping: pingCard
        case .accepting: acceptingCard
        case .confirmed: confirmedCard
        case .enRoute: enRouteCard
        case .expired: expiredCard
        }
    }

    private var pingCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Chip(text: "NEW PING", style: .accent)
                Spacer()
                Text("0:\(String(format: "%02d", seconds))")
                    .font(AviaryFont.mono(12, weight: .semibold))
                    .foregroundStyle(t.ink3)
            }

            HStack(alignment: .firstTextBaseline) {
                Text("Real estate · 1.2 mi")
                    .font(AviaryFont.display(26, weight: .bold))
                    .tracking(-0.02 * 26)
                    .foregroundStyle(t.ink)
                Spacer()
                Text("$340")
                    .font(AviaryFont.mono(32, weight: .semibold))
                    .foregroundStyle(t.accent)
            }
            .padding(.top, 8)

            Text("1247 Vine St · ~45 min · starts 3:30 PM")
                .font(AviaryFont.body(14))
                .foregroundStyle(t.ink3)
                .padding(.top, 4)

            HStack(spacing: 8) {
                Chip(text: "Clear, 9 mph", icon: "cloud")
                Chip(text: "Class G", icon: "check")
                Chip(text: "★ 4.9 client", style: .good)
            }
            .padding(.top, 14)

            ZStack(alignment: .leading) {
                Capsule().fill(t.surface2).frame(height: 4)
                GeometryReader { geo in
                    Capsule().fill(t.accent)
                        .frame(width: geo.size.width * CGFloat(seconds) / 15.0, height: 4)
                }
                .frame(height: 4)
            }
            .padding(.top, 18)

            HStack(spacing: 12) {
                SecondaryButton(title: "Pass") { dismiss() }
                    .frame(maxWidth: 130)
                PrimaryButton(title: "Accept · \(seconds)s", action: accept)
            }
            .padding(.top, 16)
        }
        .padding(.horizontal, 22)
        .padding(.top, 20)
        .padding(.bottom, 28)
        .background(sheetBg)
    }

    private var acceptingCard: some View {
        VStack(spacing: 16) {
            ProgressView()
                .controlSize(.large)
                .tint(t.accent)
            Text("Confirming with Marin Realty…")
                .font(AviaryFont.body(15, weight: .semibold))
                .foregroundStyle(t.ink)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
        .padding(.horizontal, 22)
        .background(sheetBg)
    }

    private var confirmedCard: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle().fill(t.good.opacity(0.18))
                    .frame(width: 72, height: 72)
                Circle().fill(t.good).frame(width: 56, height: 56)
                AviaryIcon(name: "check", size: 30, stroke: 3, color: .white)
            }
            Text("Locked in.")
                .font(AviaryFont.display(28, weight: .bold))
                .tracking(-0.025 * 28)
                .foregroundStyle(t.ink)
            Text("$340 · 1247 Vine St · 22 min ETA")
                .font(AviaryFont.body(14))
                .foregroundStyle(t.ink3)
            PrimaryButton(title: "Start drive", systemTrailing: "arrow.right") {
                stage = .enRoute
            }
            .padding(.top, 6)
        }
        .padding(.horizontal, 22)
        .padding(.top, 24)
        .padding(.bottom, 28)
        .background(sheetBg)
    }

    private var enRouteCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Chip(text: "EN ROUTE", style: .good)
            Text("22 min to site")
                .font(AviaryFont.display(24, weight: .bold))
                .tracking(-0.02 * 24)
                .foregroundStyle(t.ink)
            Text("1247 Vine St · pre-flight checklist ready")
                .font(AviaryFont.body(13))
                .foregroundStyle(t.ink3)
            PrimaryButton(title: "Pre-flight", systemTrailing: "arrow.right") {
                dismiss()
            }
            .padding(.top, 10)
        }
        .padding(.horizontal, 22)
        .padding(.top, 22)
        .padding(.bottom, 28)
        .background(sheetBg)
    }

    private var expiredCard: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle().fill(t.ink3.opacity(0.18))
                    .frame(width: 72, height: 72)
                AviaryIcon(name: "clock", size: 30, stroke: 2.5, color: t.ink3)
            }
            Text("Ping expired")
                .font(AviaryFont.display(26, weight: .bold))
                .tracking(-0.025 * 26)
                .foregroundStyle(t.ink)
            Text("Another pilot accepted this gig.")
                .font(AviaryFont.body(14))
                .foregroundStyle(t.ink3)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
        .padding(.horizontal, 22)
        .background(sheetBg)
    }

    private var pulseRing: some View {
        ZStack {
            Circle()
                .strokeBorder(t.accent, lineWidth: 2)
                .frame(width: 120, height: 120)
                .scaleEffect(scale)
                .opacity(opacity)
                .onAppear { animatePulse() }
        }
    }
    @State private var scale: CGFloat = 0.4
    @State private var opacity: Double = 0.9

    private func animatePulse() {
        withAnimation(.easeOut(duration: 2.2).repeatForever(autoreverses: false)) {
            scale = 2.6
            opacity = 0
        }
    }

    private var sheetBg: some View {
        UnevenRoundedRectangle(
            topLeadingRadius: 28, bottomLeadingRadius: 0,
            bottomTrailingRadius: 0, topTrailingRadius: 28,
            style: .continuous
        )
        .fill(t.surface)
        .ignoresSafeArea(edges: .bottom)
        .shadow(color: .black.opacity(0.10), radius: 32, y: -8)
    }

    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            Task { @MainActor in
                if seconds > 0 {
                    seconds -= 1
                } else {
                    timer?.invalidate()
                    if stage == .ping {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            stage = .expired
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
                            if stage == .expired { dismiss() }
                        }
                    }
                }
            }
        }
    }

    private func accept() {
        timer?.invalidate()
        stage = .accepting
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            stage = .confirmed
        }
    }
}
