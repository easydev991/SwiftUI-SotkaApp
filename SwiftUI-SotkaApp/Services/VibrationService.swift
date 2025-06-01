import OSLog
import UIKit

struct VibrationService {
    private let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier!,
        category: String(describing: VibrationService.self)
    )

    @MainActor
    func perform() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        logger.debug("Выполняем вибрацию")
    }
}
