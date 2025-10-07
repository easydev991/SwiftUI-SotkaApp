import Foundation
import Observation
import OSLog
import SwiftData

/// Сервис для работы с инфопостами
@MainActor
@Observable
final class InfopostsService {
    private let logger = Logger(subsystem: "SotkaApp", category: "InfopostsService")
    private let currentLanguage: String
    private let infopostsClient: InfopostsClient
    @ObservationIgnored private var cachedInfoposts: [Infopost]?

    init(language: String, infopostsClient: InfopostsClient) {
        self.currentLanguage = language
        self.infopostsClient = infopostsClient
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

        if let infopost = Infopost(filename: filename, language: currentLanguage) {
            logger.info("Успешно загружен инфопост 'about' напрямую")
            return infopost
        } else {
            logger.error("Не удалось загрузить инфопост 'about' напрямую")
            return nil
        }
    }

    /// Проверяет, является ли инфопост избранным
    /// - Parameters:
    ///   - infopost: Инфопост для проверки
    ///   - modelContext: Контекст модели данных
    /// - Returns: true, если инфопост в избранном
    /// - Throws: Ошибка при работе с базой данных
    func isInfopostFavorite(_ infopost: Infopost, modelContext: ModelContext) throws -> Bool {
        guard infopost.isFavoriteAvailable else {
            logger.debug("Функция избранного недоступна для инфопоста: \(infopost.id)")
            return false
        }

        if let user = try getCurrentUser(modelContext: modelContext) {
            let isFavorite = user.favoriteInfopostIds.contains(infopost.id)
            logger.debug("Инфопост \(infopost.id) в избранном: \(isFavorite)")
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

    // MARK: - Синхронизация с сервером

    /// Синхронизирует прочитанные инфопосты с сервером
    /// - Parameter modelContext: Контекст модели данных
    /// - Throws: Ошибка при синхронизации или работе с базой данных
    func syncReadPosts(modelContext: ModelContext) async throws {
        guard let user = try getCurrentUser(modelContext: modelContext) else {
            logger.error("Пользователь не найден для синхронизации")
            throw InfopostsServiceError.userNotFound
        }

        logger.info("Начинаем синхронизацию прочитанных инфопостов")

        do {
            // Получаем прочитанные дни с сервера
            let serverReadDays = try await infopostsClient.getReadPosts()
            logger.info("Получено \(serverReadDays.count) прочитанных дней с сервера")

            // Обновляем синхронизированные дни
            user.readInfopostDays = serverReadDays

            // Отправляем несинхронизированные дни на сервер
            for day in user.unsyncedReadInfopostDays {
                do {
                    try await infopostsClient.setPostRead(day: day)
                    logger.debug("Успешно синхронизирован день: \(day)")
                } catch {
                    logger.error("Ошибка синхронизации дня \(day): \(error.localizedDescription)")
                    // Продолжаем синхронизацию других дней
                }
            }

            // Очищаем несинхронизированные дни после успешной отправки
            user.unsyncedReadInfopostDays = []

            // Сохраняем изменения
            try modelContext.save()
            logger.info("Синхронизация завершена успешно")

        } catch {
            logger.error("Ошибка синхронизации: \(error.localizedDescription)")
            throw error
        }
    }

    /// Отмечает инфопост как прочитанный
    /// - Parameters:
    ///   - day: День инфопоста (может быть nil)
    ///   - modelContext: Контекст модели данных
    /// - Throws: Ошибка при работе с базой данных
    func markPostAsRead(day: Int?, modelContext: ModelContext) async throws {
        guard let day else {
            logger.warning("Попытка отметить nil день как прочитанный")
            return
        }

        guard let user = try getCurrentUser(modelContext: modelContext) else {
            logger.error("Пользователь не найден для отметки прочитанного")
            throw InfopostsServiceError.userNotFound
        }

        logger.info("Отмечаем инфопост дня \(day) как прочитанный")

        // Добавляем в несинхронизированные дни
        if !user.unsyncedReadInfopostDays.contains(day) {
            user.unsyncedReadInfopostDays.append(day)
        }

        // Сохраняем изменения
        try modelContext.save()
        logger.debug("Инфопост дня \(day) отмечен как прочитанный локально")

        // Пытаемся синхронизировать с сервером
        do {
            try await infopostsClient.setPostRead(day: day)
            // Если успешно, перемещаем из несинхронизированных в синхронизированные
            user.unsyncedReadInfopostDays.removeAll { $0 == day }
            if !user.readInfopostDays.contains(day) {
                user.readInfopostDays.append(day)
            }
            try modelContext.save()
            logger.info("Инфопост дня \(day) успешно синхронизирован с сервером")
        } catch {
            logger.error("Не удалось синхронизировать день \(day) с сервером: \(error.localizedDescription)")
        }
    }

    /// Проверяет, прочитан ли инфопост
    /// - Parameters:
    ///   - day: День инфопоста
    ///   - modelContext: Контекст модели данных
    /// - Returns: true, если инфопост прочитан
    /// - Throws: Ошибка при работе с базой данных
    func isPostRead(day: Int, modelContext: ModelContext) throws -> Bool {
        guard let user = try getCurrentUser(modelContext: modelContext) else {
            logger.error("Пользователь не найден для проверки статуса прочитанного")
            return false
        }
        let isRead = user.readInfopostDays.contains(day) || user.unsyncedReadInfopostDays.contains(day)
        logger.debug("Инфопост дня \(day) прочитан: \(isRead)")
        return isRead
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
            if let infopost = Infopost(filename: filename, language: language) {
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
