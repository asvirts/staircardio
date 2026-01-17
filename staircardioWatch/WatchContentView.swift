import SwiftUI

struct WatchContentView: View {
    @EnvironmentObject private var syncManager: WatchSyncManager

    var body: some View {
        NavigationStack {
            VStack(spacing: 12) {
                Text("Today")
                    .font(.headline)

                Text(progressText)
                    .font(.system(size: 28, weight: .bold, design: .rounded))

                ProgressView(value: progressValue)
                    .progressViewStyle(.circular)

                Button {
                    syncManager.incrementOffline()
                } label: {
                    Text("+1 Circuit")
                }
                .buttonStyle(.borderedProminent)

                NavigationLink("Start Stair Session") {
                    WatchWorkoutPlaceholderView()
                }
                .buttonStyle(.bordered)
            }
            .padding()
        }
        .onAppear {
            syncManager.requestLatestSummary()
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
    WatchContentView()
        .environmentObject(WatchSyncManager(isPreview: true))
}
