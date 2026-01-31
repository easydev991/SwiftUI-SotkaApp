@testable import SwiftUI_SotkaApp
import Testing

extension AllInfopostsTests {
    /// Тесты для интеграции YouTube видео с инфопостами
    struct InfopostYouTubeTests {
        private let youtubeService = YouTubeVideoService()

        @Test
        func infopostWithDayNumberHasYouTubeVideo() throws {
            // Given
            let infopost = Infopost(
                id: "d1",
                title: "День 1",
                content: "Контент дня 1",
                section: .base,
                dayNumber: 1,
                language: "ru"
            )

            // When
            let hasVideo = infopost.hasYouTubeVideo(using: youtubeService)
            let video = infopost.youtubeVideo(using: youtubeService)

            // Then
            #expect(hasVideo)
            let videoValue = try #require(video)
            #expect(videoValue.dayNumber == 1)
        }

        @Test
        func infopostWithoutDayNumberHasNoYouTubeVideo() {
            // Given
            let infopost = Infopost(
                id: "about",
                title: "О программе",
                content: "Информация о программе",
                section: .preparation,
                dayNumber: nil,
                language: "ru"
            )

            // When
            let hasVideo = infopost.hasYouTubeVideo(using: youtubeService)
            let video = infopost.youtubeVideo(using: youtubeService)

            // Then
            #expect(!hasVideo)
            #expect(video == nil)
        }

        @Test
        func infopostWithZeroDayNumberHasNoYouTubeVideo() {
            // Given
            let infopost = Infopost(
                id: "d0",
                title: "День 0",
                content: "Контент дня 0",
                section: .preparation,
                dayNumber: 0,
                language: "ru"
            )

            // When
            let hasVideo = infopost.hasYouTubeVideo(using: youtubeService)
            let video = infopost.youtubeVideo(using: youtubeService)

            // Then
            #expect(!hasVideo)
            #expect(video == nil)
        }

        @Test
        func infopostWithNegativeDayNumberHasNoYouTubeVideo() {
            // Given
            let infopost = Infopost(
                id: "d-1",
                title: "День -1",
                content: "Контент дня -1",
                section: .preparation,
                dayNumber: -1,
                language: "ru"
            )

            // When
            let hasVideo = infopost.hasYouTubeVideo(using: youtubeService)
            let video = infopost.youtubeVideo(using: youtubeService)

            // Then
            #expect(!hasVideo)
            #expect(video == nil)
        }

        @Test
        func infopostWithValidDayNumberReturnsCorrectVideo() throws {
            // Given
            let dayNumber = 5
            let infopost = Infopost(
                id: "d5",
                title: "День 5",
                content: "Контент дня 5",
                section: .base,
                dayNumber: dayNumber,
                language: "ru"
            )

            // When
            let video = infopost.youtubeVideo(using: youtubeService)

            // Then
            let videoValue = try #require(video)
            #expect(videoValue.dayNumber == dayNumber)
            #expect(videoValue.url.contains("youtube.com"))
        }

        @Test
        func multipleInfopostsWithDifferentDayNumbers() throws {
            // Given
            let infoposts = [
                Infopost(id: "d1", title: "День 1", content: "Контент", section: .base, dayNumber: 1, language: "ru"),
                Infopost(id: "d50", title: "День 50", content: "Контент", section: .advanced, dayNumber: 50, language: "ru"),
                Infopost(id: "d100", title: "День 100", content: "Контент", section: .conclusion, dayNumber: 100, language: "ru")
            ]

            // When & Then
            for infopost in infoposts {
                let hasVideo = infopost.hasYouTubeVideo(using: youtubeService)
                let video = infopost.youtubeVideo(using: youtubeService)

                #expect(hasVideo)
                let videoValue = try #require(video)
                #expect(videoValue.dayNumber == infopost.dayNumber)
            }
        }
    }
}
