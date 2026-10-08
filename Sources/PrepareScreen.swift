import PPDesign
import SwiftUI

/// Choosing a passage: a volume, then a book, then one or more chapters.
///
/// All taps and no typing, as on the web. The selection bar at the bottom
/// always says what has been chosen, so the person never has to scroll up to
/// check.
struct PrepareScreen: View {
    @Environment(\.ppTheme) private var theme
    @State private var selection = PassageSelection()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: PPSpacing.large) {
                    Text("Choose a passage and prepare a study that traces its people, principles, and doctrine across all four standard works — and shows how each points to the Savior.")
                        .ppText(.body)
                        .foregroundStyle(theme.textSecondary)

                    volumes
                    if !selection.volume.skipsChoosingABook {
                        books
                    }
                    if let book = selection.book {
                        chapters(of: book)
                    }

                    if selection.isLarge {
                        Text("That's a big span — the study will draw it together rather than treat each chapter in depth.")
                            .ppText(.caption)
                            .foregroundStyle(theme.textSecondary)
                    }
                }
                .padding(PPSpacing.screenMargin)
            }
            .background(theme.background)
            .navigationTitle("Prepare")
            .safeAreaInset(edge: .bottom) { selectionBar }
        }
    }

    private var volumes: some View {
        LabelledGroup(label: "Volume") {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: PPSpacing.small)], spacing: PPSpacing.small) {
                ForEach(Scripture.volumes) { volume in
                    Pill(title: volume.name, isChosen: volume == selection.volume) {
                        selection.choose(volume)
                    }
                }
            }
        }
    }

    private var books: some View {
        LabelledGroup(label: "Book") {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 110), spacing: PPSpacing.small)], spacing: PPSpacing.small) {
                ForEach(selection.volume.books, id: \.self) { book in
                    Pill(title: book.name, isChosen: book == selection.book) {
                        selection.choose(book)
                    }
                }
            }
        }
    }

    private func chapters(of book: Book) -> some View {
        let isSections = selection.volume.id == .doctrineAndCovenants
        return LabelledGroup(label: isSections ? "Sections — tap one or more" : "Chapters — tap one or more") {
            VStack(spacing: PPSpacing.small) {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 48), spacing: PPSpacing.small)], spacing: PPSpacing.small) {
                    ForEach(1...book.chapterCount, id: \.self) { chapter in
                        Tile(
                            title: "\(chapter)",
                            isChosen: selection.chapters.contains(chapter),
                            isAvailable: !selection.isFull
                        ) {
                            selection.toggle(chapter: chapter)
                        }
                    }
                }
                ForEach(selection.volume.declarations, id: \.self) { declaration in
                    Tile(
                        title: declaration,
                        isChosen: selection.declarations.contains(declaration),
                        isAvailable: !selection.isFull
                    ) {
                        selection.toggle(declaration: declaration)
                    }
                }
            }
        }
    }

    private var selectionBar: some View {
        HStack(spacing: PPSpacing.medium) {
            Text(selection.isEmpty ? "Nothing selected yet" : selection.reference)
                .ppText(.cardTitle)
                .foregroundStyle(selection.isEmpty ? theme.textSecondary : theme.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .accessibilityAddTraits(.updatesFrequently)
            // Disabled until the study server accepts the app (roadmap,
            // Phase 2). Shown now so the screen is the shape it will be.
            Button("Prepare Study") {}
                .buttonStyle(.ppProminent)
                .fixedSize()
                .disabled(true)
        }
        .padding(PPSpacing.screenMargin)
        .background(theme.surface)
        .overlay(alignment: .top) {
            Rectangle().fill(theme.separator).frame(height: 1)
        }
    }
}

/// A small heading over a group of choices.
private struct LabelledGroup<Content: View>: View {
    @Environment(\.ppTheme) private var theme
    let label: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: PPSpacing.small) {
            Text(label)
                .ppText(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(theme.textSecondary)
                .accessibilityAddTraits(.isHeader)
            content
        }
    }
}

/// A volume or a book. Chosen ones fill with the accent.
private struct Pill: View {
    @Environment(\.ppTheme) private var theme
    let title: String
    let isChosen: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .ppText(.caption)
                .fontWeight(.medium)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .frame(maxWidth: .infinity, minHeight: PPSpacing.minimumTapTarget)
                .padding(.horizontal, PPSpacing.small)
                .foregroundStyle(isChosen ? theme.textOnAccent : theme.textPrimary)
                .background(isChosen ? theme.accent : theme.surface, in: Capsule())
                .overlay(Capsule().strokeBorder(theme.separator, lineWidth: isChosen ? 0 : 1))
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isChosen ? .isSelected : [])
    }
}

/// A chapter, a section, or an Official Declaration. Chosen ones fill with the
/// accent and get the amber ring the web app uses.
private struct Tile: View {
    @Environment(\.ppTheme) private var theme
    let title: String
    let isChosen: Bool
    /// False once the study is full; a chosen tile can always be un-chosen.
    let isAvailable: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .ppText(.body)
                .fontWeight(.semibold)
                .monospacedDigit()
                .frame(maxWidth: .infinity, minHeight: PPSpacing.minimumTapTarget)
                .foregroundStyle(isChosen ? theme.textOnAccent : theme.textPrimary)
                .background(isChosen ? theme.accent : theme.surface, in: RoundedRectangle(cornerRadius: PPRadius.small))
                .overlay(
                    RoundedRectangle(cornerRadius: PPRadius.small)
                        .strokeBorder(isChosen ? AnyShapeStyle(selectionRing) : AnyShapeStyle(theme.separator), lineWidth: isChosen ? 2 : 1)
                )
        }
        .buttonStyle(.plain)
        .disabled(!isChosen && !isAvailable)
        .opacity(!isChosen && !isAvailable ? 0.4 : 1)
        .accessibilityAddTraits(isChosen ? .isSelected : [])
    }
}
