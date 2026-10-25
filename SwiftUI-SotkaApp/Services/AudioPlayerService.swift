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
        // setCategory существует только в синхронных перегрузках (async-варианта нет),
        // поэтому исполняем его вне main thread: nonisolated async-метод выполняется
        // на global executor (SE-0338), а не на MainActor вызывающего Task.
        // Активацию сессии (setActive) не делаем: Apple рекомендует откладывать её
        // до начала воспроизведения — AVAudioPlayer.play() активирует сессию сам.
        // При повышении deployment target до iOS 27 можно перейти на
        // try await session.activate(options: []).
        Task {
            await configureCategory()
        }
    }

    private nonisolated func configureCategory() async {
        do {
            try session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
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
        // AVAudioPlayer.play() активирует сессию на main изнутри AVFoundation — это даёт
        // os_log «AVAudioSession_iOS.mm:978 Hang Risk» (1 на прогон тестов). Принято: предупреждение
        // от недр AVFoundation при Apple-рекомендованной отложенной активации, на UX не влияет.
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
