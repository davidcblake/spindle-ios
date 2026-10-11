import PPDesign
import SwiftUI

/// Spindle's colors: the web app's blue, refined, on the foundation's family
/// look.
///
/// Only the colors that make Spindle look like Spindle are changed; everything
/// else is the foundation's, which is what a theme is for. The design these
/// come from is "Quiet Light": a warm white page, near-black ink, one blue.
extension PPTheme {
    static let spindle = PPTheme(
        background: PPColor(light: 0xFBFAF8, dark: 0x111318),
        accent: PPColor(light: 0x3346D3, dark: 0x8FA2F5),
        accentSoft: PPColor(light: 0xECEEFB, dark: 0x1A2250),
        textOnAccent: PPColor(light: 0xFFFFFF, dark: 0x0B1030),
        separator: PPColor(light: 0xE7E5E0, dark: 0x2C303A)
    )
}

/// The amber ring around a chosen chapter tile, as on the web, and the brass of
/// the Liahona.
///
/// Not a theme color: the foundation's theme has no slot for a ring, and one
/// app's signature detail is not a reason to give it one.
let selectionRing = PPColor(light: 0xE0A428, dark: 0xF0B940)

/// The dark block a verse sits in: the anchor at the foot of a study, and the
/// last verse on Today. Near-black in light appearance; a step up from the
/// background in dark, so it still reads as a block.
let verseBlock = PPColor(light: 0x171A23, dark: 0x1E2230)

extension PPTextStyle {
    /// Scripture itself: a quoted verse, and the name of a passage.
    ///
    /// Apple's serif (New York) rather than the family's rounded headings, so
    /// the words of scripture read as different from the buttons around them.
    /// Spindle's own, not the foundation's: of the four apps, only this one
    /// quotes scripture. Built on a text style like every other, so it grows
    /// with the person's type size.
    static var scripture: PPTextStyle {
        PPTextStyle(textStyle: .title3, design: .serif)
    }

    /// A verse quoted small, under the passage it comes from in a list.
    static var scriptureQuote: PPTextStyle {
        PPTextStyle(textStyle: .subheadline, design: .serif)
    }

    /// A passage named at the top of a screen: "Alma 32".
    static var scriptureTitle: PPTextStyle {
        PPTextStyle(textStyle: .largeTitle, design: .serif)
    }
}
