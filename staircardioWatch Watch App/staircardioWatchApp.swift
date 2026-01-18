//
//  staircardioWatchApp.swift
//  staircardioWatch Watch App
//
//  Created by Andrew Virts on 1/17/26.
//

import SwiftUI

@main
struct staircardioWatch_Watch_AppApp: App {
    @StateObject private var syncManager = WatchSyncManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(syncManager)
        }
    }
}
