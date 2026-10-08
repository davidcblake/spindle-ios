import PPDesign
import SwiftData
import SwiftUI

/// Settings: which study sections show, whose conference teachings are drawn
/// on, and the profile. The web app's `SettingsTab`.
///
/// Changes save as they are made. There is no Save button because there is no
/// server to fail: everything here is written to the phone.
struct SettingsScreen: View {
    @Environment(\.ppTheme) private var theme
    @Bindable var profile: Profile

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    ForEach(StudySection.allCases) { section in
                        Toggle(section.title, isOn: Binding(
                            get: { !profile.hidden.contains(section) },
                            set: { _ in profile.toggle(section) }
                        ))
                    }
                } header: {
                    Text("Study sections")
                } footer: {
                    Text("Choose what appears in your studies. Every study is prepared in full, so anything you switch back on will show up in past journal entries too.")
                }

                Section {
                    Picker("Conference voices", selection: $profile.scope) {
                        ForEach(ConferenceScope.allCases) { scope in
                            Text(scope.title).tag(scope)
                        }
                    }
                    .pickerStyle(.inline)
                    .labelsHidden()
                } header: {
                    Text("General conference voices")
                } footer: {
                    Text(profile.scope.note)
                }

                Section {
                    ProfileFields(profile: profile)
                } header: {
                    Text("Your profile")
                } footer: {
                    Text("Shapes every study you prepare. Everything is optional and stays on your devices until a study is prepared.")
                }
            }
            .tint(theme.accent)
            .navigationTitle("Settings")
        }
    }
}

/// The five things a person can tell Spindle about themselves, with the web
/// app's wording and its length limits. Shared by Settings and Welcome.
struct ProfileFields: View {
    @Environment(\.ppTheme) private var theme
    @Bindable var profile: Profile

    var body: some View {
        field("First name", hint: "So your studies can speak to you by name.",
              placeholder: "Dave", text: $profile.firstName, limit: 100)
        field("Current calling", hint: "Studies get framed for your service — a Primary teacher and a bishop need different things.",
              placeholder: "Counselor in a stake presidency, Relief Society president, no calling right now…",
              text: $profile.calling, limit: 200)
        field("Spiritual season", hint: "New convert, returning, lifelong member, preparing for a mission or the temple…",
              placeholder: "Lifelong member", text: $profile.spiritualSeason, limit: 200)
        field("Family", hint: "Helps invitations to act land in your real life.",
              placeholder: "Married, three kids at home (14, 11, 7)…",
              text: $profile.familyContext, limit: 500, isLong: true)
        field("Study focus", hint: "What are you working toward right now?",
              placeholder: "Preparing Sunday lessons, a question I'm pondering, Come Follow Me pace…",
              text: $profile.studyFocus, limit: 500, isLong: true)
    }

    private func field(
        _ label: String, hint: String, placeholder: String,
        text: Binding<String>, limit: Int, isLong: Bool = false
    ) -> some View {
        VStack(alignment: .leading, spacing: PPSpacing.extraSmall) {
            Text(label)
                .ppText(.caption)
                .fontWeight(.semibold)
            TextField(placeholder, text: Binding(
                get: { text.wrappedValue },
                // The web app's limits, which the server also enforces.
                set: { text.wrappedValue = String($0.prefix(limit)) }
            ), axis: isLong ? .vertical : .horizontal)
            .lineLimit(isLong ? 2... : 1...)
            Text(hint)
                .ppText(.caption)
                .foregroundStyle(theme.textSecondary)
        }
        .padding(.vertical, PPSpacing.extraSmall)
    }
}
