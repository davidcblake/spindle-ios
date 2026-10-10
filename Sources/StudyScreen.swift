import PPDesign
import SwiftData
import SwiftUI

/// A saved study, read back from the phone exactly as it was prepared.
///
/// No network: everything here comes from the journal entry. The layout is the
/// web app's `StudyView` — a reference plate, then the eleven sections in
/// order, with every scripture reference and talk opening in Gospel Library.
///
/// The refresh button is the one thing here that needs the network: it
/// prepares a fresh study of the same passage and shows that instead. The
/// study it replaces on screen stays in the journal (`Preparing.swift`).
struct StudyScreen: View {
    @Environment(\.ppTheme) private var theme
    @Environment(\.modelContext) private var context
    @Environment(\.studyService) private var studyService
    @Environment(Connection.self) private var connection: Connection?
    @Query private var profiles: [Profile]
    /// A thought being written, not yet saved.
    @State private var draft = ""
    /// The study on screen: the one opened, until a fresh one replaces it.
    @State private var entry: JournalEntry
    @State private var askingToRefresh = false
    @State private var refreshing = false
    @State private var failure: StudyFailure?
    /// Sections the person has chosen not to see. Hiding changes only what is
    /// shown; the study keeps every section, as on the web.
    let hidden: Set<StudySection>

    init(entry: JournalEntry, hidden: Set<StudySection> = []) {
        _entry = State(initialValue: entry)
        self.hidden = hidden
    }

    var body: some View {
        Group {
            switch Result(catching: { try JSONDecoder().decode(Study.self, from: entry.content) }) {
            case .success(let study):
                ScrollView {
                    VStack(alignment: .leading, spacing: PPSpacing.large) {
                        StudyPlate(reference: entry.reference, volume: entry.volume, date: entry.createdAt)
                        ForEach(StudySection.allCases.filter { !hidden.contains($0) }) { section in
                            StudySectionView(section: section, study: study)
                        }
                        thoughts
                        StudyFooter()
                    }
                    .padding(PPSpacing.screenMargin)
                }
                .toolbar {
                    Button("Prepare a fresh study", systemImage: "arrow.clockwise") {
                        askingToRefresh = true
                    }
                    .disabled(refreshing || entry.passage == nil || !(connection?.isOnline ?? true))
                    ShareLink(
                        item: StudyDocument(reference: entry.reference, volume: entry.volume, date: entry.createdAt, study: study, hidden: hidden),
                        preview: SharePreview(entry.reference)
                    ) {
                        Label("Print / Save PDF", systemImage: "printer")
                    }
                }
            case .failure(let error):
                PPErrorView(error: CouldNotReadTheStudy(logMessage: String(describing: error)))
            }
        }
        .overlay {
            if refreshing {
                PreparingView(reference: entry.reference)
                    .background(theme.background)
            }
        }
        .background(theme.background)
        .navigationTitle(entry.reference)
        .navigationBarTitleDisplayMode(.inline)
        .confirmationDialog(
            "Prepare a fresh study of \(entry.reference)?",
            isPresented: $askingToRefresh,
            titleVisibility: .visible
        ) {
            Button("Prepare a fresh study") {
                Task { await refresh() }
            }
        } message: {
            Text("You'll get a new perspective on the same passage. This study stays in your journal.")
        }
        .alert(
            "Couldn't prepare a fresh study",
            isPresented: Binding(get: { failure != nil }, set: { if !$0 { failure = nil } }),
            presenting: failure
        ) { _ in
            Button("OK") {}
        } message: { failure in
            Text(failure.userMessage)
        }
    }

    private func refresh() async {
        guard let passage = entry.passage else { return }
        refreshing = true
        defer { refreshing = false }
        do throws(StudyFailure) {
            entry = try await JournalEntry.prepare(
                passage,
                profile: Profile.current(in: profiles),
                using: studyService,
                in: context
            )
            draft = ""
        } catch {
            failure = error
        }
    }

    /// My Thoughts: the person's own notes, oldest first, then a place to add
    /// another. The keyboard's microphone works here, which is how the web
    /// app suggests dictating.
    private var thoughts: some View {
        VStack(alignment: .leading, spacing: PPSpacing.small) {
            Text("MY THOUGHTS")
                .ppText(.caption)
                .fontWeight(.bold)
                .tracking(0.8)
                .foregroundStyle(theme.accent)
                .accessibilityAddTraits(.isHeader)
            ForEach((entry.thoughts ?? []).sorted { $0.createdAt < $1.createdAt }) { thought in
                VStack(alignment: .leading, spacing: PPSpacing.extraSmall) {
                    Text(GospelLibrary.linked(thought.body))
                        .ppText(.body)
                        .foregroundStyle(theme.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                    HStack {
                        Text(thought.createdAt.formatted(date: .abbreviated, time: .shortened))
                            .ppText(.caption)
                            .foregroundStyle(theme.textSecondary)
                        Spacer()
                        Button("Delete this thought", systemImage: "trash") {
                            context.delete(thought)
                        }
                        .labelStyle(.iconOnly)
                        .foregroundStyle(theme.textSecondary)
                        .frame(minWidth: PPSpacing.minimumTapTarget, minHeight: PPSpacing.minimumTapTarget)
                    }
                }
                .padding(PPSpacing.medium)
                .background(theme.surface, in: RoundedRectangle(cornerRadius: PPRadius.medium))
            }
            TextField(
                "What stood out? What is the Spirit teaching you? Type, or tap the mic on your keyboard and speak…",
                text: $draft,
                axis: .vertical
            )
            .lineLimit(3...)
            .ppText(.body)
            .padding(PPSpacing.medium)
            .background(theme.surface, in: RoundedRectangle(cornerRadius: PPRadius.medium))
            .overlay(RoundedRectangle(cornerRadius: PPRadius.medium).strokeBorder(theme.separator))
            .onChange(of: draft) { _, text in
                // The web app's limit, so a thought is the same size in both.
                if text.count > Self.longestThought { draft = String(text.prefix(Self.longestThought)) }
            }
            Button("Add to my journal", systemImage: "pencil.line") {
                addThought()
            }
            .buttonStyle(.ppQuiet)
            .disabled(draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
    }

    private static let longestThought = 10_000

    private func addThought() {
        let body = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !body.isEmpty else { return }
        let thought = Thought(body: body)
        context.insert(thought)
        thought.entry = entry
        draft = ""
    }
}
