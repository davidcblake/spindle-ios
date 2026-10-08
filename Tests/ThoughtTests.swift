import Foundation
import SwiftData
import Testing
@testable import Spindle

@MainActor
@Suite("My Thoughts")
struct ThoughtTests {
    /// The container is kept alive by the caller; a context outliving its
    /// container is a crash, not a failed test.
    private func journal() throws -> ModelContainer {
        // Straight from SwiftData rather than through PPData, so the test
        // bundle does not need the package linked a second time.
        let memoryOnly = ModelConfiguration(isStoredInMemoryOnly: true)
        return try ModelContainer(for: JournalEntry.self, Thought.self, configurations: memoryOnly)
    }

    @Test("A thought belongs to its study")
    func belongs() throws {
        let container = try journal()
        let context = container.mainContext
        let entry = JournalEntry(reference: "Alma 32", volume: "Book of Mormon")
        context.insert(entry)
        let thought = Thought(body: "Plant the seed.")
        context.insert(thought)
        thought.entry = entry
        try context.save()
        #expect(entry.thoughts?.map(\.body) == ["Plant the seed."])
    }

    @Test("Deleting a study deletes its thoughts")
    func cascade() throws {
        let container = try journal()
        let context = container.mainContext
        let entry = JournalEntry(reference: "Alma 32", volume: "Book of Mormon")
        context.insert(entry)
        let thought = Thought(body: "Plant the seed.")
        context.insert(thought)
        thought.entry = entry
        try context.save()

        context.delete(entry)
        try context.save()
        #expect(try context.fetchCount(FetchDescriptor<Thought>()) == 0)
    }
}
