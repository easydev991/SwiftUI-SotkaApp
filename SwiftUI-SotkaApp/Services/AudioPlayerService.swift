import AVFoundation
import OSLog

final class AudioPlayerManager {
    private let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier!,
        category: String(describing: AudioPlayerManager.self)
    )
    private var audioPlayer: AVAudioPlayer?
    private let session: AVAudioSession

    init(session: AVAudioSession = .sharedInstance()) {
        self.session = session
        configureAudioSession()
    }

    private func configureAudioSession() {
        do {
            try session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try session.setActive(true)
            logger.info("AudioSession успешно настроен")
        } catch {
            logger.error("Ошибка audioSession: \(error.localizedDescription, privacy: .public)")
        }
    }

    @MainActor
    @discardableResult
    func setupSound(_ timerSound: TimerSound) -> Bool {
        guard let url = timerSound.bundleURL else {
            logger.error("Звуковой файл с названием \(timerSound.rawValue) не найден в папке TimerSounds")
            return false
        }
        do {
            stop()
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.prepareToPlay()
            logger.info("Звук настроен: \(timerSound.rawValue)")
            return true
        } catch {
            logger.error("Ошибка инициализации аудиоплеера: \(error.localizedDescription, privacy: .public)")
            return false
        }
    }

    @MainActor
    @discardableResult
    func play() -> Bool {
        guard let audioPlayer else {
            logger.error("Попытка воспроизвести звук до настройки")
            return false
        }
        let result = audioPlayer.play()
        if result {
            logger.info("Звук воспроизводится")
        } else {
            logger.error("Не удалось воспроизвести звук")
        }
        return result
    }

    /// Останавливаем предыдущий звук, если он играет
    @MainActor
    func stop() {
        guard let audioPlayer, audioPlayer.isPlaying else {
            return
        }
        audioPlayer.stop()
        logger.debug("Звук остановлен")
    }
}
