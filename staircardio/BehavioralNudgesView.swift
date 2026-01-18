import SwiftUI
import SwiftData

struct BehavioralNudgesView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var nudges: [Nudge] = []
    @State private var dayLogs: [DayLog] = []

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Text("Tips & Suggestions")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                if nudges.isEmpty {
                    Text("No suggestions available yet.")
                        .foregroundStyle(.secondary)
                } else {
                    VStack(alignment: .leading, spacing: 16) {
                        ForEach(nudges) { nudge in
                            NudgeCard(nudge: nudge)
                        }
                    }
                }
            }
            .padding()
            .navigationTitle("Nudges")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            loadDayLogs()
            generateNudges()
        }
    }

    private func loadDayLogs() {
        let descriptor = FetchDescriptor<DayLog>(sortBy: [SortDescriptor(\.dayKey, order: .reverse)])
        dayLogs = (try? modelContext.fetch(descriptor)) ?? []
    }

    private func generateNudges() {
        var generatedNudges: [Nudge] = []

        let recentLogs = dayLogs.suffix(7)
        let avgCompleted = recentLogs.isEmpty ? 0 : Double(recentLogs.reduce(0) { $0 + $1.completed }) / Double(recentLogs.count)
        let goalMetCount = recentLogs.filter { $0.completed >= $0.target }.count

        if goalMetCount >= 5 {
            generatedNudges.append(Nudge(
                id: "consistency-good",
                icon: "checkmark.circle.fill",
                title: "Great Consistency!",
                description: "You've been hitting your goal most days. Consider increasing your target by 1-2 circuits to continue progressing.",
                action: "Increase Target",
                type: .encouragement
            ))
        } else if goalMetCount < 2 {
            generatedNudges.append(Nudge(
                id: "consistency-low",
                icon: "exclamationmark.triangle.fill",
                title: "Focus on Consistency",
                description: "You've been missing your target lately. Try setting reminders and starting with smaller, achievable goals.",
                action: "View Reminders",
                type: .suggestion
            ))
        }

        let today = dayLogs.first { $0.dayKey == Self.todayKey() }
        if let todayLog = today, todayLog.completed < todayLog.target {
            let remaining = todayLog.target - todayLog.completed
            if remaining <= 2 {
                generatedNudges.append(Nudge(
                    id: "almost-there",
                    icon: "flame.fill",
                    title: "Almost There!",
                    description: "Just \(remaining) more circuit\(remaining > 1 ? "s" : "") to hit today's goal. You can do it!",
                    action: "Start Workout",
                    type: .motivation
                ))
            }
        }

        let analyzer = BehavioralAnalyzer(modelContext: modelContext)
        let plateauDetected = analyzer.detectPlateau(days: 7)

        if plateauDetected {
            generatedNudges.append(Nudge(
                id: "plateau",
                icon: "chart.line.uptrend.xyaxis",
                title: "Mix Up Your Routine",
                description: "Your activity levels have been consistent recently. Try varying your workout intensity or timing to break through.",
                action: "View Analytics",
                type: .tip
            ))
        }

        let pattern = analyzer.getPatternAnalysis()
        if pattern.pattern == "Strong weekly pattern detected", let bestDay = pattern.bestDay {
            generatedNudges.append(Nudge(
                id: "pattern-\(bestDay)",
                icon: "calendar",
                title: "Your Best Day: \(bestDay)",
                description: "Based on your data, you perform best on \(bestDay)s. Plan important or harder sessions for that day.",
                action: "View Calendar",
                type: .tip
            ))
        }

        if avgCompleted > 10 {
            generatedNudges.append(Nudge(
                id: "advanced-tip",
                icon: "lightbulb.fill",
                title: "Advanced Training Tip",
                description: "You've been doing great! Consider adding interval training - alternate between fast and slow pacing to improve cardiovascular fitness.",
                action: "Learn More",
                type: .tip
            ))
        }

        nudges = generatedNudges
    }

    private static func todayKey() -> String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }
}

struct NudgeCard: View {
    let nudge: Nudge
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: nudge.icon)
                    .font(.title2)
                    .foregroundColor(iconColor)
                    .frame(width: 32)

                VStack(alignment: .leading, spacing: 4) {
                    Text(nudge.title)
                        .font(.headline)

                    Text(nudge.description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }

            Button(action: {
                handleAction()
            }) {
                Text(nudge.action)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(8)
                    .background(iconColor)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
        .padding(16)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var iconColor: Color {
        switch nudge.type {
        case .encouragement:
            return .green
        case .motivation:
            return .orange
        case .tip:
            return .blue
        case .suggestion:
            return .purple
        }
    }

    private func handleAction() {
        dismiss()
    }
}

struct Nudge: Identifiable {
    let id: String
    let icon: String
    let title: String
    let description: String
    let action: String
    let type: NudgeType
}

enum NudgeType {
    case encouragement
    case motivation
    case tip
    case suggestion
}
