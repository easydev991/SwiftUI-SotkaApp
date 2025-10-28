import Foundation
import Observation
import OSLog

/// Сервис для работы с YouTube видео инфопостов
@Observable
final class YouTubeVideoService {
    @ObservationIgnored private let logger = Logger(subsystem: "SotkaApp", category: "YouTubeVideoService")
    @ObservationIgnored private var cachedVideos: [YouTubeVideo]?

    /// Получает YouTube видео для конкретного дня
    /// - Parameter dayNumber: Номер дня программы
    /// - Returns: YouTube видео или nil, если не найдено
    /// - Throws: Ошибка при загрузке видео
    func getVideo(for dayNumber: Int) throws -> YouTubeVideo? {
        logger.info("🎥 Запрашиваем YouTube видео для дня: \(dayNumber)")

        let videos = try loadVideos()
        logger.debug("📊 Загружено \(videos.count) видео из файла")

        let video = videos.first { $0.dayNumber == dayNumber }

        if let video {
            logger.info("✅ Найдено видео для дня \(dayNumber): \(video.url)")
            logger.debug("📺 Заголовок видео: \(video.title)")
        } else {
            logger.error("⚠️ Видео для дня \(dayNumber) не найдено в списке из \(videos.count) видео")
            logger.debug("📋 Доступные дни: \(videos.map(\.dayNumber).sorted())")
        }

        return video
    }

    /// Проверяет, есть ли видео для указанного дня
    /// - Parameter dayNumber: Номер дня программы
    /// - Returns: true, если видео существует
    /// - Throws: Ошибка при загрузке видео
    func hasVideo(for dayNumber: Int) throws -> Bool {
        try getVideo(for: dayNumber) != nil
    }

    /// Загружает список YouTube видео из файла `youtube_list.txt`
    /// - Returns: Массив YouTube видео
    /// - Throws: Ошибка при загрузке или парсинге файла
    func loadVideos() throws -> [YouTubeVideo] {
        if let cachedVideos {
            logger.debug("💾 Возвращаем кэшированные видео (\(cachedVideos.count) штук)")
            return cachedVideos
        }

        logger.info("📁 Загружаем YouTube видео из youtube_list.txt")

        guard let url = Bundle.main.url(forResource: "youtube_list", withExtension: "txt") else {
            logger.error("❌ Файл youtube_list.txt не найден в бандле")
            logger.debug("🔍 Проверяем доступные файлы в бандле:")
            do {
                let bundleURL = Bundle.main.bundleURL
                let contents = try FileManager.default.contentsOfDirectory(at: bundleURL, includingPropertiesForKeys: nil)
                let txtFiles = contents.filter { $0.pathExtension == "txt" }
                logger.debug("📋 Найдено txt файлов: \(txtFiles.map(\.lastPathComponent))")
            } catch {
                logger.error("❌ Ошибка при поиске файлов: \(error.localizedDescription)")
            }
            throw ServiceError.fileNotFound
        }

        logger.debug("✅ Файл youtube_list.txt найден: \(url.path)")

        do {
            let content = try String(contentsOf: url, encoding: .utf8)
            logger.debug("📄 Содержимое файла загружено: \(content.count) символов")
            logger.debug("📄 Первые 200 символов: \(String(content.prefix(200)))")

            let videos = try parseVideos(from: content)
            cachedVideos = videos
            logger.info("✅ Успешно загружено \(videos.count) YouTube видео")
            return videos
        } catch {
            logger.error("❌ Ошибка при чтении файла youtube_list.txt: \(error.localizedDescription)")
            throw ServiceError.fileReadError(error)
        }
    }
}

private extension YouTubeVideoService {
    /// Парсит видео из содержимого файла
    /// - Parameter content: Содержимое файла youtube_list.txt
    /// - Returns: Массив YouTube видео
    /// - Throws: Ошибка при парсинге
    func parseVideos(from content: String) throws -> [YouTubeVideo] {
        logger.debug("🔍 Начинаем парсинг видео из файла")

        let lines = content.components(separatedBy: .newlines)
        logger.debug("📄 Найдено \(lines.count) строк в файле")

        var videos: [YouTubeVideo] = []
        var invalidLines: [Int] = []

        for (index, line) in lines.enumerated() {
            let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)

            // Пропускаем пустые строки
            guard !trimmedLine.isEmpty else {
                logger.debug("⏭️ Пропускаем пустую строку \(index + 1)")
                continue
            }

            // Проверяем, что строка содержит валидный URL
            guard isValidYouTubeURL(trimmedLine) else {
                logger.warning("⚠️ Некорректный URL на строке \(index + 1): \(trimmedLine)")
                invalidLines.append(index + 1)
                continue
            }

            let dayNumber = index + 1
            let video = YouTubeVideo(dayNumber: dayNumber, url: trimmedLine)
            videos.append(video)

            if dayNumber <= 5 || dayNumber % 10 == 0 {
                logger.debug("✅ День \(dayNumber): \(trimmedLine)")
            }
        }

        logger.info("📊 Результат парсинга: \(videos.count) видео из \(lines.count) строк")
        if !invalidLines.isEmpty {
            logger.warning("⚠️ Некорректные строки: \(invalidLines)")
        }

        return videos
    }

    /// Проверяет, является ли строка валидным YouTube URL
    /// - Parameter urlString: Строка для проверки
    /// - Returns: true, если URL валидный
    func isValidYouTubeURL(_ urlString: String) -> Bool {
        // Проверяем, что строка содержит youtube.com или youtu.be
        urlString.contains("youtube.com") || urlString.contains("youtu.be")
    }
}

extension YouTubeVideoService {
    enum ServiceError: LocalizedError {
        case fileNotFound
        case fileReadError(Error)
        case parsingError

        var errorDescription: String? {
            switch self {
            case .fileNotFound:
                "Файл youtube_list.txt не найден"
            case let .fileReadError(error):
                "Ошибка чтения файла: \(error.localizedDescription)"
            case .parsingError:
                "Ошибка парсинга файла с видео"
            }
        }
    }
}
