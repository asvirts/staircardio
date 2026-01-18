import SwiftData
import SwiftUI

struct StreakCalendarView: View {
    @Query private var dayLogs: [DayLog]
    @State private var selectedMonth: Date = Date()
    @State private var selectedDay: DayLog?

    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 16) {
                Text("Streak Calendar")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                HStack(spacing: 32) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Current Streak")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text("\(currentStreak)")
                            .font(.title)
                            .fontWeight(.bold)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Longest Streak")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text("\(longestStreak)")
                            .font(.title)
                            .fontWeight(.bold)
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }

            VStack(spacing: 16) {
                monthSelector

                calendarGrid

                legend
            }
            .padding()
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .padding()
        .navigationTitle("Calendar")
        .sheet(item: $selectedDay) { day in
            DayDetailView(dayLog: day)
        }
    }

    private var monthSelector: some View {
        HStack {
            Button(action: { moveMonth(by: -1) }) {
                Image(systemName: "chevron.left")
                    .font(.title2)
                    .foregroundColor(.accentColor)
            }

            Text(monthTitle)
                .font(.title3)
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity)

            Button(action: { moveMonth(by: 1) }) {
                Image(systemName: "chevron.right")
                    .font(.title2)
                    .foregroundColor(.accentColor)
            }
        }
    }

    private var calendarGrid: some View {
        let days = calendarDays()
        let columns = Array(repeating: GridItem(.flexible(), spacing: 6), count: 7)

        return VStack(spacing: 8) {
            HStack(spacing: 6) {
                ForEach(["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"], id: \.self) { day in
                    Text(day)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }

            LazyVGrid(columns: columns, spacing: 6) {
                ForEach(days, id: \.dayKey) { dayData in
                    CalendarDayCell(dayData: dayData)
                        .onTapGesture {
                            if let log = dayData.dayLog {
                                selectedDay = log
                            }
                        }
                }
            }
        }
    }

    private var legend: some View {
        HStack(spacing: 20) {
            LegendItem(color: .green, label: "Goal Met")
            LegendItem(color: .orange, label: "Partial")
            LegendItem(color: Color(.systemGray5), label: "No Activity")
            LegendItem(color: .clear, label: "Future")
        }
        .font(.caption)
    }

    private var monthTitle: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: selectedMonth)
    }

    private var currentStreak: Int {
        let today = Date()
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: today) ?? today

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let todayKey = dateFormatter.string(from: today)
        let yesterdayKey = dateFormatter.string(from: yesterday)

        let sortedLogs = dayLogs.sorted { $0.dayKey > $1.dayKey }
        var streak = 0
        var currentDate = today

        for log in sortedLogs {
            let logKey = dateFormatter.string(from: currentDate)
            if let todayLog = sortedLogs.first(where: { $0.dayKey == logKey }) {
                if todayLog.completed >= todayLog.target {
                    streak += 1
                    currentDate = Calendar.current.date(byAdding: .day, value: -1, to: currentDate) ?? currentDate
                } else {
                    break
                }
            } else {
                break
            }
        }

        return streak
    }

    private var longestStreak: Int {
        let sortedLogs = dayLogs.sorted { $0.dayKey < $1.dayKey }
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

    private func calendarDays() -> [CalendarDayData] {
        let calendar = Calendar.current
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"

        guard let firstDayOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: selectedMonth)) else {
            return []
        }

        let firstWeekday = calendar.component(.weekday, from: firstDayOfMonth)
        let numberOfDays = calendar.range(of: .day, in: .month, for: selectedMonth)?.count ?? 0

        var days: [CalendarDayData] = []

        for i in 1..<(firstWeekday - 1) {
            days.append(CalendarDayData(day: 0, dayKey: "", status: .none, dayLog: nil))
        }

        for day in 1...numberOfDays {
            guard let date = calendar.date(bySetting: .day, value: day, of: selectedMonth) else {
                days.append(CalendarDayData(day: day, dayKey: "", status: .none, dayLog: nil))
                continue
            }

            let dayKey = dateFormatter.string(from: date)
            if let log = dayLogs.first(where: { $0.dayKey == dayKey }) {
                if log.completed >= log.target {
                    days.append(CalendarDayData(day: day, dayKey: dayKey, status: .success, dayLog: log))
                } else if log.completed > 0 {
                    days.append(CalendarDayData(day: day, dayKey: dayKey, status: .partial, dayLog: log))
                } else {
                    days.append(CalendarDayData(day: day, dayKey: dayKey, status: .none, dayLog: log))
                }
            } else {
                let isFuture = date > Date()
                if isFuture {
                    days.append(CalendarDayData(day: day, dayKey: dayKey, status: .future, dayLog: nil))
                } else {
                    days.append(CalendarDayData(day: day, dayKey: dayKey, status: .none, dayLog: nil))
                }
            }
        }

        return days
    }
}

struct CalendarDayData {
    let day: Int
    let dayKey: String
    let status: DayStatus
    let dayLog: DayLog?
}

struct CalendarDayCell: View {
    let dayData: CalendarDayData

    var body: some View {
        if dayData.day > 0 {
            Text("\(dayData.day)")
                .font(.caption)
                .fontWeight(dayData.status == .success ? .bold : .medium)
                .frame(width: 40, height: 40)
                .background(backgroundColor)
                .foregroundColor(foregroundColor)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(borderColor, lineWidth: dayData.status == .future ? 0 : 1)
                )
        } else {
            Text("")
                .frame(width: 40, height: 40)
        }
    }

    private var backgroundColor: Color {
        switch dayData.status {
        case .success:
            return .green
        case .partial:
            return .orange
        case .none:
            return Color(.systemGray6)
        case .future:
            return .clear
        }
    }

    private var foregroundColor: Color {
        switch dayData.status {
        case .success, .partial:
            return .white
        case .none:
            return .secondary
        case .future:
            return .clear
        }
    }

    private var borderColor: Color {
        switch dayData.status {
        case .success:
            return .green
        case .partial:
            return .orange
        case .none:
            return Color(.systemGray4)
        case .future:
            return .clear
        }
    }
}

struct LegendItem: View {
    let color: Color
    let label: String

    var body: some View {
        HStack(spacing: 6) {
            RoundedRectangle(cornerRadius: 4)
                .fill(color)
                .frame(width: 16, height: 16)
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(Color(.systemGray4), lineWidth: color == .clear ? 0 : 0)
                )

            Text(label)
        }
    }
}

struct DayDetailView: View {
    let dayLog: DayLog
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 12) {
                    Text(dateString(for: dayLog.dayKey))
                        .font(.title2)
                        .fontWeight(.bold)

                    Text("\(dayLog.completed) / \(dayLog.target) circuits")
                        .font(.title3)
                }

                ProgressView(value: Double(dayLog.completed) / Double(dayLog.target))
                    .progressViewStyle(.linear)
                    .tint(dayLog.completed >= dayLog.target ? .green : .orange)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Details")
                        .font(.headline)

                    if dayLog.completed >= dayLog.target {
                        Label("Goal reached", systemImage: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                    } else {
                        Label("\(dayLog.target - dayLog.completed) circuits remaining", systemImage: "exclamationmark.triangle")
                            .foregroundStyle(.orange)
                    }
                }

                Spacer()
            }
            .padding()
            .navigationTitle("Day Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }

    private func dateString(for dayKey: String) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"

        guard let date = dateFormatter.date(from: dayKey) else {
            return dayKey
        }

        let displayFormatter = DateFormatter()
        displayFormatter.dateFormat = "EEEE, MMMM d, yyyy"
        return displayFormatter.string(from: date)
    }
}
