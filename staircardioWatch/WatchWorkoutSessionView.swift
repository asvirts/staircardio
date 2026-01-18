import HealthKit
import SwiftUI

struct WatchWorkoutSessionView: View {
    @EnvironmentObject private var syncManager: WatchSyncManager
    @Environment(\.dismiss) private var dismiss
    @StateObject private var workoutManager = WatchWorkoutManager()
    @State private var isEnding = false

    var body: some View {
        VStack(spacing: 10) {
            Text("Stair Session")
                .font(.headline)

            VStack(spacing: 6) {
                metricRow(label: "Duration", value: durationText)
                metricRow(label: "Floors", value: formattedNumber(workoutManager.liveFloors))
                metricRow(label: "Heart Rate", value: heartRateText)
                metricRow(label: "Energy", value: energyText)
            }

            if let errorMessage = workoutManager.sessionErrorMessage {
                Text(errorMessage)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            Button(role: .destructive) {
                Task {
                    isEnding = true
                    if let summary = await workoutManager.endWorkout() {
                        syncManager.recordWorkoutSummary(summary)
                    }
                    isEnding = false
                    dismiss()
                }
            } label: {
                Text(isEnding ? "Ending..." : "End Session")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .disabled(isEnding)
        }
        .padding()
        .onAppear {
            workoutManager.startWorkout()
        }
        .interactiveDismissDisabled(isEnding)
    }

    private var durationText: String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.minute, .second]
        formatter.zeroFormattingBehavior = .pad
        return formatter.string(from: workoutManager.liveDuration) ?? "0:00"
    }

    private var heartRateText: String {
        if workoutManager.liveHeartRate > 0 {
            return "\(Int(workoutManager.liveHeartRate)) bpm"
        }
        return "--"
    }

    private var energyText: String {
        if workoutManager.liveActiveEnergy > 0 {
            return "\(formattedNumber(workoutManager.liveActiveEnergy)) kcal"
        }
        return "--"
    }

    private func metricRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.footnote)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.headline)
        }
    }

    private func formattedNumber(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.maximumFractionDigits = 1
        formatter.minimumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value)) ?? "0"
    }
}

#Preview("WatchWorkoutSessionView") {
    WatchWorkoutSessionView()
        .environmentObject(WatchSyncManager(isPreview: true))
}
