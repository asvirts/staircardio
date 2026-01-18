import Foundation
import SwiftUI

enum AppError: LocalizedError {
    case healthKitNotAvailable
    case healthKitAuthorizationFailed
    case workoutSessionFailed
    case workoutSaveFailed(String)
    case cloudKitSyncFailed
    case cloudKitNotSignedIn
    case dataSaveFailed
    case invalidTarget
    case notificationPermissionDenied

    var errorDescription: String? {
        switch self {
        case .healthKitNotAvailable:
            return "Health data is not available on this device."
        case .healthKitAuthorizationFailed:
            return "Failed to authorize HealthKit access."
        case .workoutSessionFailed:
            return "Unable to start workout session. Please try again."
        case .workoutSaveFailed(let message):
            return "Failed to save workout: \(message)"
        case .cloudKitSyncFailed:
            return "Failed to sync data with iCloud."
        case .cloudKitNotSignedIn:
            return "Please sign in to iCloud to enable sync."
        case .dataSaveFailed:
            return "Failed to save data. Please try again."
        case .invalidTarget:
            return "Invalid target value. Please enter a number greater than 0."
        case .notificationPermissionDenied:
            return "Notifications are disabled in Settings. Enable them to receive reminders."
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .healthKitNotAvailable, .healthKitAuthorizationFailed:
            return "Open Settings > Privacy & Security > Health to enable access."
        case .cloudKitNotSignedIn:
            return "Open Settings > [Your Name] > iCloud to sign in."
        case .notificationPermissionDenied:
            return "Open Settings > Notifications to enable notifications."
        default:
            return nil
        }
    }
}

struct AlertHelper {
    static func errorAlert(for error: AppError) -> Alert {
        return Alert(
            title: Text("common.error".localized),
            message: Text(error.errorDescription ?? "common.error".localized),
            dismissButton: .default(Text("common.ok".localized))
        )
    }

    static func errorAlertWithRecovery(for error: AppError) -> Alert {
        let message = if let recovery = error.recoverySuggestion {
            "\(error.errorDescription ?? "")\n\n\(recovery)"
        } else {
            error.errorDescription ?? "common.error".localized
        }

        return Alert(
            title: Text("common.error".localized),
            message: Text(message),
            dismissButton: .default(Text("common.ok".localized))
        )
    }
}

extension String {
    var localized: String {
        NSLocalizedString(self, comment: "")
    }
}
