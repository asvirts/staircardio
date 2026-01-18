import Combine
import HealthKit
import SwiftUI

@MainActor
final class WatchWorkoutManager: NSObject, ObservableObject {
    @Published private(set) var sessionErrorMessage: String?
    @Published var liveDuration: TimeInterval = 0
    @Published var liveFloors: Double = 0
    @Published var liveActiveEnergy: Double = 0
    @Published var liveHeartRate: Double = 0

    private let healthStore = HKHealthStore()
    private var workoutSession: HKWorkoutSession?
    private var workoutBuilder: HKLiveWorkoutBuilder?
    private var startDate: Date?

    func startWorkout() {
        #if os(watchOS)
        guard HKHealthStore.isHealthDataAvailable() else {
            sessionErrorMessage = "Health data is not available on this device."
            return
        }

        let configuration = HKWorkoutConfiguration()
        configuration.activityType = .stairClimbing
        configuration.locationType = .indoor

        do {
            let session = try HKWorkoutSession(healthStore: healthStore, configuration: configuration)
            let builder = session.associatedWorkoutBuilder()
            builder.dataSource = HKLiveWorkoutDataSource(healthStore: healthStore, workoutConfiguration: configuration)

            session.delegate = self
            builder.delegate = self

            workoutSession = session
            workoutBuilder = builder
            startDate = Date()
            resetLiveMetrics()
            sessionErrorMessage = nil

            session.startActivity(with: startDate ?? Date())
            builder.beginCollection(withStart: startDate ?? Date()) { [weak self] _, error in
                if let error {
                    Task { @MainActor in
                        self?.sessionErrorMessage = "Workout failed: \(error.localizedDescription)"
                    }
                }
            }
        } catch {
            sessionErrorMessage = "Unable to start workout session."
        }
        #else
        sessionErrorMessage = "Workout sessions require watchOS."
        #endif
    }

    func endWorkout() async -> WatchWorkoutSummary? {
        #if os(watchOS)
        guard let session = workoutSession, let builder = workoutBuilder else { return nil }
        session.end()
        builder.endCollection(withEnd: Date()) { _, _ in }

        return await withCheckedContinuation { continuation in
            builder.finishWorkout { workout, error in
                Task { @MainActor in
                    self.workoutSession = nil
                    self.workoutBuilder = nil
                    if let error {
                        self.sessionErrorMessage = "Workout save failed: \(error.localizedDescription)"
                    }
                }
                guard let workout else {
                    continuation.resume(returning: nil)
                    return
                }
                let summary = WatchWorkoutSummary(
                    date: workout.startDate,
                    duration: workout.duration,
                    floors: self.liveFloors,
                    activeEnergy: self.liveActiveEnergy,
                    averageHeartRate: self.liveHeartRate
                )
                continuation.resume(returning: summary)
            }
        }
        #else
        return nil
        #endif
    }

    private func resetLiveMetrics() {
        liveDuration = 0
        liveFloors = 0
        liveActiveEnergy = 0
        liveHeartRate = 0
    }
}

extension WatchWorkoutManager: HKWorkoutSessionDelegate {
    nonisolated func workoutSession(
        _ workoutSession: HKWorkoutSession,
        didChangeTo toState: HKWorkoutSessionState,
        from fromState: HKWorkoutSessionState,
        date: Date
    ) {
        Task { @MainActor in
            if toState == .ended {
                resetLiveMetrics()
            }
        }
    }

    nonisolated func workoutSession(_ workoutSession: HKWorkoutSession, didFailWithError error: Error) {
        Task { @MainActor in
            sessionErrorMessage = "Workout error: \(error.localizedDescription)"
        }
    }
}

extension WatchWorkoutManager: HKLiveWorkoutBuilderDelegate {
    nonisolated func workoutBuilderDidCollectEvent(_ workoutBuilder: HKLiveWorkoutBuilder) {}

    nonisolated func workoutBuilder(
        _ workoutBuilder: HKLiveWorkoutBuilder,
        didCollectDataOf collectedTypes: Set<HKSampleType>
    ) {
        Task { @MainActor in
            updateMetrics(from: workoutBuilder)
        }
    }

    private func updateMetrics(from builder: HKLiveWorkoutBuilder) {
        liveDuration = builder.elapsedTime

        if let energyType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned),
           let energy = builder.statistics(for: energyType)?.sumQuantity() {
            liveActiveEnergy = energy.doubleValue(for: .kilocalorie())
        }

        if let floorsType = HKQuantityType.quantityType(forIdentifier: .flightsClimbed),
           let floors = builder.statistics(for: floorsType)?.sumQuantity() {
            liveFloors = floors.doubleValue(for: .count())
        }

        if let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate),
           let heartRate = builder.statistics(for: heartRateType)?.mostRecentQuantity() {
            liveHeartRate = heartRate.doubleValue(for: HKUnit.count().unitDivided(by: .minute()))
        }
    }
}
