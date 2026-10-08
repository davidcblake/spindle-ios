import PPCore
import PPData
import PPDesign
import SwiftData
import SwiftUI

/// Spindle for iPhone.
///
/// Native SwiftUI on the Plug and Play foundation, with no sign-in: iCloud is
/// the account, and the journal lives on the phone. The reasoning is in
/// `docs/decisions/0001-native-rebuild-on-plug-and-play.md` in the Spindle
/// repository.
@main
struct SpindleApp: App {
    /// The journal, or the reason it could not be opened.
    ///
    /// Not a `try!`. A store that fails to open is what an app looks like after
    /// a bad migration, and to the person holding it a crash on launch is
    /// indistinguishable from having lost everything they wrote. So the failure
    /// is carried to a screen that says what happened.
    private let journal: Result<ModelContainer, any Error>

    init() {
        journal = Result {
            // On this device only, for now. Sync turns on with `.synced` once
            // the CloudKit container is entitled and signed — see docs/roadmap.md.
            // Shipping `.synced` before then would trade a working app for a
            // launch crash on every phone without the entitlement.
            try PPModelStore.container(for: [JournalEntry.self], kind: .thisDeviceOnly)
        }
    }

    var body: some Scene {
        WindowGroup {
            content
                .ppTheme(.spindle)
        }
    }

    @ViewBuilder
    private var content: some View {
        switch journal {
        case .success(let container):
            TabView {
                Tab("Prepare", systemImage: "book") {
                    PrepareScreen()
                }
                Tab("Journal", systemImage: "books.vertical") {
                    JournalScreen()
                }
            }
            .tint(PPTheme.spindle.accent)
            .modelContainer(container)
        case .failure(let error):
            PPErrorView(error: CouldNotOpenTheJournal(logMessage: String(describing: error)))
        }
    }
}

/// The two voices `PPCore` asks for: one a person reads, one the log keeps.
struct CouldNotOpenTheJournal: PPError {
    var userMessage: String {
        "Spindle couldn't open your journal on this phone."
    }

    let logMessage: String
}
