import Foundation
import PPCore

/// One prepared study: the eleven sections, in the shape the study server
/// returns them.
///
/// This is a contract with the server. Its one definition is `StudySchema` in
/// the web app's `src/lib/study.ts`, and the field names here must match it
/// letter for letter, because the JSON is decoded as it arrives and stored as
/// it arrived.
struct Study: Codable, Hashable, Sendable {
    struct Person: Codable, Hashable, Sendable {
        var name: String
        var who: String
        var elsewhere: String
    }

    struct Principle: Codable, Hashable, Sendable {
        var principle: String
        var explanation: String
        var elsewhere: String
    }

    struct Pattern: Codable, Hashable, Sendable {
        var pattern: String
        var meaning: String
        var echoes: String
    }

    struct Talk: Codable, Hashable, Sendable {
        var speaker: String
        var talk: String
        var session: String
        var point: String
    }

    struct CrossReference: Codable, Hashable, Sendable {
        var ref: String
        var note: String
    }

    var placement: String
    var background: String
    var people: [Person]
    var principles: [Principle]
    var patterns: [Pattern]
    var christ: String
    var conference: [Talk]
    var crossRefs: [CrossReference]
    var reflection: [String]
    var invitation: String
    var anchor: String

    init(
        placement: String, background: String, people: [Person], principles: [Principle],
        patterns: [Pattern], christ: String, conference: [Talk], crossRefs: [CrossReference],
        reflection: [String], invitation: String, anchor: String
    ) {
        self.placement = placement
        self.background = background
        self.people = people
        self.principles = principles
        self.patterns = patterns
        self.christ = christ
        self.conference = conference
        self.crossRefs = crossRefs
        self.reflection = reflection
        self.invitation = invitation
        self.anchor = anchor
    }

    /// Written by hand for one reason: studies prepared before the General
    /// Conference section existed have no `conference`, and they must still
    /// open. The web app guards the same way (`c.conference ?? []`).
    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        placement = try container.decode(String.self, forKey: .placement)
        background = try container.decode(String.self, forKey: .background)
        people = try container.decode([Person].self, forKey: .people)
        principles = try container.decode([Principle].self, forKey: .principles)
        patterns = try container.decode([Pattern].self, forKey: .patterns)
        christ = try container.decode(String.self, forKey: .christ)
        conference = try container.decodeIfPresent([Talk].self, forKey: .conference) ?? []
        crossRefs = try container.decode([CrossReference].self, forKey: .crossRefs)
        reflection = try container.decode([String].self, forKey: .reflection)
        invitation = try container.decode(String.self, forKey: .invitation)
        anchor = try container.decode(String.self, forKey: .anchor)
    }
}

/// The sections, in the order they are read, with the titles the web app
/// gives them. The raw values are the web app's keys for hiding a section.
enum StudySection: String, CaseIterable, Identifiable, Sendable {
    case placement, background, people, principles, patterns, christ, conference
    case crossRefs, reflection, invitation, anchor

    var id: Self { self }

    var title: String {
        switch self {
        case .placement: "Where This Sits"
        case .background: "Background & Context"
        case .people: "People & Connections"
        case .principles: "Principles & Doctrine"
        case .patterns: "Patterns & Types"
        case .christ: "Christ at the Center"
        case .conference: "From General Conference"
        case .crossRefs: "Cross-References"
        case .reflection: "For Reflection"
        case .invitation: "Invitation to Act"
        case .anchor: "Remember This"
        }
    }
}

/// A saved study whose content could not be read back.
struct CouldNotReadTheStudy: PPError {
    var userMessage: String {
        "This study couldn't be opened. It is still in your journal."
    }

    let logMessage: String
}
