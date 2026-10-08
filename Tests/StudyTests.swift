import Foundation
import Testing
@testable import Spindle

@Suite("Reading a study")
struct StudyTests {
    /// A study in the shape the server sends, with the conference section.
    private let json = """
    {
      "placement": "p", "background": "b",
      "people": [{ "name": "n", "who": "w", "elsewhere": "e" }],
      "principles": [{ "principle": "p", "explanation": "x", "elsewhere": "e" }],
      "patterns": [{ "pattern": "p", "meaning": "m", "echoes": "e" }],
      "christ": "c",
      "conference": [{ "speaker": "s", "talk": "t", "session": "April 2014", "point": "pt" }],
      "crossRefs": [{ "ref": "Alma 7:11", "note": "n" }],
      "reflection": ["one", "two", "three"],
      "invitation": "i",
      "anchor": "a"
    }
    """

    @Test("Reads every section the server sends")
    func everySection() throws {
        let study = try JSONDecoder().decode(Study.self, from: Data(json.utf8))
        #expect(study.anchor == "a")
        #expect(study.conference.first?.session == "April 2014")
        #expect(study.reflection.count == 3)
    }

    @Test("A study from before the conference section still opens")
    func beforeConference() throws {
        let older = json.replacingOccurrences(
            of: #""conference": [{ "speaker": "s", "talk": "t", "session": "April 2014", "point": "pt" }],"#,
            with: ""
        )
        #expect(!older.contains("conference"))
        let study = try JSONDecoder().decode(Study.self, from: Data(older.utf8))
        #expect(study.conference.isEmpty)
    }

    @Test("What is read can be written and read again unchanged")
    func roundTrip() throws {
        let study = try JSONDecoder().decode(Study.self, from: Data(json.utf8))
        let again = try JSONDecoder().decode(Study.self, from: JSONEncoder().encode(study))
        #expect(again == study)
    }

    @Test("Sections are in the web app's order, with its keys")
    func sectionOrder() {
        #expect(StudySection.allCases.map(\.rawValue) == [
            "placement", "background", "people", "principles", "patterns", "christ",
            "conference", "crossRefs", "reflection", "invitation", "anchor",
        ])
    }
}
