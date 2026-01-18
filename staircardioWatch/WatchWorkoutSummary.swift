import Foundation

struct WatchWorkoutSummary: Equatable {
    let date: Date
    let duration: TimeInterval
    let floors: Double
    let activeEnergy: Double
    let averageHeartRate: Double

    var payload: [String: Any] {
        [
            WatchWorkoutSummaryPayload.dateKey: date,
            WatchWorkoutSummaryPayload.durationKey: duration,
            WatchWorkoutSummaryPayload.floorsKey: floors,
            WatchWorkoutSummaryPayload.activeEnergyKey: activeEnergy,
            WatchWorkoutSummaryPayload.averageHeartRateKey: averageHeartRate
        ]
    }

    static func from(_ payload: [String: Any]) -> WatchWorkoutSummary? {
        guard let date = payload[WatchWorkoutSummaryPayload.dateKey] as? Date else { return nil }
        guard let duration = payload[WatchWorkoutSummaryPayload.durationKey] as? TimeInterval else { return nil }
        guard let floors = payload[WatchWorkoutSummaryPayload.floorsKey] as? Double else { return nil }
        guard let activeEnergy = payload[WatchWorkoutSummaryPayload.activeEnergyKey] as? Double else { return nil }
        guard let averageHeartRate = payload[WatchWorkoutSummaryPayload.averageHeartRateKey] as? Double else { return nil }
        return WatchWorkoutSummary(
            date: date,
            duration: duration,
            floors: floors,
            activeEnergy: activeEnergy,
            averageHeartRate: averageHeartRate
        )
    }
}
