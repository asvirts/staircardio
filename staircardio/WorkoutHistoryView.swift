import SwiftData
import SwiftUI

struct WorkoutHistoryView: View {
    @Query private var workouts: [WorkoutLog]

    init() {
        _workouts = Query(sort: \WorkoutLog.startDate, order: .reverse)
    }

    var body: some View {
        List {
            if workouts.isEmpty {
                Text("No workouts yet")
                    .foregroundStyle(.secondary)
            }

            ForEach(workouts) { workout in
                VStack(alignment: .leading, spacing: 6) {
                    Text(workout.startDate, style: .date)
                        .font(.headline)

                    Text(detailText(for: workout))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)
            }
        }
        .navigationTitle("Workout History")
    }

    private func detailText(for workout: WorkoutLog) -> String {
        let duration = formattedDuration(workout.duration)
        let floors = formattedNumber(workout.floors)
        let calories = formattedNumber(workout.activeEnergy)
        let circuits = workout.circuits
        return "\(duration) • \(floors) floors • \(calories) kcal • \(circuits) circuits"
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
}

#Preview("WorkoutHistoryView") {
    WorkoutHistoryView()
        .modelContainer(for: WorkoutLog.self, inMemory: true)
}
