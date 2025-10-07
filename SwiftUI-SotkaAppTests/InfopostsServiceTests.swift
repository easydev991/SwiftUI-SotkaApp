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
    func loadInfopostsSuccess() throws {
        // Arrange
        let service = createService(language: "ru")

        // Act
        let infoposts = try service.loadInfoposts()

        // Assert
        #expect(!infoposts.isEmpty)

        // Проверяем, что есть основные инфопосты
        let infopostIds = infoposts.map(\.id)
        #expect(!infopostIds.contains("about"))
        #expect(infopostIds.contains("organiz"))
        #expect(infopostIds.contains("aims"))
        #expect(infopostIds.contains("d0-women"))
        #expect(infopostIds.contains("d1"))
        #expect(infopostIds.contains("d100"))
    }

    @Test
    @MainActor
    func loadInfopostsWithEnglishLanguage() throws {
        // Arrange
        let service = createService(language: "en")

        // Act
        let infoposts = try service.loadInfoposts()

        // Assert
        #expect(!infoposts.isEmpty)

        // Проверяем, что все инфопосты имеют английский язык
        for infopost in infoposts {
            #expect(infopost.language == "en")
        }
    }

    @Test
    @MainActor
    func loadInfopostsWithRussianLanguage() throws {
        // Arrange
        let service = createService(language: "ru")

        // Act
        let infoposts = try service.loadInfoposts()

        // Assert
        #expect(!infoposts.isEmpty)

        // Проверяем, что все инфопосты имеют русский язык
        for infopost in infoposts {
            #expect(infopost.language == "ru")
        }
    }

    // MARK: - Тесты загрузки конкретного инфопоста

    @Test
    @MainActor
    func loadInfopostWithValidId() throws {
        // Arrange
        let service = createService(language: "ru")
        let infopostId = "organiz"

        // Act
        let infopost = try service.loadInfopost(id: infopostId)

        // Assert
        let validInfopost = try #require(infopost)
        #expect(validInfopost.id == infopostId)
        #expect(validInfopost.language == "ru")
        #expect(!validInfopost.title.isEmpty)
        #expect(!validInfopost.content.isEmpty)
    }

    @Test
    @MainActor
    func loadInfopostWithDayId() throws {
        // Arrange
        let service = createService(language: "ru")
        let infopostId = "d1"

        // Act
        let infopost = try service.loadInfopost(id: infopostId)

        // Assert
        let validInfopost = try #require(infopost)
        #expect(validInfopost.id == infopostId)
        #expect(validInfopost.dayNumber == 1)
        #expect(validInfopost.section == .base)
    }

    @Test
    @MainActor
    func loadInfopostWithInvalidId() throws {
        // Arrange
        let service = createService(language: "ru")
        let invalidId = "nonexistent"

        // Act
        let infopost = try service.loadInfopost(id: invalidId)

        // Assert
        #expect(infopost == nil)
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
        let isFavorite1 = try service.isInfopostFavorite(infopost1, modelContext: modelContext)
        #expect(isFavorite1)

        let isFavorite2 = try service.isInfopostFavorite(infopost2, modelContext: modelContext)
        #expect(isFavorite2)

        let isFavorite3 = try service.isInfopostFavorite(infopost3, modelContext: modelContext)
        #expect(isFavorite3)

        let isNotFavorite = try service.isInfopostFavorite(infopost4, modelContext: modelContext)
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
        let isFavorite = try service.isInfopostFavorite(infopost, modelContext: modelContext)

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
        let isFavorite = try service.isInfopostFavorite(infopost, modelContext: modelContext)

        // Assert
        #expect(!isFavorite)
    }

    @Test
    @MainActor
    func getFavoriteInfopostIdsWhenUserExists() throws {
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
        let result = try service.getFavoriteInfopostIds(modelContext: modelContext)

        // Assert
        #expect(result.count == favoriteIds.count)
        for id in favoriteIds {
            #expect(result.contains(id))
        }
    }

    @Test
    @MainActor
    func getFavoriteInfopostIdsWhenUserNotExists() throws {
        // Arrange
        let service = createService(language: "ru")
        let modelContainer = try ModelContainer(for: User.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        let modelContext = modelContainer.mainContext

        // Act
        let result = try service.getFavoriteInfopostIds(modelContext: modelContext)

        // Assert
        #expect(result.isEmpty)
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
        #expect(throws: InfopostsServiceError.userNotFound) {
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
        let infoposts = try service.loadInfoposts()

        // Assert
        for infopost in infoposts {
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
        let infoposts = try service.loadInfoposts()

        // Assert
        let dayInfoposts = infoposts.filter { $0.dayNumber != nil }

        for infopost in dayInfoposts {
            let dayNumber = try #require(infopost.dayNumber)
            let expectedSection = InfopostSection.section(for: dayNumber)
            #expect(infopost.section == expectedSection)
        }

        // Проверяем специальные инфопосты
        let aboutInfopost = infoposts.first { $0.id == "about" }
        if let about = aboutInfopost {
            #expect(about.section == .preparation)
        }

        let organizInfopost = infoposts.first { $0.id == "organiz" }
        if let organiz = organizInfopost {
            #expect(organiz.section == .preparation)
        }
    }

    // MARK: - Тесты кэширования

    @Test
    @MainActor
    func loadInfopostsClearsCache() throws {
        // Arrange
        let service = createService(language: "ru")

        // Act - первая загрузка
        let firstLoad = try service.loadInfoposts()

        // Act - вторая загрузка (должна очистить кэш)
        let secondLoad = try service.loadInfoposts()

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
    func loadInfopostsWithInvalidLanguage() throws {
        // Arrange
        let service = createService(language: "invalid")

        // Act & Assert
        // Для несуществующего языка должны вернуться пустые результаты
        // или ошибка парсинга, в зависимости от реализации
        let infoposts = try service.loadInfoposts()
        // Если не выброшена ошибка, то должен быть пустой массив
        #expect(infoposts.isEmpty)
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
}
