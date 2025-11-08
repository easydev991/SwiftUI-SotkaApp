import Foundation
import Observation
import OSLog
import SwiftData

/// Сервис для работы с инфопостами
@MainActor
@Observable
final class InfopostsService {
    @ObservationIgnored private let logger = Logger(subsystem: "SotkaApp", category: "InfopostsService")
    private let currentLanguage: String
    private let infopostsClient: InfopostsClient
    @ObservationIgnored private var userGender: Gender?
    @ObservationIgnored private var cachedInfoposts: [Infopost]?
    /// Доступные инфопосты для текущего дня
    private var availableInfoposts: [Infopost] = []
    /// ID избранных инфопостов
    private var favoriteIds: Set<String> = [] {
        didSet {
            // Автоматически переключаем режим отображения на "все", если избранных нет
            if favoriteIds.isEmpty, displayMode != .all {
                displayMode = .all
            }
        }
    }

    /// Состояние сворачивания секций
    private var collapsedSections: Set<InfopostSection> = []

    /// Фильтрованные инфопосты с учетом режима отображения и пола пользователя
    ///
    /// Доступность уже учтена при загрузке `availableInfoposts`
    @ObservationIgnored private var filteredInfoposts: [Infopost] {
        availableInfoposts.filter { infopost in
            // Проверяем соответствие полу пользователя
            let genderMatches = userGender == nil || infopost.gender == nil || infopost.gender == userGender
            // Проверяем режим отображения (все/избранные)
            let favoriteMatches = !displayMode.showsOnlyFavorites || favoriteIds.contains(infopost.id)
            return genderMatches && favoriteMatches
        }
    }

    private(set) var todayInfopost: Infopost?

    var showDisplayModePicker: Bool {
        !favoriteIds.isEmpty
    }

    /// Режим отображения инфопостов
    var displayMode: InfopostsDisplayMode = .all

    /// Секции с инфопостами для отображения
    var sectionsForDisplay: [InfopostSectionDisplay] {
        InfopostSection.allCases.compactMap { section in
            let sectionInfoposts = filteredInfoposts.filter { $0.section == section }
            guard !sectionInfoposts.isEmpty else { return nil }
            return InfopostSectionDisplay(
                id: section,
                section: section,
                infoposts: sectionInfoposts,
                isCollapsed: collapsedSections.contains(section)
            )
        }
    }

    init(language: String, infopostsClient: InfopostsClient) {
        self.currentLanguage = language
        self.infopostsClient = infopostsClient
        logger.info("Инициализирован InfopostsService для языка: \(language)")
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
    func isFavorite(_ infopost: Infopost, modelContext: ModelContext) -> Bool {
        guard infopost.isFavoriteAvailable else {
            logger.debug("Функция избранного недоступна для инфопоста: \(infopost.id)")
            return false
        }
        do {
            let user = try getCurrentUser(modelContext: modelContext)
            let isFavorite = user.favoriteInfopostIds.contains(infopost.id)
            logger.debug("Инфопост \(infopost.id) в избранном: \(isFavorite)")
            return isFavorite
        } catch {
            logger.error("Пользователь не найден для проверки избранного")
            return false
        }
    }

    /// Изменяет статус избранного для инфопоста
    /// - Parameters:
    ///   - id: ID инфопоста
    ///   - modelContext: Контекст модели данных
    /// - Throws: Ошибка при работе с базой данных
    func changeFavorite(id: String, modelContext: ModelContext) throws {
        let user = try getCurrentUser(modelContext: modelContext)

        if user.favoriteInfopostIds.contains(id) {
            user.removeFavoriteInfopostId(id)
            favoriteIds.remove(id)
            logger.info("Удален из избранного: \(id)")
        } else {
            user.addFavoriteInfopostId(id)
            favoriteIds.insert(id)
            logger.info("Добавлен в избранное: \(id)")
        }

        try modelContext.save()
        logger.debug("Изменения сохранены в базе данных")
    }

    /// Загружает и обновляет доступные инфопосты
    /// - Parameters:
    ///   - currentDay: Текущий день программы
    ///   - maxReadInfoPostDay: Максимальный день, до которого доступны инфопосты с сервера
    ///   - userGender: Пол пользователя для фильтрации инфопостов
    ///   - force: Флаг для принудительного обновления
    /// - Throws: Ошибка при загрузке инфопостов
    func loadAvailableInfoposts(
        currentDay: Int?,
        maxReadInfoPostDay: Int = 0,
        userGender: Gender? = nil,
        force: Bool = false
    ) throws {
        // Устанавливаем пол пользователя для фильтрации
        self.userGender = userGender

        guard availableInfoposts.isEmpty || force else {
            logger.debug("Пропускаем загрузку инфопостов, так как они уже загружены")
            return
        }

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

        availableInfoposts = availablePosts
        let count = availableInfoposts.count
        logger.info("Обновлены доступные инфопосты: \(count) штук")
        try loadTodayInfopost(for: currentDay)
    }

    /// Загружает и обновляет список избранных инфопостов
    /// - Parameter modelContext: Контекст модели данных
    /// - Throws: Ошибка при работе с базой данных
    func loadFavoriteIds(modelContext: ModelContext) throws {
        do {
            let user = try getCurrentUser(modelContext: modelContext)
            favoriteIds = Set(user.favoriteInfopostIds)
            let count = favoriteIds.count
            logger.info("Обновлены избранные инфопосты: \(count) штук")
        } catch {
            logger.error("Пользователь не найден для получения избранных")
            favoriteIds = []
        }
    }

    /// Обрабатывает нажатие на заголовок секции
    /// - Parameter section: Секция, на которую нажали
    func didTapSection(_ section: InfopostSection) {
        let isCollapsed = collapsedSections.contains(section)
        if isCollapsed {
            collapsedSections.remove(section)
        } else {
            collapsedSections.insert(section)
        }
        logger.debug("Секция \(section.rawValue) \(isCollapsed ? "свернута" : "развернута")")
    }
}

private extension InfopostsService {
    /// Получает текущего пользователя из базы данных
    /// - Parameter modelContext: Контекст модели данных
    /// - Returns: Текущий пользователь или nil
    /// - Throws: Ошибка при работе с базой данных
    func getCurrentUser(modelContext: ModelContext) throws -> User {
        guard let user = try modelContext.fetch(FetchDescriptor<User>()).first else {
            throw ServiceError.userNotFound
        }
        userGender = user.gender
        return user
    }

