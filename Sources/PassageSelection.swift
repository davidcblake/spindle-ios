import Observation

/// What a person has tapped on the Prepare screen so far.
///
/// The rules are the web app's `PrepareTab`: choosing a volume or a book starts
/// the chapters over, and a volume with only one book (the Doctrine and
/// Covenants) chooses that book for you.
@MainActor
@Observable
final class PassageSelection {
    private(set) var volume: Volume
    private(set) var book: Book?
    private(set) var chapters: Set<Int> = []
    private(set) var declarations: Set<String> = []

    init(volume: Volume = Scripture.volumes[0]) {
        self.volume = volume
        book = volume.skipsChoosingABook ? volume.books.first : nil
    }

    func choose(_ volume: Volume) {
        self.volume = volume
        book = volume.skipsChoosingABook ? volume.books.first : nil
        chapters = []
        declarations = []
    }

    func choose(_ book: Book) {
        self.book = book
        chapters = []
        declarations = []
    }

    /// Adds a chapter, or takes it away if it was already chosen. Does nothing
    /// once the study is full, so the server's limit is never reached.
    func toggle(chapter: Int) {
        if chapters.contains(chapter) {
            chapters.remove(chapter)
        } else if !isFull {
            chapters.insert(chapter)
        }
    }

    func toggle(declaration: String) {
        if declarations.contains(declaration) {
            declarations.remove(declaration)
        } else if !isFull {
            declarations.insert(declaration)
        }
    }

    /// What has been chosen, as a study is prepared from it.
    var passage: Passage {
        Passage(volume: volume, book: book, chapters: chapters, declarations: declarations)
    }

    /// "Alma 5–7, 32", or empty when nothing is chosen.
    var reference: String { passage.reference }

    var isEmpty: Bool { chapters.isEmpty && declarations.isEmpty }

    var count: Int { chapters.count + declarations.count }

    var isFull: Bool { count >= Scripture.maximumChapters }

    /// Above ten, the web app warns that the study will draw the span together
    /// rather than go chapter by chapter. Same number here.
    var isLarge: Bool { count > 10 }
}
