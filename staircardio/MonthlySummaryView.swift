import SwiftData
import SwiftUI
import Charts

struct MonthlySummaryView: View {
    @Query private var dayLogs: [DayLog]
    @State private var selectedTimeRange: TimeRange = .thirty
    @State private var selectedMonth: Date = Date()

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                timeRangePicker

                monthlyStatsCards

                VStack(alignment: .leading, spacing: 16) {
                    Text("30-Day Trend")
                        .font(.headline)

                    trendChart
                }
                .padding()
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 16))

                streakCalendarSection
            }
            .padding()
        }
        .navigationTitle("Monthly")
    }

    private var timeRangePicker: some View {
        Picker("Time Range", selection: $selectedTimeRange) {
            ForEach([TimeRange.thirty, .sixty, .ninety], id: \.self) { range in
                Text(range.label).tag(range)
            }
        }
        .pickerStyle(.segmented)
        .padding(.horizontal)
    }

    private var monthlyStatsCards: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 12) {
            StatsCard(
                icon: "trophy.fill",
                value: "\(monthlyLongestStreak)",
                label: "Longest Streak"
            )

            StatsCard(
                icon: "checkmark.circle.fill",
                value: "\(monthlyGoalAchievement)%",
                label: "Goal Rate"
            )

            StatsCard(
                icon: "flame.fill",
                value: "\(monthlyTotalCircuits)",
                label: "Total Circuits"
            )

            StatsCard(
                icon: "star.fill",
                value: String(format: "%.1f", monthlyAveragePerDay),
                label: "Avg/Day"
            )
        }
    }

    private var trendChart: some View {
        Chart(filteredDayLogs) { log in
            LineMark(
                x: .value("Day", log.dayKey),
                y: .value("Circuits", log.completed)
            )
            .foregroundStyle(Color.accentColor.gradient)
            .interpolationMethod(.catmullRom)

            AreaMark(
                x: .value("Day", log.dayKey),
                y: .value("Circuits", log.completed)
            )
            .foregroundStyle(
                LinearGradient(
                    colors: [.accentColor.opacity(0.3), .accentColor.opacity(0.05)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .interpolationMethod(.catmullRom)
        }
        .frame(height: 200)
        .chartXAxis {
            AxisMarks(position: .bottom, values: .stride(by: .day)) { _ in
                AxisGridLine()
                AxisValueLabel(format: .dateTime.day(.twoDigits))
            }
        }
    }

    private var streakCalendarSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Streak Calendar")
                .font(.headline)

            VStack(spacing: 16) {
                monthSelector

                calendarGrid
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var monthSelector: some View {
        HStack {
            Button(action: { moveMonth(by: -1) }) {
                Image(systemName: "chevron.left")
                    .font(.title3)
            }

            Text(monthTitle)
                .font(.headline)
                .frame(maxWidth: .infinity)

            Button(action: { moveMonth(by: 1) }) {
                Image(systemName: "chevron.right")
                    .font(.title3)
            }
        }
    }

    private var calendarGrid: some View {
        let days = calendarDays()
        let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 7)

        return VStack(spacing: 8) {
            HStack(spacing: 4) {
                ForEach(["S", "M", "T", "W", "T", "F", "S"], id: \.self) { day in
                    Text(day)
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }

            LazyVGrid(columns: columns, spacing: 4) {
                ForEach(days, id: \.day) { dayData in
                    DayCell(dayData: dayData)
                }
            }
        }
    }

    private var monthTitle: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: selectedMonth)
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
        }.sorted { $0.dayKey < $1.dayKey }
    }

    private var monthlyTotalCircuits: Int {
        filteredDayLogs.reduce(0) { $0 + $1.completed }
    }

    private var monthlyAveragePerDay: Double {
        guard !filteredDayLogs.isEmpty else { return 0 }
        return Double(monthlyTotalCircuits) / Double(filteredDayLogs.count)
    }

    private var monthlyGoalAchievement: Int {
        guard !filteredDayLogs.isEmpty else { return 0 }
        let goalsMet = filteredDayLogs.filter { $0.completed >= $0.target }.count
        return Int((Double(goalsMet) / Double(filteredDayLogs.count)) * 100)
    }

    private var monthlyLongestStreak: Int {
        let sortedLogs = filteredDayLogs.sorted { $0.dayKey < $1.dayKey }
        var longestStreak = 0
        var currentStreak = 0

        for log in sortedLogs {
            if log.completed >= log.target {
                currentStreak += 1
                if currentStreak > longestStreak {
                    longestStreak = currentStreak
                }
            } else {
                currentStreak = 0
            }
        }

        return longestStreak
    }

    private func moveMonth(by months: Int) {
        if let newMonth = Calendar.current.date(byAdding: .month, value: months, to: selectedMonth) {
            selectedMonth = newMonth
        }
    }

    private func calendarDays() -> [DayData] {
        let calendar = Calendar.current
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"

        guard let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: selectedMonth)),
              let monthEnd = calendar.date(byAdding: .month, value: 1, to: monthStart)?.addingTimeInterval(-1) else {
            return []
        }

        guard let firstDayOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: selectedMonth)) else {
            return []
        }

        let firstWeekday = calendar.component(.weekday, from: firstDayOfMonth)
        let numberOfDays = calendar.range(of: .day, in: .month, for: selectedMonth)?.count ?? 0

        var days: [DayData] = []

        for i in 1..<(firstWeekday - 1) {
            days.append(DayData(day: 0, status: .none))
        }

        for day in 1...numberOfDays {
            guard let date = calendar.date(bySetting: .day, value: day, of: selectedMonth) else {
                days.append(DayData(day: day, status: .none))
                continue
            }

            let dayKey = dateFormatter.string(from: date)
            if let log = dayLogs.first(where: { $0.dayKey == dayKey }) {
                if log.completed >= log.target {
                    days.append(DayData(day: day, status: .success))
                } else if log.completed > 0 {
                    days.append(DayData(day: day, status: .partial))
                } else {
                    days.append(DayData(day: day, status: .none))
                }
            } else {
                let isFuture = date > Date()
                if isFuture {
                    days.append(DayData(day: day, status: .future))
                } else {
                    days.append(DayData(day: day, status: .none))
                }
            }
        }

        return days
    }
}

struct DayData {
    let day: Int
    let status: DayStatus
}

enum DayStatus {
    case success
    case partial
    case none
    case future
}

struct DayCell: View {
    let dayData: DayData

    var body: some View {
        if dayData.day > 0 {
            Text("\(dayData.day)")
                .font(.caption)
                .fontWeight(.medium)
                .frame(width: 36, height: 36)
                .background(backgroundColor)
                .foregroundColor(foregroundColor)
                .clipShape(RoundedRectangle(cornerRadius: 6))
        } else {
            Text("")
                .frame(width: 36, height: 36)
        }
    }

    private var backgroundColor: Color {
        switch dayData.status {
        case .success:
            return .green
        case .partial:
            return .orange
        case .none:
            return Color(.systemGray5)
        case .future:
            return .clear
        }
    }

    private var foregroundColor: Color {
        switch dayData.status {
        case .success:
            return .white
        case .partial:
            return .white
        case .none:
            return .secondary
        case .future:
            return .clear
        }
    }
}
