import Foundation
@testable import SwiftUI_SotkaApp
import Testing

struct InfopostSectionDisplayTests {
    // MARK: - Тесты создания модели

    @Test
    func createInfopostSectionDisplayWithContent() {
        // Arrange
        let section = InfopostSection.base
        let infoposts = [
            Infopost(filename: "d1", title: "Test 1", content: "Content 1", language: "ru"),
            Infopost(filename: "d2", title: "Test 2", content: "Content 2", language: "ru")
        ]
        let isCollapsed = false

        // Act
        let sectionDisplay = InfopostSectionDisplay(
            id: section,
            section: section,
            infoposts: infoposts,
            isCollapsed: isCollapsed
        )

        // Assert
        #expect(sectionDisplay.id == section)
        #expect(sectionDisplay.section == section)
        #expect(sectionDisplay.infoposts.count == 2)
        #expect(!sectionDisplay.isCollapsed)
        #expect(sectionDisplay.hasContent)
    }

    @Test
    func createInfopostSectionDisplayWithoutContent() {
        // Arrange
        let section = InfopostSection.base
        let infoposts: [Infopost] = []
        let isCollapsed = true

        // Act
        let sectionDisplay = InfopostSectionDisplay(
            id: section,
            section: section,
            infoposts: infoposts,
            isCollapsed: isCollapsed
        )

        // Assert
        #expect(sectionDisplay.id == section)
        #expect(sectionDisplay.section == section)
        #expect(sectionDisplay.infoposts.isEmpty)
        #expect(sectionDisplay.isCollapsed)
        #expect(!sectionDisplay.hasContent)
    }

    // MARK: - Тесты computed properties

    @Test
    func hasContentReturnsTrueWhenInfopostsNotEmpty() {
        // Arrange
        let section = InfopostSection.preparation
        let infoposts = [
            Infopost(filename: "organiz", title: "Test", content: "Content", language: "ru")
        ]

        // Act
        let sectionDisplay = InfopostSectionDisplay(
            id: section,
            section: section,
            infoposts: infoposts,
            isCollapsed: false
        )

        // Assert
        #expect(sectionDisplay.hasContent)
    }

    @Test
    func hasContentReturnsFalseWhenInfopostsEmpty() {
        // Arrange
        let section = InfopostSection.turbo
        let infoposts: [Infopost] = []

        // Act
        let sectionDisplay = InfopostSectionDisplay(
            id: section,
            section: section,
            infoposts: infoposts,
            isCollapsed: false
        )

        // Assert
        #expect(!sectionDisplay.hasContent)
    }

    @Test
    func titleReturnsCorrectLocalizedStringKey() {
        // Arrange
        let section = InfopostSection.conclusion
        let infoposts = [
            Infopost(filename: "d100", title: "Test", content: "Content", language: "ru")
        ]

        // Act
        let sectionDisplay = InfopostSectionDisplay(
            id: section,
            section: section,
            infoposts: infoposts,
            isCollapsed: false
        )

        // Assert
        // Проверяем, что title возвращает правильный LocalizedStringKey
        // Это проверяется через сравнение с ожидаемым значением секции
        #expect(sectionDisplay.title == section.localizedTitle)
    }

    // MARK: - Тесты идентичности

    @Test
    func idEqualsSection() {
        // Arrange
        let section = InfopostSection.advanced
        let infoposts = [
            Infopost(filename: "d50", title: "Test", content: "Content", language: "ru")
        ]

        // Act
        let sectionDisplay = InfopostSectionDisplay(
            id: section,
            section: section,
            infoposts: infoposts,
            isCollapsed: false
        )

        // Assert
        #expect(sectionDisplay.id == sectionDisplay.section)
    }

    // MARK: - Тесты с разными секциями

    @Test
    func allSectionsCanBeCreated() {
        // Arrange
        let allSections = InfopostSection.allCases
        let testInfopost = Infopost(filename: "d1", title: "Test", content: "Content", language: "ru")

        // Act & Assert
        for section in allSections {
            let sectionDisplay = InfopostSectionDisplay(
                id: section,
                section: section,
                infoposts: [testInfopost],
                isCollapsed: false
            )

            #expect(sectionDisplay.id == section)
            #expect(sectionDisplay.section == section)
            #expect(sectionDisplay.hasContent)
            #expect(!sectionDisplay.isCollapsed)
        }
    }

    // MARK: - Тесты состояния сворачивания

    @Test
    func collapsedStateIsPreserved() {
        // Arrange
        let section = InfopostSection.base
        let infoposts = [
            Infopost(filename: "d1", title: "Test", content: "Content", language: "ru")
        ]

        // Act - создаем свернутую секцию
        let collapsedSection = InfopostSectionDisplay(
            id: section,
            section: section,
            infoposts: infoposts,
            isCollapsed: true
        )

        // Act - создаем развернутую секцию
        let expandedSection = InfopostSectionDisplay(
            id: section,
            section: section,
            infoposts: infoposts,
            isCollapsed: false
        )

        // Assert
        #expect(collapsedSection.isCollapsed)
        #expect(!expandedSection.isCollapsed)
    }
}
