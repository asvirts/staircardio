import Combine
import Foundation
import HealthKit

@MainActor
final class HealthKitManager: NSObject, ObservableObject {
    override init() {
        super.init()
    }
    @Published private(set) var authorizationStatus: HKAuthorizationStatus = .notDetermined
    @Published private(set) var isWorkoutActive = false
    @Published private(set) var sessionErrorMessage: String?

    @Published var liveDuration: TimeInterval = 0
    @Published var liveFloors: Double = 0
    @Published var liveActiveEnergy: Double = 0
    @Published var liveHeartRate: Double = 0

    private let healthStore = HKHealthStore()
    private var workoutSession: HKWorkoutSession?
    private var workoutBuilder: HKLiveWorkoutBuilder?
    private var startDate: Date?

    func refreshAuthorizationStatus() {
        authorizationStatus = healthStore.authorizationStatus(for: .workoutType())
    }

    func requestAuthorization() async {
        guard HKHealthStore.isHealthDataAvailable() else {
            sessionErrorMessage = "Health data is not available on this device."
            return
        }

        let shareTypes = Set([
            HKObjectType.workoutType(),
            HKObjectType.quantityType(forIdentifier: .activeEnergyBurned),
            HKObjectType.quantityType(forIdentifier: .heartRate),
            HKObjectType.quantityType(forIdentifier: .stepCount),
            HKObjectType.quantityType(forIdentifier: .flightsClimbed)
        ].compactMap { $0 })

        let readTypes: Set<HKObjectType> = Set(shareTypes)

        do {
            try await healthStore.requestAuthorization(toShare: shareTypes, read: readTypes)
            refreshAuthorizationStatus()
        } catch {
            sessionErrorMessage = "HealthKit authorization failed."
        }
    }

    func startWorkout() {
        #if os(iOS)
        guard workoutSession == nil else { return }

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
            liveDuration = 0
            liveFloors = 0
            liveActiveEnergy = 0
            liveHeartRate = 0
            sessionErrorMessage = nil

            session.startActivity(with: startDate ?? Date())
            builder.beginCollection(withStart: startDate ?? Date()) { [weak self] _, error in
                if let error {
                    Task { @MainActor in
                        self?.sessionErrorMessage = "Workout failed: \(error.localizedDescription)"
                    }
                }
            }

            isWorkoutActive = true
        } catch {
            sessionErrorMessage = "Unable to start workout session."
        }
        #else
        sessionErrorMessage = "Workout sessions require iOS."
        #endif
    }

    func endWorkout() async -> HKWorkout? {
        #if os(iOS)
        guard let session = workoutSession, let builder = workoutBuilder else { return nil }
        session.end()
        builder.endCollection(withEnd: Date()) { _, _ in }

        return await withCheckedContinuation { continuation in
            builder.finishWorkout { workout, error in
                Task { @MainActor in
                    self.isWorkoutActive = false
                    self.workoutSession = nil
                    self.workoutBuilder = nil
                    if let error {
                        self.sessionErrorMessage = "Workout save failed: \(error.localizedDescription)"
                    }
                }
                continuation.resume(returning: workout)
            }
        }
        #else
        return nil
        #endif
    }

    func resetLiveMetrics() {
        liveDuration = 0
        liveFloors = 0
        liveActiveEnergy = 0
        liveHeartRate = 0
    }

    func fetchRecentStairWorkouts(limit: Int) async -> [HKWorkout] {
        let predicate = HKQuery.predicateForWorkouts(with: .stairClimbing)
        let sort = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)

        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: .workoutType(),
                predicate: predicate,
                limit: limit,
                sortDescriptors: [sort]
            ) { _, samples, _ in
                continuation.resume(returning: samples as? [HKWorkout] ?? [])
            }
            healthStore.execute(query)
        }
    }

    func fetchAverageHeartRate(for workout: HKWorkout) async -> Double {
        guard let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate) else {
            return 0
        }

        let predicate = HKQuery.predicateForSamples(withStart: workout.startDate, end: workout.endDate)
        let sort = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)

        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: heartRateType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [sort]
            ) { _, samples, _ in
                let quantities = (samples as? [HKQuantitySample]) ?? []
                let values = quantities.map { $0.quantity.doubleValue(for: HKUnit.count().unitDivided(by: .minute())) }
                guard !values.isEmpty else {
                    continuation.resume(returning: 0)
                    return
                }
                continuation.resume(returning: values.reduce(0, +) / Double(values.count))
            }
            healthStore.execute(query)
        }
    }
}

extension HealthKitManager: HKWorkoutSessionDelegate {
    nonisolated func workoutSession(
        _ workoutSession: HKWorkoutSession,
        didChangeTo toState: HKWorkoutSessionState,
        from fromState: HKWorkoutSessionState,
        date: Date
    ) {
        Task { @MainActor in
            if toState == .ended {
                isWorkoutActive = false
            }
        }
    }

    nonisolated func workoutSession(_ workoutSession: HKWorkoutSession, didFailWithError error: Error) {
        Task { @MainActor in
            sessionErrorMessage = "Workout error: \(error.localizedDescription)"
            isWorkoutActive = false
        }
    }
}

extension HealthKitManager: HKLiveWorkoutBuilderDelegate {
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
