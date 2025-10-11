import Foundation
import SwiftData
@testable import SwiftUI_SotkaApp
import Testing

struct InfopostsServiceTests {
    // MARK: - Private Methods

    /// Создает InfopostsService с MockInfopostsClient для тестирования
    /// - Parameter language: Язык для сервиса
    /// - Returns: Настроенный сервис для тестов
    @MainActor
    private func createService(language: String) -> InfopostsService {
        let mockClient = MockInfopostsClient(result: .success)
        return InfopostsService(language: language, infopostsClient: mockClient)
    }

    // MARK: - Тесты загрузки инфопостов

    @Test
    @MainActor
    func loadAvailableInfopostsSuccess() throws {
        // Arrange
        let service = createService(language: "ru")

        // Act
        try service.loadAvailableInfoposts(currentDay: 100, maxReadInfoPostDay: 0)

        // Assert
        let sections = service.sectionsForDisplay
        #expect(!sections.isEmpty)

        // Проверяем, что есть основные инфопосты через секции
        let allInfopostIds = sections.flatMap { $0.infoposts.map(\.id) }
        #expect(allInfopostIds.contains("organiz"))
        #expect(allInfopostIds.contains("aims"))
        #expect(allInfopostIds.contains("d0-women"))
        #expect(allInfopostIds.contains("d1"))
        #expect(allInfopostIds.contains("d100"))
    }

    @Test
    @MainActor
    func loadAvailableInfopostsWithEnglishLanguage() throws {
        // Arrange
        let service = createService(language: "en")

        // Act
        try service.loadAvailableInfoposts(currentDay: 100, maxReadInfoPostDay: 0)

        // Assert
        let sections = service.sectionsForDisplay
        #expect(!sections.isEmpty)

        // Проверяем, что все инфопосты имеют английский язык
        let allInfoposts = sections.flatMap(\.infoposts)
        for infopost in allInfoposts {
            #expect(infopost.language == "en")
        }
    }

    @Test
    @MainActor
    func loadAvailableInfopostsWithRussianLanguage() throws {
        // Arrange
        let service = createService(language: "ru")

        // Act
        try service.loadAvailableInfoposts(currentDay: 100, maxReadInfoPostDay: 0)

        // Assert
        let sections = service.sectionsForDisplay
        #expect(!sections.isEmpty)

        // Проверяем, что все инфопосты имеют русский язык
        let allInfoposts = sections.flatMap(\.infoposts)
        for infopost in allInfoposts {
            #expect(infopost.language == "ru")
        }
    }

    // MARK: - Тесты загрузки конкретного инфопоста

    @Test
    @MainActor
    func loadAboutInfopostSuccess() throws {
        // Arrange
        let service = createService(language: "ru")

        // Act
        let infopost = service.loadAboutInfopost()

        // Assert
        let validInfopost = try #require(infopost)
        #expect(validInfopost.id == "about")
        #expect(validInfopost.language == "ru")
        #expect(!validInfopost.title.isEmpty)
        #expect(!validInfopost.content.isEmpty)
    }

    // MARK: - Тесты работы с избранным

