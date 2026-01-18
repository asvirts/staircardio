import SwiftUI

struct WorkoutAdjustmentView: View {
    let metrics: WorkoutMetrics
    let floorsPerCircuit: Int
    @State private var adjustedCircuits: Int
    @State private var applyToToday: Bool
    let onSave: (Int, Bool) -> Void

    init(
        metrics: WorkoutMetrics,
        floorsPerCircuit: Int,
        applyToToday: Bool,
        onSave: @escaping (Int, Bool) -> Void
    ) {
        self.metrics = metrics
        self.floorsPerCircuit = floorsPerCircuit
        self._adjustedCircuits = State(initialValue: WorkoutAdjustmentView.defaultCircuits(
            floors: metrics.floors,
            floorsPerCircuit: floorsPerCircuit
        ))
        self._applyToToday = State(initialValue: applyToToday)
        self.onSave = onSave
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Workout Summary") {
                    LabeledContent("Floors", value: formattedNumber(metrics.floors))
                    LabeledContent("Active Energy", value: "\(formattedNumber(metrics.activeEnergy)) kcal")
                    LabeledContent("Avg Heart Rate", value: "\(formattedNumber(metrics.averageHeartRate)) bpm")
                }

                Section("Circuits") {
                    Stepper(value: $adjustedCircuits, in: 0...999) {
                        Text("\(adjustedCircuits) circuits")
                    }

                    Toggle("Apply to today", isOn: $applyToToday)
                }
            }
            .navigationTitle("Adjust Circuits")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave(adjustedCircuits, applyToToday)
                    }
                }
            }
        }
    }

    private func formattedNumber(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.maximumFractionDigits = 1
        formatter.minimumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value)) ?? "0"
    }

    private static func defaultCircuits(floors: Double, floorsPerCircuit: Int) -> Int {
        guard floorsPerCircuit > 0 else { return 0 }
        return max(Int((floors / Double(floorsPerCircuit)).rounded(.down)), 0)
    }
}

#Preview("WorkoutAdjustmentView") {
    WorkoutAdjustmentView(
        metrics: WorkoutMetrics(floors: 28, activeEnergy: 120, averageHeartRate: 120),
        floorsPerCircuit: 4,
        applyToToday: true
    ) { _, _ in
    }
}
