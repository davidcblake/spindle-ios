import Foundation
import SwiftData
import Testing
@testable import Spindle

@MainActor
@Suite("Study plans")
struct PlanTests {
    private let generated = GeneratedPlan(
        title: "Mercy",
        description: "Mercy across the standard works.",
        items: [
            .init(title: "Alma 42", subtitle: "Justice and mercy", reference: "Alma 42:15"),
            .init(title: "Luke 15", subtitle: "The prodigal son", reference: "Luke 15:20"),
            .init(title: "Moses 7", subtitle: "Enoch sees God weep", reference: ""),
        ]
    )

    private func store() throws -> ModelContainer {
        try ModelContainer(
            for: StudyPlan.self, PlanItem.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
    }

    @Test("A prepared plan is saved with its items in order")
    func saved() throws {
        let container = try store()
        let plan = StudyPlan.save(generated, request: "mercy", in: container.mainContext)
        try container.mainContext.save()
        #expect(plan.orderedItems.map(\.position) == [1, 2, 3])
        #expect(plan.orderedItems.map(\.title) == ["Alma 42", "Luke 15", "Moses 7"])
        #expect(plan.summary == "Mercy across the standard works.")
    }

    @Test("Ticking items off counts towards the plan, in the web app's words")
    func progress() throws {
        let container = try store()
        let plan = StudyPlan.save(generated, request: "mercy", in: container.mainContext)
        #expect(plan.progress == "0 of 3 complete")
        plan.orderedItems[0].toggle()
        #expect(plan.progress == "1 of 3 complete")
        plan.orderedItems[0].toggle()
        #expect(plan.progress == "0 of 3 complete")
    }

    @Test("Deleting a plan deletes its items")
    func cascade() throws {
        let container = try store()
        let context = container.mainContext
        let plan = StudyPlan.save(generated, request: "mercy", in: context)
        try context.save()
        context.delete(plan)
        try context.save()
        #expect(try context.fetchCount(FetchDescriptor<PlanItem>()) == 0)
    }

    @Test("A plan request carries the profile under the web app's names")
    func request() throws {
        let sent = try JSONEncoder().encode(PlanRequest(request: "mercy", profile: .init()))
        let json = try #require(try JSONSerialization.jsonObject(with: sent) as? [String: Any])
        #expect(json["request"] as? String == "mercy")
        #expect((json["profile"] as? [String: Any])?["conference_scope"] as? String == "core")
    }
}
