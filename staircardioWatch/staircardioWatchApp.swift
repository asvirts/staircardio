import SwiftUI

@main
struct staircardioWatchApp: App {
    @StateObject private var syncManager = WatchSyncManager()

    var body: some Scene {
        WindowGroup {
            WatchContentView()
                .environmentObject(syncManager)
        }
    }
}
