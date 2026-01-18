import Foundation

struct WatchWorkoutSummary: Equatable {
    let date: Date
    let duration: TimeInterval
    let floors: Double
    let activeEnergy: Double
    let averageHeartRate: Double
}
