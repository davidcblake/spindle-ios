import Foundation
import Network
import Observation

/// Whether the phone can reach the internet right now.
///
/// Only Prepare asks. Everything else in Spindle is on the phone and does not
/// care, which is the point of local-first.
@MainActor
@Observable
final class Connection {
    private(set) var isOnline = true
    private let monitor = NWPathMonitor()

    /// Made once, when the app starts, and kept for as long as it runs; the
    /// monitor holding on to this is therefore not a leak worth breaking.
    init() {
        // Marked @Sendable so it is not treated as main-actor code: the
        // monitor calls it on its own queue, and Swift 6 stops the app if
        // main-actor code runs anywhere else.
        monitor.pathUpdateHandler = { @Sendable path in
            let online = path.status == .satisfied
            Task { @MainActor in
                self.isOnline = online
            }
        }
        monitor.start(queue: DispatchQueue(label: "Spindle.Connection"))
    }
}
