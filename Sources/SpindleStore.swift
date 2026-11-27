import CoreData
import Foundation
import PPData
import SwiftData

/// Where Spindle keeps what a person saves: on the phone, mirrored to their
/// own private iCloud so a second iPhone or a new one has the same journal.
///
/// Nothing here reaches Spindle's server. CloudKit's private database can be
/// read only by the person whose iCloud it is.
enum SpindleStore {
    /// The container ticked on the `com.wpv.spindle` App ID in the developer
    /// portal. Must match it and the entitlements in `project.yml` exactly.
    static let cloudKitContainer = "iCloud.com.wpv.spindle"

    /// Every model the app saves. A type left out is a crash the first time
    /// something tries to save one.
    static var models: [any PersistentModel.Type] {
        [JournalEntry.self, Thought.self, Profile.self, StudyPlan.self, PlanItem.self]
    }

    /// The synced store, or, if that will not open, the same store on this
    /// phone only, so a sync problem never costs anyone their journal. iCloud
    /// being signed out is not a failure: the store opens and simply waits.
    static func open() throws -> ModelContainer {
        do {
            return try PPModelStore.container(for: models, kind: .syncedTo(container: cloudKitContainer))
        } catch {
            return try PPModelStore.container(for: models, kind: .thisDeviceOnly)
        }
    }

    #if DEBUG
    /// Teaches the CloudKit *development* environment every record type and
    /// field, including ones no record has filled in yet (a plan item not yet
    /// ticked off, a thought not yet written). Runs in builds from Xcode only,
    /// once per build number, against a scratch file so the real journal is
    /// never touched.
    ///
    /// After it has run, the schema must be deployed to production in the
    /// CloudKit Console, or TestFlight and App Store copies cannot sync. That
    /// step is Dave's: `docs/your-checklist.md`.
    ///
    /// This is Apple's documented way to do it for SwiftData ("Syncing model
    /// data across a person's devices"): SwiftData has no call of its own.
    static func prepareCloudKitSchema() {
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "?"
        let key = "cloudKitSchemaPreparedForBuild"
        guard UserDefaults.standard.string(forKey: key) != build else { return }
        let container = cloudKitContainer
        Task.detached(priority: .background) {
            do {
                try initializeSchema(container: container)
                UserDefaults.standard.set(build, forKey: key)
                print("Spindle: CloudKit development schema prepared for build \(build).")
            } catch {
                print("Spindle: CloudKit schema not prepared (is this phone signed in to iCloud?): \(error)")
            }
        }
    }

    private static func initializeSchema(container: String) throws {
        guard let model = NSManagedObjectModel.makeManagedObjectModel(for: models) else { return }
        let scratch = FileManager.default.temporaryDirectory.appending(path: "cloudkit-schema.store")
        let description = NSPersistentStoreDescription(url: scratch)
        description.cloudKitContainerOptions = NSPersistentCloudKitContainerOptions(containerIdentifier: container)
        description.shouldAddStoreAsynchronously = false
        let cloud = NSPersistentCloudKitContainer(name: "SpindleSchema", managedObjectModel: model)
        cloud.persistentStoreDescriptions = [description]
        // Loads synchronously (above); an empty coordinator means it failed.
        cloud.loadPersistentStores { _, _ in }
        guard !cloud.persistentStoreCoordinator.persistentStores.isEmpty else {
            throw SchemaStoreDidNotOpen()
        }
        try cloud.initializeCloudKitSchema()
        for store in cloud.persistentStoreCoordinator.persistentStores {
            try cloud.persistentStoreCoordinator.remove(store)
        }
    }

    private struct SchemaStoreDidNotOpen: Error {}
    #endif
}
