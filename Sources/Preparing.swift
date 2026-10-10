import Foundation
import SwiftData

/// Preparing a study once, and keeping it.
///
/// A study is tailored to the person — their calling, family and season of
/// life — so nobody else's copy will do. But once a person has a study of a
/// passage, choosing that passage again opens it rather than paying for the
/// same study twice. A fresh one is prepared only when the person asks for it
/// with the refresh button, and the earlier one stays in the journal.
/// Decided by Dave, 2026-10-10.
extension JournalEntry {
    /// The newest study of exactly this passage, if the journal has one.
    @MainActor
    static func latest(of passage: Passage, in context: ModelContext) -> JournalEntry? {
        let reference = passage.reference
        let volume = passage.volume.name
        var newestFirst = FetchDescriptor<JournalEntry>(
            predicate: #Predicate { $0.reference == reference && $0.volume == volume },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        newestFirst.fetchLimit = 1
        return try? context.fetch(newestFirst).first
    }

    /// Asks the server for a study, saves it to the journal, and only then
    /// hands it back — the web app's promise that a prepared study is never
    /// only on screen.
    @MainActor
    static func prepare(
        _ passage: Passage,
        profile: Profile?,
        using service: any StudyService,
        in context: ModelContext
    ) async throws(StudyFailure) -> JournalEntry {
        let study = try await service.prepare(StudyRequest(passage, profile: profile))
        do {
            let entry = JournalEntry(
                reference: passage.reference,
                volume: passage.volume.name,
                anchor: study.anchor,
                content: try JSONEncoder().encode(study)
            )
            context.insert(entry)
            try context.save()
            return entry
        } catch {
            throw StudyFailure("The study was prepared but couldn't be saved — tap again.", log: String(describing: error))
        }
    }

    /// The passage this study was prepared from, so a fresh one can be asked
    /// for. Nil only for an entry this app could not have written.
    var passage: Passage? { Passage(reference: reference, volume: volume) }
}
