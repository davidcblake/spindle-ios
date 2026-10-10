/// The standard works, as far as choosing a passage needs to know them: the
/// volumes, their books, and how many chapters each book has.
///
/// Copied from the web app's `src/lib/scripture.ts`, which copied it from the
/// prototype that was checked by hand. The server checks every selection
/// against its own copy of this table, so the two must agree — a chapter this
/// table allows and the server's does not is a study that fails to prepare.
enum Scripture {
    /// The most chapters one study can cover. The server refuses more, so the
    /// picker stops a person here rather than letting the server say no.
    static let maximumChapters = 20

    static let volumes: [Volume] = [
        Volume(
            id: .bookOfMormon,
            name: "Book of Mormon",
            books: [
                Book("1 Nephi", 22), Book("2 Nephi", 33), Book("Jacob", 7), Book("Enos", 1),
                Book("Jarom", 1), Book("Omni", 1), Book("Words of Mormon", 1), Book("Mosiah", 29),
                Book("Alma", 63), Book("Helaman", 16), Book("3 Nephi", 30), Book("4 Nephi", 1),
                Book("Mormon", 9), Book("Ether", 15), Book("Moroni", 10),
            ]
        ),
        Volume(
            id: .oldTestament,
            name: "Old Testament",
            books: [
                Book("Genesis", 50), Book("Exodus", 40), Book("Leviticus", 27), Book("Numbers", 36),
                Book("Deuteronomy", 34), Book("Joshua", 24), Book("Judges", 21), Book("Ruth", 4),
                Book("1 Samuel", 31), Book("2 Samuel", 24), Book("1 Kings", 22), Book("2 Kings", 25),
                Book("1 Chronicles", 29), Book("2 Chronicles", 36), Book("Ezra", 10),
                Book("Nehemiah", 13), Book("Esther", 10), Book("Job", 42), Book("Psalms", 150),
                Book("Proverbs", 31), Book("Ecclesiastes", 12), Book("Song of Solomon", 8),
                Book("Isaiah", 66), Book("Jeremiah", 52), Book("Lamentations", 5),
                Book("Ezekiel", 48), Book("Daniel", 12), Book("Hosea", 14), Book("Joel", 3),
                Book("Amos", 9), Book("Obadiah", 1), Book("Jonah", 4), Book("Micah", 7),
                Book("Nahum", 3), Book("Habakkuk", 3), Book("Zephaniah", 3), Book("Haggai", 2),
                Book("Zechariah", 14), Book("Malachi", 4),
            ]
        ),
        Volume(
            id: .newTestament,
            name: "New Testament",
            books: [
                Book("Matthew", 28), Book("Mark", 16), Book("Luke", 24), Book("John", 21),
                Book("Acts", 28), Book("Romans", 16), Book("1 Corinthians", 16),
                Book("2 Corinthians", 13), Book("Galatians", 6), Book("Ephesians", 6),
                Book("Philippians", 4), Book("Colossians", 4), Book("1 Thessalonians", 5),
                Book("2 Thessalonians", 3), Book("1 Timothy", 6), Book("2 Timothy", 4),
                Book("Titus", 3), Book("Philemon", 1), Book("Hebrews", 13), Book("James", 5),
                Book("1 Peter", 5), Book("2 Peter", 3), Book("1 John", 5), Book("2 John", 1),
                Book("3 John", 1), Book("Jude", 1), Book("Revelation", 22),
            ]
        ),
        Volume(
            id: .doctrineAndCovenants,
            name: "Doctrine and Covenants",
            books: [Book("Doctrine and Covenants", 138)],
            declarations: ["Official Declaration 1", "Official Declaration 2"]
        ),
        Volume(
            id: .pearlOfGreatPrice,
            name: "Pearl of Great Price",
            books: [
                Book("Moses", 8), Book("Abraham", 5), Book("Joseph Smith—Matthew", 1),
                Book("Joseph Smith—History", 1), Book("Articles of Faith", 1),
            ]
        ),
    ]

    static func volume(_ id: Volume.ID) -> Volume {
        // Every case of `Volume.ID` has an entry above, and a test checks it.
        volumes.first { $0.id == id }!
    }

    /// A passage written the way a person would say it: "Alma 5–7, 32", "Enos",
    /// "Doctrine and Covenants 137–138; Official Declaration 1".
    ///
    /// Declarations come out in the volume's own order rather than the order
    /// they were tapped. The web app keeps the tap order, so the same two
    /// declarations could be written two ways; nobody would choose that.
    static func reference(book: Book?, chapters: Set<Int>, declarations: Set<String>, in volume: Volume) -> String {
        var pieces: [String] = []
        if let book, !chapters.isEmpty {
            if book.hasOneChapter && chapters == [1] {
                pieces.append(book.name)
            } else {
                pieces.append("\(book.name) \(chapterRanges(chapters))")
            }
        }
        pieces += volume.declarations.filter { declarations.contains($0) }
        return pieces.joined(separator: "; ")
    }

