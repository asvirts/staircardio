import Foundation
import OSLog

final class Log {
    static let shared = Logger(subsystem: "com.staircardio", category: "app")

    static func error(_ message: String, _ error: Error?) {
        if let error {
            shared.error("\(message): \(error.localizedDescription)")
        } else {
            shared.error("\(message)")
        }
    }

    static func warning(_ message: String) {
        shared.warning("\(message)")
    }

    static func info(_ message: String) {
        shared.info("\(message)")
    }

    static func debug(_ message: String) {
        shared.debug("\(message)")
    }
}
