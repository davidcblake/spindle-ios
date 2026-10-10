import PPDesign
import SwiftData
import SwiftUI

/// Study plans: describe what to study, get an ordered plan, tick it off.
/// The web app's `PlansTab`, including its "Beta" label and both of its
/// reminders that a plan is AI-prepared.
struct PlansScreen: View {
    @Environment(\.ppTheme) private var theme
    @Environment(\.modelContext) private var context
    @Environment(\.studyService) private var studyService
    @Environment(Connection.self) private var connection: Connection?
    @Query(sort: \StudyPlan.createdAt, order: .reverse) private var plans: [StudyPlan]
    @Query private var profiles: [Profile]
    @State private var request = ""
    @State private var creating = false
    @State private var failure: StudyFailure?
    @State private var opened: StudyPlan?

    private static let examples = [
        "The Savior's teachings in 3 Nephi, one chapter a day",
        "Elder Neal A. Maxwell's best-known conference talks",
        "Mercy across all four standard works",
        "Last general conference, one talk per day",
    ]

    private var isOnline: Bool { connection?.isOnline ?? true }

    private var trimmed: String { request.trimmingCharacters(in: .whitespacesAndNewlines) }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Text("Describe what you'd like to study over the coming days or weeks, and Spindle builds an ordered plan you can check off as you go.")
                        .ppText(.body)
                        .foregroundStyle(theme.textSecondary)
                    TextField("e.g. Mercy across all four standard works…", text: Binding(
                        get: { request },
                        set: { request = String($0.prefix(PlanRequest.longest)) }
                    ), axis: .vertical)
                    .lineLimit(2...)
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: PPSpacing.small) {
                            ForEach(Self.examples, id: \.self) { example in
                                Button(example) { request = example }
                                    .ppText(.caption)
                                    .padding(.horizontal, PPSpacing.medium)
                                    .frame(minHeight: PPSpacing.minimumTapTarget)
                                    .background(theme.accentSoft, in: Capsule())
                                    .buttonStyle(.plain)
                            }
                        }
                    }
                    if let failure {
                        Text(failure.userMessage)
                            .ppText(.caption)
                            .foregroundStyle(theme.danger)
                    }
                    Button(creating ? "Preparing your plan…" : "Create plan") {
                        Task { await create() }
                    }
                    .buttonStyle(.ppProminent)
                    .disabled(creating || trimmed.count < PlanRequest.shortest || !isOnline)
                    if creating {
                        Text("Gathering and ordering the right scriptures and talks — broad topics can take up to a minute. Please keep this screen open.")
                            .ppText(.caption)
                            .foregroundStyle(theme.textSecondary)
                    }
                    if !isOnline {
                        Label("Creating a plan needs a connection.", systemImage: "wifi.slash")
                            .ppText(.caption)
                            .foregroundStyle(theme.textSecondary)
                    }
                } header: {
                    Text("Study plans · Beta")
                }

                Section {
                    if plans.isEmpty {
                        Text("No plans yet. Describe one above — a book to walk through, a topic to trace, a conference to revisit — and start checking off sessions.")
                            .ppText(.caption)
                            .foregroundStyle(theme.textSecondary)
                    }
                    ForEach(plans) { plan in
                        NavigationLink(value: plan) {
                            PlanRow(plan: plan)
                        }
                    }
                } footer: {
                    Label("Plans are AI-prepared and may not be exhaustive — a great start, not an official list.", systemImage: "sparkles")
                }
            }
            .navigationTitle("Plans")
            .navigationDestination(for: StudyPlan.self) { plan in
                PlanScreen(plan: plan)
            }
            .navigationDestination(item: $opened) { plan in
                PlanScreen(plan: plan)
            }
        }
    }

    private func create() async {
        let asked = trimmed
        creating = true
        failure = nil
        defer { creating = false }
        do throws(StudyFailure) {
            let generated = try await studyService.preparePlan(
                PlanRequest(request: asked, profile: StudyRequest.Reader(Profile.current(in: profiles)))
            )
            let plan = StudyPlan.save(generated, request: asked, in: context)
            try? context.save()
            request = ""
            opened = plan
        } catch {
            failure = error
        }
    }
}

