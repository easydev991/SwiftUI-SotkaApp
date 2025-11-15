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
            try session.setCategory(.playback, mode: .default)
            try session.setActive(true)
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
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.prepareToPlay()
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
        return audioPlayer.play()
    }

    func stop() {
        guard let audioPlayer, audioPlayer.isPlaying else {
            return
        }
        audioPlayer.stop()
    }
}
