import SwiftUI
import SwiftData

struct TabContentView: View {
    @EnvironmentObject private var tabSelectionManager: TabSelectionManager

    var body: some View {
        TabView(selection: $tabSelectionManager.selectedTab) {
            ContentView()
                .environmentObject(tabSelectionManager)
                .tabItem {
                    Label("Today", systemImage: "figure.stairs")
                }
                .tag(0)

            AnalyticsTabView()
                .tabItem {
                    Label("Analytics", systemImage: "chart.bar.fill")
                }
                .tag(1)

            HealthTabView()
                .tabItem {
                    Label("Health", systemImage: "heart.fill")
                }
                .tag(2)

            SettingsTabView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
                .tag(3)
        }
    }
}

public struct AnalyticsTabView: View {
    public var body: some View {
        NavigationStack {
            List {
                NavigationLink {
                    WeeklySummaryView()
                } label: {
                    Label("Weekly Summary", systemImage: "chart.line.uptrend.xyaxis")
                }
                .accessibilityLabel("Weekly Summary")
                .accessibilityHint("View weekly circuit statistics and trends")

                NavigationLink {
                    MonthlySummaryView()
                } label: {
                    Label("Monthly Summary", systemImage: "calendar")
                }
                .accessibilityLabel("Monthly Summary")
                .accessibilityHint("View monthly circuit statistics and trends")

                NavigationLink {
                    StreakCalendarView()
                } label: {
                    Label("Streak Calendar", systemImage: "flame.fill")
                }
                .accessibilityLabel("Streak Calendar")
                .accessibilityHint("View calendar showing daily goal completion")
            }
            .navigationTitle("Analytics")
            .accessibilityLabel("Analytics menu")
        }
    }
}

public struct HealthTabView: View {
    public var body: some View {
        NavigationStack {
            List {
                NavigationLink {
                    HealthDashboardView()
                } label: {
                    Label("Health Dashboard", systemImage: "lungs.fill")
                }
                .accessibilityLabel("Health Dashboard")
                .accessibilityHint("View VO₂ max and resting heart rate trends")

                NavigationLink {
                    HealthInsightsView()
                } label: {
                    Label("Health Insights", systemImage: "chart.xyaxis.line")
                }
                .accessibilityLabel("Health Insights")
                .accessibilityHint("View health correlations and fitness progress")

                NavigationLink {
                    AchievementsView()
                } label: {
                    Label("Achievements", systemImage: "trophy.fill")
                }
                .accessibilityLabel("Achievements")
                .accessibilityHint("View earned badges and progress")
            }
            .navigationTitle("Health")
            .accessibilityLabel("Health menu")
        }
    }
}

public struct SettingsTabView: View {
    public var body: some View {
        NavigationStack {
            List {
                NavigationLink {
                    ContentViewSettingsSheet()
                } label: {
                    Label("Daily Target & Reminders", systemImage: "target")
                }
                .accessibilityLabel("Daily Target and Reminders")
                .accessibilityHint("Adjust daily circuit target and notification settings")

                NavigationLink(destination: AdvancedSettingsView()) {
                    Label("Advanced Settings", systemImage: "gearshape.2.fill")
                }
                .accessibilityLabel("Advanced Settings")
                .accessibilityHint("Configure work days and data management options")

                NavigationLink {
                    BehavioralNudgesView()
                } label: {
                    Label("Tips & Suggestions", systemImage: "lightbulb.fill")
                }
                .accessibilityLabel("Tips and Suggestions")
                .accessibilityHint("View personalized workout tips and suggestions")

                NavigationLink {
                    AchievementsView()
                } label: {
                    Label("Achievements", systemImage: "trophy.fill")
                }
                .accessibilityLabel("Achievements")
                .accessibilityHint("View earned badges and progress")

                NavigationLink {
                    WorkoutHistoryView()
                } label: {
                    Label("Workout History", systemImage: "clock.arrow.circlepath")
                }
                .accessibilityLabel("Workout History")
                .accessibilityHint("View past stair climbing workout sessions")
            }
            .navigationTitle("Settings")
            .accessibilityLabel("Settings menu")
        }
    }
}

public struct ContentViewSettingsSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var todayLogs: [DayLog]
    @State private var targetInput = ""
    @State private var floorsPerCircuitInput = ""
    @StateObject private var appModel = AppModel()
    @Environment(\.dismiss) private var dismiss

    public var body: some View {
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
        .navigationTitle("Daily Settings")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    dismiss()
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

    private var today: DayLog {
        if let existing = todayLogs.first { return existing }
        let key = ContentView.todayKey
        let created = DayLog(dayKey: key)
        modelContext.insert(created)
        return created
    }

    private var remindersSection: some View {
        Section("Reminders") {
            Toggle("Enable reminders", isOn: $appModel.remindersEnabled)

            DatePicker(
                "Start time",
                selection: Binding(
                    get: { dateFromMinutes(appModel.startMinutes) },
                    set: { appModel.startMinutes = minutesFromDate($0) }
                ),
                displayedComponents: .hourAndMinute
            )
            .disabled(!appModel.remindersEnabled)

            DatePicker(
                "End time",
                selection: Binding(
                    get: { dateFromMinutes(appModel.endMinutes) },
                    set: { appModel.endMinutes = minutesFromDate($0) }
                ),
                displayedComponents: .hourAndMinute
            )
            .disabled(!appModel.remindersEnabled)

            Picker("Interval", selection: $appModel.intervalMinutes) {
                ForEach(NotificationIntervalOption.allCases, id: \.self) { option in
                    Text(option.label)
                        .tag(option.minutes)
                }
            }
            .disabled(!appModel.remindersEnabled)
        }
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
        return "Sync uses your device's iCloud account to keep data up to date."
    }

    private var iCloudToken: NSObjectProtocol? {
        FileManager.default.ubiquityIdentityToken
    }

    private var parsedTarget: Int? {
        let trimmed = targetInput.trimmingCharacters(in: .whitespacesAndNewlines)
        return Int(trimmed)
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

        dismiss()
    }
}

