import Foundation
import Testing
@testable import Spindle

/// The web app's tests from `src/lib/__tests__/links.test.ts`.
@Suite("Links into Gospel Library")
struct GospelLibraryTests {
    @Test("A verse range")
    func verseRange() {
        #expect(GospelLibrary.url(book: "Alma", chapter: "7", verse: "11", throughVerse: "12")?.absoluteString
            == "https://www.churchofjesuschrist.org/study/scriptures/bofm/alma/7?lang=eng&id=p11-p12#p11")
    }

    @Test("A single verse")
    func singleVerse() {
        #expect(GospelLibrary.url(book: "Hebrews", chapter: "4", verse: "15")?.absoluteString
            == "https://www.churchofjesuschrist.org/study/scriptures/nt/heb/4?lang=eng&id=p15#p15")
    }

    @Test("A whole chapter")
    func chapter() {
        #expect(GospelLibrary.url(book: "3 Nephi", chapter: "10")?.absoluteString
            == "https://www.churchofjesuschrist.org/study/scriptures/bofm/3-ne/10?lang=eng")
    }

    @Test("D&C")
    func doctrineAndCovenants() {
        #expect(GospelLibrary.url(book: "D&C", chapter: "122", verse: "8")?.absoluteString
            == "https://www.churchofjesuschrist.org/study/scriptures/dc-testament/dc/122?lang=eng&id=p8#p8")
    }

    @Test("A book Gospel Library does not have")
    func unknownBook() {
        #expect(GospelLibrary.url(book: "Hezekiah", chapter: "1") == nil)
    }

    @Test("References inside prose are linked, and the text is unchanged")
    func prose() {
        let text = "His conversion is recounted in Mosiah 27:8-31 and Alma 36:6-24."
        let segments = GospelLibrary.segments(of: text)
        #expect(segments.filter { $0.url != nil }.map(\.text) == ["Mosiah 27:8-31", "Alma 36:6-24"])
        #expect(segments.map(\.text).joined() == text)
    }

    @Test("En-dash verse ranges")
    func enDash() {
        let segments = GospelLibrary.segments(of: "See Alma 7:11–12 for the doctrine.")
        #expect(segments.first { $0.url != nil }?.text == "Alma 7:11–12")
    }

    @Test("Longer book names win")
    func longerNames() {
        let segments = GospelLibrary.segments(of: "Compare 1 Nephi 3:7 and 2 Nephi 25:26.")
        #expect(segments.filter { $0.url != nil }.map(\.text) == ["1 Nephi 3:7", "2 Nephi 25:26"])
    }

    @Test("Doctrine and Covenants by its full name")
    func fullName() {
        let segments = GospelLibrary.segments(of: "Doctrine and Covenants 122:8 teaches this.")
        #expect(segments.first { $0.url != nil }?.url?.absoluteString.contains("/dc-testament/dc/122") == true)
    }

    @Test("Text with no references comes back whole")
    func noReferences() {
        #expect(GospelLibrary.segments(of: "No references here.") == [.init(text: "No references here.")])
    }

    @Test("A talk citation")
    func talk() {
        let citation = GospelLibrary.talk(in: #"Elder David A. Bednar — "Bear Up Their Burdens with Ease" (April 2014)"#)
        #expect(citation?.speaker == "Elder David A. Bednar")
        #expect(citation?.talk == "Bear Up Their Burdens with Ease")
    }

    @Test("Curly quotes")
    func curlyQuotes() {
        let citation = GospelLibrary.talk(in: "President Russell M. Nelson — “Think Celestial!” (October 2023)")
        #expect(citation?.speaker == "President Russell M. Nelson")
        #expect(citation?.talk == "Think Celestial!")
    }

    @Test("A scripture reference is not a talk")
    func scriptureIsNotATalk() {
        #expect(GospelLibrary.talk(in: "Alma 42:13-25") == nil)
        #expect(GospelLibrary.talk(in: "Doctrine and Covenants 6:9; 64:7") == nil)
    }

    @Test("Prose with a dash and a parenthesis is not a talk")
    func proseIsNotATalk() {
        #expect(GospelLibrary.talk(in: "faith — and hope — unto salvation (see Alma 32)") == nil)
    }

    @Test("A talk needs a year")
    func needsAYear() {
        #expect(GospelLibrary.talk(in: #"Someone — "A Title" (a devotional)"#) == nil)
    }

    @Test("Talks link to a conference search")
    func search() {
        let address = GospelLibrary.searchURL(speaker: "Elder David A. Bednar", talk: "Bear Up Their Burdens with Ease").absoluteString
        #expect(address.contains("churchofjesuschrist.org/search"))
        #expect(address.contains("facet=general-conference"))
        #expect(address.contains("Bear%20Up%20Their%20Burdens%20with%20Ease"))
    }
}
