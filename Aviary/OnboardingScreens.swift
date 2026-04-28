import SwiftUI

struct OnboardingFlow: View {
    @EnvironmentObject private var auth: AuthViewModel
    @State private var step: Step = .welcome
    @State private var role: UserRole = .pilot
    @State private var authMode: AuthScreen.Mode = .signUp
    @Environment(\.theme) private var t

    enum Step { case welcome, roleSelect, cert, auth }

    var body: some View {
        ZStack {
            switch step {
            case .welcome:
                WelcomeHero(
                    onContinue: { step = .roleSelect },
                    onSignIn: {
                        authMode = .signIn
                        step = .auth
                    }
                )
            case .roleSelect:
                RoleSelect(
                    onBack: { step = .welcome },
                    onContinue: { selected in
                        role = selected
                        authMode = .signUp
                        step = (selected == .pilot) ? .cert : .auth
                    }
                )
            case .cert:
                CertCheck(
                    onBack: { step = .roleSelect },
                    onContinue: {
                        authMode = .signUp
                        step = .auth
                    }
                )
            case .auth:
                AuthScreen(
                    role: role,
                    initialMode: authMode,
                    onBack: {
                        auth.errorMessage = nil
                        switch authMode {
                        case .signIn:
                            step = .welcome
                        case .signUp:
                            step = (role == .pilot) ? .cert : .roleSelect
                        }
                    }
                )
                .id(authMode)
            }
        }
        .animation(.easeInOut(duration: 0.25), value: step)
    }
}

private struct WelcomeHero: View {
    var onContinue: () -> Void
    var onSignIn: () -> Void
    @Environment(\.theme) private var t

    var body: some View {
        ZStack {
            t.bg.ignoresSafeArea()

            VStack(spacing: 0) {
                topBar
                editorialHero
                Spacer(minLength: 0)
                horizonIllustration
                cta
            }
        }
    }

