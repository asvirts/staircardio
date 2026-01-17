import SwiftData
import SwiftUI
import UserNotifications

@main
struct staircardioApp: App {
    private let modelContainer: ModelContainer
    private let watchSyncManager = WatchSyncManager()
    private let notificationHandler = NotificationHandler()
    private let healthKitManager = HealthKitManager()

    init() {
        let schema = Schema([DayLog.self, WorkoutLog.self])
        let configuration = ModelConfiguration(
            schema: schema,
            cloudKitDatabase: .private(CloudKitConfig.containerIdentifier)
        )

        do {
            modelContainer = try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }

        watchSyncManager.configure(modelContainer: modelContainer)
        UNUserNotificationCenter.current().delegate = notificationHandler
        CloudKitConfig.logSetupInstructions()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(watchSyncManager)
                .environmentObject(healthKitManager)
        }
        .modelContainer(modelContainer)
    }
}
