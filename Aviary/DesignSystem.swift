import SwiftUI
import Combine

enum AviaryTheme: String, CaseIterable, Identifiable {
    case field, skyline, hangar
    var id: String { rawValue }

    var label: String {
        switch self {
        case .field: return "Field"
        case .skyline: return "Skyline"
        case .hangar: return "Hangar"
        }
    }
}

struct ThemeTokens {
    let bg: Color
    let surface: Color
    let surface2: Color
    let line: Color
    let lineStrong: Color
    let ink: Color
    let ink2: Color
    let ink3: Color
    let ink4: Color
    let accent: Color
    let accentInk: Color
    let accentSoft: Color
    let good: Color
    let warn: Color
    let bad: Color
    let mapBg: Color
    let mapRoad: Color
    let mapWater: Color

    static let field = ThemeTokens(
        bg:          Color(hex: 0xF1EBDD),
        surface:     Color(hex: 0xFBF7EC),
        surface2:    Color(hex: 0xEDE4D0),
        line:        Color(red: 54/255, green: 36/255, blue: 18/255).opacity(0.10),
        lineStrong:  Color(red: 54/255, green: 36/255, blue: 18/255).opacity(0.20),
        ink:         Color(hex: 0x2A1D0E),
        ink2:        Color(hex: 0x4F3D24),
        ink3:        Color(hex: 0x7A6849),
        ink4:        Color(hex: 0xA89576),
        accent:      Color(hex: 0xC7501C),
        accentInk:   Color(hex: 0xFBF7EC),
        accentSoft:  Color(hex: 0xC7501C).opacity(0.12),
        good:        Color(hex: 0x5C7B3E),
        warn:        Color(hex: 0xD49019),
        bad:         Color(hex: 0xB0381C),
        mapBg:       Color(hex: 0xE6DCC2),
        mapRoad:     Color(hex: 0xFBF7EC),
        mapWater:    Color(hex: 0xB8C4A8)
    )

    static let hangar = ThemeTokens(
        bg:          Color(hex: 0x0B0E14),
        surface:     Color(hex: 0x141821),
        surface2:    Color(hex: 0x1C2230),
        line:        Color.white.opacity(0.08),
        lineStrong:  Color.white.opacity(0.16),
        ink:         Color(hex: 0xF4F5F7),
        ink2:        Color(hex: 0xC8CDD8),
        ink3:        Color(hex: 0x8B92A0),
        ink4:        Color(hex: 0x5A6171),
        accent:      Color(hex: 0xFFB23A),
        accentInk:   Color(hex: 0x14171F),
        accentSoft:  Color(hex: 0xFFB23A).opacity(0.14),
        good:        Color(hex: 0x10A36F),
        warn:        Color(hex: 0xFFB23A),
        bad:         Color(hex: 0xE5484D),
        mapBg:       Color(hex: 0x0F1219),
        mapRoad:     Color(hex: 0x1C2230),
        mapWater:    Color(hex: 0x0A1825)
    )
}

final class ThemeManager: ObservableObject {
    @Published var theme: AviaryTheme = .field
    var tokens: ThemeTokens {
        switch theme {
        case .hangar: return .hangar
        default: return .field
        }
    }
}

private struct ThemeKey: EnvironmentKey {
    static let defaultValue: ThemeTokens = .field
}

extension EnvironmentValues {
    var theme: ThemeTokens {
        get { self[ThemeKey.self] }
        set { self[ThemeKey.self] = newValue }
    }
}

extension Color {
    init(hex: UInt32, alpha: Double = 1) {
        let r = Double((hex >> 16) & 0xFF) / 255
        let g = Double((hex >> 8) & 0xFF) / 255
        let b = Double(hex & 0xFF) / 255
        self.init(.sRGB, red: r, green: g, blue: b, opacity: alpha)
    }
}

enum Radius {
    static let sm: CGFloat = 12
    static let md: CGFloat = 18
    static let lg: CGFloat = 28
    static let pill: CGFloat = 999
}

enum AviaryFont {
    static func display(_ size: CGFloat, weight: Font.Weight = .bold) -> Font {
        .system(size: size, weight: weight, design: .default)
    }
    static func body(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .default)
    }
    static func mono(_ size: CGFloat, weight: Font.Weight = .semibold) -> Font {
        .system(size: size, weight: weight, design: .monospaced)
    }
}
