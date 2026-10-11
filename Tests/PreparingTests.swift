import Foundation
import SwiftData
import Testing
@testable import Spindle

/// Reading a journal entry's words back into a passage, so a fresh study can
/// be asked for exactly as the Prepare screen would ask.
@Suite("Reading a passage back")
struct PassageTests {
    @Test("Every book, written out and read back, is the same passage")
    func everyBook() throws {
        for volume in Scripture.volumes {
            for book in volume.books {
                let chapters: Set<Int> = book.hasOneChapter ? [1] : [1, book.chapterCount]
                let passage = Passage(volume: volume, book: book, chapters: chapters)
                #expect(Passage(reference: passage.reference, volume: volume.name) == passage, "\(passage.reference)")
            }
        }
    }

    @Test("Runs and single chapters together")
    func runs() throws {
        let passage = try #require(Passage(reference: "Alma 5–7, 32", volume: "Book of Mormon"))
        #expect(passage.book?.name == "Alma")
        #expect(passage.chapters == [5, 6, 7, 32])
    }

    @Test("Sections with a declaration, and a declaration on its own")
    func declarations() throws {
        let both = try #require(Passage(reference: "Doctrine and Covenants 137–138; Official Declaration 1", volume: "Doctrine and Covenants"))
        #expect(both.chapters == [137, 138])
        #expect(both.declarations == ["Official Declaration 1"])
        let alone = try #require(Passage(reference: "Official Declaration 2", volume: "Doctrine and Covenants"))
        #expect(alone.chapters.isEmpty)
        #expect(alone.declarations == ["Official Declaration 2"])
    }

    @Test("Anything this app would not have written is refused, not guessed at")
    func refused() {
        #expect(Passage(reference: "Alma 64", volume: "Book of Mormon") == nil)
        #expect(Passage(reference: "Alma", volume: "Book of Mormon") == nil)
        #expect(Passage(reference: "Alma 7–5", volume: "Book of Mormon") == nil)
        #expect(Passage(reference: "Alma 32", volume: "Old Testament") == nil)
        #expect(Passage(reference: "Alma 32", volume: "Nothing") == nil)
        #expect(Passage(reference: "", volume: "Book of Mormon") == nil)
    }
}

/// Prepare once, keep it, and prepare again only when asked.
@MainActor
@Suite("Reusing a study")
struct ReusingTests {
    private let study = Study(
        placement: "p", background: "b",
        people: [], principles: [], patterns: [],
        christ: "c", conference: [], crossRefs: [],
        reflection: [], invitation: "i", anchor: "Plant the seed."
    )

    private func journal() throws -> ModelContainer {
        let memoryOnly = ModelConfiguration(isStoredInMemoryOnly: true)
        return try ModelContainer(for: JournalEntry.self, Thought.self, configurations: memoryOnly)
    }

    private let alma32 = Passage(reference: "Alma 32", volume: "Book of Mormon")!

    @Test("The newest study of the passage is the one opened")
    func newest() throws {
        let container = try journal()
        let context = container.mainContext
        context.insert(JournalEntry(reference: "Alma 32", volume: "Book of Mormon", anchor: "older", createdAt: .now.addingTimeInterval(-60)))
        context.insert(JournalEntry(reference: "Alma 32", volume: "Book of Mormon", anchor: "newer"))
        context.insert(JournalEntry(reference: "Alma 33", volume: "Book of Mormon", anchor: "other"))
        try context.save()
        #expect(JournalEntry.latest(of: alma32, in: context)?.anchor == "newer")
    }

    @Test("A passage never studied has nothing to open")
    func nothing() throws {
        let container = try journal()
        #expect(JournalEntry.latest(of: alma32, in: container.mainContext) == nil)
    }

    @Test("A fresh study is saved beside the earlier one, which is kept")
    func fresh() async throws {
        let container = try journal()
        let context = container.mainContext
        context.insert(JournalEntry(reference: "Alma 32", volume: "Book of Mormon", anchor: "older", createdAt: .now.addingTimeInterval(-60)))
        try context.save()
        let entry = try await JournalEntry.prepare(alma32, profile: nil, using: Answers(study: study), in: context)
        #expect(entry.anchor == "Plant the seed.")
        #expect(entry.passage == alma32)
        #expect(try context.fetchCount(FetchDescriptor<JournalEntry>()) == 2)
        #expect(JournalEntry.latest(of: alma32, in: context) == entry)
    }
}

/// A study service that always answers with the same study.
private struct Answers: StudyService {
    let study: Study

    func prepare(_ request: StudyRequest) async throws(StudyFailure) -> Study { study }

    func preparePlan(_ request: PlanRequest) async throws(StudyFailure) -> GeneratedPlan {
        throw .notYet
    }
}
