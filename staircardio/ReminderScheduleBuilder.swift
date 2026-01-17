import Foundation

enum ReminderScheduleBuilder {
    static func buildFireDates(
        calendar: Calendar,
        now: Date,
        startMinutes: Int,
        endMinutes: Int,
        intervalMinutes: Int,
        weekdaysOnly: Bool
    ) -> [Date] {
        let interval = max(intervalMinutes, 15)
        let start = max(startMinutes, 0)
        let end = max(endMinutes, start + 1)

        let startDate = nextStartDate(
            calendar: calendar,
            now: now,
            startMinutes: start,
            weekdaysOnly: weekdaysOnly
        )

        var fireDates: [Date] = []
        var currentStart = startDate

        for _ in 0..<7 {
            let daySchedule = buildDaySchedule(
                calendar: calendar,
                startDate: currentStart,
                startMinutes: start,
                endMinutes: end,
                intervalMinutes: interval
            )

            fireDates.append(contentsOf: daySchedule)
            guard let nextDay = calendar.date(byAdding: .day, value: 1, to: currentStart) else {
                break
            }
            currentStart = nextDay

            if weekdaysOnly {
                currentStart = nextWeekday(calendar: calendar, from: currentStart)
            }
        }

        return fireDates
    }

    private static func buildDaySchedule(
        calendar: Calendar,
        startDate: Date,
        startMinutes: Int,
        endMinutes: Int,
        intervalMinutes: Int
    ) -> [Date] {
        guard let dayStart = dateBySettingMinutes(calendar: calendar, date: startDate, minutes: startMinutes) else {
            return []
        }

        guard let dayEnd = dateBySettingMinutes(calendar: calendar, date: startDate, minutes: endMinutes) else {
            return []
        }

        if dayEnd <= dayStart {
            return []
        }

        var fireDates: [Date] = []
        var next = dayStart

        while next <= dayEnd {
            if next >= Date() {
                fireDates.append(next)
            }
            guard let candidate = calendar.date(byAdding: .minute, value: intervalMinutes, to: next) else {
                break
            }
            next = candidate
        }

        return fireDates
    }

    private static func nextStartDate(
        calendar: Calendar,
        now: Date,
        startMinutes: Int,
        weekdaysOnly: Bool
    ) -> Date {
        guard let todayStart = dateBySettingMinutes(calendar: calendar, date: now, minutes: startMinutes) else {
            return now
        }

        var candidate = todayStart
        if candidate < now {
            candidate = calendar.date(byAdding: .day, value: 1, to: candidate) ?? candidate
        }

        if weekdaysOnly {
            candidate = nextWeekday(calendar: calendar, from: candidate)
        }

        return candidate
    }

    private static func dateBySettingMinutes(calendar: Calendar, date: Date, minutes: Int) -> Date? {
        let clampedMinutes = max(minutes, 0)
        let hour = clampedMinutes / 60
        let minute = clampedMinutes % 60
        return calendar.date(bySettingHour: hour, minute: minute, second: 0, of: date)
    }

    private static func nextWeekday(calendar: Calendar, from date: Date) -> Date {
        var candidate = date
        while isWeekend(calendar: calendar, date: candidate) {
            candidate = calendar.date(byAdding: .day, value: 1, to: candidate) ?? candidate
        }
        return candidate
    }

    private static func isWeekend(calendar: Calendar, date: Date) -> Bool {
        calendar.isDateInWeekend(date)
    }
}
