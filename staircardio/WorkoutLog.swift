import Foundation
import SwiftData

@Model
final class WorkoutLog {
    var id: UUID = UUID()
    var workoutUUID: UUID = UUID()
    var startDate: Date = Date()
    var endDate: Date = Date()
    var duration: TimeInterval = 0
    var floors: Double = 0
    var activeEnergy: Double = 0
    var averageHeartRate: Double = 0
    var circuits: Int = 0
    var appliedDayKey: String?

    init(
        workoutUUID: UUID,
        startDate: Date,
        endDate: Date,
        duration: TimeInterval,
        floors: Double,
        activeEnergy: Double,
        averageHeartRate: Double,
        circuits: Int,
        appliedDayKey: String? = nil
    ) {
        self.id = UUID()
        self.workoutUUID = workoutUUID
        self.startDate = startDate
        self.endDate = endDate
        self.duration = duration
        self.floors = floors
        self.activeEnergy = activeEnergy
        self.averageHeartRate = averageHeartRate
        self.circuits = circuits
        self.appliedDayKey = appliedDayKey
    }
}
