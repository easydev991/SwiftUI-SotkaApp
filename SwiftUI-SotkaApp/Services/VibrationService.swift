import AudioToolbox
import CoreHaptics
import OSLog
import UIKit

@MainActor
struct VibrationService {
    private static let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "SotkaApp",
        category: String(describing: VibrationService.self)
    )
    private static var engine: CHHapticEngine?
    private static var isPrepared = false

    static func perform() {
        prepareHaptics()
        if CHHapticEngine.capabilitiesForHardware().supportsHaptics,
           let engine {
            do {
                let intensity = CHHapticEventParameter(parameterID: .hapticIntensity, value: 1.0)
                let sharpness = CHHapticEventParameter(parameterID: .hapticSharpness, value: 1.0)
                let event = CHHapticEvent(
                    eventType: .hapticContinuous,
                    parameters: [intensity, sharpness],
                    relativeTime: 0,
                    duration: 0.5
                )
                let pattern = try CHHapticPattern(events: [event], parameters: [])
                let player = try engine.makePlayer(with: pattern)
                try player.start(atTime: 0)
                logger.info("Вибрация выполнена через CoreHaptics (hapticContinuous)")
            } catch {
                logger.error("Ошибка воспроизведения вибрации через CoreHaptics: \(error.localizedDescription)")
            }
        } else {
            AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
            logger.info("Вибрация выполнена через AudioServicesPlaySystemSound (fallback)")
        }
    }
}

private extension VibrationService {
    static func prepareHaptics() {
        guard !isPrepared else { return }
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else {
            logger.warning("Устройство не поддерживает CoreHaptics")
            return
        }
        do {
            engine = try CHHapticEngine()
            engine?.stoppedHandler = { reason in
                logger.warning("Haptic engine остановлен: \(reason.rawValue)")
                isPrepared = false
            }
            engine?.resetHandler = {
                logger.info("Haptic engine требует сброса")
                do {
                    try engine?.start()
                } catch {
                    logger.error("Ошибка перезапуска haptic engine: \(error.localizedDescription)")
                }
            }
            try engine?.start()
            isPrepared = true
            logger.info("Haptic engine подготовлен")
        } catch {
            logger.error("Ошибка подготовки haptic engine: \(error.localizedDescription)")
        }
    }
}
