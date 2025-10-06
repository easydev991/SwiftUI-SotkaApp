import Foundation
import Observation
import OSLog
import SwiftData

/// Сервис для работы с инфопостами
@Observable
final class InfopostsService {
    private let logger = Logger(subsystem: "SotkaApp", category: "InfopostsService")
    private let currentLanguage: String
    @ObservationIgnored private var cachedInfoposts: [Infopost]?

    init(language: String) {
        self.currentLanguage = language
        logger.info("Инициализирован InfopostsService для языка: \(language)")
    }

    /// Загружает все инфопосты для текущего языка
    /// - Returns: Массив всех инфопостов
    /// - Throws: Ошибка при загрузке или парсинге инфопостов
    func loadInfoposts() throws -> [Infopost] {
        cachedInfoposts = nil
        logger.debug("Очищаем кэш инфопостов для корректной загрузки")
        let infoposts = try parseAllInfoposts(for: currentLanguage)
        cachedInfoposts = infoposts
        logger.info("Загружено \(infoposts.count) инфопостов")
        return infoposts
    }

    /// Загружает конкретный инфопост по ID
    /// - Parameter id: ID инфопоста
    /// - Returns: Инфопост или nil, если не найден
    /// - Throws: Ошибка при загрузке инфопостов
    func loadInfopost(id: String) throws -> Infopost? {
        // Используем кэшированные данные, если они есть, иначе загружаем
        let infoposts: [Infopost]
        if let cached = cachedInfoposts {
            logger.debug("Используем кэшированные инфопосты для поиска: \(id)")
            infoposts = cached
        } else {
            logger.debug("Кэш пуст, загружаем инфопосты для поиска: \(id)")
            infoposts = try loadInfoposts()
        }

        let infopost = infoposts.first { $0.id == id }

        if infopost != nil {
            logger.debug("Найден инфопост: \(id)")
        } else {
            logger.warning("Инфопост не найден: \(id)")
        }

        return infopost
    }

    /// Загружает инфопост "about" напрямую из файла, минуя `filenameManager`
    /// - Returns: Инфопост "about" или nil, если не найден
    func loadAboutInfopost() -> Infopost? {
        let filename = "about"
        logger.debug("Загружаем инфопост 'about' напрямую из файла")

        if let htmlContent = InfopostParser.loadInfopostFile(filename: filename, language: currentLanguage),
           let infopost = InfopostParser.parse(html: htmlContent, filename: filename, language: currentLanguage) {
            logger.info("Успешно загружен инфопост 'about' напрямую")
            return infopost
        } else {
            logger.error("Не удалось загрузить инфопост 'about' напрямую")
            return nil
        }
    }

    /// Проверяет, является ли инфопост избранным
    /// - Parameters:
    ///   - id: ID инфопоста
    ///   - modelContext: Контекст модели данных
    /// - Returns: true, если инфопост в избранном
    /// - Throws: Ошибка при работе с базой данных
    func isInfopostFavorite(_ id: String, modelContext: ModelContext) throws -> Bool {
        if let user = try getCurrentUser(modelContext: modelContext) {
            let isFavorite = user.favoriteInfopostIds.contains(id)
            logger.debug("Инфопост \(id) в избранном: \(isFavorite)")
            return isFavorite
        }
        logger.warning("Пользователь не найден для проверки избранного")
        return false
    }

    /// Получает список ID избранных инфопостов
    /// - Parameter modelContext: Контекст модели данных
    /// - Returns: Массив ID избранных инфопостов
    /// - Throws: Ошибка при работе с базой данных
    func getFavoriteInfopostIds(modelContext: ModelContext) throws -> [String] {
        if let user = try getCurrentUser(modelContext: modelContext) {
            logger.debug("Получено \(user.favoriteInfopostIds.count) избранных инфопостов")
            return user.favoriteInfopostIds
        }
        logger.warning("Пользователь не найден для получения избранных")
        return []
    }

