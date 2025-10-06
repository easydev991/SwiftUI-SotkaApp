import Foundation
import SwiftData
@testable import SwiftUI_SotkaApp
import Testing

struct InfopostsServiceTests {
    // MARK: - Тесты загрузки инфопостов

    @Test
    func loadInfopostsSuccess() throws {
        // Arrange
        let service = InfopostsService(language: "ru")

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
    func loadInfopostsWithEnglishLanguage() throws {
        // Arrange
        let service = InfopostsService(language: "en")

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
    func loadInfopostsWithRussianLanguage() throws {
        // Arrange
        let service = InfopostsService(language: "ru")

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
    func loadInfopostWithValidId() throws {
        // Arrange
        let service = InfopostsService(language: "ru")
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
    func loadInfopostWithDayId() throws {
        // Arrange
        let service = InfopostsService(language: "ru")
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
    func loadInfopostWithInvalidId() throws {
        // Arrange
        let service = InfopostsService(language: "ru")
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
        let service = InfopostsService(language: "ru")
        let modelContainer = try ModelContainer(for: User.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        let modelContext = modelContainer.mainContext

        let user = User(id: 1)
        user.favoriteInfopostIds = ["d1", "d2", "about"]
        modelContext.insert(user)
        try modelContext.save()

        // Act & Assert
        let isFavorite1 = try service.isInfopostFavorite("d1", modelContext: modelContext)
        #expect(isFavorite1)

        let isFavorite2 = try service.isInfopostFavorite("d2", modelContext: modelContext)
        #expect(isFavorite2)

        let isFavorite3 = try service.isInfopostFavorite("about", modelContext: modelContext)
        #expect(isFavorite3)

        let isNotFavorite = try service.isInfopostFavorite("d3", modelContext: modelContext)
        #expect(!isNotFavorite)
    }

    @Test
    @MainActor
    func isInfopostFavoriteWhenUserNotExists() throws {
        // Arrange
        let service = InfopostsService(language: "ru")
        let modelContainer = try ModelContainer(for: User.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        let modelContext = modelContainer.mainContext

        // Act
        let isFavorite = try service.isInfopostFavorite("d1", modelContext: modelContext)

        // Assert
        #expect(!isFavorite)
    }

    @Test
    @MainActor
    func getFavoriteInfopostIdsWhenUserExists() throws {
        // Arrange
        let service = InfopostsService(language: "ru")
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
        let service = InfopostsService(language: "ru")
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
        let service = InfopostsService(language: "ru")
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
        let service = InfopostsService(language: "ru")
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
        let service = InfopostsService(language: "ru")
        let modelContainer = try ModelContainer(for: User.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        let modelContext = modelContainer.mainContext

        // Act & Assert
        #expect(throws: InfopostsServiceError.userNotFound) {
            try service.changeFavorite(id: "d1", modelContext: modelContext)
        }
    }

    // MARK: - Тесты структуры инфопостов

    @Test
    func infopostsHaveCorrectStructure() throws {
        // Arrange
        let service = InfopostsService(language: "ru")

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
    func infopostsHaveCorrectSections() throws {
        // Arrange
        let service = InfopostsService(language: "ru")

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
    func loadInfopostsClearsCache() throws {
        // Arrange
        let service = InfopostsService(language: "ru")

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
    func loadInfopostsWithInvalidLanguage() throws {
        // Arrange
        let service = InfopostsService(language: "invalid")

        // Act & Assert
        // Для несуществующего языка должны вернуться пустые результаты
        // или ошибка парсинга, в зависимости от реализации
        do {
            let infoposts = try service.loadInfoposts()
            // Если не выброшена ошибка, то должен быть пустой массив
            #expect(infoposts.isEmpty)
        } catch {
            // Ошибка также допустима для несуществующего языка
            #expect(error is InfopostsServiceError)
        }
    }

    // MARK: - Тесты фильтрации по полу

    @Test
    func infopostFromFilenameWithWomenSuffix() throws {
        // Arrange
        let filename = "d0-women"
        let title = "Test Title"
        let content = "Test Content"
        let language = "ru"

        // Act
        let infopost = Infopost.from(filename: filename, title: title, content: content, language: language)

        // Assert
        #expect(infopost.id == filename)
        #expect(infopost.gender == .female)
        #expect(infopost.title == title)
        #expect(infopost.content == content)
        #expect(infopost.language == language)
    }

    @Test
    func infopostFromFilenameWithoutGenderSuffix() throws {
        // Arrange
        let filename = "d1"
        let title = "Test Title"
        let content = "Test Content"
        let language = "ru"

        // Act
        let infopost = Infopost.from(filename: filename, title: title, content: content, language: language)

        // Assert
        #expect(infopost.id == filename)
        #expect(infopost.gender == nil)
        #expect(infopost.title == title)
        #expect(infopost.content == content)
        #expect(infopost.language == language)
    }

    @Test
    func infopostFromFilenameWithSpecialId() throws {
        // Arrange
        let filename = "about"
        let title = "Test Title"
        let content = "Test Content"
        let language = "ru"

        // Act
        let infopost = Infopost.from(filename: filename, title: title, content: content, language: language)

        // Assert
        #expect(infopost.id == filename)
        #expect(infopost.gender == nil)
        #expect(infopost.title == title)
        #expect(infopost.content == content)
        #expect(infopost.language == language)
    }
}
