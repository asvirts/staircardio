import SwiftData
import SwiftUI
import Charts

struct WeeklySummaryView: View {
    @Query private var dayLogs: [DayLog]
    @State private var selectedTimeRange: TimeRange = .seven

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                timeRangePicker

                statsGrid

                VStack(alignment: .leading, spacing: 16) {
                    Text("Circuits Per Day")
                        .font(.headline)

                    circuitsChart
                }
                .padding()
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 16))

                VStack(alignment: .leading, spacing: 16) {
                    Text("Completion Rate")
                        .font(.headline)

                    completionRateChart
                }
                .padding()
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
        }
        .padding()
        .navigationTitle("Analytics")
    }

    private var timeRangePicker: some View {
        Picker("Time Range", selection: $selectedTimeRange) {
            ForEach(TimeRange.allCases) { range in
                Text(range.label).tag(range)
            }
        }
        .pickerStyle(.segmented)
        .padding(.horizontal)
        .accessibilityLabel("Time range selector")
        .accessibilityHint("Select time range for analytics display")
    }

    private var statsGrid: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 12) {
            StatsCard(
                icon: "flame.fill",
                value: "\(weeklyStats.totalCircuits)",
                label: "Total Circuits",
                trend: trendDirection(for: weeklyStats.totalCircuits),
                trendLabel: trendLabel(for: weeklyStats.totalCircuits)
            )

            StatsCard(
                icon: "figure.walk",
                value: String(format: "%.1f", weeklyStats.averageCircuitsPerDay),
                label: "Avg per Day"
            )

            StatsCard(
                icon: "star.fill",
                value: "\(Int(weeklyStats.completionRate * 100))%",
                label: "Goal Rate"
            )

            StatsCard(
                icon: "calendar",
                value: "\(weeklyStats.streakDays)",
                label: "Current Streak"
            )
        }
    }

    private var circuitsChart: some View {
        Chart(filteredDayLogs) { log in
            BarMark(
                x: .value("Day", dayLabel(for: log.dayKey)),
                y: .value("Circuits", log.completed)
            )
            .foregroundStyle(log.completed >= log.target ? .green : .orange)
        }
        .frame(height: 200)
        .chartYAxis {
            AxisMarks(position: .leading)
        }
    }

    private var completionRateChart: some View {
        Chart(filteredDayLogs) { log in
            let completionRate = log.target > 0 ? Double(log.completed) / Double(log.target) : 0
            LineMark(
                x: .value("Day", dayLabel(for: log.dayKey)),
                y: .value("Rate", completionRate)
            )
            .foregroundStyle(.blue)

            if completionRate >= 1.0 {
                PointMark(
                    x: .value("Day", dayLabel(for: log.dayKey)),
                    y: .value("Rate", 1.0)
                )
                .foregroundStyle(.green)
                .annotation(position: .top) {
                    Text("✓").font(.caption2)
                }
            }
        }
        .frame(height: 200)
        .chartYAxis {
            AxisMarks(position: .leading, values: [0, 0.5, 1.0]) { value in
                AxisGridLine()
                AxisValueLabel {
                    if let doubleValue = value.as(Double.self) {
                        Text("\(Int(doubleValue * 100))%")
                    }
                }
            }
        }
    }

    private var filteredDayLogs: [DayLog] {
        let calendar = Calendar.current
        let endDate = Date()
        guard let startDate = calendar.date(byAdding: .day, value: -selectedTimeRange.days, to: endDate) else {
            return dayLogs
        }

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"

        return dayLogs.filter { log in
            guard let logDate = dateFormatter.date(from: log.dayKey) else { return false }
            return logDate >= startDate && logDate <= endDate
        }
    }

    private var weeklyStats: WeeklyStats {
        let logs = filteredDayLogs
        guard !logs.isEmpty else {
            return WeeklyStats()
        }

        let totalCircuits = logs.reduce(0) { $0 + $1.completed }
        let totalDays = Double(logs.count)
        let goalsMet = logs.filter { $0.completed >= $0.target }.count
        let completionRate = totalDays > 0 ? Double(goalsMet) / totalDays : 0
        let averageCircuitsPerDay = totalDays > 0 ? Double(totalCircuits) / totalDays : 0

        let sortedLogs = logs.sorted { a, b in
            guard let dateA = dateFromKey(a.dayKey), let dateB = dateFromKey(b.dayKey) else {
                return false
            }
            return dateA > dateB
        }

        var currentStreak = 0
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let yesterdayKey = dateFormatter.string(from: yesterday)

        for log in sortedLogs {
            if log.dayKey == yesterdayKey {
                currentStreak = 1
                break
            }
        }

        for (index, log) in sortedLogs.enumerated() {
            if index > 0 {
                let currentLog = sortedLogs[index]
                let previousLog = sortedLogs[index - 1]

                guard let currentDate = dateFromKey(currentLog.dayKey),
                      let previousDate = dateFromKey(previousLog.dayKey) else {
                    break
                }

                let daysDiff = Calendar.current.dateComponents([.day], from: previousDate, to: currentDate).day ?? 1

                if daysDiff == 1 && currentLog.completed >= currentLog.target {
                    currentStreak += 1
                } else {
                    break
                }
            }
        }

        return WeeklyStats(
            totalCircuits: totalCircuits,
            completionRate: completionRate,
            streakDays: currentStreak,
            bestDay: nil,
            averageCircuitsPerDay: averageCircuitsPerDay
        )
    }

    private func dayLabel(for dayKey: String) -> String {
        guard let date = dateFromKey(dayKey) else { return dayKey }
        let formatter = DateFormatter()
        formatter.dateFormat = "E"
        return formatter.string(from: date)
    }

    private func dateString(for dayKey: String) -> String {
        guard let date = dateFromKey(dayKey) else { return dayKey }
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter.string(from: date)
    }

    private func dateFromKey(_ dayKey: String) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: dayKey)
    }

    private func trendDirection(for currentValue: Int) -> TrendDirection {
        if currentValue < 10 {
            return .flat
        } else if currentValue < 20 {
            return .up
        } else {
            return .up
        }
    }

    private func trendLabel(for currentValue: Int) -> String {
        if currentValue < 10 {
            return "Start"
        } else if currentValue < 20 {
            return "Good"
        } else {
            return "+\(currentValue / 10 * 10)"
        }
    }
}

#Preview("WeeklySummaryView Preview") {
    WeeklySummaryView()
        .modelContainer(for: [DayLog.self], inMemory: true)
}
