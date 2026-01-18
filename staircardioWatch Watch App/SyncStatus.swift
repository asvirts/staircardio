import Foundation

enum SyncStatus: String {
    case idle = "Idle"
    case syncing = "Syncing"
    case synced = "Synced"
    case error = "Sync Error"
}
