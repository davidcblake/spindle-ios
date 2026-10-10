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

extension StudyRequest.Reader {
    @MainActor
    init(_ profile: Profile?) {
        self.init(
            firstName: profile?.firstName ?? "",
            calling: profile?.calling ?? "",
            familyContext: profile?.familyContext ?? "",
            studyFocus: profile?.studyFocus ?? "",
            spiritualSeason: profile?.spiritualSeason ?? "",
            conferenceScope: profile?.conferenceScope ?? ConferenceScope.core.rawValue
        )
    }
}

extension StudyRequest {
    @MainActor
    init(_ selection: PassageSelection, profile: Profile?) {
        volumeId = selection.volume.id.rawValue
        book = selection.chapters.isEmpty ? nil : selection.book?.name
        chapters = selection.chapters.sorted()
        extras = selection.volume.declarations.filter { selection.declarations.contains($0) }
        self.profile = Reader(profile)
    }
}

/// A request for a study plan: what the person wants to study, in their own
/// words, and the same profile a study gets. The server treats the words as a
/// topic, never as instructions (`buildPlanPrompt` in the web app).
struct PlanRequest: Codable, Equatable, Sendable {
    var request: String
    var profile: StudyRequest.Reader

    /// The web app's limits on what can be asked.
    static let shortest = 3
    static let longest = 500
}

/// A plan as the server returns it: the web app's `PlanSchema`.
struct GeneratedPlan: Codable, Equatable, Sendable {
    struct Item: Codable, Equatable, Sendable {
        var title: String
        var subtitle: String
        /// A scripture reference, a talk citation, or empty.
        var reference: String
    }

    var title: String
    var description: String
    var items: [Item]
}

/// The one edge where a study comes from somewhere else. Behind a protocol so
/// every screen can be built and tested without a server (`AGENTS.md`: every
/// network edge can be faked).
protocol StudyService: Sendable {
    func prepare(_ request: StudyRequest) async throws(StudyFailure) -> Study
    func preparePlan(_ request: PlanRequest) async throws(StudyFailure) -> GeneratedPlan
    /// Sends a person's feedback or feature request to Dave. Never shown to a
    /// model (decision `0006` in the Spindle repository).
    func sendFeedback(_ feedback: Feedback) async throws(StudyFailure)
}

extension StudyService {
    /// Only the real server takes feedback; every other service says so.
    func sendFeedback(_ feedback: Feedback) async throws(StudyFailure) {
        throw .notYet
    }
}

/// Feedback as the server takes it: the person's own words, and nothing else.
struct Feedback: Codable, Equatable, Sendable {
    var message: String

    /// The server's limits on what can be sent.
    static let shortest = 3
    static let longest = 2000
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

    func preparePlan(_ request: PlanRequest) async throws(StudyFailure) -> GeneratedPlan {
        throw .notYet
    }
}

/// For tests and previews: hands back whatever it was given.
struct InMemoryStudyService: StudyService {
    var study: Result<Study, StudyFailure> = .failure(.notYet)
    var plan: Result<GeneratedPlan, StudyFailure> = .failure(.notYet)

    func prepare(_ request: StudyRequest) async throws(StudyFailure) -> Study {
        try study.get()
    }

    func preparePlan(_ request: PlanRequest) async throws(StudyFailure) -> GeneratedPlan {
        try plan.get()
    }
}

extension EnvironmentValues {
    @Entry var studyService: any StudyService = NoStudyService()
}
