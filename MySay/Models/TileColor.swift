import SwiftUI

/// The soft, warm tile palette. Each case has a standard (pastel) fill and
/// a deeper high-contrast variant used when the High Contrast setting is on
/// or the system requests increased contrast.
nonisolated enum TileColor: String, CaseIterable, Codable, Sendable {
    case coral
    case peach
    case butter
    case sage
    case teal
    case sky
    case lavender
    case rose
    case sand
    case slate

    var displayName: String {
        rawValue.capitalized
    }
}

extension TileColor {
    /// Soft pastel fill for the tile background.
    var fill: Color {
        switch self {
        case .coral:    Color(red: 0.99, green: 0.86, blue: 0.82)
        case .peach:    Color(red: 1.00, green: 0.90, blue: 0.80)
        case .butter:   Color(red: 0.99, green: 0.95, blue: 0.78)
        case .sage:     Color(red: 0.85, green: 0.93, blue: 0.83)
        case .teal:     Color(red: 0.80, green: 0.93, blue: 0.92)
        case .sky:      Color(red: 0.82, green: 0.91, blue: 0.99)
        case .lavender: Color(red: 0.89, green: 0.87, blue: 0.98)
        case .rose:     Color(red: 0.99, green: 0.87, blue: 0.92)
        case .sand:     Color(red: 0.95, green: 0.91, blue: 0.84)
        case .slate:    Color(red: 0.88, green: 0.90, blue: 0.94)
        }
    }

    /// Deeper companion colour used for icons, borders, and text accents,
    /// and as the fill in high-contrast mode.
    var accent: Color {
        switch self {
        case .coral:    Color(red: 0.78, green: 0.33, blue: 0.24)
        case .peach:    Color(red: 0.80, green: 0.45, blue: 0.13)
        case .butter:   Color(red: 0.65, green: 0.52, blue: 0.05)
        case .sage:     Color(red: 0.25, green: 0.50, blue: 0.28)
        case .teal:     Color(red: 0.05, green: 0.49, blue: 0.47)
        case .sky:      Color(red: 0.10, green: 0.42, blue: 0.72)
        case .lavender: Color(red: 0.42, green: 0.34, blue: 0.74)
        case .rose:     Color(red: 0.76, green: 0.25, blue: 0.47)
        case .sand:     Color(red: 0.55, green: 0.43, blue: 0.26)
        case .slate:    Color(red: 0.32, green: 0.39, blue: 0.51)
        }
    }

    /// Tile background, respecting the high-contrast preference.
    func tileFill(highContrast: Bool) -> Color {
        highContrast ? .white : fill
    }

    /// Foreground/icon colour, respecting the high-contrast preference.
    func tileAccent(highContrast: Bool) -> Color {
        highContrast ? .black : accent
    }

    /// Ink: dark text colour for anything sitting on a pastel fill. The
    /// fills stay light in dark mode (tiles look the same day and night),
    /// so their text must stay dark too — `.primary` would flip to white
    /// and vanish.
    static let ink = Color(red: 0.12, green: 0.14, blue: 0.18)

    /// Text colour readable on this tile's fill in both colour schemes.
    func tileText(highContrast: Bool) -> Color {
        highContrast ? .black : Self.ink
    }
}
