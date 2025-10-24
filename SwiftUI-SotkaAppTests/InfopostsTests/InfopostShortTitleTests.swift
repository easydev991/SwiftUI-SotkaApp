import Foundation
@testable import SwiftUI_SotkaApp
import Testing

extension AllInfopostsTests {
    /// Тесты для свойства shortTitle в модели Infopost
    struct InfopostShortTitleTests {
        // MARK: - Тесты для shortTitle

        @Test
        func shortTitleRemovesDayPrefix() {
            // Given
            let infopost = Infopost(
                id: "d100",
                title: "День 100. Вот и все",
                content: "Test content",
                section: .conclusion,
                dayNumber: 100,
                language: "ru"
            )

            // When
            let shortTitle = infopost.shortTitle

            // Then
            #expect(shortTitle == "Вот и все")
        }

        @Test
        func shortTitleRemovesDayPrefixWithSpace() {
            // Given
            let infopost = Infopost(
                id: "d1",
                title: "День 1. Начинаем тренировки",
                content: "Test content",
                section: .base,
                dayNumber: 1,
                language: "ru"
            )

            // When
            let shortTitle = infopost.shortTitle

            // Then
            #expect(shortTitle == "Начинаем тренировки")
        }

        @Test
        func shortTitleHandlesTitleWithoutDot() {
            // Given
            let infopost = Infopost(
                id: "about",
                title: "О программе",
                content: "Test content",
                section: .preparation,
                dayNumber: nil,
                language: "ru"
            )

            // When
            let shortTitle = infopost.shortTitle

            // Then
            #expect(shortTitle == "О программе")
        }

        @Test
        func shortTitleHandlesTitleWithMultipleDots() {
            // Given
            let infopost = Infopost(
                id: "d50",
                title: "День 50. Продолжаем. Не останавливаемся",
                content: "Test content",
                section: .advanced,
                dayNumber: 50,
                language: "ru"
            )

            // When
            let shortTitle = infopost.shortTitle

            // Then
            #expect(shortTitle == "Продолжаем. Не останавливаемся")
        }

        @Test
        func shortTitleHandlesEmptyTitleAfterDot() {
            // Given
            let infopost = Infopost(
                id: "d99",
                title: "День 99. ",
                content: "Test content",
                section: .turbo,
                dayNumber: 99,
                language: "ru"
            )

            // When
            let shortTitle = infopost.shortTitle

            // Then
            #expect(shortTitle == "")
        }

        @Test
        func shortTitleHandlesTitleWithoutSpaceAfterDot() {
            // Given
            let infopost = Infopost(
                id: "d25",
                title: "День 25.Тренировка без пробела",
                content: "Test content",
                section: .base,
                dayNumber: 25,
                language: "ru"
            )

            // When
            let shortTitle = infopost.shortTitle

            // Then
            #expect(shortTitle == "Тренировка без пробела")
        }

        @Test
        func shortTitleHandlesEnglishTitle() {
            // Given
            let infopost = Infopost(
                id: "d1",
                title: "Day 1. Start your journey",
                content: "Test content",
                section: .base,
                dayNumber: 1,
                language: "en"
            )

            // When
            let shortTitle = infopost.shortTitle

            // Then
            #expect(shortTitle == "Start your journey")
        }

        @Test
        func shortTitleHandlesSingleWordTitle() {
            // Given
            let infopost = Infopost(
                id: "d75",
                title: "День 75. Мотивация",
                content: "Test content",
                section: .advanced,
                dayNumber: 75,
                language: "ru"
            )

            // When
            let shortTitle = infopost.shortTitle

            // Then
            #expect(shortTitle == "Мотивация")
        }
    }
}
