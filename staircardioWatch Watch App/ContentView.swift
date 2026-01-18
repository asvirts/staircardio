//
//  ContentView.swift
//  staircardioWatch Watch App
//
//  Created by Andrew Virts on 1/17/26.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var syncManager: WatchSyncManager
    @StateObject private var healthKitManager = WatchHealthKitManager()
    @State private var isShowingWorkout = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 12) {
                Text("Today")
                    .font(.headline)

                Text(progressText)
                    .font(.system(size: 28, weight: .bold, design: .rounded))

                ProgressView(value: progressValue)
                    .progressViewStyle(.circular)

                HStack {
                    Text(syncManager.syncStatus.rawValue)
                        .font(.footnote)
                        .foregroundStyle(.secondary)

                    Spacer()

                    Button {
                        syncManager.requestLatestSummary()
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                    .buttonStyle(.bordered)
                }

                Button {
                    syncManager.incrementOffline()
                } label: {
                    Text("+1 Circuit")
                }
                .buttonStyle(.borderedProminent)

                Button {
                    isShowingWorkout = true
                } label: {
                    Text("Start Stair Session")
                }
                .buttonStyle(.bordered)
                .disabled(!healthKitManager.isAuthorized)

                if let summary = syncManager.lastWorkoutSummary {
                    NavigationLink("Last Session") {
                        WatchWorkoutSummaryView(summary: summary)
                    }
                }
            }
            .padding()
        }
        .onAppear {
            syncManager.requestLatestSummary()
            Task {
                await healthKitManager.requestAuthorization()
            }
        }
        .sheet(isPresented: $isShowingWorkout) {
            WatchWorkoutSessionView()
                .environmentObject(syncManager)
        }
    }

    private var progressText: String {
        guard let summary = syncManager.summary else { return "-- / --" }
        return "\(summary.completed) / \(summary.target)"
    }

    private var progressValue: Double {
        guard let summary = syncManager.summary else { return 0 }
        guard summary.target > 0 else { return 0 }
        return Double(summary.completed) / Double(summary.target)
    }
}

#Preview {
    ContentView()
        .environmentObject(WatchSyncManager(isPreview: true))
}
