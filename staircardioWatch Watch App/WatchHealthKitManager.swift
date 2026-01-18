import Combine
import HealthKit
import SwiftUI

@MainActor
final class WatchHealthKitManager: ObservableObject {
    @Published private(set) var isAuthorized = false
    @Published private(set) var authorizationError: String?

    private let healthStore = HKHealthStore()

    func requestAuthorization() async {
        guard HKHealthStore.isHealthDataAvailable() else {
            authorizationError = "Health data is not available on this device."
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
            isAuthorized = true
        } catch {
            authorizationError = "HealthKit authorization failed."
        }
    }
}
