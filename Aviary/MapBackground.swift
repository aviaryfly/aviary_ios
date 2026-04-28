import SwiftUI

struct MapPin: Identifiable {
    let id = UUID()
    var x: CGFloat
    var y: CGFloat
    var label: String = "$"
    var color: Color? = nil
    var pulse: Bool = false
}

struct MapRoute: Identifiable {
    let id = UUID()
    var path: Path
    var dashed: Bool = false
}

/// Stylized paper-feel map background scaled to a 390 × design-height coordinate space.
struct MapBackground: View {
    var pins: [MapPin] = []
    var routes: [MapRoute] = []
    var showPilot: Bool = false
    var pilotPos: CGPoint = CGPoint(x: 195, y: 422)

    @Environment(\.theme) private var t

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let sx = w / 390
            let sy = h / 700
            ZStack {
                t.mapBg
                grid(in: geo.size)
                water(sx: sx, sy: sy)
                roads(sx: sx, sy: sy)
                buildings(sx: sx, sy: sy)
                parks(sx: sx, sy: sy)
                routesView(sx: sx, sy: sy)
                ForEach(pins) { pin in
                    pinView(pin: pin)
                        .position(x: pin.x * sx, y: pin.y * sy)
                }
                if showPilot {
                    pilot
                        .position(x: pilotPos.x * sx, y: pilotPos.y * sy)
                }
            }
        }
        .clipped()
    }

    private func grid(in size: CGSize) -> some View {
        Canvas { ctx, _ in
            var path = Path()
            let step: CGFloat = 40
            stride(from: 0, through: size.width, by: step).forEach { x in
                path.move(to: .init(x: x, y: 0))
                path.addLine(to: .init(x: x, y: size.height))
            }
            stride(from: 0, through: size.height, by: step).forEach { y in
                path.move(to: .init(x: 0, y: y))
                path.addLine(to: .init(x: size.width, y: y))
            }
            ctx.stroke(path, with: .color(t.line), lineWidth: 0.5)
        }
        .allowsHitTesting(false)
    }

    private func water(sx: CGFloat, sy: CGFloat) -> some View {
        Canvas { ctx, _ in
            var blob = Path()
            blob.move(to: .init(x: -20 * sx, y: 480 * sy))
            blob.addQuadCurve(to: .init(x: 140 * sx, y: 500 * sy),
                              control: .init(x: 80 * sx, y: 460 * sy))
            blob.addQuadCurve(to: .init(x: 260 * sx, y: 510 * sy),
                              control: .init(x: 200 * sx, y: 540 * sy))
            blob.addQuadCurve(to: .init(x: 410 * sx, y: 480 * sy),
                              control: .init(x: 340 * sx, y: 480 * sy))
            blob.addLine(to: .init(x: 410 * sx, y: 720 * sy))
            blob.addLine(to: .init(x: -20 * sx, y: 720 * sy))
            blob.closeSubpath()
            ctx.fill(blob, with: .color(t.mapWater.opacity(0.7)))

            let lake = Path(ellipseIn: .init(x: -20 * sx, y: 140 * sy,
                                              width: 160 * sx, height: 80 * sy))
            ctx.fill(lake, with: .color(t.mapWater.opacity(0.6)))
        }
        .allowsHitTesting(false)
    }

    private func roads(sx: CGFloat, sy: CGFloat) -> some View {
        Canvas { ctx, _ in
            let strokeStyle = StrokeStyle(lineWidth: 14, lineCap: .round)
            let mediumStyle = StrokeStyle(lineWidth: 10, lineCap: .round)
            let thinStyle = StrokeStyle(lineWidth: 8, lineCap: .round)

            var r1 = Path()
            r1.move(to: .init(x: -10 * sx, y: 220 * sy))
            r1.addQuadCurve(to: .init(x: 200 * sx, y: 240 * sy),
                            control: .init(x: 100 * sx, y: 200 * sy))
            r1.addQuadCurve(to: .init(x: 410 * sx, y: 220 * sy),
                            control: .init(x: 305 * sx, y: 280 * sy))
            ctx.stroke(r1, with: .color(t.mapRoad), style: strokeStyle)

            var r2 = Path()
            r2.move(to: .init(x: 80 * sx, y: -10 * sy))
            r2.addQuadCurve(to: .init(x: 90 * sx, y: 240 * sy),
                            control: .init(x: 110 * sx, y: 120 * sy))
            r2.addQuadCurve(to: .init(x: 130 * sx, y: 480 * sy),
                            control: .init(x: 70 * sx, y: 360 * sy))
            r2.addQuadCurve(to: .init(x: 100 * sx, y: 720 * sy),
                            control: .init(x: 190 * sx, y: 600 * sy))
            ctx.stroke(r2, with: .color(t.mapRoad), style: mediumStyle)

            var r3 = Path()
            r3.move(to: .init(x: 280 * sx, y: -10 * sy))
            r3.addQuadCurve(to: .init(x: 290 * sx, y: 260 * sy),
                            control: .init(x: 250 * sx, y: 120 * sy))
            r3.addQuadCurve(to: .init(x: 250 * sx, y: 480 * sy),
                            control: .init(x: 330 * sx, y: 360 * sy))
            r3.addQuadCurve(to: .init(x: 300 * sx, y: 720 * sy),
                            control: .init(x: 170 * sx, y: 600 * sy))
            ctx.stroke(r3, with: .color(t.mapRoad), style: mediumStyle)

            var r4 = Path()
            r4.move(to: .init(x: -10 * sx, y: 380 * sy))
            r4.addQuadCurve(to: .init(x: 220 * sx, y: 400 * sy),
                            control: .init(x: 130 * sx, y: 360 * sy))
            r4.addQuadCurve(to: .init(x: 410 * sx, y: 380 * sy),
                            control: .init(x: 315 * sx, y: 440 * sy))
            ctx.stroke(r4, with: .color(t.mapRoad), style: thinStyle)
        }
        .allowsHitTesting(false)
    }

    private func buildings(sx: CGFloat, sy: CGFloat) -> some View {
        let blocks: [CGRect] = [
            .init(x: 30, y: 280, width: 50, height: 60),
            .init(x: 100, y: 290, width: 40, height: 50),
            .init(x: 160, y: 280, width: 60, height: 50),
            .init(x: 40, y: 410, width: 60, height: 40),
            .init(x: 120, y: 420, width: 50, height: 40),
            .init(x: 220, y: 290, width: 45, height: 60),
            .init(x: 310, y: 280, width: 50, height: 50),
            .init(x: 220, y: 420, width: 60, height: 50),
            .init(x: 310, y: 420, width: 45, height: 50),
            .init(x: 50, y: 60, width: 80, height: 80),
            .init(x: 180, y: 80, width: 60, height: 60),
            .init(x: 290, y: 60, width: 70, height: 70),
            .init(x: 40, y: 620, width: 60, height: 50),
            .init(x: 180, y: 630, width: 70, height: 40),
            .init(x: 310, y: 620, width: 50, height: 50),
        ]
        return Canvas { ctx, _ in
            for r in blocks {
                let scaled = CGRect(x: r.minX * sx, y: r.minY * sy,
                                    width: r.width * sx, height: r.height * sy)
                let path = Path(roundedRect: scaled, cornerRadius: 3)
                ctx.fill(path, with: .color(t.surface.opacity(0.6)))
                ctx.stroke(path, with: .color(t.line), lineWidth: 0.5)
            }
        }
        .allowsHitTesting(false)
    }

    private func parks(sx: CGFloat, sy: CGFloat) -> some View {
        Canvas { ctx, _ in
            ctx.fill(
                Path(ellipseIn: .init(x: 314 * sx, y: 314 * sy, width: 72 * sx, height: 72 * sy)),
                with: .color(t.good.opacity(0.18))
            )
            ctx.fill(
                Path(ellipseIn: .init(x: 12 * sx, y: 512 * sy, width: 56 * sx, height: 56 * sy)),
                with: .color(t.good.opacity(0.18))
            )
        }
        .allowsHitTesting(false)
    }

    private func routesView(sx: CGFloat, sy: CGFloat) -> some View {
        Canvas { ctx, _ in
            for r in routes {
                let scaled = r.path.applying(.init(scaleX: sx, y: sy))
                let style = StrokeStyle(lineWidth: 3, lineCap: .round,
                                        dash: r.dashed ? [4, 6] : [])
                ctx.stroke(scaled, with: .color(t.accent.opacity(0.85)), style: style)
            }
        }
        .allowsHitTesting(false)
    }

    @ViewBuilder
    private func pinView(pin: MapPin) -> some View {
        let color = pin.color ?? t.accent
        ZStack {
            if pin.pulse {
                Circle().fill(color.opacity(0.15)).frame(width: 44, height: 44)
                Circle().fill(color.opacity(0.25)).frame(width: 28, height: 28)
            }
            Circle().fill(color)
                .overlay(Circle().strokeBorder(.white, lineWidth: 3))
                .frame(width: 28, height: 28)
            Text(pin.label)
                .font(AviaryFont.body(11, weight: .bold))
                .foregroundStyle(.white)
        }
    }

    private var pilot: some View {
        ZStack {
            Circle().fill(t.accent.opacity(0.18)).frame(width: 44, height: 44)
            Circle().fill(.white).frame(width: 28, height: 28)
                .overlay(Circle().strokeBorder(t.accent, lineWidth: 3))
            Circle().fill(t.accent).frame(width: 12, height: 12)
        }
    }
}
