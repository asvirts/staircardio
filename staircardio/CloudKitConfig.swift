import Foundation

enum CloudKitConfig {
    static let containerIdentifier = "iCloud.dev.virts.staircardio"

    static func logSetupInstructions() {
        #if DEBUG
        print("CloudKit setup required: add iCloud capability, enable CloudKit, and select container \"\(containerIdentifier)\".")
        #endif
    }
}
