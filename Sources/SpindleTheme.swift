import PPDesign

/// Spindle's colors: the web app's blue, on the foundation's family look.
///
/// Only the colors that make Spindle look like Spindle are changed; everything
/// else is the foundation's, which is what a theme is for.
extension PPTheme {
    static let spindle = PPTheme(
        background: PPColor(light: 0xF6F7F9, dark: 0x111318),
        accent: PPColor(light: 0x2B4BD7, dark: 0x8FA2F5),
        accentSoft: PPColor(light: 0xE6EBFC, dark: 0x1A2250),
        textOnAccent: PPColor(light: 0xFFFFFF, dark: 0x0B1030),
        separator: PPColor(light: 0xE3E6EE, dark: 0x2C303A)
    )
}

/// The amber ring around a chosen chapter tile, as on the web.
///
/// Not a theme color: the foundation's theme has no slot for a ring, and one
/// app's signature detail is not a reason to give it one.
let selectionRing = PPColor(light: 0xE0A428, dark: 0xF0B940)
