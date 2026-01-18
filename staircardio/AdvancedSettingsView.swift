import SwiftUI
import SwiftData

struct AdvancedSettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var appModel = AppModel()
    @State private var selectedWorkdays: Set<Int> = [2, 3, 4, 5, 6]
    @State private var isExporting = false
    @State private var exportAlert: ExportAlert?
    @State private var dayLogs: [DayLog] = []
    @State private var workoutLogs: [WorkoutLog] = []

    enum ExportAlert: Identifiable {
        case success
        case error(String)

        var id: String {
            switch self {
            case .success:
                return "success"
            case .error:
                return "error"
            }
        }
    }

    private let workdays = [1: "Monday", 2: "Tuesday", 3: "Wednesday", 4: "Thursday", 5: "Friday", 6: "Saturday", 7: "Sunday"]

    var body: some View {
        Form {
            Section("Workout Settings") {
                HStack {
                    Text("Floors per circuit")
                    Spacer()
                    Text("\(appModel.floorsPerCircuit)")
                        .foregroundStyle(.secondary)
                }

                Stepper("", value: $appModel.floorsPerCircuit, in: 1...20)
                    .labelsHidden()
            }

            Section("Work Days") {
                ForEach([2, 3, 4, 5, 6], id: \.self) { day in
                    Toggle(workdays[day, default: "Day \(day)"], isOn: Binding(
                        get: { selectedWorkdays.contains(day) },
                        set: { newValue in
                            if newValue {
                                selectedWorkdays.insert(day)
                            } else {
                                selectedWorkdays.remove(day)
                            }
                        }
                    ))
                }

                Text("Your target is tracked daily, but you may set reminders for specific days.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("Data Management") {
                Button(action: exportData) {
                    HStack {
                        if isExporting {
                            ProgressView()
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "square.and.arrow.up")
                        }
                        Text("Export Workout Data (CSV)")
                        Spacer()
                    }
                }
                .disabled(isExporting)

                Button(role: .destructive, action: clearAllData) {
                    Text("Clear All Data")
                }
            }

            Section("About") {
                HStack {
                    Text("Version")
                    Spacer()
                    Text("1.0.0")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle("Advanced Settings")
        .onAppear {
            loadData()
        }
        .alert(item: $exportAlert) { alert in
            switch alert {
            case .success:
                Alert(
                    title: Text("Export Successful"),
                    message: Text("Your workout data has been saved to Files."),
                    dismissButton: .default(Text("OK"))
                )
            case .error(let message):
                Alert(
                    title: Text("Export Failed"),
                    message: Text(message),
                    dismissButton: .default(Text("OK"))
                )
            }
        }
    }

    private func exportData() {
        isExporting = true

        // Fetch fresh data for export
        let workoutLogsDescriptor = FetchDescriptor<WorkoutLog>(sortBy: [SortDescriptor(\.startDate, order: .reverse)])
        let logsToExport = (try? modelContext.fetch(workoutLogsDescriptor)) ?? []

        let csvHeader = "Date,Start Time,End Time,Duration (s),Floors,Calories (kcal),Average Heart Rate (bpm),Circuits\n"
        let csvRows = logsToExport.map { log in
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            let timeFormatter = DateFormatter()
            timeFormatter.dateFormat = "HH:mm:ss"

            return String(format: "%@,%@,%@,%.1f,%.1f,%.1f,%.0f,%d\n",
                       dateFormatter.string(from: log.startDate),
                       timeFormatter.string(from: log.startDate),
                       timeFormatter.string(from: log.endDate),
                       log.duration,
                       log.floors,
                       log.activeEnergy,
                       log.averageHeartRate,
                       log.circuits)
        }.joined()

        let csvContent = csvHeader + csvRows

        guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            exportAlert = .error("Unable to access documents directory.")
            isExporting = false
            return
        }

        let fileURL = documentsDirectory.appendingPathComponent("staircardio_workouts_\(Date().timeIntervalSince1970).csv")

        do {
            try csvContent.write(to: fileURL, atomically: true, encoding: .utf8)
            exportAlert = .success
        } catch {
            exportAlert = .error("Failed to write file: \(error.localizedDescription)")
        }

        isExporting = false
    }

    private func loadData() {
        let dayLogsDescriptor = FetchDescriptor<DayLog>(sortBy: [SortDescriptor(\.dayKey, order: .reverse)])
        dayLogs = (try? modelContext.fetch(dayLogsDescriptor)) ?? []

        let workoutLogsDescriptor = FetchDescriptor<WorkoutLog>(sortBy: [SortDescriptor(\.startDate, order: .reverse)])
        workoutLogs = (try? modelContext.fetch(workoutLogsDescriptor)) ?? []
    }

    private func clearAllData() {
        // Clear all DayLog entities
        do {
            let dayLogsDescriptor = FetchDescriptor<DayLog>()
            let dayLogs = try modelContext.fetch(dayLogsDescriptor)
            for log in dayLogs {
                modelContext.delete(log)
            }
        } catch {
            print("Failed to clear day logs: \(error)")
        }

        // Clear all WorkoutLog entities
        do {
            let workoutLogsDescriptor = FetchDescriptor<WorkoutLog>()
            let workoutLogs = try modelContext.fetch(workoutLogsDescriptor)
            for log in workoutLogs {
                modelContext.delete(log)
            }
        } catch {
            print("Failed to clear workout logs: \(error)")
        }

        // Save changes
        do {
            try modelContext.save()
            loadData() // Refresh the state after clearing
        } catch {
            print("Failed to save after clearing: \(error)")
        }
    }
}
