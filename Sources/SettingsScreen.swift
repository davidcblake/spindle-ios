import PPDesign
import PPNotify
import SwiftData
import SwiftUI

/// Settings: which study sections show, whose conference teachings are drawn
/// on, and the profile. The web app's `SettingsTab`.
///
/// Changes save as they are made. There is no Save button because there is no
/// server to fail: everything here is written to the phone. Opened as a sheet
/// from the profile button on Today, so Done only closes it.
struct SettingsScreen: View {
    @Environment(\.ppTheme) private var theme
    @Environment(\.dismiss) private var dismiss
    @Environment(\.reminders) private var reminders
    @Bindable var profile: Profile
    /// Why the reminder could not be set, in words for a person.
    @State private var reminderProblem: String?

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
                    Toggle("Remind me to study", isOn: Binding(
                        get: { profile.remindsDaily },
                        set: { on in
                            profile.remindsDaily = on
                            Task { await applyReminder() }
                        }
                    ))
                    if profile.remindsDaily {
                        DatePicker("Time", selection: reminderTime, displayedComponents: .hourAndMinute)
                    }
                    if let reminderProblem {
                        Text(reminderProblem)
                            .ppText(.caption)
                            .foregroundStyle(theme.textSecondary)
                    }
                } header: {
                    Text("Daily reminder")
                } footer: {
                    Text("A gentle nudge each day at the time you choose. It's set on your iPhone; nothing is sent anywhere.")
                }

                Section {
                    NavigationLink("Send feedback or an idea") {
                        FeedbackScreen()
                    }
                } footer: {
                    Text("Something not working, or a feature you'd love? It goes straight to the person who makes Spindle.")
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
            .onChange(of: profile.firstName) {
                // The reminder greets the person by name.
                if profile.remindsDaily { Task { await applyReminder() } }
            }
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

extension SettingsScreen {
    /// The reminder time as a picker wants it; saving reschedules.
    private var reminderTime: Binding<Date> {
        Binding(
            get: {
                Calendar.current.date(bySettingHour: profile.reminderHour, minute: profile.reminderMinute, second: 0, of: .now) ?? .now
            },
            set: { time in
                let parts = Calendar.current.dateComponents([.hour, .minute], from: time)
                profile.reminderHour = parts.hour ?? 7
                profile.reminderMinute = parts.minute ?? 0
                Task { await applyReminder() }
            }
        )
    }

    /// Schedules the reminder as the profile now says, or cancels it. If it
    /// cannot be set (notifications turned off), the switch goes back off
    /// and says why.
    private func applyReminder() async {
        reminderProblem = nil
        guard profile.remindsDaily else {
            await reminders.cancel(id: DailyReminder.id)
            return
        }
        do {
            try await reminders.schedule(DailyReminder.reminder(for: profile))
        } catch let failure as NotifyFailure {
            profile.remindsDaily = false
            reminderProblem = failure.userMessage
        } catch {
            profile.remindsDaily = false
            reminderProblem = "The reminder couldn't be set. Try again in a moment."
        }
    }
}

/// The five things a person can tell Spindle about themselves, with the web
/// app's wording and its length limits. Shared by Settings and Welcome.
struct ProfileFields: View {
    @Environment(\.ppTheme) private var theme
    @Bindable var profile: Profile

    var body: some View {
        field("What should we call you?", hint: "Spindle greets you by this name, and your studies speak to you by it. A nickname is fine.",
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