    /// Изменяет статус избранного для инфопоста
    /// - Parameters:
    ///   - id: ID инфопоста
    ///   - modelContext: Контекст модели данных
    /// - Throws: Ошибка при работе с базой данных
    func changeFavorite(id: String, modelContext: ModelContext) throws {
        guard let user = try getCurrentUser(modelContext: modelContext) else {
            logger.error("Пользователь не найден для изменения избранного")
            throw InfopostsServiceError.userNotFound
        }

        if user.favoriteInfopostIds.contains(id) {
            user.favoriteInfopostIds.removeAll { $0 == id }
            logger.info("Удален из избранного: \(id)")
        } else {
            user.favoriteInfopostIds.append(id)
            logger.info("Добавлен в избранное: \(id)")
        }

        try modelContext.save()
        logger.debug("Изменения сохранены в базе данных")
    }

    /// Возвращает только доступные инфопосты в зависимости от текущего дня
    /// - Parameters:
    ///   - currentDay: Текущий день программы
    ///   - maxReadInfoPostDay: Максимальный день, до которого доступны инфопосты с сервера
    /// - Returns: Массив доступных инфопостов
    /// - Throws: Ошибка при загрузке инфопостов
    func getAvailableInfoposts(currentDay: Int?, maxReadInfoPostDay: Int = 0) throws -> [Infopost] {
        // Используем кэшированные данные, если они есть, иначе загружаем
        let allInfoposts: [Infopost]
        if let cached = cachedInfoposts {
            logger.debug("Используем кэшированные инфопосты (\(cached.count) штук)")
            allInfoposts = cached
        } else {
            logger.debug("Кэш пуст, загружаем инфопосты")
            allInfoposts = try loadInfoposts()
        }

        let availabilityManager = InfopostAvailabilityManager(
            currentDay: currentDay ?? 0,
            maxReadInfoPostDay: maxReadInfoPostDay
        )

        let availablePosts = availabilityManager.filterAvailablePosts(allInfoposts)
        logger.debug("Отфильтровано \(availablePosts.count) доступных инфопостов из \(allInfoposts.count)")

        return availablePosts
    }

    // MARK: - Private Methods

    /// Получает текущего пользователя из базы данных
    /// - Parameter modelContext: Контекст модели данных
    /// - Returns: Текущий пользователь или nil
    /// - Throws: Ошибка при работе с базой данных
    private func getCurrentUser(modelContext: ModelContext) throws -> User? {
        let users = try modelContext.fetch(FetchDescriptor<User>())
        return users.first
    }

    /// Парсит все инфопосты для указанного языка
    /// - Parameter language: Язык инфопостов
    /// - Returns: Массив инфопостов
    /// - Throws: Ошибка при парсинге
    private func parseAllInfoposts(for language: String) throws -> [Infopost] {
        var infoposts: [Infopost] = []

        // Создаем менеджер файлов для указанного языка
        let filenameManager = FilenameManager(language: language)
        let filenames = filenameManager.getOrderedFilenames()
        logger.debug("Получен список из \(filenames.count) файлов для парсинга")

        // Парсим все файлы
        for filename in filenames {
            if let htmlContent = InfopostParser.loadInfopostFile(filename: filename, language: language),
               let infopost = InfopostParser.parse(html: htmlContent, filename: filename, language: language) {
                infoposts.append(infopost)
                logger.debug("Успешно распарсен файл: \(filename)")
            } else {
                logger.warning("Не удалось распарсить файл: \(filename)")
            }
        }

        logger.info("Успешно распарсено \(infoposts.count) инфопостов для языка \(language)")
        return infoposts
    }
}

// MARK: - Errors

enum InfopostsServiceError: LocalizedError {
    case userNotFound
    case infopostNotFound
    case parsingError

    var errorDescription: String? {
        switch self {
        case .userNotFound:
            "Пользователь не найден"
        case .infopostNotFound:
            "Инфопост не найден"
        case .parsingError:
            "Ошибка парсинга инфопоста"
        }
    }
}
