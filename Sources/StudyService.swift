import Foundation
import PPCore
import SwiftUI

/// What the phone sends to have a study prepared: the passage chosen, and the
/// profile the server uses to tailor it.
///
/// The shape is `docs/decisions/0003` in the Spindle repository, and the
/// profile's keys are the web app's database columns, because the server feeds
/// them to the same `describeReader()` that guards them.
struct StudyRequest: Codable, Equatable, Sendable {
    struct Reader: Codable, Equatable, Sendable {
        var firstName = ""
        var calling = ""
        var familyContext = ""
        var studyFocus = ""
        var spiritualSeason = ""
        var conferenceScope = ConferenceScope.core.rawValue

        enum CodingKeys: String, CodingKey {
            case firstName = "first_name"
            case calling
            case familyContext = "family_context"
            case studyFocus = "study_focus"
            case spiritualSeason = "spiritual_season"
            case conferenceScope = "conference_scope"
        }
    }

    var volumeId: String
    var book: String?
    var chapters: [Int]
    var extras: [String]
    var profile: Reader
}

extension StudyRequest {
    @MainActor
    init(_ selection: PassageSelection, profile: Profile?) {
        volumeId = selection.volume.id.rawValue
        book = selection.chapters.isEmpty ? nil : selection.book?.name
        chapters = selection.chapters.sorted()
        extras = selection.volume.declarations.filter { selection.declarations.contains($0) }
        self.profile = Reader(
            firstName: profile?.firstName ?? "",
            calling: profile?.calling ?? "",
            familyContext: profile?.familyContext ?? "",
            studyFocus: profile?.studyFocus ?? "",
            spiritualSeason: profile?.spiritualSeason ?? "",
            conferenceScope: profile?.conferenceScope ?? ConferenceScope.core.rawValue
        )
    }
}

/// The one edge where a study comes from somewhere else. Behind a protocol so
/// every screen can be built and tested without a server (`AGENTS.md`: every
/// network edge can be faked).
protocol StudyService: Sendable {
    func prepare(_ request: StudyRequest) async throws(StudyFailure) -> Study
}

/// Why a study could not be prepared, in the web app's words where it has them.
struct StudyFailure: PPError, Equatable {
    let userMessage: String
    let logMessage: String

    init(_ userMessage: String, log: String? = nil) {
        self.userMessage = userMessage
        self.logMessage = log ?? userMessage
    }

    static let unreachable = StudyFailure("Couldn't reach the study service — check your connection.")
    static let tooSlow = StudyFailure("That study took longer than expected — check your connection and tap Prepare Study again.")
    static let notYet = StudyFailure("Preparing a study isn't switched on in this build yet. Everything already in your journal works.")
}

/// The honest default: says plainly that it cannot prepare anything.
struct NoStudyService: StudyService {
    func prepare(_ request: StudyRequest) async throws(StudyFailure) -> Study {
        throw .notYet
    }
}

/// For tests and previews: hands back whatever it was given.
struct InMemoryStudyService: StudyService {
    let result: Result<Study, StudyFailure>

    func prepare(_ request: StudyRequest) async throws(StudyFailure) -> Study {
        try result.get()
    }
}

extension EnvironmentValues {
    @Entry var studyService: any StudyService = NoStudyService()
}
