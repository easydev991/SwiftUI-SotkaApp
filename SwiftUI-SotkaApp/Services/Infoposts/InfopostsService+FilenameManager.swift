import Foundation
import OSLog

extension InfopostsService {
    /// Менеджер для управления порядком файлов инфопостов
    struct FilenameManager {
        private let logger = Logger(subsystem: "SotkaApp", category: "InfopostsService.FilenameManager")
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
            if InfopostParser.loadInfopostFile(filename: womenFilename, language: language) != nil {
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

        /// Проверяет, должен ли файл быть включен для настроенного языка
        /// - Parameter filename: Имя файла
        /// - Returns: true, если файл должен быть включен
        private func shouldIncludeFile(_ filename: String) -> Bool {
            // Женская статья только для русского языка
            if filename == "d0-women" {
                return language == "ru"
            }

            // Все остальные файлы включаем для всех языков
            return true
        }

        /// Возвращает секцию инфопоста на основе имени файла
        /// - Parameter filename: Имя файла
        /// - Returns: Секция инфопоста
        private func getSection(for filename: String) -> InfopostSection {
            // Используем существующий метод из InfopostSection
            InfopostSection.section(for: filename)
        }

        /// Возвращает номер дня для файлов дней программы
        /// - Parameter filename: Имя файла (например, "d1", "d25")
        /// - Returns: Номер дня или nil, если файл не является файлом дня
        private func getDayNumber(from filename: String) -> Int? {
            // Проверяем, что файл начинается с "d" и имеет правильный формат
            guard filename.hasPrefix("d"), filename.count <= 4 else {
                return nil
            }

            // Извлекаем номер дня
            let dayString = String(filename.dropFirst())
            return Int(dayString)
        }
    }
}
