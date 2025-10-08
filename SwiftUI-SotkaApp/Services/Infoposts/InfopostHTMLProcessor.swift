import Foundation
import OSLog

/// Сервис для обработки HTML контента инфопостов
struct InfopostHTMLProcessor {
    private let logger = Logger(subsystem: "SotkaApp", category: "InfopostHTMLProcessor")

    /// Загружает и обрабатывает HTML контент для отображения
    /// - Parameters:
    ///   - filename: Имя файла HTML
    ///   - fontSize: Размер шрифта
    ///   - infopost: Модель инфопоста
    ///   - youtubeService: Сервис для работы с YouTube
    /// - Returns: Обработанный HTML контент или nil в случае ошибки
    func loadAndProcessHTML(
        filename: String,
        fontSize: FontSize,
        infopost: Infopost,
        youtubeService: YouTubeVideoService
    ) -> String? {
        logger.info("🌐 Начинаем загрузку контента: \(filename)")

        // Загружаем HTML файл из бандла
        guard let htmlFileURL = Bundle.main.url(forResource: filename, withExtension: "html") else {
            logger.error("❌ Файл не найден: \(filename).html в бандле")
            logAvailableFiles(for: filename)
            return nil
        }

        do {
            // Загружаем HTML контент
            let htmlContent = try String(contentsOf: htmlFileURL, encoding: .utf8)

            // Подготавливаем HTML для отображения через парсер с YouTube видео
            let parser = InfopostParser(filename: filename, language: infopost.language)
            let modifiedHTML = parser.prepareHTMLForDisplay(
                htmlContent,
                fontSize: fontSize,
                infopost: infopost,
                youtubeService: youtubeService
            )

            logger.debug("✅ HTML контент успешно обработан")
            return modifiedHTML

        } catch {
            logger.error("❌ Ошибка загрузки HTML файла: \(error.localizedDescription)")
            return nil
        }
    }

    /// Логирует доступные файлы в бандле для отладки
    private func logAvailableFiles(for filename: String) {
        do {
            let bundleURL = Bundle.main.bundleURL
            let contents = try FileManager.default.contentsOfDirectory(at: bundleURL, includingPropertiesForKeys: nil)
            let htmlFiles = contents
                .filter { $0.pathExtension == "html" && $0.lastPathComponent.contains(filename.split(separator: "_").first ?? "") }
            logger.error("🔍 Найдено похожих файлов: \(htmlFiles.map(\.lastPathComponent))")
        } catch {
            logger.error("❌ Ошибка при поиске файлов: \(error.localizedDescription)")
        }
    }
}
