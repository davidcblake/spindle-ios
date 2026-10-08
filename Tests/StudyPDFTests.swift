import CoreGraphics
import Foundation
import Testing
@testable import Spindle

@MainActor
@Suite("Print / Save PDF")
struct StudyPDFTests {
    private let study = Study(
        placement: "p", background: "b",
        people: [.init(name: "Alma", who: "w", elsewhere: "Mosiah 17:2")],
        principles: [.init(principle: "Faith", explanation: "x", elsewhere: "Hebrews 11:1")],
        patterns: [.init(pattern: "Seed", meaning: "m", echoes: "Matthew 13:31")],
        christ: "c",
        conference: [],
        crossRefs: [.init(ref: "Alma 7:11", note: "n")],
        reflection: ["one", "two", "three"],
        invitation: "i",
        anchor: "a"
    )

    @Test("Makes a readable PDF of at least one page")
    func makesAPDF() throws {
        let document = StudyDocument(reference: "Alma 32", volume: "Book of Mormon", date: .now, study: study, hidden: [])
        let url = try document.pdf()
        let pdf = try #require(CGPDFDocument(url as CFURL))
        #expect(pdf.numberOfPages >= 1)
    }
}
