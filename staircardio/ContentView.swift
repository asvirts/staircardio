import SwiftData
import HealthKit
import SwiftData
import SwiftUI

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var watchSyncManager: WatchSyncManager
    @EnvironmentObject private var healthKitManager: HealthKitManager
    @Query private var todayLogs: [DayLog]
    @State private var isShowingSettings = false
    @State private var targetInput = ""
    @State private var floorsPerCircuitInput = ""
    @StateObject private var appModel = AppModel()
    @State private var isRefreshingNotifications = false
    @State private var isSyncingHistory = false
    @State private var isShowingWorkoutSession = false
    @State private var isShowingWorkoutAdjustment = false
    @State private var pendingWorkout: HKWorkout?
    @State private var pendingWorkoutMetrics: WorkoutMetrics?
    @State private var pendingApplyToToday = false

    static var todayKey: String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }

    private var todayKey: String { Self.todayKey }

    init() {
        let key = Self.todayKey
        _todayLogs = Query(filter: #Predicate<DayLog> { $0.dayKey == key }, sort: [])
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                if isRefreshingNotifications {
                    ProgressView("Updating reminders...")
                        .font(.footnote)
                }

                if isSyncingHistory {
                    ProgressView("Syncing workout history...")
                        .font(.footnote)
                }

                VStack(spacing: 8) {
                    Text("Today’s Stair Circuits")
                        .font(.headline)

                    Text("\(today.completed) / \(today.target)")
                        .font(.system(size: 40, weight: .bold, design: .rounded))

                    ProgressView(value: progress)
                        .progressViewStyle(.linear)
                        .tint(.accentColor)

                    Text(progressLabel)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 16))

                Button {
                    today.completed += 1
                    appModel.scheduleOrCancelReminders(goalReached: goalReached)
                    watchSyncManager.refreshSummary()
                } label: {
                    Text("+1 Quick Circuit")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentColor)
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                Button {
                    if healthKitManager.authorizationStatus == .notDetermined {
                        Task {
                            await healthKitManager.requestAuthorization()
                            if healthKitManager.authorizationStatus == .sharingAuthorized {
                                isShowingWorkoutSession = true
                            }
                        }
                    } else if healthKitManager.authorizationStatus == .sharingAuthorized {
                        isShowingWorkoutSession = true
                    }
                } label: {
                    Text(startWorkoutLabel)
                        .font(.subheadline.weight(.medium))
                        .frame(maxWidth: .infinity)
                        .padding()
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.accentColor, lineWidth: 1.5)
                        )
                }
                .disabled(healthKitManager.authorizationStatus == .sharingDenied)

                Spacer()

                Button(role: .destructive) {
                    today.completed = 0
                    appModel.scheduleOrCancelReminders(goalReached: false)
                    watchSyncManager.refreshSummary()
                } label: {
                    Text("Reset Today")
                        .font(.footnote)
                }
            }
            .padding()
            .navigationTitle("StairCardio")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: 16) {
                        NavigationLink {
                            WorkoutHistoryView()
                        } label: {
                            Image(systemName: "clock.arrow.circlepath")
                        }
                        .accessibilityLabel("Workout history")

                        Button {
                            targetInput = String(today.target)
                            floorsPerCircuitInput = String(appModel.floorsPerCircuit)
                            isShowingSettings = true
                        } label: {
                            Image(systemName: "gearshape")
                        }
                        .accessibilityLabel("Edit daily target")
                    }
                }
            }
            .onAppear {
                appModel.scheduleOrCancelReminders(goalReached: goalReached)
                watchSyncManager.refreshSummary()
            }
            .onOpenURL { url in
                if url.absoluteString == DeepLinkHandler.todayRoute {
                    isShowingSettings = false
                }
            }
            .sheet(isPresented: $isShowingSettings) {
                NavigationStack {
                    Form {
                        Section("Daily Target") {
                            TextField("Target circuits", text: $targetInput)
                                .keyboardType(.numberPad)
                        }

                        Section("Workout Settings") {
                            TextField("Floors per circuit", text: $floorsPerCircuitInput)
                                .keyboardType(.numberPad)
                            Text("Used to convert workouts into circuits.")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }

                        remindersSection

                        Section("iCloud Sync") {
                            LabeledContent("Status", value: iCloudStatusText)
                            Text(iCloudStatusDetail)
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .navigationTitle("Settings")
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Cancel") {
                                isShowingSettings = false
                            }
                        }
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Save") {
                                saveTarget()
                            }
                            .disabled(!isTargetValid || !isFloorsPerCircuitValid)
                        }
                    }
                }
            }
        .sheet(isPresented: $isShowingWorkoutSession) {
            WorkoutSessionView { workout, metrics in
                await handleWorkoutCompletion(workout, metrics: metrics)
            }
            .environmentObject(healthKitManager)
        }
        .sheet(isPresented: $isShowingWorkoutAdjustment) {
            if let metrics = pendingWorkoutMetrics {
                WorkoutAdjustmentView(
                    metrics: metrics,
                    floorsPerCircuit: appModel.floorsPerCircuit,
                    applyToToday: pendingApplyToToday
                ) { adjustedCircuits, applyToToday in
                    if let workout = pendingWorkout {
                        Task {
                            await storeWorkout(
                                workout,
                                metrics: metrics,
                                circuits: adjustedCircuits,
                                applyToToday: applyToToday
                            )
                        }
                    }
                    pendingWorkout = nil
                    pendingWorkoutMetrics = nil
                    pendingApplyToToday = false
                    isShowingWorkoutAdjustment = false
                }
            }
        }

        .task {
            healthKitManager.refreshAuthorizationStatus()
            if appModel.shouldRequestHealthKitAuthorization {
                await healthKitManager.requestAuthorization()
                appModel.markHealthKitAuthorizationRequested()
                healthKitManager.refreshAuthorizationStatus()
            }
            await refreshWorkoutHistoryIfNeeded()
        }
        .onChange(of: healthKitManager.authorizationStatus) { _, newValue in
            guard newValue == HKAuthorizationStatus.sharingAuthorized else { return }
            Task {
                await refreshWorkoutHistoryIfNeeded()
            }
        }

        }
    }

    private var today: DayLog {
        if let existing = todayLogs.first { return existing }
        let created = DayLog(dayKey: todayKey)
        modelContext.insert(created)
        return created
    }

    private var startWorkoutLabel: String {
        switch healthKitManager.authorizationStatus {
        case .sharingDenied:
            return "Health Access Required"
        case .sharingAuthorized:
            return "Start Stair Session"
        case .notDetermined:
            return "Enable HealthKit"
        @unknown default:
            return "Start Stair Session"
        }
    }

    private var progress: Double {
        guard today.target > 0 else { return 0 }
        return Double(today.completed) / Double(today.target)
    }

    private var progressLabel: String {
        if today.completed >= today.target {
            return "Goal reached 🎉"
        } else {
            let remaining = today.target - today.completed
            return "\(remaining) circuits left today"
        }
    }

    private var parsedTarget: Int? {
        let trimmed = targetInput.trimmingCharacters(in: .whitespacesAndNewlines)
        return Int(trimmed)
    }

    private var remindersSection: some View {
        Section("Reminders") {
            Toggle("Enable reminders", isOn: $appModel.remindersEnabled)
                .onChange(of: appModel.remindersEnabled) { (_, newValue: Bool) in
                    Task {
                        isRefreshingNotifications = true
                        await appModel.handleRemindersToggleChanged(
                            enabled: newValue,
                            goalReached: goalReached
                        )
                        isRefreshingNotifications = false
                    }
                }

            DatePicker(
                "Start time",
                selection: Binding(
                    get: { dateFromMinutes(appModel.startMinutes) },
                    set: { appModel.startMinutes = minutesFromDate($0) }
                ),
                displayedComponents: .hourAndMinute
            )
            .disabled(!appModel.remindersEnabled)
            .onChange(of: appModel.startMinutes) { _, _ in
                appModel.scheduleOrCancelReminders(goalReached: goalReached)
            }

            DatePicker(
                "End time",
                selection: Binding(
                    get: { dateFromMinutes(appModel.endMinutes) },
                    set: { appModel.endMinutes = minutesFromDate($0) }
                ),
                displayedComponents: .hourAndMinute
            )
            .disabled(!appModel.remindersEnabled)
            .onChange(of: appModel.endMinutes) { _, _ in
                appModel.scheduleOrCancelReminders(goalReached: goalReached)
            }

            Picker("Interval", selection: $appModel.intervalMinutes) {
                ForEach(NotificationIntervalOption.allCases, id: \.self) { option in
                    Text(option.label)
                        .tag(option.minutes)
                }
            }
            .disabled(!appModel.remindersEnabled)
            .onChange(of: appModel.intervalMinutes) { _, _ in
                appModel.intervalMinutes = clampedInterval(appModel.intervalMinutes)
                appModel.scheduleOrCancelReminders(goalReached: goalReached)
            }

            Text("Reminders run Monday through Friday during work hours.")
                .font(.footnote)
                .foregroundStyle(.secondary)

            if let status = appModel.notificationStatusMessage {
                Text(status)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var goalReached: Bool {
        today.completed >= today.target
    }

    private func dateFromMinutes(_ minutes: Int) -> Date {
        let clamped = max(minutes, 0)
        let hour = clamped / 60
        let minute = clamped % 60
        return Calendar.current.date(bySettingHour: hour, minute: minute, second: 0, of: Date()) ?? Date()
    }

    private func minutesFromDate(_ date: Date) -> Int {
        let components = Calendar.current.dateComponents([.hour, .minute], from: date)
        return (components.hour ?? 0) * 60 + (components.minute ?? 0)
    }

    private func clampedInterval(_ minutes: Int) -> Int {
        NotificationIntervalOption.closest(to: minutes).minutes
    }

    private var iCloudStatusText: String {
        if iCloudToken == nil {
            return "Not Signed In"
        }
        return "Enabled"
    }

    private var iCloudStatusDetail: String {
        if iCloudToken == nil {
            return "Sign in to iCloud in Settings to enable sync across devices."
        }
        return "Sync uses your device’s iCloud account to keep data up to date."
    }

    private var iCloudToken: NSObjectProtocol? {
        FileManager.default.ubiquityIdentityToken
    }

    private var parsedFloorsPerCircuit: Int? {
        let trimmed = floorsPerCircuitInput.trimmingCharacters(in: .whitespacesAndNewlines)
        return Int(trimmed)
    }

    private var isTargetValid: Bool {
        guard let value = parsedTarget else { return false }
        return value > 0
    }

    private var isFloorsPerCircuitValid: Bool {
        guard let value = parsedFloorsPerCircuit else { return false }
        return value > 0
    }

    private func handleWorkoutCompletion(_ workout: HKWorkout?, metrics: WorkoutMetrics) async {
        guard let workout else { return }
        pendingWorkout = workout
        pendingWorkoutMetrics = metrics
        pendingApplyToToday = true
        isShowingWorkoutAdjustment = true
    }

    private func refreshWorkoutHistoryIfNeeded() async {
        guard healthKitManager.authorizationStatus == HKAuthorizationStatus.sharingAuthorized else { return }
        guard !isSyncingHistory else { return }

        isSyncingHistory = true
        let workouts = await healthKitManager.fetchRecentStairWorkouts(limit: 30)
        for workout in workouts {
            let floors = workout.totalFlightsClimbed?.doubleValue(for: HKUnit.count()) ?? healthKitManager.liveFloors
            let energy = workout.totalEnergyBurned?.doubleValue(for: HKUnit.kilocalorie()) ?? healthKitManager.liveActiveEnergy
            let avgHeartRate = await healthKitManager.fetchAverageHeartRate(for: workout)
            let metrics = WorkoutMetrics(
                floors: floors,
                activeEnergy: energy,
                averageHeartRate: avgHeartRate
            )
            await storeWorkout(workout, metrics: metrics, circuits: nil, applyToToday: false)
        }
        isSyncingHistory = false
    }

    private func storeWorkout(
        _ workout: HKWorkout,
        metrics: WorkoutMetrics,
        circuits: Int?,
        applyToToday: Bool
    ) async {
        let workoutUUID = workout.uuid
        if workoutAlreadyStored(workoutUUID) {
            return
        }

        let computedCircuits = circuits ?? max(Int((metrics.floors / Double(appModel.floorsPerCircuit)).rounded(.down)), 0)
        let appliedDayKey = applyToToday ? today.dayKey : nil

        let log = WorkoutLog(
            workoutUUID: workoutUUID,
            startDate: workout.startDate,
            endDate: workout.endDate,
            duration: workout.duration,
            floors: metrics.floors,
            activeEnergy: metrics.activeEnergy,
            averageHeartRate: metrics.averageHeartRate,
            circuits: computedCircuits,
            appliedDayKey: appliedDayKey
        )

        modelContext.insert(log)

        if applyToToday {
            today.appliedWorkoutUUIDs.append(workoutUUID)
            today.completed += computedCircuits
        }

        do {
            try modelContext.save()
        } catch {
            print("Failed to save workout log: \(error)")
        }

        if applyToToday {
            appModel.scheduleOrCancelReminders(goalReached: goalReached)
            watchSyncManager.refreshSummary()
        }
    }

    private func workoutAlreadyStored(_ workoutUUID: UUID) -> Bool {
        let descriptor = FetchDescriptor<WorkoutLog>(predicate: #Predicate { (log: WorkoutLog) in
            log.workoutUUID == workoutUUID
        })
        return (try? modelContext.fetch(descriptor).first) != nil
    }

    private func saveTarget() {
        guard let targetValue = parsedTarget, targetValue > 0 else { return }
        guard let floorsValue = parsedFloorsPerCircuit, floorsValue > 0 else { return }
        today.target = targetValue
        appModel.floorsPerCircuit = floorsValue

        do {
            try modelContext.save()
        } catch {
            print("Failed to save daily target: \(error)")
        }

        appModel.scheduleOrCancelReminders(goalReached: goalReached)
        watchSyncManager.refreshSummary()
        isShowingSettings = false
    }
}


#Preview("ContentView Preview") {
    ContentView()
        .environmentObject(WatchSyncManager(isPreview: true))
        .environmentObject(HealthKitManager())
        .modelContainer(for: [DayLog.self, WorkoutLog.self], inMemory: true)
}

