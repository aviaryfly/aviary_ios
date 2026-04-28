import SwiftUI

// MARK: - Pre-flight checklist

struct PreFlightScreen: View {
    @Environment(\.theme) private var t
    var onTakeoff: () -> Void = {}
    var onBack: () -> Void = {}

    private struct Item: Identifiable { let id = UUID(); var label: String; var value: String?; var done: Bool; var warn: Bool = false }
    private let aircraft: [Item] = [
        .init(label: "Drone battery", value: "98% · 2 spares charged", done: true),
        .init(label: "SD card · clean & seated", value: "128 GB free", done: true),
        .init(label: "Visual line of sight", value: "No obstructions", done: true),
        .init(label: "Airspace authorization", value: "LAANC granted · 200 ft AGL", done: true),
    ]
    private let conditions: [Item] = [
        .init(label: "Weather check", value: "Clear · 9 mph · gust 14", done: false),
        .init(label: "Bystanders briefed", value: "Required for premium gigs", done: false, warn: true),
    ]

    var body: some View {
        ZStack {
            t.bg.ignoresSafeArea()
            VStack(spacing: 0) {
                header
                progressBar
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)

                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        SectionTitle(text: "Aircraft & site")
                            .padding(.bottom, 8)
                        ForEach(aircraft) { row(for: $0) }

                        SectionTitle(text: "Conditions")
                            .padding(.top, 12)
                            .padding(.bottom, 8)
                        ForEach(conditions) { row(for: $0) }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)
                }

                footer
            }
        }
    }

    private var header: some View {
        HStack(spacing: 12) {
            Button(action: onBack) {
                AviaryIcon(name: "arrow-left", size: 22, color: t.ink)
            }
            VStack(alignment: .leading, spacing: 1) {
                Text("EN ROUTE · 4 min away")
                    .font(AviaryFont.body(12))
                    .foregroundStyle(t.ink3)
                Text("Pre-flight checklist")
                    .font(AviaryFont.body(16, weight: .semibold))
                    .foregroundStyle(t.ink)
            }
            Spacer()
            Text("4 of 6")
                .font(AviaryFont.mono(13, weight: .semibold))
                .foregroundStyle(t.accent)
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
        .padding(.bottom, 12)
    }

    private var progressBar: some View {
        ZStack(alignment: .leading) {
            Capsule().fill(t.surface2).frame(height: 4)
            GeometryReader { geo in
                Capsule().fill(t.accent)
                    .frame(width: geo.size.width * 0.66, height: 4)
            }
            .frame(height: 4)
        }
    }

    private func row(for it: Item) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle().fill(it.done ? t.good : (it.warn ? t.warn : t.surface2))
                if it.done {
                    AviaryIcon(name: "check", size: 16, stroke: 3, color: .white)
                } else if it.warn {
                    Text("!")
                        .font(AviaryFont.body(14, weight: .bold))
                        .foregroundStyle(.white)
                }
            }
            .frame(width: 28, height: 28)

            VStack(alignment: .leading, spacing: 2) {
                Text(it.label)
                    .font(AviaryFont.body(14, weight: .medium))
                    .foregroundStyle(t.ink)
                if let v = it.value {
                    Text(v)
                        .font(AviaryFont.body(12))
                        .foregroundStyle(t.ink3)
                }
            }
            Spacer()
            AviaryIcon(name: "chevron-right", size: 16, color: t.ink4)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 14).fill(t.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14).strokeBorder(t.line)
        )
        .padding(.bottom, 8)
    }

    private var footer: some View {
        VStack {
            PrimaryButton(title: "Complete 2 more to fly", enabled: false, action: onTakeoff)
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 24)
        .background(
            t.surface
                .overlay(Rectangle().fill(t.line).frame(height: 1), alignment: .top)
                .ignoresSafeArea(edges: .bottom)
        )
    }
}

// MARK: - In-flight HUD (forced cockpit dark)

struct InFlightScreen: View {
    @Environment(\.dismiss) private var dismiss

    private let bg = Color(hex: 0x0B0E14)
    private let amber = Color(hex: 0xFFB23A)
    private let ink = Color(hex: 0xF4F5F7)
    private let dim = Color(hex: 0x8B92A0)
    private let good = Color(hex: 0x10A36F)

