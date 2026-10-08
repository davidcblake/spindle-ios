import PPDesign
import SwiftData
import SwiftUI

/// Welcome on first launch, then the tabs.
///
/// "First launch" means there is no profile yet, exactly as on the web, where
/// a missing profile row is what shows the welcome. Skipping saves an empty
/// profile, so the welcome never comes back.
struct RootView: View {
    @Query private var profiles: [Profile]

    var body: some View {
        if let profile = Profile.current(in: profiles) {
            TabView {
                Tab("Prepare", systemImage: "book") {
                    PrepareScreen()
                }
                Tab("Journal", systemImage: "books.vertical") {
                    JournalScreen(hidden: profile.hidden)
                }
                Tab("Settings", systemImage: "gearshape") {
                    SettingsScreen(profile: profile)
                }
            }
        } else {
            WelcomeScreen()
        }
    }
}

/// The web app's welcome card: an invitation to fill in the profile, every
/// part of it optional.
struct WelcomeScreen: View {
    @Environment(\.ppTheme) private var theme
    @Environment(\.modelContext) private var context
    /// Filled in here and saved only when the person continues or skips.
    @State private var draft = Profile()

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Text("Tell Spindle a little about yourself and every study will be prepared for *you* — your calling, your family, your season of life. Everything is optional, private to you, and editable any time in Settings.")
                        .ppText(.body)
                        .foregroundStyle(theme.textSecondary)
                }
                Section {
                    ProfileFields(profile: draft)
                }
                Section {
                    Button("Continue") { save(draft) }
                        .buttonStyle(.ppProminent)
                    Button("Skip for now") { save(Profile()) }
                        .buttonStyle(.ppQuiet)
                }
                .listRowBackground(Color.clear)
            }
            .tint(theme.accent)
            .navigationTitle("Welcome")
        }
    }

    private func save(_ profile: Profile) {
        profile.createdAt = .now
        context.insert(profile)
    }
}