    @Test
    @MainActor
    func isInfopostFavoriteWhenUserExists() throws {
        // Arrange
        let service = createService(language: "ru")
        let modelContainer = try ModelContainer(for: User.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        let modelContext = modelContainer.mainContext

        let user = User(id: 1)
        user.favoriteInfopostIds = ["d1", "d2", "d4"]
        modelContext.insert(user)
        try modelContext.save()

        // Создаем тестовые инфопосты
        let infopost1 = Infopost(filename: "d1", title: "Test 1", content: "Content 1", language: "ru")
        let infopost2 = Infopost(filename: "d2", title: "Test 2", content: "Content 2", language: "ru")
        let infopost3 = Infopost(filename: "d4", title: "Test 4", content: "Content 4", language: "ru")
        let infopost4 = Infopost(filename: "d3", title: "Test 3", content: "Content 3", language: "ru")

        // Act & Assert
        let isFavorite1 = service.isFavorite(infopost1, modelContext: modelContext)
        #expect(isFavorite1)

        let isFavorite2 = service.isFavorite(infopost2, modelContext: modelContext)
        #expect(isFavorite2)

        let isFavorite3 = service.isFavorite(infopost3, modelContext: modelContext)
        #expect(isFavorite3)

        let isNotFavorite = service.isFavorite(infopost4, modelContext: modelContext)
        #expect(!isNotFavorite)
    }

    @Test
    @MainActor
    func isInfopostFavoriteWhenUserNotExists() throws {
        // Arrange
        let service = createService(language: "ru")
        let modelContainer = try ModelContainer(for: User.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        let modelContext = modelContainer.mainContext

        let infopost = Infopost(filename: "d1", title: "Test", content: "Content", language: "ru")

        // Act
        let isFavorite = service.isFavorite(infopost, modelContext: modelContext)

        // Assert
        #expect(!isFavorite)
    }

    @Test
    @MainActor
    func isInfopostFavoriteWhenFavoriteNotAvailable() throws {
        // Arrange
        let service = createService(language: "ru")
        let modelContainer = try ModelContainer(for: User.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        let modelContext = modelContainer.mainContext

        let user = User(id: 1)
        user.favoriteInfopostIds = ["d1"]
        modelContext.insert(user)
        try modelContext.save()

        // Создаем инфопост с отключенной функцией избранного
        let infopost = Infopost(
            id: "d1",
            title: "Test",
            content: "Content",
            section: .base,
            language: "ru",
            isFavoriteAvailable: false
        )

        // Act
        let isFavorite = service.isFavorite(infopost, modelContext: modelContext)

        // Assert
        #expect(!isFavorite)
    }

    @Test
    @MainActor
    func loadFavoriteIdsWhenUserExists() throws {
        // Arrange
        let service = createService(language: "ru")
        let modelContainer = try ModelContainer(for: User.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        let modelContext = modelContainer.mainContext

        let user = User(id: 1)
        let favoriteIds = ["d1", "d2", "about", "organiz"]
        user.favoriteInfopostIds = favoriteIds
        modelContext.insert(user)
        try modelContext.save()

        // Act
        try service.loadFavoriteIds(modelContext: modelContext)

        // Assert
        #expect(service.showDisplayModePicker)
    }

    @Test
    @MainActor
    func loadFavoriteIdsWhenUserNotExists() throws {
        // Arrange
        let service = createService(language: "ru")
        let modelContainer = try ModelContainer(for: User.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        let modelContext = modelContainer.mainContext

        // Act
        try service.loadFavoriteIds(modelContext: modelContext)

        // Assert
        #expect(!service.showDisplayModePicker)
    }

    @Test
    @MainActor
    func changeFavoriteAddToFavorites() throws {
        // Arrange
        let service = createService(language: "ru")
        let modelContainer = try ModelContainer(for: User.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        let modelContext = modelContainer.mainContext

        let user = User(id: 1)
        user.favoriteInfopostIds = ["d1", "d2"]
        modelContext.insert(user)
        try modelContext.save()

        // Act
        try service.changeFavorite(id: "d3", modelContext: modelContext)

        // Assert
        #expect(user.favoriteInfopostIds.contains("d3"))
        #expect(user.favoriteInfopostIds.count == 3)
    }

    @Test
    @MainActor
    func changeFavoriteRemoveFromFavorites() throws {
        // Arrange
        let service = createService(language: "ru")
        let modelContainer = try ModelContainer(for: User.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        let modelContext = modelContainer.mainContext

        let user = User(id: 1)
        user.favoriteInfopostIds = ["d1", "d2", "d3"]
        modelContext.insert(user)
        try modelContext.save()

        // Act
        try service.changeFavorite(id: "d2", modelContext: modelContext)

        // Assert
        #expect(!user.favoriteInfopostIds.contains("d2"))
        #expect(user.favoriteInfopostIds.count == 2)
        #expect(user.favoriteInfopostIds.contains("d1"))
        #expect(user.favoriteInfopostIds.contains("d3"))
    }

    @Test
    @MainActor
    func changeFavoriteWhenUserNotExists() throws {
        // Arrange
        let service = createService(language: "ru")
        let modelContainer = try ModelContainer(for: User.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        let modelContext = modelContainer.mainContext

        // Act & Assert
        #expect(throws: InfopostsService.ServiceError.userNotFound) {
            try service.changeFavorite(id: "d1", modelContext: modelContext)
        }
    }

    // MARK: - Тесты структуры инфопостов

    @Test
    @MainActor
    func infopostsHaveCorrectStructure() throws {
        // Arrange
        let service = createService(language: "ru")

        // Act
        try service.loadAvailableInfoposts(currentDay: 100, maxReadInfoPostDay: 0)

        // Assert
        let sections = service.sectionsForDisplay
        let allInfoposts = sections.flatMap(\.infoposts)

        for infopost in allInfoposts {
            #expect(!infopost.id.isEmpty)
            #expect(!infopost.title.isEmpty)
            #expect(!infopost.content.isEmpty)
            #expect(infopost.language == "ru")

            // Проверяем, что для дневных инфопостов правильно определен номер дня
            if infopost.id.hasPrefix("d") {
                let dayString = String(infopost.id.dropFirst())
                if let expectedDayNumber = Int(dayString) {
                    #expect(infopost.dayNumber == expectedDayNumber)
                }
            }
        }
    }

    @Test
    @MainActor
    func infopostsHaveCorrectSections() throws {
        // Arrange
        let service = createService(language: "ru")

        // Act
        try service.loadAvailableInfoposts(currentDay: 100, maxReadInfoPostDay: 0)

        // Assert
        let sections = service.sectionsForDisplay
        let allInfoposts = sections.flatMap(\.infoposts)
        let dayInfoposts = allInfoposts.filter { $0.dayNumber != nil }

        for infopost in dayInfoposts {
            let dayNumber = try #require(infopost.dayNumber)
            let expectedSection = InfopostSection.section(for: dayNumber)
            #expect(infopost.section == expectedSection)
        }

        // Проверяем специальные инфопосты
        let organizInfopost = allInfoposts.first { $0.id == "organiz" }
        if let organiz = organizInfopost {
            #expect(organiz.section == .preparation)
        }
    }

    // MARK: - Тесты кэширования

    @Test
    @MainActor
    func loadAvailableInfopostsCaching() throws {
        // Arrange
        let service = createService(language: "ru")

        // Act - первая загрузка
        try service.loadAvailableInfoposts(currentDay: 100, maxReadInfoPostDay: 0)
        let firstLoad = service.sectionsForDisplay.flatMap(\.infoposts)

        // Act - вторая загрузка (должна использовать кэш)
        try service.loadAvailableInfoposts(currentDay: 100, maxReadInfoPostDay: 0)
        let secondLoad = service.sectionsForDisplay.flatMap(\.infoposts)

        // Assert
        #expect(firstLoad.count == secondLoad.count)

        // Проверяем, что инфопосты загружаются заново
        for (first, second) in zip(firstLoad, secondLoad) {
            #expect(first.id == second.id)
            #expect(first.title == second.title)
        }
    }

    // MARK: - Тесты обработки ошибок

    @Test
    @MainActor
    func loadAvailableInfopostsWithInvalidLanguage() throws {
        // Arrange
        let service = createService(language: "invalid")

        // Act & Assert
        #expect(throws: InfopostsService.ServiceError.parsingError) {
            try service.loadAvailableInfoposts(currentDay: 100, maxReadInfoPostDay: 0)
        }
    }

    // MARK: - Тесты фильтрации по полу

    @Test
    @MainActor
    func infopostFromFilenameWithWomenSuffix() throws {
        // Arrange
        let filename = "d0-women"
        let title = "Test Title"
        let content = "Test Content"
        let language = "ru"

        // Act
        let infopost = Infopost(filename: filename, title: title, content: content, language: language)

        // Assert
        #expect(infopost.id == filename)
        #expect(infopost.gender == .female)
        #expect(infopost.title == title)
        #expect(infopost.content == content)
        #expect(infopost.language == language)
    }

    @Test
    @MainActor
    func infopostFromFilenameWithoutGenderSuffix() throws {
        // Arrange
        let filename = "d1"
        let title = "Test Title"
        let content = "Test Content"
        let language = "ru"

        // Act
        let infopost = Infopost(filename: filename, title: title, content: content, language: language)

        // Assert
        #expect(infopost.id == filename)
        #expect(infopost.gender == nil)
        #expect(infopost.title == title)
        #expect(infopost.content == content)
        #expect(infopost.language == language)
    }

    @Test
    @MainActor
    func infopostFromFilenameWithSpecialId() throws {
        // Arrange
        let filename = "about"
        let title = "Test Title"
        let content = "Test Content"
        let language = "ru"

        // Act
        let infopost = Infopost(filename: filename, title: title, content: content, language: language)

        // Assert
        #expect(infopost.id == filename)
        #expect(infopost.gender == nil)
        #expect(infopost.title == title)
        #expect(infopost.content == content)
        #expect(infopost.language == language)
    }

    // MARK: - Тесты управления секциями

    @Test
    @MainActor
    func sectionsForDisplayReturnsCorrectSections() throws {
        // Arrange
        let service = createService(language: "ru")
        try service.loadAvailableInfoposts(currentDay: 100, maxReadInfoPostDay: 0)

        // Act
        let sections = service.sectionsForDisplay

        // Assert
        #expect(!sections.isEmpty)

        // Проверяем, что все секции имеют контент
        for section in sections {
            #expect(section.hasContent)
            #expect(!section.infoposts.isEmpty)
            #expect(section.id == section.section)
        }
    }

    @Test
    @MainActor
    func sectionsForDisplayFiltersEmptySections() throws {
        // Arrange
        let service = createService(language: "ru")
        try service.loadAvailableInfoposts(currentDay: 1, maxReadInfoPostDay: 0) // Только первый день

        // Act
        let sections = service.sectionsForDisplay

        // Assert
        // Должны быть только секции с контентом
        for section in sections {
            #expect(!section.infoposts.isEmpty)
        }
    }

    @Test
    @MainActor
    func didTapSectionTogglesCollapsedState() throws {
        // Arrange
        let service = createService(language: "ru")
        try service.loadAvailableInfoposts(currentDay: 100, maxReadInfoPostDay: 0)
        let sections = service.sectionsForDisplay
        let firstSection = try #require(sections.first)

        // Act - сворачиваем секцию
        service.didTapSection(firstSection.section)
        let sectionsAfterCollapse = service.sectionsForDisplay
        let collapsedSection = try #require(sectionsAfterCollapse.first { $0.section == firstSection.section })

        // Assert
        #expect(collapsedSection.isCollapsed)

        // Act - разворачиваем секцию
        service.didTapSection(firstSection.section)
        let sectionsAfterExpand = service.sectionsForDisplay
        let expandedSection = try #require(sectionsAfterExpand.first { $0.section == firstSection.section })

        // Assert
        #expect(!expandedSection.isCollapsed)
    }

    @Test
    @MainActor
    func didTapSectionMultipleTimes() throws {
        // Arrange
        let service = createService(language: "ru")
        try service.loadAvailableInfoposts(currentDay: 100, maxReadInfoPostDay: 0)
        let sections = service.sectionsForDisplay
        let firstSection = try #require(sections.first)

        // Act - несколько нажатий на одну секцию
        service.didTapSection(firstSection.section) // Сворачиваем
        service.didTapSection(firstSection.section) // Разворачиваем
        service.didTapSection(firstSection.section) // Сворачиваем снова

        let finalSections = service.sectionsForDisplay
        let finalSection = try #require(finalSections.first { $0.section == firstSection.section })

        // Assert
        #expect(finalSection.isCollapsed)
    }

    @Test
    @MainActor
    func didTapSectionDifferentSections() throws {
        // Arrange
        let service = createService(language: "ru")
        try service.loadAvailableInfoposts(currentDay: 100, maxReadInfoPostDay: 0)
        let sections = service.sectionsForDisplay
        let firstSection = try #require(sections.first)
        let secondSection = try #require(sections.dropFirst().first)

        // Act - сворачиваем разные секции
        service.didTapSection(firstSection.section)
        service.didTapSection(secondSection.section)

        let finalSections = service.sectionsForDisplay
        let finalFirstSection = try #require(finalSections.first { $0.section == firstSection.section })
        let finalSecondSection = try #require(finalSections.first { $0.section == secondSection.section })

        // Assert
        #expect(finalFirstSection.isCollapsed)
        #expect(finalSecondSection.isCollapsed)
    }

    @Test
    @MainActor
    func didLogoutResetsSectionsState() throws {
        // Arrange
        let service = createService(language: "ru")
        try service.loadAvailableInfoposts(currentDay: 100, maxReadInfoPostDay: 0)
        let sections = service.sectionsForDisplay
        let firstSection = try #require(sections.first)

        // Act - сворачиваем секцию
        service.didTapSection(firstSection.section)
        let sectionsAfterCollapse = service.sectionsForDisplay
        let collapsedSection = try #require(sectionsAfterCollapse.first { $0.section == firstSection.section })
        #expect(collapsedSection.isCollapsed)

        // Act - выходим из аккаунта
        service.didLogout()

        // Act - загружаем инфопосты снова
        try service.loadAvailableInfoposts(currentDay: 100, maxReadInfoPostDay: 0)
        let sectionsAfterLogout = service.sectionsForDisplay
        let sectionAfterLogout = try #require(sectionsAfterLogout.first { $0.section == firstSection.section })

        // Assert
        #expect(!sectionAfterLogout.isCollapsed)
    }
}