    private var topBar: some View {
        HStack(spacing: 10) {
            AviaryLogo(size: 26, color: t.accent)
            Text("aviary")
                .font(AviaryFont.body(19, weight: .bold))
                .tracking(-0.02 * 19)
                .foregroundStyle(t.ink)
            Spacer()
            Button(action: onSignIn) {
                Text("Sign in")
                    .font(AviaryFont.body(13, weight: .medium))
                    .foregroundStyle(t.ink3)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 28)
        .padding(.top, 16)
    }

    private var editorialHero: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("── EST. 2024 · BERKELEY, CA")
                .font(AviaryFont.body(12, weight: .semibold))
                .tracking(0.12 * 12)
                .foregroundStyle(t.accent)
                .padding(.bottom, 14)

            (Text("Drone work,\n").foregroundStyle(t.ink)
             + Text("on demand.").italic().foregroundStyle(t.accent).fontWeight(.medium))
                .font(AviaryFont.display(56, weight: .bold))
                .tracking(-0.04 * 56)
                .lineSpacing(-12)

            Text("The workforce platform for Part 107 pilots. Get paid to fly, or hire one in minutes.")
                .font(AviaryFont.body(16))
                .lineSpacing(4)
                .foregroundStyle(t.ink2)
                .padding(.top, 20)
                .frame(maxWidth: 300, alignment: .leading)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 28)
        .padding(.top, 40)
    }

    private var horizonIllustration: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h: CGFloat = 240
            ZStack {
                LinearGradient(colors: [t.bg, t.surface2, t.mapBg],
                               startPoint: .top, endPoint: .bottom)

                Canvas { ctx, size in
                    var ridge1 = Path()
                    ridge1.move(to: .init(x: 0, y: 200/280 * size.height))
                    let pts1: [CGPoint] = [
                        .init(x: 60, y: 170), .init(x: 120, y: 185), .init(x: 180, y: 150),
                        .init(x: 240, y: 175), .init(x: 300, y: 145), .init(x: 360, y: 170),
                        .init(x: 390, y: 160)
                    ]
                    for p in pts1 {
                        ridge1.addLine(to: .init(x: p.x/390 * size.width,
                                                  y: p.y/280 * size.height))
                    }
                    ridge1.addLine(to: .init(x: size.width, y: size.height))
                    ridge1.addLine(to: .init(x: 0, y: size.height))
                    ridge1.closeSubpath()
                    ctx.fill(ridge1, with: .color(t.ink.opacity(0.08)))

                    var ridge2 = Path()
                    ridge2.move(to: .init(x: 0, y: 220/280 * size.height))
                    let pts2: [CGPoint] = [
                        .init(x: 80, y: 200), .init(x: 160, y: 215),
                        .init(x: 240, y: 195), .init(x: 320, y: 215), .init(x: 390, y: 200)
                    ]
                    for p in pts2 {
                        ridge2.addLine(to: .init(x: p.x/390 * size.width,
                                                  y: p.y/280 * size.height))
                    }
                    ridge2.addLine(to: .init(x: size.width, y: size.height))
                    ridge2.addLine(to: .init(x: 0, y: size.height))
                    ridge2.closeSubpath()
                    ctx.fill(ridge2, with: .color(t.ink.opacity(0.10)))
                }

                Circle()
                    .fill(t.accent.opacity(0.18))
                    .frame(width: 80, height: 80)
                    .position(x: 300/390 * w, y: 110/280 * h)
                Circle()
                    .fill(t.accent.opacity(0.4))
                    .frame(width: 44, height: 44)
                    .position(x: 300/390 * w, y: 110/280 * h)

                Canvas { ctx, size in
                    var path = Path()
                    path.move(to: .init(x: 30/390 * size.width, y: 240/280 * size.height))
                    path.addQuadCurve(
                        to: .init(x: 240/390 * size.width, y: 100/280 * size.height),
                        control: .init(x: 130/390 * size.width, y: 80/280 * size.height)
                    )
                    path.addQuadCurve(
                        to: .init(x: 380/390 * size.width, y: 60/280 * size.height),
                        control: .init(x: 320/390 * size.width, y: 80/280 * size.height)
                    )
                    ctx.stroke(path, with: .color(t.accent),
                               style: StrokeStyle(lineWidth: 2, lineCap: .round, dash: [2, 6]))
                }

                droneGlyph
                    .position(x: 380/390 * w, y: 60/280 * h)

                statTag
                    .position(x: 200/390 * w, y: 80/280 * h)
            }
        }
        .frame(height: 240)
    }

    private var droneGlyph: some View {
        ZStack {
            ForEach(0..<4) { i in
                let x: CGFloat = i % 2 == 0 ? -6 : 6
                let y: CGFloat = i < 2 ? -6 : 6
                Circle().fill(t.ink).frame(width: 6, height: 6).offset(x: x, y: y)
            }
            Path { p in
                p.move(to: .init(x: -4, y: -4)); p.addLine(to: .init(x: 4, y: 4))
                p.move(to: .init(x: 4, y: -4)); p.addLine(to: .init(x: -4, y: 4))
            }
            .stroke(t.ink, lineWidth: 1.5)
            RoundedRectangle(cornerRadius: 1).fill(t.accent)
                .frame(width: 6, height: 4)
        }
        .frame(width: 24, height: 24)
    }

    private var statTag: some View {
        VStack(alignment: .leading, spacing: 1) {
            Text("6,400+ PILOTS")
                .font(AviaryFont.mono(9, weight: .regular))
                .tracking(0.5)
                .foregroundStyle(t.ink3)
            Text("Active this month")
                .font(AviaryFont.body(13, weight: .semibold))
                .foregroundStyle(t.ink)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous).fill(t.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous).strokeBorder(t.lineStrong)
        )
    }

    private var cta: some View {
        VStack(spacing: 14) {
            PrimaryButton(title: "Get started", systemTrailing: "arrow.right", action: onContinue)

            HStack(spacing: 0) {
                statCol(value: "$2M", caption: "Cover incl.")
                Rectangle().fill(t.line).frame(width: 1, height: 32)
                statCol(value: "2 min", caption: "Avg accept")
                Rectangle().fill(t.line).frame(width: 1, height: 32)
                statCol(value: "FAA", caption: "Auto-verified")
            }
        }
        .padding(.horizontal, 28)
        .padding(.top, 20)
        .padding(.bottom, 36)
        .background(
            t.surface
                .overlay(Rectangle().fill(t.line).frame(height: 1), alignment: .top)
                .ignoresSafeArea(edges: .bottom)
        )
    }

    private func statCol(value: String, caption: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(AviaryFont.mono(15, weight: .semibold))
                .foregroundStyle(t.ink)
            Text(caption)
                .font(AviaryFont.body(11))
                .foregroundStyle(t.ink3)
        }
        .frame(maxWidth: .infinity)
    }
}

