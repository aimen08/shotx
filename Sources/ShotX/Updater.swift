import Cocoa
import Sparkle

@MainActor
final class UpdaterController {
    static let shared = UpdaterController()

    let controller: SPUStandardUpdaterController

    private init() {
        // startingUpdater: true → enables automatic background checks
        // (frequency controlled by SUScheduledCheckInterval in Info.plist,
        // defaults to once a day).
        controller = SPUStandardUpdaterController(
            startingUpdater: true,
            updaterDelegate: nil,
            userDriverDelegate: nil
        )
    }

    func checkForUpdates() {
        controller.checkForUpdates(nil)
    }
}
