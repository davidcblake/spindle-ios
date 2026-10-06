import Testing
@testable import Spindle

/// The web app's tests from `src/lib/__tests__/scripture.test.ts`, carried
/// across so both apps are held to the same answers.
@Suite("Writing out a passage")
struct ReferenceTests {
    private let bookOfMormon = Scripture.volume(.bookOfMormon)
    private let doctrineAndCovenants = Scripture.volume(.doctrineAndCovenants)

    @Test("Runs of chapters join with an en dash")
    func runs() {
        #expect(Scripture.chapterRanges([5, 6, 7, 32]) == "5–7, 32")
        #expect(Scripture.chapterRanges([1, 2, 5, 6, 9]) == "1–2, 5–6, 9")
    }

    @Test("A single chapter is just its number")
    func singleChapter() {
        #expect(Scripture.chapterRanges([8]) == "8")
    }

    @Test("Order of tapping makes no difference")
    func order() {
        #expect(Scripture.chapterRanges([3, 1, 2]) == "1–3")
    }

    @Test("Alma 5, 6, 7 and 32 read as Alma 5–7, 32")
    func alma() {
        let alma = bookOfMormon.books.first { $0.name == "Alma" }
        let reference = Scripture.reference(book: alma, chapters: [5, 6, 7, 32], declarations: [], in: bookOfMormon)
        #expect(reference == "Alma 5–7, 32")
    }

    @Test("A book with one chapter is written without a number")
    func enos() {
        let enos = bookOfMormon.books.first { $0.name == "Enos" }
        #expect(Scripture.reference(book: enos, chapters: [1], declarations: [], in: bookOfMormon) == "Enos")
    }

    @Test("Sections and a declaration join with a semicolon")
    func sectionsAndDeclaration() {
        let reference = Scripture.reference(
            book: doctrineAndCovenants.books.first,
            chapters: [137, 138],
            declarations: ["Official Declaration 1"],
            in: doctrineAndCovenants
        )
        #expect(reference == "Doctrine and Covenants 137–138; Official Declaration 1")
    }

    @Test("A declaration on its own")
    func declarationAlone() {
        let reference = Scripture.reference(
            book: doctrineAndCovenants.books.first,
            chapters: [],
            declarations: ["Official Declaration 2"],
            in: doctrineAndCovenants
        )
        #expect(reference == "Official Declaration 2")
    }

    @Test("Declarations come out in order, however they were tapped")
    func declarationOrder() {
        let reference = Scripture.reference(
            book: nil,
            chapters: [],
            declarations: ["Official Declaration 2", "Official Declaration 1"],
            in: doctrineAndCovenants
        )
        #expect(reference == "Official Declaration 1; Official Declaration 2")
    }

    @Test("Nothing chosen writes nothing")
    func nothing() {
        #expect(Scripture.reference(book: nil, chapters: [], declarations: [], in: bookOfMormon) == "")
    }
}

@Suite("The standard works")
struct ScriptureDataTests {
    @Test("Five volumes with the right number of books")
    func bookCounts() {
        #expect(Scripture.volumes.count == 5)
        #expect(Scripture.volume(.oldTestament).books.count == 39)
        #expect(Scripture.volume(.newTestament).books.count == 27)
        #expect(Scripture.volume(.bookOfMormon).books.count == 15)
        #expect(Scripture.volume(.pearlOfGreatPrice).books.count == 5)
    }

    @Test("Chapter counts match the canon")
    func chapterCounts() {
        func chapters(_ volume: Volume.ID, _ book: String) -> Int? {
            Scripture.volume(volume).books.first { $0.name == book }?.chapterCount
        }
        #expect(chapters(.oldTestament, "Psalms") == 150)
        #expect(chapters(.oldTestament, "Isaiah") == 66)
        #expect(chapters(.bookOfMormon, "Alma") == 63)
        #expect(chapters(.newTestament, "Revelation") == 22)
        #expect(chapters(.doctrineAndCovenants, "Doctrine and Covenants") == 138)
    }

    @Test("Every volume the server knows by name is here")
    func everyVolume() {
        for id in Volume.ID.allCases {
            #expect(Scripture.volumes.contains { $0.id == id })
        }
    }

    /// The web app keeps a hand-written list of these. Here it is worked out
    /// from the chapter counts, so this checks the two still agree.
    @Test("The books written without a chapter number are the web app's list")
    func oneChapterBooks() {
        let worked = Set(Scripture.volumes.flatMap(\.books).filter(\.hasOneChapter).map(\.name))
        let webList: Set = [
            "Enos", "Jarom", "Omni", "Words of Mormon", "4 Nephi", "Philemon",
            "2 John", "3 John", "Jude", "Obadiah",
            "Joseph Smith—Matthew", "Joseph Smith—History", "Articles of Faith",
        ]
        #expect(worked == webList)
    }

    @Test("Only the Doctrine and Covenants skips choosing a book")
    func skipsChoosingABook() {
        let skipping = Scripture.volumes.filter(\.skipsChoosingABook).map(\.id)
        #expect(skipping == [.doctrineAndCovenants])
    }
}
