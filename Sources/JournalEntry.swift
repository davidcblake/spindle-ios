import Foundation
import SwiftData

/// One prepared study, kept on the phone.
///
/// The web app stores this in Postgres. Here it lives in SwiftData and is
/// mirrored to the person's own iCloud — `docs/decisions/0001` in the Spindle
/// repository, which decided that a scripture journal should not sit on a
/// server anybody operates.
///
/// **Every property has a default and nothing is unique, on purpose.** CloudKit
/// refuses a schema with a property it cannot fill in for a record that was
/// already on the server, and it cannot enforce uniqueness across devices that
/// have not spoken to each other yet. A store that breaks those rules opens
/// fine as `.temporary` in a test and fails on somebody's phone.
@Model
final class JournalEntry {
    /// What was studied, as a person would say it: "3 Nephi 8".
    var reference: String = ""
    /// Which of the standard works it came from.
    var volume: String = ""
    /// The one line the study hangs on.
    var anchor: String = ""
    var createdAt: Date = Date.distantPast

    /// The study itself, as the JSON the API returned.
    ///
    /// Stored as encoded bytes rather than modelled out, because the shape is a
    /// contract with the server (`docs/spindle-prd.md` §6.2) and decoding it
    /// into types is the next piece of work, not this one. Naming it honestly
    /// beats a half-modelled version that has to be migrated twice.
    var content: Data = Data()

    /// Deleting a study deletes its thoughts, as on the web.
    @Relationship(deleteRule: .cascade, inverse: \Thought.entry)
    var thoughts: [Thought]? = []

    init(reference: String, volume: String, anchor: String = "", createdAt: Date = .now, content: Data = Data()) {
        self.reference = reference
        self.volume = volume
        self.anchor = anchor
        self.createdAt = createdAt
        self.content = content
    }
}

/// A person's own note on a study: what stood out, what the Spirit taught.
///
/// The web app's `entry_notes`. Same CloudKit rules as `JournalEntry`: every
/// property has a default, and the link back to the study is optional because
/// CloudKit can deliver a thought before the study it belongs to.
@Model
final class Thought {
    var body: String = ""
    var createdAt: Date = Date.distantPast
    var entry: JournalEntry?

    init(body: String, createdAt: Date = .now) {
        self.body = body
        self.createdAt = createdAt
    }
}
