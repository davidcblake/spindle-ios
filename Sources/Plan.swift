import Foundation
import SwiftData

/// A study plan: an ordered list of things to study, ticked off over days or
/// weeks. The web app's `study_plans`, kept on the phone and in iCloud.
///
/// Same CloudKit rules as `JournalEntry`: every property has a default, the
/// relationship is optional on both ends.
@Model
final class StudyPlan {
    var title: String = ""
    /// The plan's one-paragraph overview. Not `description`, which every Swift
    /// type already uses for something else.
    var summary: String = ""
    /// What the person asked for, in their words.
    var request: String = ""
    var createdAt: Date = Date.distantPast

    /// Deleting a plan deletes its items, as on the web.
    @Relationship(deleteRule: .cascade, inverse: \PlanItem.plan)
    var items: [PlanItem]? = []

    init(title: String, summary: String, request: String, createdAt: Date = .now) {
        self.title = title
        self.summary = summary
        self.request = request
        self.createdAt = createdAt
    }

    /// The items in the order the plan gives them.
    var orderedItems: [PlanItem] {
        (items ?? []).sorted { $0.position < $1.position }
    }

    var completedCount: Int {
        (items ?? []).filter { $0.completedAt != nil }.count
    }

    /// "3 of 8 complete", the web app's words.
    var progress: String {
        "\(completedCount) of \((items ?? []).count) complete"
    }
}

@Model
final class PlanItem {
    /// One-based, as on the web.
    var position: Int = 0
    var title: String = ""
    var subtitle: String = ""
    var reference: String = ""
    var completedAt: Date?
    var plan: StudyPlan?

    init(position: Int, title: String, subtitle: String, reference: String) {
        self.position = position
        self.title = title
        self.subtitle = subtitle
        self.reference = reference
    }

    var isDone: Bool { completedAt != nil }

    func toggle() {
        completedAt = isDone ? nil : .now
    }
}

extension StudyPlan {
    /// Saves a plan the server prepared, with its items in order.
    @MainActor
    static func save(_ generated: GeneratedPlan, request: String, in context: ModelContext) -> StudyPlan {
        let plan = StudyPlan(title: generated.title, summary: generated.description, request: request)
        context.insert(plan)
        for (index, item) in generated.items.enumerated() {
            let saved = PlanItem(position: index + 1, title: item.title, subtitle: item.subtitle, reference: item.reference)
            context.insert(saved)
            saved.plan = plan
        }
        return plan
    }
}