public struct AchievementsView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var healthKitManager: HealthKitManager
    @Query private var dayLogs: [DayLog]
    @State private var achievementsProgress: [AchievementProgress] = []
    @State private var isLoading = false

    public var body: some View {
        List {
            if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, alignment: .center)
                    .listRowBackground(Color.clear)
            } else if achievementsProgress.isEmpty {
                Text("No achievements yet. Keep completing circuits to earn badges!")
                    .foregroundStyle(.secondary)
            } else {
                let grouped = groupAchievementsByType(achievementsProgress)

                ForEach(grouped.keys.sorted(by: { $0.rawValue < $1.rawValue }), id: \.self) { badgeType in
                    if let achievements = grouped[badgeType], !achievements.isEmpty {
                        Section {
                            ForEach(achievements, id: \.definition.title) { progress in
                                AchievementProgressRow(progress: progress, healthKitManager: healthKitManager)
                            }
                        } header: {
                            Text(sectionTitle(for: badgeType))
                                .font(.headline)
                        }
                    }
                }
            }
        }
        .navigationTitle("Achievements")
        .onAppear {
            loadAchievements()
        }
    }

    private func loadAchievements() {
        Task {
            isLoading = true
            let manager = AchievementManager(
                modelContext: modelContext,
                healthKitManager: healthKitManager
            )
            await manager.loadAllAchievementsProgress(dayLogs: dayLogs)
            await MainActor.run {
                achievementsProgress = manager.allAchievementsProgress
                isLoading = false
            }
        }
    }

    private func groupAchievementsByType(_ progress: [AchievementProgress]) -> [BadgeType: [AchievementProgress]] {
        Dictionary(grouping: progress) { $0.definition.type }
    }

    private func sectionTitle(for badgeType: BadgeType) -> String {
        switch badgeType {
        case .streak:
            return "Streaks"
        case .totalCircuits:
            return "Total Circuits"
        case .consistency:
            return "Consistency"
        case .healthImprovement:
            return "Health & Fitness"
        }
    }
}

public struct AchievementRow: View {
    let achievement: Achievement

    public var body: some View {
        HStack(spacing: 12) {
            Image(systemName: achievement.icon)
                .font(.title2)
                .foregroundColor(.accentColor)
                .frame(width: 40)

            VStack(alignment: .leading, spacing: 4) {
                Text(achievement.title)
                    .font(.headline)

                Text(achievement.badgeDescription)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text(achievement.earnedDate, style: .date)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if achievement.isEarned {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
            }
        }
        .padding(.vertical, 4)
    }
}

struct AchievementProgressRow: View {
    let progress: AchievementProgress
    let healthKitManager: HealthKitManager

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: progress.definition.icon)
                .font(.title2)
                .foregroundColor(progress.isEarned ? .accentColor : .secondary)
                .frame(width: 40)

            VStack(alignment: .leading, spacing: 4) {
                Text(progress.definition.title)
                    .font(.headline)
                    .foregroundStyle(progress.isEarned ? .primary : .secondary)

                Text(progress.definition.badgeDescription)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                if progress.isEarned {
                    Text("Earned!")
                        .font(.caption2)
                        .foregroundStyle(.green)
                } else {
                    VStack(alignment: .leading, spacing: 2) {
                        progressContent

                        if progress.definition.type == .healthImprovement && progress.healthValue == nil {
                            Text("Connect HealthKit to track")
                                .font(.caption2)
                                .foregroundStyle(.orange)
                        }
                    }
                }
            }

            Spacer()

            if progress.isEarned {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
            }
        }
        .padding(.vertical, 4)
    }

    @ViewBuilder
    private var progressContent: some View {
        switch progress.definition.type {
        case .streak:
            progressText("\(progress.currentValue) / \(progress.definition.threshold) days")
            progressBar

        case .totalCircuits:
            progressText("\(progress.currentValue) / \(progress.definition.threshold) circuits")
            progressBar

        case .consistency:
            Text("Coming soon")
                .font(.caption2)
                .foregroundStyle(.secondary)

        case .healthImprovement:
            if let healthValue = progress.healthValue {
                if progress.definition.title.contains("VO₂") {
                    progressText(String(format: "%.1f / %d ml/kg·min", healthValue, progress.definition.threshold))
                    progressBar
                } else if progress.definition.title.contains("Heart") {
                    if healthValue < Double(progress.definition.threshold) {
                        Text(String(format: "%.0f bpm (below %d)", healthValue, progress.definition.threshold))
                            .font(.caption2)
                            .foregroundStyle(.green)
                    } else {
                        progressText(String(format: "%.0f / below %d bpm", healthValue, progress.definition.threshold))
                        progressBar
                    }
                }
            } else {
                Text("No data available")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func progressText(_ text: String) -> some View {
        Text(text)
            .font(.caption2)
            .foregroundStyle(.secondary)
    }

    private var progressBar: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(.systemGray5))
                    .frame(height: 6)

                RoundedRectangle(cornerRadius: 4)
                    .fill(progressColor)
                    .frame(width: geometry.size.width * CGFloat(progress.progressPercentage), height: 6)
            }
        }
        .frame(height: 6)
    }

    private var progressColor: Color {
        if progress.isEarned {
            return .green
        }
        if progress.progressPercentage >= 0.75 {
            return .orange
        }
        return .blue
    }
}
