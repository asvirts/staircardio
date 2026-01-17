import Foundation
import SwiftData

@Model
final class DayLog {
    var dayKey: String = ""
    var completed: Int = 0
    var target: Int = 10
    var appliedWorkoutUUIDs: [UUID] = []

    init(
        dayKey: String,
        completed: Int = 0,
        target: Int = 10,
        appliedWorkoutUUIDs: [UUID] = []
    ) {
        self.dayKey = dayKey
        self.completed = completed
        self.target = target
        self.appliedWorkoutUUIDs = appliedWorkoutUUIDs
    }
}
