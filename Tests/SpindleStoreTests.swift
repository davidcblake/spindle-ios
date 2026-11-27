import PPData
import SwiftData
import Testing
@testable import Spindle

@Suite("The store")
struct SpindleStoreTests {
    @Test("Syncs to the container ticked on the App ID")
    func container() {
        #expect(SpindleStore.cloudKitContainer == "iCloud.com.wpv.spindle")
    }

    @Test("Every model the app saves opens in one store")
    func everyModel() throws {
        let names = SpindleStore.models.map { String(describing: $0) }.sorted()
        #expect(names == ["JournalEntry", "PlanItem", "Profile", "StudyPlan", "Thought"])
        _ = try PPModelStore.container(for: SpindleStore.models, kind: .temporary)
    }
}
