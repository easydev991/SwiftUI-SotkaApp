import AVFoundation
import OSLog

@MainActor
final class AudioPlayerManager {
    private let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier!,
        category: String(describing: AudioPlayerManager.self)
    )
    private var audioPlayer: AVAudioPlayer?
    private let session: AVAudioSession

    init(session: AVAudioSession = .sharedInstance()) {
        self.session = session
        // Синхронные setCategory/setActive на main thread дают предупреждение AVAudioSession_iOS.mm
        // («can lead to UI unresponsiveness») — используем async API.
        Task {
            await configureAudioSession()
        }
    }

    private func configureAudioSession() async {
        do {
            try await session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try await session.setActive(true)
            logger.info("AudioSession успешно настроен")
        } catch {
            logger.error("Ошибка audioSession: \(error.localizedDescription, privacy: .public)")
        }
    }

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

    @discardableResult
    func play() -> Bool {
        guard let audioPlayer else {
            logger.error("Попытка воспроизвести звук до настройки")
            return false
        }
        // shortcut: первый вызов в те же мс после init может сыграть до async-конфигурации сессии
        // (категория .soloAmbient вместо .playback); реальный первый звук — спустя секунды, апгрейд
        // (await-конфигурация в play()) имеет смысл только при появлении реальных глитчей.
        let result = audioPlayer.play()
        if result {
            logger.info("Звук воспроизводится")
        } else {
            logger.error("Не удалось воспроизвести звук")
        }
        return result
    }

    /// Останавливаем предыдущий звук, если он играет
    func stop() {
        guard let audioPlayer, audioPlayer.isPlaying else {
            return
        }
        audioPlayer.stop()
        logger.debug("Звук остановлен")
    }
}
