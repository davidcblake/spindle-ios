import Testing
@testable import Spindle

/// The rules of the web app's Prepare tab.
@MainActor
@Suite("Choosing a passage")
struct PassageSelectionTests {
    private func book(_ name: String, in id: Volume.ID) -> Book {
        Scripture.volume(id).books.first { $0.name == name }!
    }

    @Test("Starts on the Book of Mormon with nothing chosen")
    func start() {
        let selection = PassageSelection()
        #expect(selection.volume.id == .bookOfMormon)
        #expect(selection.book == nil)
        #expect(selection.isEmpty)
        #expect(selection.reference == "")
    }

    @Test("Choosing the Doctrine and Covenants chooses its one book")
    func doctrineAndCovenants() {
        let selection = PassageSelection()
        selection.choose(Scripture.volume(.doctrineAndCovenants))
        #expect(selection.book?.name == "Doctrine and Covenants")
    }

    @Test("Chapters build the reference as they are tapped")
    func reference() {
        let selection = PassageSelection()
        selection.choose(book("Alma", in: .bookOfMormon))
        for chapter in [32, 5, 6, 7] {
            selection.toggle(chapter: chapter)
        }
        #expect(selection.reference == "Alma 5–7, 32")
    }

    @Test("Tapping a chosen chapter again un-chooses it")
    func untoggle() {
        let selection = PassageSelection()
        selection.choose(book("Alma", in: .bookOfMormon))
        selection.toggle(chapter: 5)
        selection.toggle(chapter: 5)
        #expect(selection.isEmpty)
    }

    @Test("Changing the book starts the chapters over")
    func changingBook() {
        let selection = PassageSelection()
        selection.choose(book("Alma", in: .bookOfMormon))
        selection.toggle(chapter: 5)
        selection.choose(book("Helaman", in: .bookOfMormon))
        #expect(selection.isEmpty)
    }

    @Test("Changing the volume starts everything over")
    func changingVolume() {
        let selection = PassageSelection()
        selection.choose(Scripture.volume(.doctrineAndCovenants))
        selection.toggle(chapter: 138)
        selection.toggle(declaration: "Official Declaration 1")
        selection.choose(Scripture.volume(.newTestament))
        #expect(selection.book == nil)
        #expect(selection.isEmpty)
    }

    @Test("Sections and a declaration together")
    func sectionsAndDeclaration() {
        let selection = PassageSelection()
        selection.choose(Scripture.volume(.doctrineAndCovenants))
        selection.toggle(chapter: 137)
        selection.toggle(chapter: 138)
        selection.toggle(declaration: "Official Declaration 1")
        #expect(selection.reference == "Doctrine and Covenants 137–138; Official Declaration 1")
    }

    @Test("Stops at twenty, the server's limit, but still lets one go")
    func full() {
        let selection = PassageSelection()
        selection.choose(book("Alma", in: .bookOfMormon))
        for chapter in 1...25 {
            selection.toggle(chapter: chapter)
        }
        #expect(selection.count == 20)
        #expect(selection.isFull)
        selection.toggle(chapter: 20)
        #expect(selection.count == 19)
    }

    @Test("Warns above ten, as the web app does")
    func large() {
        let selection = PassageSelection()
        selection.choose(book("Alma", in: .bookOfMormon))
        for chapter in 1...10 {
            selection.toggle(chapter: chapter)
        }
        #expect(!selection.isLarge)
        selection.toggle(chapter: 11)
        #expect(selection.isLarge)
    }
}
