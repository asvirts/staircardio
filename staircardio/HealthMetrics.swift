import Foundation
import SwiftData

@Model
final class VO2MaxRecord {
    var id: UUID = UUID()
    var date: Date = Date()
    var vo2MaxValue: Double = 0

    init(
        date: Date = Date(),
        vo2MaxValue: Double = 0
    ) {
        self.id = UUID()
        self.date = date
        self.vo2MaxValue = vo2MaxValue
    }
}

@Model
final class RestingHeartRateRecord {
    var id: UUID = UUID()
    var date: Date = Date()
    var restingHeartRate: Double = 0

    init(
        date: Date = Date(),
        restingHeartRate: Double = 0
    ) {
        self.id = UUID()
        self.date = date
        self.restingHeartRate = restingHeartRate
    }
}

@Model
final class HealthCorrelation {
    var id: UUID = UUID()
    var dayKey: String = ""
    var circuitCount: Int = 0
    var vo2Max: Double?
    var restingHeartRate: Double?
    var date: Date = Date()

    init(
        dayKey: String,
        circuitCount: Int = 0,
        vo2Max: Double? = nil,
        restingHeartRate: Double? = nil,
        date: Date = Date()
    ) {
        self.id = UUID()
        self.dayKey = dayKey
        self.circuitCount = circuitCount
        self.vo2Max = vo2Max
        self.restingHeartRate = restingHeartRate
        self.date = date
    }
}