    var body: some View {
        ZStack {
            bg.ignoresSafeArea()

            cameraFeed.ignoresSafeArea()

            recBar
            reticle
            telemetryStack
            batteryStack
            shotList
            controls
            closeButton
        }
        .preferredColorScheme(.dark)
    }

    private var cameraFeed: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            ZStack {
                RadialGradient(colors: [Color(hex: 0x1A2436), Color(hex: 0x060810)],
                               center: .init(x: 0.5, y: 0.3),
                               startRadius: 0, endRadius: max(w, h))

                Canvas { ctx, size in
                    let sx = size.width / 390
                    let sy = size.height / 700

                    var ground = Path()
                    ground.move(to: .init(x: 0, y: 500 * sy))
                    ground.addLine(to: .init(x: 130 * sx, y: 360 * sy))
                    ground.addLine(to: .init(x: 260 * sx, y: 360 * sy))
                    ground.addLine(to: .init(x: 390 * sx, y: 500 * sy))
                    ground.closeSubpath()
                    ctx.fill(ground, with: .color(Color(hex: 0x1F2A3D).opacity(0.6)))

                    var lower = Path()
                    lower.move(to: .init(x: 130 * sx, y: 360 * sy))
                    lower.addLine(to: .init(x: 260 * sx, y: 360 * sy))
                    lower.addLine(to: .init(x: 390 * sx, y: 500 * sy))
                    lower.addLine(to: .init(x: size.width, y: size.height))
                    lower.addLine(to: .init(x: 0, y: size.height))
                    lower.addLine(to: .init(x: 0, y: 500 * sy))
                    ctx.fill(lower, with: .color(Color(hex: 0x0E1521)))

                    let houses: [CGRect] = [
                        .init(x: 140, y: 380, width: 110, height: 40),
                        .init(x: 60,  y: 460, width: 120, height: 60),
                        .init(x: 270, y: 470, width: 90,  height: 70),
                    ]
                    for r in houses {
                        let scaled = CGRect(x: r.minX * sx, y: r.minY * sy,
                                            width: r.width * sx, height: r.height * sy)
                        ctx.fill(Path(scaled), with: .color(Color(hex: 0x2A3850).opacity(0.7)))
                        ctx.stroke(Path(scaled), with: .color(Color(hex: 0x3D4F6E)), lineWidth: 1)
                    }
                }
            }
        }
    }

    private var recBar: some View {
        VStack {
            HStack {
                HStack(spacing: 6) {
                    Text("● REC")
                        .font(AviaryFont.body(12, weight: .semibold))
                        .foregroundStyle(amber)
                        .padding(.horizontal, 10).padding(.vertical, 5)
                        .background(Capsule().fill(amber.opacity(0.18)))
                        .overlay(Capsule().strokeBorder(amber))
                    Text("04:32")
                        .font(AviaryFont.mono(12, weight: .semibold))
                        .foregroundStyle(ink)
                        .padding(.horizontal, 10).padding(.vertical, 5)
                        .background(Capsule().fill(Color.white.opacity(0.08)))
                }
                Spacer()
                Text("4K · 60 fps")
                    .font(AviaryFont.mono(12, weight: .semibold))
                    .foregroundStyle(ink)
                    .padding(.horizontal, 10).padding(.vertical, 5)
                    .background(Capsule().fill(Color.white.opacity(0.08)))
            }
            .padding(.horizontal, 16)
            .padding(.top, 60)
            Spacer()
        }
    }

    private var reticle: some View {
        GeometryReader { geo in
            let cx = geo.size.width / 2
            let cy = geo.size.height * 0.38
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .strokeBorder(amber.opacity(0.7), lineWidth: 1.5)
                    .frame(width: 80, height: 80)
                Group {
                    Rectangle().fill(amber).frame(width: 6, height: 1.5).offset(x: -45)
                    Rectangle().fill(amber).frame(width: 6, height: 1.5).offset(x: 45)
                    Rectangle().fill(amber).frame(width: 1.5, height: 6).offset(y: -45)
                    Rectangle().fill(amber).frame(width: 1.5, height: 6).offset(y: 45)
                }
            }
            .position(x: cx, y: cy)
        }
    }

    private var telemetryStack: some View {
        GeometryReader { geo in
            VStack(alignment: .leading, spacing: 12) {
                tile(label: "ALT", value: "127", unit: "ft")
                tile(label: "SPD", value: "12",  unit: "mph")
                tile(label: "DIST", value: "340", unit: "ft")
            }
            .position(x: 50, y: geo.size.height * 0.42)
        }
    }

    private func tile(label: String, value: String, unit: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(AviaryFont.body(10, weight: .semibold))
                .tracking(0.08 * 10)
                .foregroundStyle(dim)
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value)
                    .font(AviaryFont.mono(18, weight: .semibold))
                    .foregroundStyle(ink)
                Text(unit)
                    .font(AviaryFont.body(10))
                    .foregroundStyle(dim)
            }
        }
        .padding(.horizontal, 10).padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(hex: 0x0B0E14).opacity(0.6))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10).strokeBorder(Color.white.opacity(0.1))
        )
        .frame(minWidth: 64)
    }

    private var batteryStack: some View {
        GeometryReader { geo in
            VStack(spacing: 2) {
                AviaryIcon(name: "battery", size: 20, stroke: 2, color: good)
                Text("78%")
                    .font(AviaryFont.mono(18, weight: .semibold))
                    .foregroundStyle(good)
                Text("~14 min")
                    .font(AviaryFont.body(9))
                    .foregroundStyle(dim)
            }
            .padding(.horizontal, 12).padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 10).fill(Color(hex: 0x0B0E14).opacity(0.6))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10).strokeBorder(Color.white.opacity(0.1))
            )
            .position(x: geo.size.width - 46, y: geo.size.height * 0.42)
        }
    }

    private var shotList: some View {
        VStack {
            Spacer()
            VStack(alignment: .leading, spacing: 8) {
                Text("SHOT LIST · 7 OF 12")
                    .font(AviaryFont.body(11, weight: .semibold))
                    .tracking(0.08 * 11)
                    .foregroundStyle(dim)
                HStack(spacing: 10) {
                    ZStack {
                        Circle().fill(amber)
                        AviaryIcon(name: "camera", size: 14, stroke: 2.5, color: bg)
                    }
                    .frame(width: 28, height: 28)
                    VStack(alignment: .leading, spacing: 1) {
                        Text("Front exterior · twilight")
                            .font(AviaryFont.body(14, weight: .semibold))
                            .foregroundStyle(ink)
                        Text("20 ft AGL · 30° pitch")
                            .font(AviaryFont.body(11))
                            .foregroundStyle(dim)
                    }
                    Spacer()
                    Text("Capture")
                        .font(AviaryFont.body(12, weight: .semibold))
                        .foregroundStyle(bg)
                        .padding(.horizontal, 14).padding(.vertical, 8)
                        .background(Capsule().fill(amber))
                }
                HStack(spacing: 4) {
                    ForEach(0..<12, id: \.self) { i in
                        let fill: Color = i < 7 ? amber
                            : (i == 7 ? amber.opacity(0.4) : Color.white.opacity(0.1))
                        Capsule().fill(fill).frame(height: 4)
                    }
                }
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(hex: 0x0B0E14).opacity(0.7))
                    .background(.ultraThinMaterial.opacity(0.8))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16).strokeBorder(Color.white.opacity(0.1))
            )
            .padding(.horizontal, 16)
            .padding(.bottom, 124)
        }
    }

    private var controls: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                ZStack {
                    Circle().fill(Color.white.opacity(0.08))
                        .background(.ultraThinMaterial.opacity(0.5))
                        .clipShape(Circle())
                    AviaryIcon(name: "home", size: 20, color: ink)
                }
                .frame(width: 48, height: 48)
                Spacer()
                Circle().fill(Color(hex: 0xE5484D))
                    .frame(width: 72, height: 72)
                    .overlay(Circle().strokeBorder(ink, lineWidth: 4))
                Spacer()
                ZStack {
                    Circle().fill(Color.white.opacity(0.08))
                        .background(.ultraThinMaterial.opacity(0.5))
                        .clipShape(Circle())
                    AviaryIcon(name: "x", size: 20, color: ink)
                }
                .frame(width: 48, height: 48)
                Spacer()
            }
            .padding(.bottom, 36)
        }
    }

    private var closeButton: some View {
        VStack {
            HStack {
                Button { dismiss() } label: {
                    Text("Done")
                        .font(AviaryFont.body(14, weight: .semibold))
                        .foregroundStyle(ink)
                        .padding(.horizontal, 14).padding(.vertical, 7)
                        .background(Capsule().fill(Color.white.opacity(0.12)))
                }
                .padding(.leading, 16)
                .padding(.top, 16)
                Spacer()
            }
            Spacer()
        }
    }
}