private struct RoleSelect: View {
    var onBack: () -> Void
    var onContinue: (UserRole) -> Void
    @Environment(\.theme) private var t
    @State private var choice: UserRole = .pilot

    var body: some View {
        ZStack {
            t.bg.ignoresSafeArea()
            VStack(alignment: .leading, spacing: 0) {
                Button(action: onBack) {
                    AviaryIcon(name: "arrow-left", size: 24, color: t.ink)
                }
                .padding(.top, 8)
                .padding(.bottom, 32)

                Text("CHOOSE YOUR ROLE")
                    .font(AviaryFont.body(13, weight: .semibold))
                    .tracking(0.04 * 13)
                    .foregroundStyle(t.accent)
                    .padding(.bottom, 8)

                Text("How will you use Aviary?")
                    .font(AviaryFont.display(30, weight: .bold))
                    .tracking(-0.025 * 30)
                    .foregroundStyle(t.ink)
                    .padding(.bottom, 8)

                Text("You'll keep this role on your account.")
                    .font(AviaryFont.body(15))
                    .foregroundStyle(t.ink3)
                    .padding(.bottom, 28)

                VStack(spacing: 14) {
                    roleCard(title: "I'm a Pilot",
                             sub: "Find paid drone gigs in your area. Set your own schedule.",
                             icon: "drone", recommended: true, role: .pilot)
                    roleCard(title: "I need a flight",
                             sub: "Post a job in 60 seconds. A vetted pilot accepts.",
                             icon: "briefcase", role: .customer)
                }

                Spacer(minLength: 0)

                PrimaryButton(title: "Continue",
                              systemTrailing: "arrow.right",
                              action: { onContinue(choice) })
                    .padding(.top, 24)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 28)
        }
    }

    private func roleCard(title: String, sub: String, icon: String,
                          recommended: Bool = false, role: UserRole) -> some View {
        Button { choice = role } label: {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 0) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12).fill(t.accentSoft)
                        AviaryIcon(name: icon, size: 24, stroke: 2, color: t.accent)
                    }
                    .frame(width: 44, height: 44)
                    .padding(.bottom, 14)

                    Text(title)
                        .font(AviaryFont.body(18, weight: .semibold))
                        .foregroundStyle(t.ink)
                        .padding(.bottom, 4)
                    Text(sub)
                        .font(AviaryFont.body(14))
                        .foregroundStyle(t.ink3)
                        .lineSpacing(2)
                        .multilineTextAlignment(.leading)
                }
                Spacer(minLength: 0)
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: Radius.md, style: .continuous).fill(t.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Radius.md, style: .continuous)
                    .strokeBorder(choice == role ? t.accent : t.line,
                                  lineWidth: choice == role ? 2 : 1)
            )
            .overlay(alignment: .topTrailing) {
                if recommended {
                    Text("POPULAR")
                        .font(AviaryFont.body(10, weight: .bold))
                        .tracking(0.06 * 10)
                        .foregroundStyle(t.accentInk)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Capsule().fill(t.accent))
                        .offset(x: -16, y: -10)
                }
            }
        }
        .buttonStyle(PressableButtonStyle())
    }
}

