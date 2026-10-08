import Foundation
import Testing
@testable import Spindle

/// The request has to match decision `0003` byte for byte in its keys, or the
/// server will refuse it.
@MainActor
@Suite("Asking for a study")
struct StudyRequestTests {
    private func json(_ request: StudyRequest) throws -> [String: Any] {
        let data = try JSONEncoder().encode(request)
        return try #require(try JSONSerialization.jsonObject(with: data) as? [String: Any])
    }

    @Test("Chapters go in order, with the book and the volume's id")
    func chapters() throws {
        let selection = PassageSelection()
        selection.choose(Scripture.volume(.bookOfMormon).books.first { $0.name == "Alma" }!)
        for chapter in [32, 5, 7, 6] { selection.toggle(chapter: chapter) }
        let request = StudyRequest(selection, profile: nil)
        #expect(request.volumeId == "bofm")
        #expect(request.book == "Alma")
        #expect(request.chapters == [5, 6, 7, 32])
        #expect(request.extras.isEmpty)
    }

    @Test("A declaration on its own sends no book, as the web app does")
    func declarationOnly() {
        let selection = PassageSelection()
        selection.choose(Scripture.volume(.doctrineAndCovenants))
        selection.toggle(declaration: "Official Declaration 2")
        let request = StudyRequest(selection, profile: nil)
        #expect(request.volumeId == "dc")
        #expect(request.book == nil)
        #expect(request.extras == ["Official Declaration 2"])
    }

    @Test("The profile goes under the web app's column names")
    func profileKeys() throws {
        let profile = Profile()
        profile.firstName = "Dave"
        profile.scope = .expanded
        let selection = PassageSelection()
        selection.choose(Scripture.volume(.bookOfMormon).books.first { $0.name == "Enos" }!)
        selection.toggle(chapter: 1)

        let sent = try json(StudyRequest(selection, profile: profile))
        let reader = try #require(sent["profile"] as? [String: Any])
        #expect(Set(reader.keys) == [
            "first_name", "calling", "family_context", "study_focus", "spiritual_season", "conference_scope",
        ])
        #expect(reader["first_name"] as? String == "Dave")
        #expect(reader["conference_scope"] as? String == "expanded")
        #expect(Set(sent.keys).isSuperset(of: ["volumeId", "chapters", "extras", "profile"]))
    }

    @Test("With no server in the build, preparing says so plainly")
    func notYet() async {
        let request = StudyRequest(volumeId: "bofm", book: "Enos", chapters: [1], extras: [], profile: .init())
        await #expect(throws: StudyFailure.notYet) {
            try await NoStudyService().prepare(request)
        }
    }
}
