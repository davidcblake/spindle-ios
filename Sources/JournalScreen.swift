import PPDesign
import SwiftData
import SwiftUI

/// Everything ever studied, newest first.
///
/// The first screen, and deliberately the one that works with no network, no
/// account and no model: it reads what is already on the phone. Preparing a new
/// study is the only thing in this app that needs anything else.
struct JournalScreen: View {
    @Environment(\.ppTheme) private var theme
    @Query(sort: \JournalEntry.createdAt, order: .reverse) private var entries: [JournalEntry]

    var body: some View {
        NavigationStack {
            Group {
                if entries.isEmpty {
                    PPEmptyState(
                        symbolName: "book.closed",
                        title: "No studies yet",
                        message: "Pick a passage and Spindle will prepare a study of it."
                    )
                } else {
                    list
                }
            }
            .navigationTitle("Journal")
        }
    }

    private var list: some View {
        List(entries) { entry in
            VStack(alignment: .leading, spacing: PPSpacing.extraSmall) {
                Text(entry.reference)
                    .ppText(.cardTitle)
                    .foregroundStyle(theme.textPrimary)
                Text(entry.volume)
                    .ppText(.caption)
                    .foregroundStyle(theme.textSecondary)
            }
        }
    }
}
