import SwiftData
import SwiftUI
import Charts

struct HealthInsightsView: View {
    @Query private var healthCorrelations: [HealthCorrelation]
    @Query private var dayLogs: [DayLog]
    @EnvironmentObject private var healthKitManager: HealthKitManager

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Text("Health Correlations")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                if healthCorrelations.isEmpty {
                    Text("Not enough health data to show insights.")
                        .foregroundStyle(.secondary)
                        .padding()
                } else {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Circuits vs VO₂ Max")
                            .font(.headline)

                        correlationChart
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 16))

                    insightsCards

                    targetSuggestionSection
                }
            }
            .padding()
        }
        .navigationTitle("Insights")
    }

    private var correlationChart: some View {
        Chart(healthCorrelations) { correlation in
            if let vo2Max = correlation.vo2Max {
                PointMark(
                    x: .value("Circuits", correlation.circuitCount),
                    y: .value("VO₂ Max", vo2Max)
                )
                .foregroundStyle(.purple)
                .symbolSize(100)
            }
        }
        .frame(height: 250)
        .chartXAxis {
            AxisMarks(position: .bottom)
        }
        .chartYAxis {
            AxisMarks(position: .leading)
        }
        .overlay {
            if !healthCorrelations.isEmpty {
                correlationLineOverlay
            }
        }
    }

    private var correlationLineOverlay: some View {
        GeometryReader { geometry in
            Path { path in
                let points = healthCorrelations.compactMap { correlation -> CGPoint? in
                    guard let vo2Max = correlation.vo2Max else { return nil }
                    let x = CGFloat(correlation.circuitCount) / CGFloat(maxCircuits) * geometry.size.width
                    let y = CGFloat(vo2Max) / CGFloat(maxVO2Max) * (geometry.size.height)
                    return CGPoint(x: x, y: geometry.size.height - y)
                }
                .sorted { $0.x < $1.x }

                guard !points.isEmpty else { return }

                path.move(to: points[0])
                for point in points.dropFirst() {
                    path.addLine(to: point)
                }
            }
            .stroke(Color.purple.opacity(0.5), lineWidth: 2)
        }
    }

    private var insightsCards: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Key Findings")
                .font(.headline)

            insightCard(
                icon: "chart.xyaxis.line",
                title: "Activity vs Fitness",
                description: activityFitnessInsight
            )

            insightCard(
                icon: "heart.circle",
                title: "Heart Health",
                description: heartHealthInsight
            )

            insightCard(
                icon: "trendline.up",
                title: "Progress Trend",
                description: progressTrendInsight
            )
        }
    }

    private var targetSuggestionSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Suggested Target Adjustment")
                .font(.headline)

            HStack(alignment: .top, spacing: 16) {
                Image(systemName: "lightbulb.fill")
                    .font(.title2)
                    .foregroundColor(.yellow)

                VStack(alignment: .leading, spacing: 8) {
                    Text(suggestedTargetTitle)
                        .font(.subheadline)
                        .fontWeight(.semibold)

                    Text(suggestedTargetDescription)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }
            .padding(12)
            .background(Color(.systemGray5))
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }

    private var activityFitnessInsight: String {
        let correlations = healthCorrelations.filter { $0.vo2Max != nil }
        guard !correlations.isEmpty else { return "Need more data to analyze patterns." }

        let highActivityDays = correlations.filter { $0.circuitCount >= 10 }
        let lowActivityDays = correlations.filter { $0.circuitCount < 5 }

        guard !highActivityDays.isEmpty && !lowActivityDays.isEmpty else {
            return "Need more varied activity data to analyze patterns."
        }

        let highActivityAvg = highActivityDays.compactMap { $0.vo2Max }.reduce(0, +) / Double(highActivityDays.count)
        let lowActivityAvg = lowActivityDays.compactMap { $0.vo2Max }.reduce(0, +) / Double(lowActivityDays.count)

        if highActivityAvg > lowActivityAvg * 1.05 {
            return "Your VO₂ max tends to be higher on days with 10+ circuits. Keep up the consistency!"
        } else if highActivityAvg < lowActivityAvg * 0.95 {
            return "Your VO₂ max is higher on rest days. Consider more recovery time between sessions."
        } else {
            return "VO₂ max levels appear stable regardless of daily circuit count."
        }
    }

    private var heartHealthInsight: String {
        let correlations = healthCorrelations.filter { $0.restingHeartRate != nil }
        guard !correlations.isEmpty else { return "Need resting heart rate data to analyze patterns." }

        let avgRHR = correlations.compactMap { $0.restingHeartRate }.reduce(0, +) / Double(correlations.count)

        if avgRHR < 55 {
            return "Your resting heart rate is excellent (below 55 bpm), indicating strong cardiovascular health."
        } else if avgRHR < 65 {
            return "Your resting heart rate is good (55-65 bpm). Keep up the training!"
        } else if avgRHR < 75 {
            return "Your resting heart rate is average (65-75 bpm). Regular stair circuits can help improve it."
        } else {
            return "Your resting heart rate is above average. Consider consulting a healthcare provider."
        }
    }

    private var progressTrendInsight: String {
        let sortedCorrelations = healthCorrelations.sorted { $0.dayKey < $1.dayKey }
        guard sortedCorrelations.count >= 2 else { return "Need more historical data to analyze trends." }

        let firstVO2 = sortedCorrelations.first?.vo2Max
        let lastVO2 = sortedCorrelations.last?.vo2Max

        guard let first = firstVO2, let last = lastVO2 else {
            return "Need more VO₂ max data to analyze trends."
        }

        let change = ((last - first) / first) * 100

        if change > 10 {
            return "Outstanding! Your VO₂ max has improved by \(String(format: "%.1f", change))% with regular stair circuits."
        } else if change > 5 {
            return "Great progress! Your VO₂ max has improved by \(String(format: "%.1f", change))%."
        } else if change > 0 {
            return "Your VO₂ max is improving slowly. Consistency is key!"
        } else if change > -5 {
            return "Your fitness level has remained stable. Keep pushing!"
        } else {
            return "Consider focusing on more consistent training to improve fitness."
        }
    }

    private var suggestedTargetTitle: String {
        let recentLogs = dayLogs.suffix(7)
        guard !recentLogs.isEmpty else { return "Complete more days to get suggestions" }

        let avgCompleted = recentLogs.reduce(0) { $0 + $1.completed } / recentLogs.count

        if avgCompleted >= 12 {
            return "Consider Increasing Your Target"
        } else if avgCompleted >= 8 {
            return "Target Looks Good"
        } else {
            return "Focus on Consistency"
        }
    }

    private var suggestedTargetDescription: String {
        let recentLogs = dayLogs.suffix(7)
        guard !recentLogs.isEmpty else { return "Complete at least 7 days of circuit tracking." }

        let avgCompleted = recentLogs.reduce(0) { $0 + $1.completed } / recentLogs.count
        let goalMetCount = recentLogs.filter { $0.completed >= $0.target }.count

        if avgCompleted >= 12 {
            return "Based on your recent performance, you could increase your target by 1-2 circuits."
        } else if avgCompleted >= 8 {
            return "Your current target is well-matched to your performance. Keep it up!"
        } else if goalMetCount >= 5 {
            return "You're hitting your goal consistently. Try to exceed it!"
        } else {
            return "Focus on hitting your current target consistently before adjusting."
        }
    }

    private var maxCircuits: Int {
        healthCorrelations.map { $0.circuitCount }.max() ?? 10
    }

    private var maxVO2Max: Double {
        healthCorrelations.compactMap { $0.vo2Max }.max() ?? 40
    }

    private func insightCard(icon: String, title: String, description: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.accentColor)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)

                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(12)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}
