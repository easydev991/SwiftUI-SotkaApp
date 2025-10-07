import Foundation
@testable import SwiftUI_SotkaApp
import Testing

struct InfopostFavoriteAvailabilityTests {
    // MARK: - Тесты для isFavoriteAvailable в инициализаторе

    @Test
    func initWithDefaultIsFavoriteAvailable() {
        // Arrange & Act
        let infopost = Infopost(
            id: "test",
            title: "Test",
            content: "Test content",
            section: .base,
            language: "ru"
        )

        // Assert
        #expect(infopost.isFavoriteAvailable)
    }

    @Test
    func initWithCustomIsFavoriteAvailable() {
        // Arrange & Act
        let infopost = Infopost(
            id: "test",
            title: "Test",
            content: "Test content",
            section: .base,
            language: "ru",
            isFavoriteAvailable: false
        )

        // Assert
        #expect(!infopost.isFavoriteAvailable)
    }

    // MARK: - Тесты для логики isFavoriteAvailable в методе from

    @Test
    func fromMethodWithAboutFilename() {
        // Arrange
        let filename = "about"
        let title = "About the program"
        let content = "About content"
        let language = "ru"

        // Act
        let infopost = Infopost(
            filename: filename,
            title: title,
            content: content,
            language: language
        )

        // Assert
        #expect(infopost.id == "about")
        #expect(!infopost.isFavoriteAvailable)
        #expect(infopost.title == "About the program")
        #expect(infopost.section == .preparation)
    }

    @Test
    func fromMethodWithRegularDayFilename() {
        // Arrange
        let filename = "d1"
        let title = "Day 1"
        let content = "Day 1 content"
        let language = "ru"

        // Act
        let infopost = Infopost(
            filename: filename,
            title: title,
            content: content,
            language: language
        )

        // Assert
        #expect(infopost.id == "d1")
        #expect(infopost.isFavoriteAvailable)
        #expect(infopost.dayNumber == 1)
        #expect(infopost.section == .base)
    }

    @Test
    func fromMethodWithAimsFilename() {
        // Arrange
        let filename = "aims"
        let title = "Aims"
        let content = "Aims content"
        let language = "ru"

        // Act
        let infopost = Infopost(
            filename: filename,
            title: title,
            content: content,
            language: language
        )

        // Assert
        #expect(infopost.id == "aims")
        #expect(infopost.isFavoriteAvailable)
        #expect(infopost.dayNumber == nil)
        #expect(infopost.section == .preparation)
    }

    @Test
    func fromMethodWithOrganizFilename() {
        // Arrange
        let filename = "organiz"
        let title = "Organization"
        let content = "Organization content"
        let language = "ru"

        // Act
        let infopost = Infopost(
            filename: filename,
            title: title,
            content: content,
            language: language
        )

        // Assert
        #expect(infopost.id == "organiz")
        #expect(infopost.isFavoriteAvailable)
        #expect(infopost.dayNumber == nil)
        #expect(infopost.section == .preparation)
    }

    @Test
    func fromMethodWithWomenFilename() {
        // Arrange
        let filename = "d0-women"
        let title = "Day 0 for women"
        let content = "Day 0 content for women"
        let language = "ru"

        // Act
        let infopost = Infopost(
            filename: filename,
            title: title,
            content: content,
            language: language
        )

        // Assert
        #expect(infopost.id == "d0-women")
        #expect(infopost.isFavoriteAvailable)
        #expect(infopost.dayNumber == nil)
        #expect(infopost.gender == .female)
        #expect(infopost.section == .preparation)
    }

    // MARK: - Тесты для различных типов файлов

    @Test
    func fromMethodWithAdvancedDayFilename() {
        // Arrange
        let filename = "d50"
        let title = "Day 50"
        let content = "Day 50 content"
        let language = "ru"

        // Act
        let infopost = Infopost(
            filename: filename,
            title: title,
            content: content,
            language: language
        )

        // Assert
        #expect(infopost.id == "d50")
        #expect(infopost.isFavoriteAvailable)
        #expect(infopost.dayNumber == 50)
        #expect(infopost.section == .advanced)
    }

    @Test
    func fromMethodWithTurboDayFilename() {
        // Arrange
        let filename = "d95"
        let title = "Day 95"
        let content = "Day 95 content"
        let language = "ru"

        // Act
        let infopost = Infopost(
            filename: filename,
            title: title,
            content: content,
            language: language
        )

        // Assert
        #expect(infopost.id == "d95")
        #expect(infopost.isFavoriteAvailable)
        #expect(infopost.dayNumber == 95)
        #expect(infopost.section == .turbo)
    }

    @Test
    func fromMethodWithConclusionDayFilename() {
        // Arrange
        let filename = "d100"
        let title = "Day 100"
        let content = "Day 100 content"
        let language = "ru"

        // Act
        let infopost = Infopost(
            filename: filename,
            title: title,
            content: content,
            language: language
        )

        // Assert
        #expect(infopost.id == "d100")
        #expect(infopost.isFavoriteAvailable)
        #expect(infopost.dayNumber == 100)
        #expect(infopost.section == .conclusion)
    }

    // MARK: - Тесты для граничных случаев

    @Test
    func fromMethodWithEmptyFilename() {
        // Arrange
        let filename = ""
        let title = "Empty"
        let content = "Empty content"
        let language = "ru"

        // Act
        let infopost = Infopost(
            filename: filename,
            title: title,
            content: content,
            language: language
        )

        // Assert
        #expect(infopost.id == "")
        #expect(infopost.isFavoriteAvailable)
        #expect(infopost.section == .preparation)
    }

    @Test
    func fromMethodWithAboutLikeFilename() {
        // Arrange
        let filename = "about-something"
        let title = "About something"
        let content = "About something content"
        let language = "ru"

        // Act
        let infopost = Infopost(
            filename: filename,
            title: title,
            content: content,
            language: language
        )

        // Assert
        #expect(infopost.id == "about-something")
        #expect(!infopost.isFavoriteAvailable)
        #expect(infopost.section == .preparation)
    }

    @MainActor
    @Test(arguments: ["ru", "en"])
    func loadAboutInfopostMethod(language: String) throws {
        // Arrange
        let service = InfopostsService(
            language: language,
            infopostsClient: MockInfopostsClient(result: .success)
        )

        // Act
        let infopost = service.loadAboutInfopost()

        // Assert
        let loadedInfopost = try #require(infopost, "Файл about_\(language).html должен существовать в проекте")
        #expect(loadedInfopost.id == "about")
        #expect(!loadedInfopost.isFavoriteAvailable)
        #expect(loadedInfopost.language == language)
        #expect(loadedInfopost.section == .preparation)
    }
}