// MARK: - Deliverables upload

struct UploadScreen: View {
    @Environment(\.theme) private var t
    @Environment(\.dismiss) private var dismiss
    var onSubmit: () -> Void = {}

    var body: some View {
        ZStack {
            t.bg.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    HStack(spacing: 12) {
                        Button { dismiss() } label: {
                            AviaryIcon(name: "x", size: 22, color: t.ink)
                        }
                        Text("Deliverables")
                            .font(AviaryFont.body(16, weight: .semibold))
                            .foregroundStyle(t.ink)
                        Spacer()
                        Chip(text: "8 of 13", style: .accent)
                    }
                    .padding(.bottom, 16)

                    Text("Hand off your work")
                        .font(AviaryFont.display(26, weight: .bold))
                        .tracking(-0.02 * 26)
                        .foregroundStyle(t.ink)
                        .padding(.bottom, 4)
                    Text("Auto-uploading over Wi-Fi · 142 MB left")
                        .font(AviaryFont.body(14))
                        .foregroundStyle(t.ink3)
                        .padding(.bottom, 16)

                    AviaryCard(padding: 14, shadowed: true) {
                        VStack(spacing: 8) {
                            HStack(spacing: 10) {
                                AviaryIcon(name: "upload", size: 18, color: t.accent)
                                Text("Uploading 8 / 13")
                                    .font(AviaryFont.body(13, weight: .semibold))
                                    .foregroundStyle(t.ink)
                                Spacer()
                                Text("62%")
                                    .font(AviaryFont.mono(13, weight: .semibold))
                                    .foregroundStyle(t.ink3)
                            }
                            ZStack(alignment: .leading) {
                                Capsule().fill(t.surface2).frame(height: 6)
                                GeometryReader { geo in
                                    Capsule().fill(t.accent)
                                        .frame(width: geo.size.width * 0.62, height: 6)
                                }
                                .frame(height: 6)
                            }
                        }
                    }
                    .padding(.bottom, 16)

                    SectionTitle(text: "12 photos · 4K")
                        .padding(.bottom, 6)
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 4), spacing: 6) {
                        ForEach(0..<8, id: \.self) { i in thumb(idx: i, done: i < 5) }
                    }
                    .padding(.bottom, 18)

