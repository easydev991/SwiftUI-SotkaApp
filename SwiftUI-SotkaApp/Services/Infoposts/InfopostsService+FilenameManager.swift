import Foundation
import OSLog

extension InfopostsService {
    /// Менеджер для управления порядком файлов инфопостов
    struct FilenameManager {
        private let logger = Logger(subsystem: Bundle.sotkaAppBundleId, category: String(describing: FilenameManager.self))
        private let language: String

        /// Инициализатор менеджера файлов инфопостов
        /// - Parameter language: Язык инфопостов ("ru" или "en")
        init(language: String) {
            self.language = language
            logger.debug("Инициализирован FilenameManager для языка: \(language)")
        }

        /// Возвращает упорядоченный список имен файлов инфопостов для настроенного языка
        /// - Returns: Массив имен файлов в правильном порядке
        func getOrderedFilenames() -> [String] {
            logger.debug("Формируем список файлов для языка: \(language)")

            // Базовый список файлов в правильном порядке
            let baseFilenames = getBaseFilenames()

            // Список файлов дней программы (d1-d100)
            let dayFilenames = getDayFilenames()

            // Объединяем базовые файлы и файлы дней
            var allFilenames = baseFilenames + dayFilenames

            // Для русского языка добавляем женскую статью (d0-women) после целей программы
            if language == "ru" {
                allFilenames = addWomenFileIfNeeded(to: allFilenames)
            }

            logger.info("Сформирован список из \(allFilenames.count) файлов для языка \(language)")
            return allFilenames
        }

        /// Возвращает базовые файлы в правильном порядке
        /// - Returns: Массив базовых файлов
        private func getBaseFilenames() -> [String] {
            [
                "organiz", // 1. Организационные моменты
                "aims" // 2. Цели программы
            ]
        }

        /// Возвращает список файлов дней программы
        /// - Returns: Массив файлов дней (d1-d100)
        private func getDayFilenames() -> [String] {
            (1 ... 100).map { "d\($0)" }
        }

        /// Добавляет женскую статью для русского языка, если файл существует
        /// - Parameter filenames: Текущий список файлов
        /// - Returns: Обновленный список файлов
        private func addWomenFileIfNeeded(to filenames: [String]) -> [String] {
            let womenFilename = "d0-women"

            // Проверяем, существует ли файл женской статьи
            if Infopost(filename: womenFilename, language: language) != nil {
                logger.debug("Добавляем женскую статью \(womenFilename) для русского языка")
                // Вставляем женскую статью после "aims" (индекс 1)
                var updatedFilenames = filenames
                updatedFilenames.insert(womenFilename, at: 2)
                return updatedFilenames
            } else {
                logger.warning("Файл женской статьи \(womenFilename) не найден для русского языка")
                return filenames
            }
        }
    }
}
