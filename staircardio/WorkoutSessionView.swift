import SwiftUI

struct WorkoutSessionView: View {
    @EnvironmentObject private var healthKitManager: HealthKitManager
    @Environment(\.dismiss) private var dismiss
    @State private var isEnding = false

    let onEnd: () async -> Void

    var body: some View {
        VStack(spacing: 20) {
            Text("Stair Session")
                .font(.title2.weight(.semibold))

            VStack(spacing: 12) {
                metricRow(label: "Duration", value: durationText)
                metricRow(label: "Floors", value: formattedNumber(healthKitManager.liveFloors))
                metricRow(label: "Heart Rate", value: heartRateText)
                metricRow(label: "Active Energy", value: energyText)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 16))

            if let errorMessage = healthKitManager.sessionErrorMessage {
                Text(errorMessage)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            Button(role: .destructive) {
                Task {
                    isEnding = true
                    await onEnd()
                    isEnding = false
                    dismiss()
                }
            } label: {
                Text(isEnding ? "Ending..." : "End Session")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
            }
            .buttonStyle(.borderedProminent)
            .disabled(isEnding)
        }
        .padding()
        .onAppear {
            healthKitManager.resetLiveMetrics()
            healthKitManager.startWorkout()
        }
        .interactiveDismissDisabled(isEnding)
    }

    private var durationText: String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.minute, .second]
        formatter.zeroFormattingBehavior = .pad
        return formatter.string(from: healthKitManager.liveDuration) ?? "0:00"
    }

    private var heartRateText: String {
        if healthKitManager.liveHeartRate > 0 {
            return "\(Int(healthKitManager.liveHeartRate)) bpm"
        }
        return "--"
    }

    private var energyText: String {
        if healthKitManager.liveActiveEnergy > 0 {
            return "\(formattedNumber(healthKitManager.liveActiveEnergy)) kcal"
        }
        return "--"
    }

    private func metricRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.subheadline)
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

#Preview("WorkoutSessionView") {
    WorkoutSessionView {
        await Task.yield()
    }
    .environmentObject(HealthKitManager())
}
