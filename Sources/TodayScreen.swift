import PPDesign
import SwiftData
import SwiftUI

/// The first tab: a greeting by name, the verse from the last study, and the
/// next session of the plan in progress. Nothing more.
///
/// Everything here is read from the phone. A person with no studies and no
/// plans sees the greeting and the way to start one.
struct TodayScreen: View {
    @Environment(\.ppTheme) private var theme
    @Query(sort: \JournalEntry.createdAt, order: .reverse) private var entries: [JournalEntry]
    @Query(sort: \StudyPlan.createdAt, order: .reverse) private var plans: [StudyPlan]
    @Bindable var profile: Profile
    @State private var showingSettings = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: PPSpacing.large) {
                    greeting
                    if let last = entries.first, !last.anchor.isEmpty {
                        lastVerse(last)
                    }
                    if let plan = planInProgress, let next = plan.orderedItems.first(where: { !$0.isDone }) {
                        planCard(plan, next: next)
                    }
                    if entries.isEmpty {
                        Text("Tap + to choose a passage. Spindle prepares a study that traces its people, principles and doctrine across all four standard works, and shows how each points to the Savior.")
                            .ppText(.body)
                            .foregroundStyle(theme.textSecondary)
                    }
                }
                .padding(PPSpacing.screenMargin)
            }
            .background(theme.background)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    profileButton
                }
            }
            .navigationDestination(for: JournalEntry.self) { entry in
                StudyScreen(entry: entry, hidden: profile.hidden)
            }
            .navigationDestination(for: StudyPlan.self) { plan in
                PlanScreen(plan: plan)
            }
            .newStudyButton()
        }
        .sheet(isPresented: $showingSettings) {
            SettingsScreen(profile: profile)
        }
    }

    /// The newest plan with something left in it.
    private var planInProgress: StudyPlan? {
        plans.first { $0.completedCount < ($0.items ?? []).count }
    }

    private var name: String {
        profile.firstName.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// "Hey Dave." — the name from the welcome screen, as the person wrote it.
    private var greeting: some View {
        VStack(alignment: .leading, spacing: PPSpacing.extraSmall) {
            Text(Date.now.formatted(.dateTime.weekday(.wide).month(.wide).day()))
                .ppText(.caption)
                .fontWeight(.semibold)
                .textCase(.uppercase)
                .tracking(0.6)
                .foregroundStyle(theme.textSecondary)
            Text(name.isEmpty ? "Hey there." : "Hey \(name).")
                .ppText(.screenTitle)
                .foregroundStyle(theme.textPrimary)
            Text("What do you want to study today?")
                .ppText(.sectionTitle)
                .foregroundStyle(theme.textSecondary)
        }
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isHeader)
    }

    private func lastVerse(_ entry: JournalEntry) -> some View {
        NavigationLink(value: entry) {
            VStack(alignment: .leading, spacing: PPSpacing.medium) {
                Label("From your last study", systemImage: "sparkles")
                    .ppText(.caption)
                    .fontWeight(.semibold)
                    .textCase(.uppercase)
                    .tracking(0.6)
                    .foregroundStyle(selectionRing)
                Text("“\(entry.anchor)”")
                    .ppText(.scripture)
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                HStack {
                    Text(entry.reference)
                        .ppText(.caption)
                        .foregroundStyle(.white.opacity(0.7))
                    Spacer()
                    Label("Open study", systemImage: "arrow.right")
                        .labelStyle(TrailingIcon())
                        .ppText(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                }
            }
            .padding(PPSpacing.large)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(verseBlock, in: RoundedRectangle(cornerRadius: PPRadius.large))
        }
        .buttonStyle(.plain)
    }

    private func planCard(_ plan: StudyPlan, next: PlanItem) -> some View {
        let total = max((plan.items ?? []).count, 1)
        return VStack(alignment: .leading, spacing: PPSpacing.small) {
            HStack(alignment: .firstTextBaseline) {
                Text("Your plan")
                    .ppText(.sectionTitle)
                    .foregroundStyle(theme.textPrimary)
                Spacer()
                Text("\(plan.completedCount) of \(total)")
                    .ppText(.caption)
                    .monospacedDigit()
                    .foregroundStyle(theme.textSecondary)
            }
            NavigationLink(value: plan) {
                PPCard {
                    VStack(alignment: .leading, spacing: PPSpacing.small) {
                        Text(plan.title)
                            .ppText(.caption)
                            .foregroundStyle(theme.textSecondary)
                        ProgressView(value: Double(plan.completedCount), total: Double(total))
                            .tint(theme.accent)
                            .accessibilityHidden(true)
                        Text(next.title)
                            .ppText(.scripture)
                            .foregroundStyle(theme.textPrimary)
                            .multilineTextAlignment(.leading)
                        if !next.subtitle.isEmpty {
                            Text(next.subtitle)
                                .ppText(.caption)
                                .foregroundStyle(theme.textSecondary)
                                .multilineTextAlignment(.leading)
                        }
                    }
                }
            }
            .buttonStyle(.plain)
        }
    }

    /// The person's initial in a blue circle, or a person symbol before they
    /// have given a name.
    private var profileButton: some View {
        Button {
            showingSettings = true
        } label: {
            Group {
                if let initial = name.first {
                    Text(String(initial).uppercased())
                        .ppText(.cardTitle)
                } else {
                    Image(systemName: "person.fill")
                }
            }
            .foregroundStyle(theme.textOnAccent)
            .frame(width: 34, height: 34)
            .background(theme.accent, in: Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Profile and settings")
    }
}

/// A label with its icon after the words: "Open study →".
private struct TrailingIcon: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: PPSpacing.extraSmall) {
            configuration.title
            configuration.icon
        }
    }
}
