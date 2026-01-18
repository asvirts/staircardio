import Foundation
import SwiftData

@MainActor
final class BehavioralAnalyzer {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func detectPlateau(days: Int = 7) -> Bool {
        let logs = fetchRecentDayLogs(days: days)
        guard logs.count >= 3 else { return false }

        let avgCompleted = Double(logs.reduce(0) { $0 + $1.completed }) / Double(logs.count)

        let variance = logs.reduce(0.0) { sum, log in
            let diff = Double(log.completed) - avgCompleted
            return sum + (diff * diff)
        } / Double(logs.count)

        let standardDeviation = sqrt(variance)
        return standardDeviation < 1.5
    }

    func suggestTargetAdjustment() -> Int? {
        let logs = fetchRecentDayLogs(days: 7)
        guard logs.count >= 5 else { return nil }

        let avgCompleted = Double(logs.reduce(0) { $0 + $1.completed }) / Double(logs.count)
        let currentTarget = Double(logs.first?.target ?? 10)

        let goalMetRate = Double(logs.filter { $0.completed >= $0.target }.count) / Double(logs.count)

        if goalMetRate > 0.9 && avgCompleted > currentTarget * 1.2 {
            let suggestedTarget = Int(round(currentTarget * 1.1))
            return max(suggestedTarget, Int(avgCompleted))
        } else if goalMetRate < 0.4 {
            let suggestedTarget = Int(round(currentTarget * 0.9))
            return max(suggestedTarget, 1)
        } else {
            return nil
        }
    }

    func getPatternAnalysis() -> PatternAnalysis {
        let logs = fetchRecentDayLogs(days: 14)
        guard logs.count >= 5 else {
            return PatternAnalysis(
                pattern: "Need more data",
                bestDay: nil,
                worstDay: nil,
                suggestion: "Complete more days of circuit tracking for pattern analysis."
            )
        }

        let dayOfWeekTotals = Dictionary(grouping: logs) { log in
            dayOfWeek(from: log.dayKey)
        }.mapValues { logs in
            DayOfWeekStats(
                totalCircuits: logs.reduce(0) { $0 + $1.completed },
                days: logs.count,
                avgCircuits: Double(logs.reduce(0) { $0 + $1.completed }) / Double(logs.count)
            )
        }

        let bestDay = dayOfWeekTotals.max { $0.value.avgCircuits < $1.value.avgCircuits }
        let worstDay = dayOfWeekTotals.min { $0.value.avgCircuits < $1.value.avgCircuits }

        let pattern: String
        let suggestion: String
        let bestDayName: String?
        let worstDayName: String?

        if let best = bestDay, let worst = worstDay {
            if best.value.avgCircuits > worst.value.avgCircuits * 1.5 {
                pattern = "Strong weekly pattern detected"
                suggestion = "You perform best on \(best.key). Consider scheduling harder sessions on that day."
                bestDayName = best.key
                worstDayName = worst.key
            } else {
                pattern = "Consistent performance"
                suggestion = "Your performance is stable throughout the week. Keep up consistency!"
                bestDayName = best.key
                worstDayName = worst.key
            }
        } else {
            pattern = "Need more data"
            suggestion = "Complete more days of circuit tracking for pattern analysis."
            bestDayName = nil
            worstDayName = nil
        }

        return PatternAnalysis(
            pattern: pattern,
            bestDay: bestDayName,
            worstDay: worstDayName,
            suggestion: suggestion
        )
    }

    func getConsistencyScore(days: Int = 14) -> Double {
        let logs = fetchRecentDayLogs(days: days)
        guard !logs.isEmpty else { return 0 }

        let goalMetCount = logs.filter { $0.completed >= $0.target }.count
        return Double(goalMetCount) / Double(logs.count)
    }

    func getWeeklyComparison() -> WeeklyComparison {
        let thisWeekLogs = fetchDayLogsForWeek(weekOffset: 0)
        let lastWeekLogs = fetchDayLogsForWeek(weekOffset: 1)

        let thisWeekTotal = thisWeekLogs.reduce(0) { $0 + $1.completed }
        let lastWeekTotal = lastWeekLogs.reduce(0) { $0 + $1.completed }

        let change = lastWeekTotal > 0 ? Double(thisWeekTotal - lastWeekTotal) / Double(lastWeekTotal) * 100 : 0

        return WeeklyComparison(
            thisWeekTotal: thisWeekTotal,
            lastWeekTotal: lastWeekTotal,
            percentChange: change
        )
    }

    private func fetchRecentDayLogs(days: Int) -> [DayLog] {
        let calendar = Calendar.current
        let endDate = Date()
        guard let startDate = calendar.date(byAdding: .day, value: -days, to: endDate) else {
            return []
        }

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"

        let startKey = dateFormatter.string(from: startDate)
        let endKey = dateFormatter.string(from: endDate)

        let descriptor = FetchDescriptor<DayLog>(
            predicate: #Predicate<DayLog> { log in
                log.dayKey >= startKey && log.dayKey <= endKey
            },
            sortBy: [SortDescriptor(\.dayKey, order: .reverse)]
        )

        return (try? modelContext.fetch(descriptor)) ?? []
    }

    private func fetchDayLogsForWeek(weekOffset: Int) -> [DayLog] {
        let calendar = Calendar.current
        let endDate = calendar.date(byAdding: .day, value: -(weekOffset * 7), to: Date()) ?? Date()
        guard let startDate = calendar.date(byAdding: .day, value: -7, to: endDate) else {
            return []
        }

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"

        let startKey = dateFormatter.string(from: startDate)
        let endKey = dateFormatter.string(from: endDate)

        let descriptor = FetchDescriptor<DayLog>(
            predicate: #Predicate<DayLog> { log in
                log.dayKey >= startKey && log.dayKey < endKey
            }
        )

        return (try? modelContext.fetch(descriptor)) ?? []
    }

    private func dayOfWeek(from dayKey: String) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"

        guard let date = dateFormatter.date(from: dayKey) else {
            return "Unknown"
        }

        let displayFormatter = DateFormatter()
        displayFormatter.dateFormat = "EEEE"
        return displayFormatter.string(from: date)
    }
}

struct PatternAnalysis {
    let pattern: String
    let bestDay: String?
    let worstDay: String?
    let suggestion: String
}

struct DayOfWeekStats {
    let totalCircuits: Int
    let days: Int
    let avgCircuits: Double
}

struct WeeklyComparison {
    let thisWeekTotal: Int
    let lastWeekTotal: Int
    let percentChange: Double

    var trend: TrendDirection {
        if percentChange > 5 {
            return .up
        } else if percentChange < -5 {
            return .down
        } else {
            return .flat
        }
    }
}
