import SwiftUI

struct WatchWorkoutSummaryView: View {
    let summary: WatchWorkoutSummary

    var body: some View {
        VStack(spacing: 10) {
            Text("Session Summary")
                .font(.headline)

            VStack(spacing: 6) {
                metricRow(label: "Duration", value: formattedDuration(summary.duration))
                metricRow(label: "Floors", value: formattedNumber(summary.floors))
                metricRow(label: "Heart Rate", value: heartRateText)
                metricRow(label: "Energy", value: "\(formattedNumber(summary.activeEnergy)) kcal")
            }
        }
        .padding()
    }

    private var heartRateText: String {
        if summary.averageHeartRate > 0 {
            return "\(Int(summary.averageHeartRate)) bpm"
        }
        return "--"
    }

    private func formattedDuration(_ duration: TimeInterval) -> String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.minute, .second]
        formatter.zeroFormattingBehavior = .pad
        return formatter.string(from: duration) ?? "0:00"
    }

    private func formattedNumber(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.maximumFractionDigits = 1
        formatter.minimumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value)) ?? "0"
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
}

#Preview("WatchWorkoutSummaryView") {
    WatchWorkoutSummaryView(
        summary: WatchWorkoutSummary(
            date: Date(),
            duration: 900,
            floors: 24,
            activeEnergy: 120,
            averageHeartRate: 124
        )
    )
}