    /// Runs of chapters joined with an en dash: 5, 6, 7 and 32 become "5–7, 32".
    static func chapterRanges(_ chapters: Set<Int>) -> String {
        var runs: [String] = []
        var remaining = chapters.sorted()[...]
        while let first = remaining.popFirst() {
            var last = first
            while remaining.first == last + 1 {
                last = remaining.removeFirst()
            }
            runs.append(first == last ? "\(first)" : "\(first)–\(last)")
        }
        return runs.joined(separator: ", ")
    }
}

/// One of the five volumes of scripture.
struct Volume: Identifiable, Hashable, Sendable {
    /// The raw values are what the study server expects in a request, so they
    /// must not change.
    enum ID: String, CaseIterable, Sendable {
        case bookOfMormon = "bofm"
        case oldTestament = "ot"
        case newTestament = "nt"
        case doctrineAndCovenants = "dc"
        case pearlOfGreatPrice = "pgp"
    }

    let id: ID
    let name: String
    let books: [Book]
    /// Only the Doctrine and Covenants has these; they are chosen alongside
    /// its sections rather than as chapters of a book.
    var declarations: [String] = []

    /// The Doctrine and Covenants is one book, so the picker skips straight to
    /// its sections.
    var skipsChoosingABook: Bool { books.count == 1 }
}

/// A book of scripture and how many chapters it has.
struct Book: Hashable, Sendable {
    let name: String
    let chapterCount: Int

    init(_ name: String, _ chapterCount: Int) {
        self.name = name
        self.chapterCount = chapterCount
    }

    /// Enos, Jude, Articles of Faith and the like are written without a
    /// chapter number.
    var hasOneChapter: Bool { chapterCount == 1 }
}

/// A chosen passage, with nothing left to tap: what a study is prepared from.
struct Passage: Hashable, Sendable {
    var volume: Volume
    var book: Book?
    var chapters: Set<Int> = []
    var declarations: Set<String> = []

    /// "Alma 5–7, 32", the words a journal entry keeps.
    var reference: String {
        Scripture.reference(book: book, chapters: chapters, declarations: declarations, in: volume)
    }

    /// The passage a journal entry was prepared from, read back out of its
    /// words — the reverse of `reference`.
    ///
    /// A journal entry keeps only "Alma 5–7, 32" and "Book of Mormon", and a
    /// fresh study of it has to be asked for the way the Prepare screen asks:
    /// by volume, book and chapters. Nil for anything this app would not have
    /// written, rather than a guess the server might prepare the wrong study
    /// from.
    init?(reference: String, volume volumeName: String) {
        guard let volume = Scripture.volumes.first(where: { $0.name == volumeName }) else { return nil }
        self.volume = volume
        for piece in reference.components(separatedBy: "; ") {
            if volume.declarations.contains(piece) {
                declarations.insert(piece)
                continue
            }
            // Only one book per passage, and declarations come after it.
            guard book == nil, declarations.isEmpty, let read = Self.read(piece, in: volume) else { return nil }
            book = read.book
            chapters = read.chapters
        }
        guard !chapters.isEmpty || !declarations.isEmpty else { return nil }
    }

    init(volume: Volume, book: Book? = nil, chapters: Set<Int> = [], declarations: Set<String> = []) {
        self.volume = volume
        self.book = book
        self.chapters = chapters
        self.declarations = declarations
    }

    /// "Alma 5–7, 32" → Alma and its chapters. The longest book name that
    /// fits wins, so "Joseph Smith—History" is never read as a shorter book.
    private static func read(_ piece: String, in volume: Volume) -> (book: Book, chapters: Set<Int>)? {
        for book in volume.books.sorted(by: { $0.name.count > $1.name.count }) {
            if piece == book.name {
                return book.hasOneChapter ? (book, [1]) : nil
            }
            guard piece.hasPrefix(book.name + " ") else { continue }
            var chapters: Set<Int> = []
            for run in piece.dropFirst(book.name.count + 1).components(separatedBy: ", ") {
                let ends = run.components(separatedBy: "–").map { Int($0) }
                guard let first = ends.first ?? nil, let last = ends.last ?? nil, ends.count <= 2,
                      1 <= first, first <= last, last <= book.chapterCount
                else { return nil }
                chapters.formUnion(first...last)
            }
            return (book, chapters)
        }
        return nil
    }
}