private struct PlanRow: View {
    @Environment(\.ppTheme) private var theme
    let plan: StudyPlan

    var body: some View {
        VStack(alignment: .leading, spacing: PPSpacing.extraSmall) {
            Text(plan.title)
                .ppText(.cardTitle)
                .foregroundStyle(theme.textPrimary)
            Text(plan.progress)
                .ppText(.caption)
                .foregroundStyle(theme.textSecondary)
            Text(plan.summary)
                .ppText(.caption)
                .foregroundStyle(theme.textSecondary)
                .lineLimit(2)
            let total = max((plan.items ?? []).count, 1)
            ProgressView(value: Double(plan.completedCount), total: Double(total))
                .tint(theme.accent)
                .accessibilityHidden(true)
        }
        .padding(.vertical, PPSpacing.extraSmall)
    }
}

/// One plan: its items in order, each ticked off with a tap.
struct PlanScreen: View {
    @Environment(\.ppTheme) private var theme
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Bindable var plan: StudyPlan
    @State private var confirmingDelete = false

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: PPSpacing.extraSmall) {
                    Text(plan.title).ppText(.sectionTitle)
                    Text(plan.progress).ppText(.caption).opacity(0.85)
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(PPSpacing.large)
                .background(
                    LinearGradient(colors: [Color(hex: 0x1D2F8F), Color(hex: 0x2B4BD7)], startPoint: .topLeading, endPoint: .bottomTrailing),
                    in: RoundedRectangle(cornerRadius: PPRadius.large)
                )
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)

                Text(GospelLibrary.linked(plan.summary))
                    .ppText(.body)
                    .foregroundStyle(theme.textSecondary)
            }

            Section {
                ForEach(plan.orderedItems) { item in
                    PlanItemRow(item: item)
                }
            }

            Section {
                Button("Delete plan", systemImage: "trash", role: .destructive) {
                    confirmingDelete = true
                }
            } footer: {
                Text("Plans are AI-prepared study outlines — verify talk titles in Gospel Library as you go.")
            }
        }
        .navigationTitle(plan.title)
        .navigationBarTitleDisplayMode(.inline)
        .confirmationDialog("Delete the plan “\(plan.title)”?", isPresented: $confirmingDelete, titleVisibility: .visible) {
            Button("Delete plan", role: .destructive) {
                context.delete(plan)
                dismiss()
            }
        } message: {
            Text("This can't be undone.")
        }
    }
}

private struct PlanItemRow: View {
    @Environment(\.ppTheme) private var theme
    @Bindable var item: PlanItem

    var body: some View {
        HStack(alignment: .top, spacing: PPSpacing.medium) {
            Button {
                item.toggle()
            } label: {
                Image(systemName: item.isDone ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundStyle(item.isDone ? theme.accent : theme.textSecondary)
                    .frame(minWidth: PPSpacing.minimumTapTarget, minHeight: PPSpacing.minimumTapTarget)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(item.isDone ? "Mark “\(item.title)” not done" : "Mark “\(item.title)” done")

            VStack(alignment: .leading, spacing: PPSpacing.extraSmall) {
                Text(GospelLibrary.linked(item.title))
                    .ppText(.cardTitle)
                    .strikethrough(item.isDone)
                    .foregroundStyle(item.isDone ? theme.textSecondary : theme.textPrimary)
                if !item.subtitle.isEmpty {
                    Text(GospelLibrary.linked(item.subtitle))
                        .ppText(.caption)
                        .foregroundStyle(theme.textSecondary)
                }
                if !item.reference.isEmpty, item.reference != item.title {
                    Text(GospelLibrary.linked(item.reference))
                        .ppText(.caption)
                }
            }
        }
    }
}