    /// Загружает все инфопосты для текущего языка
    /// - Returns: Массив всех инфопостов
    /// - Throws: Ошибка при загрузке или парсинге инфопостов
    func loadInfoposts() throws -> [Infopost] {
        let infoposts = try parseAllInfoposts(for: currentLanguage)
        cachedInfoposts = infoposts
        logger.info("Загружено \(infoposts.count) инфопостов")
        return infoposts
    }

    /// Парсит все инфопосты для указанного языка
    /// - Parameter language: Язык инфопостов
    /// - Returns: Массив инфопостов
    /// - Throws: Ошибка при парсинге
    func parseAllInfoposts(for language: String) throws -> [Infopost] {
        var infoposts: [Infopost] = []

        // Создаем менеджер файлов для указанного языка
        let filenames = FilenameManager(language: language).getOrderedFilenames()
        logger.debug("Получен список из \(filenames.count) файлов для парсинга")

        // Парсим все файлы
        for filename in filenames {
            if let infopost = Infopost(filename: filename, language: language) {
                infoposts.append(infopost)
                logger.debug("Успешно распарсен файл: \(filename)")
            } else {
                logger.error("Не удалось распарсить файл: \(filename)")
                throw ServiceError.parsingError
            }
        }

        logger.info("Успешно распарсено \(infoposts.count) инфопостов для языка \(language)")
        return infoposts
    }

