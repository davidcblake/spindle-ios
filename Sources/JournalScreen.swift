import PPDesign
import SwiftData
import SwiftUI

/// Everything ever studied, newest first.
///
/// Deliberately the screen that works with no network and no account: it reads
/// what is already on the phone. Preparing a new study is the only thing in
/// this app that needs anything else.
struct JournalScreen: View {
    @Environment(\.ppTheme) private var theme
    @Environment(\.modelContext) private var context
    @Query(sort: \JournalEntry.createdAt, order: .reverse) private var entries: [JournalEntry]
    /// The entry waiting on "are you sure?" before it is deleted.
    @State private var deleting: JournalEntry?

    var body: some View {
        NavigationStack {
            Group {
                if entries.isEmpty {
                    PPEmptyState(
                        symbolName: "book.closed",
                        title: "Your journal is empty",
                        message: "Each study you prepare is saved here automatically, so your understanding compounds day by day."
                    )
                } else {
                    list
                }
            }
            .navigationTitle("Journal")
            .navigationDestination(for: JournalEntry.self) { entry in
                StudyScreen(entry: entry)
            }
        }
        .confirmationDialog(
            "Delete this study?",
            isPresented: Binding(get: { deleting != nil }, set: { if !$0 { deleting = nil } }),
            titleVisibility: .visible,
            presenting: deleting
        ) { entry in
            Button("Delete \(entry.reference)", role: .destructive) {
                context.delete(entry)
                deleting = nil
            }
        } message: { _ in
            Text("This can't be undone.")
        }
    }

    private var list: some View {
        List(entries) { entry in
            NavigationLink(value: entry) {
                row(entry)
            }
            // Not `role: .destructive`: that makes the row slide away before
            // the person has said yes, and slide back if they say no.
            .swipeActions {
                Button("Delete", systemImage: "trash") {
                    deleting = entry
                }
                .tint(theme.danger)
            }
        }
    }

    private func row(_ entry: JournalEntry) -> some View {
        VStack(alignment: .leading, spacing: PPSpacing.extraSmall) {
            Text(entry.reference)
                .ppText(.cardTitle)
                .foregroundStyle(theme.textPrimary)
            Text(entry.createdAt.formatted(.dateTime.weekday(.abbreviated).month(.wide).day().year()))
                .ppText(.caption)
                .foregroundStyle(theme.textSecondary)
            if !entry.anchor.isEmpty {
                Text("“\(entry.anchor)”")
                    .ppText(.caption)
                    .italic()
                    .foregroundStyle(theme.textSecondary)
                    .lineLimit(2)
            }
            if let count = entry.thoughts?.count, count > 0 {
                Label(count == 1 ? "1 thought" : "\(count) thoughts", systemImage: "pencil.line")
                    .ppText(.caption)
                    .foregroundStyle(theme.accent)
            }
        }
        .padding(.vertical, PPSpacing.extraSmall)
    }
}