                    SectionTitle(text: "1 cinematic flyover")
                        .padding(.bottom, 6)
                    thumb(idx: 99, done: true, video: true)
                        .frame(width: 110, height: 110)

                    PrimaryButton(title: "Submit & finish gig", action: onSubmit)
                        .padding(.top, 24)
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 24)
            }
        }
    }

    private func thumb(idx: Int, done: Bool, video: Bool = false) -> some View {
        ZStack {
            LinearGradient(colors: [t.accentSoft, t.surface2],
                           startPoint: .topLeading, endPoint: .bottomTrailing)

            Canvas { ctx, size in
                var p = Path()
                p.move(to: .init(x: 0, y: size.height * 0.7))
                p.addLine(to: .init(x: size.width * 0.3, y: size.height * 0.5))
                p.addLine(to: .init(x: size.width * 0.5, y: size.height * 0.6))
                p.addLine(to: .init(x: size.width * 0.7, y: size.height * 0.4))
                p.addLine(to: .init(x: size.width, y: size.height * 0.55))
                p.addLine(to: .init(x: size.width, y: size.height))
                p.addLine(to: .init(x: 0, y: size.height))
                p.closeSubpath()
                ctx.fill(p, with: .color(t.ink2.opacity(0.4)))
                ctx.fill(Path(ellipseIn: .init(x: size.width * 0.7, y: size.height * 0.18,
                                                width: 12, height: 12)),
                         with: .color(t.warn.opacity(0.7)))
            }

            if done {
                VStack {
                    HStack {
                        Spacer()
                        ZStack {
                            Circle().fill(t.good)
                            AviaryIcon(name: "check", size: 11, stroke: 3.5, color: .white)
                        }
                        .frame(width: 18, height: 18)
                        .padding(4)
                    }
                    Spacer()
                }
            }
            if video {
                VStack {
                    Spacer()
                    HStack {
                        Text("0:42")
                            .font(AviaryFont.mono(9, weight: .semibold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 5).padding(.vertical, 2)
                            .background(Capsule().fill(.black.opacity(0.6)))
                            .padding(4)
                        Spacer()
                    }
                }
            }
        }
        .aspectRatio(1, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(t.line))
    }
}

