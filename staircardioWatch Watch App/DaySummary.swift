import Foundation

struct DaySummary: Equatable {
    static let dayKeyKey = "dayKey"
    static let completedKey = "completed"
    static let targetKey = "target"
    static let floorsPerCircuitKey = "floorsPerCircuit"

    let dayKey: String
    let completed: Int
    let target: Int
    let floorsPerCircuit: Int

    var payload: [String: Any] {
        [
            Self.dayKeyKey: dayKey,
            Self.completedKey: completed,
            Self.targetKey: target,
            Self.floorsPerCircuitKey: floorsPerCircuit
        ]
    }

    static func from(_ payload: [String: Any]) -> DaySummary? {
        guard let dayKey = payload[Self.dayKeyKey] as? String else { return nil }
        guard let completed = payload[Self.completedKey] as? Int else { return nil }
        guard let target = payload[Self.targetKey] as? Int else { return nil }
        guard let floorsPerCircuit = payload[Self.floorsPerCircuitKey] as? Int else { return nil }
        return DaySummary(
            dayKey: dayKey,
            completed: completed,
            target: target,
            floorsPerCircuit: floorsPerCircuit
        )
    }
}