    /// Получает инфопост для текущего дня
    /// - Parameter day: Номер текущего дня
    func loadTodayInfopost(for currentDay: Int?) throws {
        let day = currentDay ?? 1
        guard let infopost = availableInfoposts.first(where: { $0.dayNumber == day }) else {
            throw ServiceError.infopostNotFound(day)
        }
        logger.debug("Найден инфопост для дня \(day)")
        todayInfopost = infopost
    }
}

extension InfopostsService {
    /// Синхронизирует прочитанные инфопосты с сервером
    /// - Parameter context: Контекст модели данных
    /// - Throws: Ошибка при синхронизации или работе с базой данных
    func syncReadPosts(context: ModelContext) async throws {
        let user = try getCurrentUser(modelContext: context)

        logger.info("Начинаем синхронизацию прочитанных инфопостов")

        do {
            // Получаем прочитанные дни с сервера
            let serverReadDays = try await infopostsClient.getReadPosts()
            logger.info("Получено \(serverReadDays.count) прочитанных дней с сервера")

            // Обновляем синхронизированные дни
            user.setReadInfopostDays(serverReadDays)

            // Параллельно отправляем несинхронизированные дни на сервер
            let successfullySyncedDays = try await withThrowingTaskGroup(of: Int?.self) { group in
                var syncedDays: [Int] = []

                // Добавляем задачи для каждого несинхронизированного дня
                for day in user.unsyncedReadInfopostDays {
                    group.addTask {
                        do {
                            try await self.infopostsClient.setPostRead(day: day)
                            self.logger.debug("Успешно синхронизирован день: \(day)")
                            return day // Возвращаем успешно синхронизированный день
                        } catch {
                            self.logger.error("Ошибка синхронизации дня \(day): \(error.localizedDescription)")
                            return nil // Возвращаем nil для неуспешных
                        }
                    }
                }

                // Собираем результаты
                for try await result in group {
                    if let day = result {
                        syncedDays.append(day)
                    }
                }

                return syncedDays
            }

            // Перемещаем успешно синхронизированные дни
            if !successfullySyncedDays.isEmpty {
                try moveDaysToSynced(successfullySyncedDays, user: user, modelContext: context)
            }

            logger.info("Синхронизация завершена. Успешно синхронизировано: \(successfullySyncedDays.count) дней")

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

        let user = try getCurrentUser(modelContext: modelContext)

        logger.info("Отмечаем инфопост дня \(day) как прочитанный")

        // Добавляем в несинхронизированные дни
        user.addUnsyncedReadInfopostDay(day)

        // Сохраняем изменения
        try modelContext.save()
        logger.debug("Инфопост дня \(day) отмечен как прочитанный локально")

        // Пытаемся синхронизировать с сервером
        do {
            try await infopostsClient.setPostRead(day: day)
            // Если успешно, перемещаем из несинхронизированных в синхронизированные
            try moveDaysToSynced([day], user: user, modelContext: modelContext)
            logger.info("Инфопост дня \(day) успешно синхронизирован с сервером")
        } catch {
            logger.error("Не удалось синхронизировать день \(day) с сервером: \(error.localizedDescription)")
        }
    }

    /// Проверяет, прочитан ли инфопост
    /// - Parameters:
    ///   - infopost: Инфопост для проверки
    ///   - modelContext: Контекст модели данных
    /// - Returns: true, если инфопост прочитан
    /// - Throws: Ошибка при работе с базой данных или если инфопост не может быть отмечен как прочитанный
    func isPostRead(_ infopost: Infopost, modelContext: ModelContext) throws -> Bool {
        guard let dayNumber = infopost.dayNumber else {
            logger.error("Инфопост \(infopost.id) не имеет номера дня, его нельзя отметить как прочитанный")
            throw ServiceError.infopostCannotBeMarkedAsRead
        }
        do {
            let user = try getCurrentUser(modelContext: modelContext)
            let isRead = user.readInfopostDays.contains(dayNumber) || user.unsyncedReadInfopostDays.contains(dayNumber)
            logger.debug("Инфопост \(infopost.id) (день \(dayNumber)) прочитан: \(isRead)")
            return isRead
        } catch {
            logger.error("Пользователь не найден для проверки статуса прочитанного")
            return false
        }
    }
}

extension InfopostsService {
    func didLogout() {
        userGender = nil
        displayMode = .all
        favoriteIds = []
        availableInfoposts = []
        collapsedSections = []
    }
}

extension InfopostsService {
    enum ServiceError: LocalizedError, Equatable {
        case userNotFound
        case infopostNotFound(_ day: Int)
        case parsingError
        case infopostCannotBeMarkedAsRead

        var errorDescription: String? {
            switch self {
            case .userNotFound:
                "Пользователь не найден"
            case let .infopostNotFound(day):
                "Инфопост \(day) не найден"
            case .parsingError:
                "Ошибка парсинга инфопоста"
            case .infopostCannotBeMarkedAsRead:
                "Инфопост не может быть отмечен как прочитанный"
            }
        }
    }
}

private extension InfopostsService {
    /// Перемещает дни из несинхронизированных в синхронизированные
    /// - Parameters:
    ///   - days: Массив дней для перемещения
    ///   - user: Пользователь
    ///   - modelContext: Контекст модели данных
    /// - Throws: Ошибка при работе с базой данных
    func moveDaysToSynced(_ days: [Int], user: User, modelContext: ModelContext) throws {
        // В одном цикле делаем обе операции
        for day in days {
            // Удаляем из несинхронизированных
            user.removeUnsyncedReadInfopostDay(day)

            // Добавляем в синхронизированные (только если еще нет)
            user.addReadInfopostDay(day)
        }

        // Сохраняем изменения один раз
        try modelContext.save()
    }
}
