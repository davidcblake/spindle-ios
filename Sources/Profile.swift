import Foundation
import SwiftData

/// What a person has told Spindle about themselves, and how they like their
/// studies shown. Every field is optional, as on the web.
///
/// The web app's `profiles` row. Sent with each study request once preparing
/// a study works, so the server can tailor the study (decision `0002`).
///
/// There should only ever be one. CloudKit cannot promise that across two
/// devices that both started fresh, so whoever reads it takes the earliest
/// (`Profile.current`) rather than trusting there is exactly one.
@Model
final class Profile {
    var firstName: String = ""
    var calling: String = ""
    var spiritualSeason: String = ""
    var familyContext: String = ""
    var studyFocus: String = ""
    /// `StudySection` raw values the person has switched off.
    var hiddenSections: [String] = []
    /// "core" or "expanded", the web app's two values.
    var conferenceScope: String = ConferenceScope.core.rawValue
    var createdAt: Date = Date.distantPast

    init(createdAt: Date = .now) {
        self.createdAt = createdAt
    }

    var hidden: Set<StudySection> {
        Set(hiddenSections.compactMap(StudySection.init(rawValue:)))
    }

    func toggle(_ section: StudySection) {
        if hiddenSections.contains(section.rawValue) {
            hiddenSections.removeAll { $0 == section.rawValue }
        } else {
            hiddenSections.append(section.rawValue)
        }
    }

    var scope: ConferenceScope {
        get { ConferenceScope(rawValue: conferenceScope) ?? .core }
        set { conferenceScope = newValue.rawValue }
    }

    /// The earliest, if there is more than one.
    static func current(in profiles: [Profile]) -> Profile? {
        profiles.min { $0.createdAt < $1.createdAt }
    }
}

/// Whose general conference teachings a study draws on.
enum ConferenceScope: String, CaseIterable, Identifiable, Sendable {
    case core, expanded

    var id: Self { self }

    var title: String {
        switch self {
        case .core: "Emphasize First Presidency & Twelve"
        case .expanded: "Best fit, wherever it's found"
        }
    }

    var note: String {
        switch self {
        case .core: "Quote the current First Presidency and Quorum of the Twelve by default — but never miss an exceptional talk from a broader source when it truly nails the topic."
        case .expanded: "Choose whatever conference talk best addresses the topic across recent years, still giving preference to the current First Presidency and Twelve when the fit is comparable."
        }
    }
}
