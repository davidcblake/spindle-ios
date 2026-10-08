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
    @State private var connection = Connection()
    /// Where studies are prepared. With no server named in the build, the app
    /// says so plainly instead of calling one that is not there — the server
    /// side of decision `0003` is not built yet.
    private let studyService: any StudyService = { () -> any StudyService in
        let address = BundleConfiguration().string("SpindleServer", default: "")
        guard let server = URL(string: address), !address.isEmpty else { return NoStudyService() }
        return AppAttestStudyService(server: server)
    }()

    init() {
        journal = Result {
            // On this device only, for now. Sync turns on with `.synced` once
            // the CloudKit container is entitled and signed — see docs/roadmap.md.
            // Shipping `.synced` before then would trade a working app for a
            // launch crash on every phone without the entitlement.
            try PPModelStore.container(for: [JournalEntry.self, Thought.self, Profile.self], kind: .thisDeviceOnly)
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
            RootView()
                .tint(PPTheme.spindle.accent)
                .environment(connection)
                .environment(\.studyService, studyService)
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
