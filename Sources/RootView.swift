import PPDesign
import SwiftData
import SwiftUI

/// Welcome on first launch, then the tabs.
///
/// "First launch" means there is no profile yet, exactly as on the web, where
/// a missing profile row is what shows the welcome. Skipping saves an empty
/// profile, so the welcome never comes back.
///
/// Three tabs: Today, Journal and Plans. Starting a study is the round button
/// on Today and Journal, and Settings is behind the profile button on Today.
struct RootView: View {
    @Query private var profiles: [Profile]

    var body: some View {
        if let profile = Profile.current(in: profiles) {
            TabView {
                Tab("Today", systemImage: "sun.max") {
                    TodayScreen(profile: profile)
                }
                Tab("Journal", systemImage: "book.closed") {
                    JournalScreen(hidden: profile.hidden)
                }
                Tab("Plans", systemImage: "checklist") {
                    PlansScreen()
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
            .navigationTitle("Welcome to Spindle")
        }
    }

    private func save(_ profile: Profile) {
        profile.createdAt = .now
        context.insert(profile)
    }
}

extension View {
    /// The round button that starts a new study, floating above the tab bar,
    /// and the sheet it opens.
    func newStudyButton() -> some View {
        modifier(NewStudyButton())
    }
}

private struct NewStudyButton: ViewModifier {
    @Environment(\.ppTheme) private var theme
    @State private var choosing = false

    func body(content: Content) -> some View {
        content
            .safeAreaInset(edge: .bottom, alignment: .trailing) {
                Button {
                    choosing = true
                } label: {
                    Image(systemName: "plus")
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(theme.textOnAccent)
                        .frame(width: 60, height: 60)
                        .background(theme.accent, in: Circle())
                        .shadow(color: .black.opacity(0.18), radius: 12, y: 6)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("New study")
                .padding(PPSpacing.screenMargin)
            }
            .sheet(isPresented: $choosing) {
                PrepareScreen()
            }
    }
}
