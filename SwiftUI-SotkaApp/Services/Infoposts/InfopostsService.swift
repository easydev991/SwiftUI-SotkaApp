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
        let infoposts = try loadInfoposts()
        let infopost = infoposts.first { $0.id == id }

        if infopost != nil {
            logger.debug("Найден инфопост: \(id)")
        } else {
            logger.warning("Инфопост не найден: \(id)")
        }

        return infopost
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

        // Список файлов инфопостов для парсинга в правильном порядке
        let filenames = [
            "about", // Дополнительная информация о программе (первая в списке)
            "organiz", "aims", // Подготовка (BLOCK_PREPARE)
            "d1", "d2", "d3", "d4", "d5", "d6", "d7", "d8", "d9", "d10",
            "d11", "d12", "d13", "d14", "d15", "d16", "d17", "d18", "d19", "d20",
            "d21", "d22", "d23", "d24", "d25", "d26", "d27", "d28", "d29", "d30",
            "d31", "d32", "d33", "d34", "d35", "d36", "d37", "d38", "d39", "d40",
            "d41", "d42", "d43", "d44", "d45", "d46", "d47", "d48", "d49", "d50",
            "d51", "d52", "d53", "d54", "d55", "d56", "d57", "d58", "d59", "d60",
            "d61", "d62", "d63", "d64", "d65", "d66", "d67", "d68", "d69", "d70",
            "d71", "d72", "d73", "d74", "d75", "d76", "d77", "d78", "d79", "d80",
            "d81", "d82", "d83", "d84", "d85", "d86", "d87", "d88", "d89", "d90",
            "d91", "d92", "d93", "d94", "d95", "d96", "d97", "d98", "d99", "d100"
        ]

        // Добавляем специальный файл для женщин, если он есть (только для русского языка)
        var allFilenames = filenames
        if language == "ru" {
            let womenFilename = "d0-women"
            if InfopostParser.loadInfopostFile(filename: womenFilename, language: language) != nil {
                allFilenames = [womenFilename] + filenames
            }
        }

        // Парсим все файлы
        for filename in allFilenames {
            if let htmlContent = InfopostParser.loadInfopostFile(filename: filename, language: language),
               let infopost = InfopostParser.parse(html: htmlContent, filename: filename, language: language) {
                infoposts.append(infopost)
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
