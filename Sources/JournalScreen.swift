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
    /// Sections switched off in Settings, passed on to each study.
    var hidden: Set<StudySection> = []
    /// The entry waiting on "are you sure?" before it is deleted.
    @State private var deleting: JournalEntry?
    @State private var search = ""

    /// Entries whose passage, verse or thoughts contain what was typed.
    private var shown: [JournalEntry] {
        let query = search.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return entries }
        return entries.filter { entry in
            entry.reference.localizedStandardContains(query)
                || entry.anchor.localizedStandardContains(query)
                || (entry.thoughts ?? []).contains { $0.body.localizedStandardContains(query) }
        }
    }

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
                        .searchable(text: $search, prompt: "Search passages and thoughts")
                        .overlay {
                            if shown.isEmpty {
                                ContentUnavailableView.search(text: search)
                            }
                        }
                }
            }
            .newStudyButton()
            .navigationTitle("Journal")
            .navigationDestination(for: JournalEntry.self) { entry in
                StudyScreen(entry: entry, hidden: hidden)
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
        List(shown) { entry in
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
                .ppText(.scripture)
                .foregroundStyle(theme.textPrimary)
            Text(entry.createdAt.formatted(.dateTime.weekday(.abbreviated).month(.wide).day().year()))
                .ppText(.caption)
                .foregroundStyle(theme.textSecondary)
            if !entry.anchor.isEmpty {
                Text("“\(entry.anchor)”")
                    .ppText(.scriptureQuote)
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
