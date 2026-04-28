import SwiftUI

struct AviaryIcon: View {
    var name: String
    var size: CGFloat = 24
    var stroke: CGFloat = 1.8
    var color: Color = .primary

    var body: some View {
        Canvas { ctx, sz in
            let s = sz.width / 24
            ctx.translateBy(x: 0, y: 0)
            draw(in: ctx, scale: s)
        }
        .frame(width: size, height: size)
    }

    private func draw(in ctx: GraphicsContext, scale s: CGFloat) {
        let strokeStyle = StrokeStyle(lineWidth: stroke, lineCap: .round, lineJoin: .round)
        let stroked: (Path) -> Void = { p in
            ctx.stroke(p.applying(.init(scaleX: s, y: s)), with: .color(color), style: strokeStyle)
        }
        let filled: (Path) -> Void = { p in
            ctx.fill(p.applying(.init(scaleX: s, y: s)), with: .color(color))
        }

        switch name {
        case "home":
            stroked(Path { p in
                p.move(to: .init(x: 3, y: 11))
                p.addLine(to: .init(x: 12, y: 4))
                p.addLine(to: .init(x: 21, y: 11))
                p.addLine(to: .init(x: 21, y: 20))
                p.addLine(to: .init(x: 15, y: 20))
                p.addLine(to: .init(x: 15, y: 13))
                p.addLine(to: .init(x: 9, y: 13))
                p.addLine(to: .init(x: 9, y: 20))
                p.addLine(to: .init(x: 3, y: 20))
                p.closeSubpath()
            })
        case "compass":
            stroked(Path(ellipseIn: .init(x: 3, y: 3, width: 18, height: 18)))
            filled(Path { p in
                p.move(to: .init(x: 15.5, y: 8.5))
                p.addLine(to: .init(x: 13.5, y: 13.5))
                p.addLine(to: .init(x: 8.5, y: 15.5))
                p.addLine(to: .init(x: 10.5, y: 10.5))
                p.closeSubpath()
            })
        case "drone":
            stroked(Path(ellipseIn: .init(x: 2.5, y: 2.5, width: 5, height: 5)))
            stroked(Path(ellipseIn: .init(x: 16.5, y: 2.5, width: 5, height: 5)))
            stroked(Path(ellipseIn: .init(x: 2.5, y: 16.5, width: 5, height: 5)))
            stroked(Path(ellipseIn: .init(x: 16.5, y: 16.5, width: 5, height: 5)))
            stroked(Path { p in
                p.move(to: .init(x: 7, y: 7));   p.addLine(to: .init(x: 11, y: 11))
                p.move(to: .init(x: 17, y: 7));  p.addLine(to: .init(x: 13, y: 11))
                p.move(to: .init(x: 7, y: 17));  p.addLine(to: .init(x: 11, y: 13))
                p.move(to: .init(x: 17, y: 17)); p.addLine(to: .init(x: 13, y: 13))
            })
            stroked(Path(roundedRect: .init(x: 10, y: 10, width: 4, height: 4), cornerRadius: 1))
        case "wallet":
            stroked(Path(roundedRect: .init(x: 3, y: 6, width: 18, height: 14), cornerRadius: 2))
            stroked(Path { p in
                p.move(to: .init(x: 3, y: 10));  p.addLine(to: .init(x: 21, y: 10))
                p.move(to: .init(x: 16, y: 15)); p.addLine(to: .init(x: 18, y: 15))
            })
        case "user":
            stroked(Path(ellipseIn: .init(x: 8, y: 4, width: 8, height: 8)))
            stroked(Path { p in
                p.move(to: .init(x: 4, y: 21))
                p.addCurve(to: .init(x: 20, y: 21),
                           control1: .init(x: 4, y: 17), control2: .init(x: 20, y: 17))
            })
        case "search":
            stroked(Path(ellipseIn: .init(x: 4, y: 4, width: 14, height: 14)))
            stroked(Path { p in
                p.move(to: .init(x: 21, y: 21))
                p.addLine(to: .init(x: 16.5, y: 16.5))
            })
        case "bell":
            stroked(Path { p in
                p.move(to: .init(x: 6, y: 8))
                p.addCurve(to: .init(x: 18, y: 8), control1: .init(x: 6, y: 4.5), control2: .init(x: 18, y: 4.5))
                p.addLine(to: .init(x: 18, y: 8))
                p.addCurve(to: .init(x: 21, y: 16),
                           control1: .init(x: 18, y: 14), control2: .init(x: 21, y: 16))
                p.addLine(to: .init(x: 3, y: 16))
                p.addCurve(to: .init(x: 6, y: 8),
                           control1: .init(x: 3, y: 16), control2: .init(x: 6, y: 14))
                p.closeSubpath()
            })
            stroked(Path { p in
                p.move(to: .init(x: 10, y: 21))
                p.addCurve(to: .init(x: 14, y: 21),
                           control1: .init(x: 10, y: 22.5), control2: .init(x: 14, y: 22.5))
            })
        case "message":
            stroked(Path { p in
                p.addRoundedRect(in: .init(x: 4, y: 4, width: 16, height: 13), cornerSize: .init(width: 2, height: 2))
                p.move(to: .init(x: 11, y: 17))
                p.addLine(to: .init(x: 7, y: 20))
                p.addLine(to: .init(x: 7, y: 17))
            })
        case "star":
            stroked(Path { p in
                p.move(to: .init(x: 12, y: 3))
                p.addLine(to: .init(x: 14.7, y: 8.5))
                p.addLine(to: .init(x: 20.7, y: 9.4))
                p.addLine(to: .init(x: 16.3, y: 13.7))
                p.addLine(to: .init(x: 17.3, y: 19.7))
                p.addLine(to: .init(x: 12, y: 17))
                p.addLine(to: .init(x: 6.7, y: 19.7))
                p.addLine(to: .init(x: 7.7, y: 13.7))
                p.addLine(to: .init(x: 3.3, y: 9.4))
                p.addLine(to: .init(x: 9.3, y: 8.5))
                p.closeSubpath()
            })
        case "star.fill":
            filled(Path { p in
                p.move(to: .init(x: 12, y: 3))
                p.addLine(to: .init(x: 14.7, y: 8.5))
                p.addLine(to: .init(x: 20.7, y: 9.4))
                p.addLine(to: .init(x: 16.3, y: 13.7))
                p.addLine(to: .init(x: 17.3, y: 19.7))
                p.addLine(to: .init(x: 12, y: 17))
                p.addLine(to: .init(x: 6.7, y: 19.7))
                p.addLine(to: .init(x: 7.7, y: 13.7))
                p.addLine(to: .init(x: 3.3, y: 9.4))
                p.addLine(to: .init(x: 9.3, y: 8.5))
                p.closeSubpath()
            })
        case "clock":
            stroked(Path(ellipseIn: .init(x: 3, y: 3, width: 18, height: 18)))
            stroked(Path { p in
                p.move(to: .init(x: 12, y: 7))
                p.addLine(to: .init(x: 12, y: 12))
                p.addLine(to: .init(x: 15, y: 14))
            })
        case "pin":
            stroked(Path { p in
                p.move(to: .init(x: 12, y: 22))
                p.addCurve(to: .init(x: 19, y: 9),
                           control1: .init(x: 17, y: 18), control2: .init(x: 19, y: 13))
                p.addCurve(to: .init(x: 5, y: 9),
                           control1: .init(x: 19, y: 5), control2: .init(x: 5, y: 5))
                p.addCurve(to: .init(x: 12, y: 22),
                           control1: .init(x: 5, y: 13), control2: .init(x: 7, y: 18))
            })
            stroked(Path(ellipseIn: .init(x: 9.5, y: 6.5, width: 5, height: 5)))
        case "arrow-right":
            stroked(Path { p in
                p.move(to: .init(x: 5, y: 12)); p.addLine(to: .init(x: 19, y: 12))
                p.move(to: .init(x: 13, y: 5)); p.addLine(to: .init(x: 20, y: 12)); p.addLine(to: .init(x: 13, y: 19))
            })
        case "arrow-left":
            stroked(Path { p in
                p.move(to: .init(x: 19, y: 12)); p.addLine(to: .init(x: 5, y: 12))
                p.move(to: .init(x: 11, y: 5));  p.addLine(to: .init(x: 4, y: 12)); p.addLine(to: .init(x: 11, y: 19))
            })
        case "chevron-right":
            stroked(Path { p in
                p.move(to: .init(x: 9, y: 6)); p.addLine(to: .init(x: 15, y: 12)); p.addLine(to: .init(x: 9, y: 18))
            })
        case "chevron-down":
            stroked(Path { p in
                p.move(to: .init(x: 6, y: 9)); p.addLine(to: .init(x: 12, y: 15)); p.addLine(to: .init(x: 18, y: 9))
            })
        case "check":
            stroked(Path { p in
                p.move(to: .init(x: 5, y: 13)); p.addLine(to: .init(x: 9, y: 17)); p.addLine(to: .init(x: 19, y: 7))
            })
        case "check-circle":
            stroked(Path(ellipseIn: .init(x: 3, y: 3, width: 18, height: 18)))
            stroked(Path { p in
                p.move(to: .init(x: 8, y: 12)); p.addLine(to: .init(x: 11, y: 15)); p.addLine(to: .init(x: 16, y: 9))
            })
        case "x":
            stroked(Path { p in
                p.move(to: .init(x: 6, y: 6));  p.addLine(to: .init(x: 18, y: 18))
                p.move(to: .init(x: 18, y: 6)); p.addLine(to: .init(x: 6, y: 18))
            })
        case "plus":
            stroked(Path { p in
                p.move(to: .init(x: 12, y: 5));  p.addLine(to: .init(x: 12, y: 19))
                p.move(to: .init(x: 5, y: 12)); p.addLine(to: .init(x: 19, y: 12))
            })
        case "camera":
            stroked(Path { p in
                p.addRoundedRect(in: .init(x: 3, y: 6, width: 18, height: 14), cornerSize: .init(width: 2, height: 2))
                p.move(to: .init(x: 7, y: 6))
                p.addLine(to: .init(x: 9, y: 4))
                p.addLine(to: .init(x: 15, y: 4))
                p.addLine(to: .init(x: 17, y: 6))
            })
            stroked(Path(ellipseIn: .init(x: 8, y: 9, width: 8, height: 8)))
        case "upload":
            stroked(Path { p in
                p.move(to: .init(x: 12, y: 16)); p.addLine(to: .init(x: 12, y: 4))
                p.move(to: .init(x: 6, y: 10));  p.addLine(to: .init(x: 12, y: 4)); p.addLine(to: .init(x: 18, y: 10))
                p.move(to: .init(x: 4, y: 20));  p.addLine(to: .init(x: 20, y: 20))
            })
        case "shield":
            stroked(Path { p in
                p.move(to: .init(x: 12, y: 3))
                p.addLine(to: .init(x: 20, y: 6))
                p.addLine(to: .init(x: 20, y: 12))
                p.addCurve(to: .init(x: 12, y: 21),
                           control1: .init(x: 20, y: 17), control2: .init(x: 16.5, y: 20))
                p.addCurve(to: .init(x: 4, y: 12),
                           control1: .init(x: 7.5, y: 20), control2: .init(x: 4, y: 17))
                p.addLine(to: .init(x: 4, y: 6))
                p.closeSubpath()
            })
            stroked(Path { p in
                p.move(to: .init(x: 9, y: 12)); p.addLine(to: .init(x: 11, y: 14)); p.addLine(to: .init(x: 15, y: 10))
            })
        case "battery":
            stroked(Path(roundedRect: .init(x: 3, y: 8, width: 16, height: 8), cornerRadius: 2))
            stroked(Path { p in
                p.move(to: .init(x: 21, y: 11)); p.addLine(to: .init(x: 21, y: 13))
            })
            ctx.fill(
                Path(roundedRect: .init(x: 5, y: 10, width: 10, height: 4), cornerRadius: 1)
                    .applying(.init(scaleX: s, y: s)),
                with: .color(color)
            )
        case "altitude":
            stroked(Path { p in
                p.move(to: .init(x: 3, y: 21))
                p.addLine(to: .init(x: 8, y: 12))
                p.addLine(to: .init(x: 12, y: 17))
                p.addLine(to: .init(x: 15, y: 13))
                p.addLine(to: .init(x: 21, y: 21))
                p.closeSubpath()
            })
            stroked(Path(ellipseIn: .init(x: 15, y: 4, width: 4, height: 4)))
        case "filter":
            stroked(Path { p in
                p.move(to: .init(x: 4, y: 5));  p.addLine(to: .init(x: 20, y: 5))
                p.move(to: .init(x: 7, y: 12)); p.addLine(to: .init(x: 17, y: 12))
                p.move(to: .init(x: 10, y: 19)); p.addLine(to: .init(x: 14, y: 19))
            })
        case "phone":
            stroked(Path { p in
                p.move(to: .init(x: 5, y: 4))
                p.addLine(to: .init(x: 9, y: 4))
                p.addLine(to: .init(x: 11, y: 9))
                p.addLine(to: .init(x: 8, y: 11))
                p.addCurve(to: .init(x: 14, y: 17),
                           control1: .init(x: 9, y: 14), control2: .init(x: 11, y: 16))
                p.addLine(to: .init(x: 16, y: 14))
                p.addLine(to: .init(x: 21, y: 16))
                p.addLine(to: .init(x: 21, y: 20))
                p.addCurve(to: .init(x: 19, y: 22),
                           control1: .init(x: 21, y: 21), control2: .init(x: 20, y: 22))
                p.addCurve(to: .init(x: 3, y: 6),
                           control1: .init(x: 11, y: 22), control2: .init(x: 3, y: 14))
                p.addCurve(to: .init(x: 5, y: 4),
                           control1: .init(x: 3, y: 5), control2: .init(x: 4, y: 4))
            })
        case "play":
            filled(Path { p in
                p.move(to: .init(x: 7, y: 5))
                p.addLine(to: .init(x: 7, y: 19))
                p.addLine(to: .init(x: 19, y: 12))
                p.closeSubpath()
            })
        case "sliders":
            stroked(Path { p in
                p.move(to: .init(x: 4, y: 6));  p.addLine(to: .init(x: 16, y: 6))
                p.move(to: .init(x: 4, y: 12)); p.addLine(to: .init(x: 10, y: 12))
                p.move(to: .init(x: 4, y: 18)); p.addLine(to: .init(x: 14, y: 18))
            })
            stroked(Path(ellipseIn: .init(x: 16, y: 4, width: 4, height: 4)))
            stroked(Path(ellipseIn: .init(x: 12, y: 10, width: 4, height: 4)))
            stroked(Path(ellipseIn: .init(x: 14, y: 16, width: 4, height: 4)))
        case "briefcase":
            stroked(Path(roundedRect: .init(x: 3, y: 7, width: 18, height: 13), cornerRadius: 2))
            stroked(Path { p in
                p.move(to: .init(x: 9, y: 7))
                p.addLine(to: .init(x: 9, y: 5))
                p.addCurve(to: .init(x: 15, y: 5),
                           control1: .init(x: 9, y: 3), control2: .init(x: 15, y: 3))
                p.addLine(to: .init(x: 15, y: 7))
            })
        case "cert":
            stroked(Path(ellipseIn: .init(x: 7, y: 4, width: 10, height: 10)))
            stroked(Path { p in
                p.move(to: .init(x: 9, y: 13))
                p.addLine(to: .init(x: 7, y: 21))
                p.addLine(to: .init(x: 12, y: 18))
                p.addLine(to: .init(x: 17, y: 21))
                p.addLine(to: .init(x: 15, y: 13))
            })
        case "cloud":
            stroked(Path { p in
                p.move(to: .init(x: 7, y: 18))
                p.addCurve(to: .init(x: 6, y: 10.1),
                           control1: .init(x: 4, y: 18), control2: .init(x: 4, y: 11))
                p.addCurve(to: .init(x: 17.7, y: 11.5),
                           control1: .init(x: 8, y: 5), control2: .init(x: 16, y: 6))
                p.addCurve(to: .init(x: 17, y: 18),
                           control1: .init(x: 21, y: 12), control2: .init(x: 21, y: 18))
                p.closeSubpath()
            })
        case "sun":
            stroked(Path(ellipseIn: .init(x: 8, y: 8, width: 8, height: 8)))
            stroked(Path { p in
                p.move(to: .init(x: 12, y: 3));   p.addLine(to: .init(x: 12, y: 5))
                p.move(to: .init(x: 12, y: 19));  p.addLine(to: .init(x: 12, y: 21))
                p.move(to: .init(x: 3, y: 12));   p.addLine(to: .init(x: 5, y: 12))
                p.move(to: .init(x: 19, y: 12));  p.addLine(to: .init(x: 21, y: 12))
                p.move(to: .init(x: 5.6, y: 5.6)); p.addLine(to: .init(x: 7, y: 7))
                p.move(to: .init(x: 17, y: 17));  p.addLine(to: .init(x: 18.4, y: 18.4))
                p.move(to: .init(x: 5.6, y: 18.4)); p.addLine(to: .init(x: 7, y: 17))
                p.move(to: .init(x: 17, y: 7));   p.addLine(to: .init(x: 18.4, y: 5.6))
            })
        case "navigation":
            filled(Path { p in
                p.move(to: .init(x: 12, y: 3))
                p.addLine(to: .init(x: 20, y: 21))
                p.addLine(to: .init(x: 12, y: 16))
                p.addLine(to: .init(x: 4, y: 21))
                p.closeSubpath()
            })
        case "card":
            stroked(Path(roundedRect: .init(x: 3, y: 6, width: 18, height: 13), cornerRadius: 2))
            stroked(Path { p in
                p.move(to: .init(x: 3, y: 11)); p.addLine(to: .init(x: 21, y: 11))
            })
        case "gift":
            stroked(Path(roundedRect: .init(x: 3, y: 9, width: 18, height: 11), cornerRadius: 1))
            stroked(Path { p in
                p.move(to: .init(x: 3, y: 13));  p.addLine(to: .init(x: 21, y: 13))
                p.move(to: .init(x: 12, y: 9));  p.addLine(to: .init(x: 12, y: 20))
            })
            stroked(Path { p in
                p.move(to: .init(x: 8, y: 9))
                p.addCurve(to: .init(x: 12, y: 6), control1: .init(x: 7, y: 7), control2: .init(x: 9, y: 5))
                p.addCurve(to: .init(x: 16, y: 9), control1: .init(x: 15, y: 5), control2: .init(x: 17, y: 7))
            })
        case "wind":
            stroked(Path { p in
                p.move(to: .init(x: 3, y: 8));  p.addLine(to: .init(x: 16, y: 8))
                p.addCurve(to: .init(x: 13, y: 5),
                           control1: .init(x: 18, y: 8), control2: .init(x: 18, y: 5))
                p.move(to: .init(x: 3, y: 16));  p.addLine(to: .init(x: 20, y: 16))
                p.addCurve(to: .init(x: 17, y: 19),
                           control1: .init(x: 22, y: 16), control2: .init(x: 22, y: 19))
                p.move(to: .init(x: 3, y: 12)); p.addLine(to: .init(x: 14, y: 12))
            })
        default:
            stroked(Path(ellipseIn: .init(x: 3, y: 3, width: 18, height: 18)))
        }
    }
}