// MARK: - Review / complete

struct ReviewCompleteScreen: View {
    @Environment(\.theme) private var t
    @Environment(\.dismiss) private var dismiss
    @State private var stars: Int = 5
    @State private var tags: Set<String> = []

    var body: some View {
        ZStack {
            t.bg.ignoresSafeArea()
            VStack(spacing: 0) {
                HStack {
                    Spacer()
                    Button { dismiss() } label: {
                        AviaryIcon(name: "x", size: 22, color: t.ink)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 8)

                ScrollView {
                    VStack(spacing: 0) {
                        ZStack {
                            Circle().fill(t.good)
                                .frame(width: 76, height: 76)
                            AviaryIcon(name: "check", size: 38, stroke: 3, color: .white)
                        }
                        .padding(.top, 16)
                        .padding(.bottom, 18)

                        Text("GIG COMPLETE")
                            .font(AviaryFont.body(13, weight: .semibold))
                            .tracking(0.04 * 13)
                            .foregroundStyle(t.good)
                            .padding(.bottom, 6)
                        Text("Nice flying.")
                            .font(AviaryFont.display(28, weight: .bold))
                            .tracking(-0.025 * 28)
                            .foregroundStyle(t.ink)
                        Text("+$340.00")
                            .font(AviaryFont.mono(36, weight: .semibold))
                            .foregroundStyle(t.accent)
                            .padding(.top, 6)
                        Text("Released after client review (24h)")
                            .font(AviaryFont.body(13))
                            .foregroundStyle(t.ink3)
                            .padding(.top, 4)

                        ratingCard
                            .padding(.top, 32)
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 24)
                }

                PrimaryButton(title: "Submit & find next gig") { dismiss() }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 28)
            }
        }
    }

    private var ratingCard: some View {
        AviaryCard(padding: 18) {
            VStack(spacing: 12) {
                HStack(spacing: 12) {
                    Avatar(size: 40, initials: "MR", background: t.accentSoft)
                    VStack(alignment: .leading, spacing: 1) {
                        Text("Rate Marin Realty Co.")
                            .font(AviaryFont.body(14, weight: .semibold))
                            .foregroundStyle(t.ink)
                        Text("Helps other pilots decide")
                            .font(AviaryFont.body(12))
                            .foregroundStyle(t.ink3)
                    }
                    Spacer()
                }
                HStack(spacing: 6) {
                    ForEach(1...5, id: \.self) { n in
                        Button { stars = n } label: {
                            AviaryIcon(name: n <= stars ? "star.fill" : "star",
                                       size: 36, stroke: 1.6,
                                       color: n <= stars ? t.warn : t.ink4)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.vertical, 8)

                FlowLayout(spacing: 6) {
                    ForEach(["Clear brief", "Fair pay", "Easy site", "Friendly"], id: \.self) { tag in
                        Button { toggle(tag) } label: {
                            Chip(text: tag, style: tags.contains(tag) ? .accent : .surface)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private func toggle(_ tag: String) {
        if tags.contains(tag) { tags.remove(tag) } else { tags.insert(tag) }
    }
}

// Simple flow layout for chip wrapping
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? .infinity
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowH: CGFloat = 0
        for v in subviews {
            let s = v.sizeThatFits(.unspecified)
            if x + s.width > width {
                x = 0; y += rowH + spacing; rowH = 0
            }
            x += s.width + spacing
            rowH = max(rowH, s.height)
        }
        return .init(width: width, height: y + rowH)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x: CGFloat = bounds.minX
        var y: CGFloat = bounds.minY
        var rowH: CGFloat = 0
        for v in subviews {
            let s = v.sizeThatFits(.unspecified)
            if x + s.width > bounds.maxX {
                x = bounds.minX; y += rowH + spacing; rowH = 0
            }
            v.place(at: .init(x: x, y: y), proposal: .init(s))
            x += s.width + spacing
            rowH = max(rowH, s.height)
        }
    }
}