private struct CertCheck: View {
    var onBack: () -> Void
    var onContinue: () -> Void
    @Environment(\.theme) private var t
    @State private var faaStatus: FieldStatus = .pending
    @State private var droneStatus: FieldStatus = .pending

    var body: some View {
        ZStack {
            t.bg.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    Button(action: onBack) {
                        AviaryIcon(name: "arrow-left", size: 24, color: t.ink)
                    }
                    .padding(.top, 8)
                    .padding(.bottom, 24)

                    Text("STEP 1 OF 2 · CERTIFICATIONS")
                        .font(AviaryFont.body(13, weight: .semibold))
                        .tracking(0.04 * 13)
                        .foregroundStyle(t.accent)
                        .padding(.bottom, 8)

                    Text("Verify your Part 107")
                        .font(AviaryFont.display(30, weight: .bold))
                        .tracking(-0.025 * 30)
                        .foregroundStyle(t.ink)
                        .padding(.bottom, 8)

                    Text("We auto-check your FAA cert. Most pilots are verified in under 2 minutes.")
                        .font(AviaryFont.body(15))
                        .foregroundStyle(t.ink3)
                        .lineSpacing(3)
                        .padding(.bottom, 24)

                    field(label: "FAA REMOTE PILOT CERTIFICATE",
                          value: "4081294-A",
                          status: faaStatus,
                          hint: "Issued Mar 2024 · Expires Mar 2026")
                    field(label: "DRONE REGISTRATION",
                          value: "FA39SXKLP4",
                          status: droneStatus, hint: nil)
                    field(label: "LIABILITY INSURANCE",
                          value: "$1M · SkyWatch",
                          status: .pending,
                          hint: "Optional but recommended for premium gigs")

                    HStack(alignment: .top, spacing: 10) {
                        AviaryIcon(name: "shield", size: 20, stroke: 2, color: t.accent)
                        (Text("Aviary Cover ").bold().foregroundColor(t.ink)
                         + Text("includes $2M operator liability on every accepted gig — no extra cost."))
                            .font(AviaryFont.body(13))
                            .foregroundStyle(t.ink2)
                            .lineSpacing(3)
                    }
                    .padding(14)
                    .background(
                        RoundedRectangle(cornerRadius: 14).fill(t.accentSoft)
                    )
                    .padding(.top, 8)

                    PrimaryButton(title: "Continue", action: onContinue)
                        .padding(.top, 20)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 28)
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                withAnimation(.easeInOut(duration: 0.3)) { faaStatus = .verified }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                withAnimation(.easeInOut(duration: 0.3)) { droneStatus = .verified }
            }
        }
    }

    enum FieldStatus { case verified, pending }
    @ViewBuilder
    private func field(label: String, value: String, status: FieldStatus, hint: String?) -> some View {
        AviaryCard(padding: 16) {
            VStack(alignment: .leading, spacing: 6) {
                Text(label)
                    .font(AviaryFont.body(12, weight: .medium))
                    .foregroundStyle(t.ink3)
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(value)
                            .font(AviaryFont.mono(17, weight: .medium))
                            .foregroundStyle(t.ink)
                        if let h = hint {
                            Text(h)
                                .font(AviaryFont.body(12))
                                .foregroundStyle(t.ink4)
                        }
                    }
                    Spacer()
                    switch status {
                    case .verified:
                        Chip(text: "Verified", icon: "check", style: .good)
                    case .pending:
                        Chip(text: "Checking", icon: "clock", style: .neutral)
                    }
                }
            }
        }
        .padding(.bottom, 12)
    }
}
