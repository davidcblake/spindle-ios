import Foundation
import Testing
@testable import Spindle

@Suite("Feedback")
struct FeedbackTests {
    @Test("Sent as the server reads it: the words, under \"message\", and nothing else")
    func shape() throws {
        let data = try JSONEncoder().encode(Feedback(message: "A daily reminder, please"))
        let json = try #require(try JSONSerialization.jsonObject(with: data) as? [String: Any])
        #expect(json.count == 1)
        #expect(json["message"] as? String == "A daily reminder, please")
    }

    @Test("Without the server, sending says so plainly")
    func notYet() async {
        await #expect(throws: StudyFailure.notYet) {
            try await NoStudyService().sendFeedback(Feedback(message: "Hello"))
        }
    }
}
