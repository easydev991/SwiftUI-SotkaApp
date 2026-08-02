import AudioToolbox
import OSLog

@MainActor
enum VibrationService {
    private static let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "SotkaApp",
        category: "VibrationService"
    )

    static func perform() {
        AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
        logger.info("Вибрация выполнена через AudioServicesPlaySystemSound")
    }
}
