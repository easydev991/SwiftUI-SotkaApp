@testable import SwiftUI_SotkaApp
import Testing

extension AllInfopostsTests {
    /// Тесты для YouTubeVideoService
    struct YouTubeVideoServiceTests {
        private let youtubeService = YouTubeVideoService(
            analytics: AnalyticsService(providers: [NoopAnalyticsProvider()])
        )

        @Test
        func loadVideos() throws {
            // Given & When
            let videos = try youtubeService.loadVideos()

            // Then
            #expect(!videos.isEmpty)
            #expect(videos.count == 100)

            // Проверяем первое видео
            let firstVideo = try #require(videos.first)
            #expect(firstVideo.dayNumber == 1)
            #expect(firstVideo.url.contains("youtube.com"))
        }

        @Test
        func getVideoForValidDay() throws {
            // Given
            let dayNumber = 1

            // When
            let video = try youtubeService.getVideo(for: dayNumber)

            // Then
            let videoValue = try #require(video)
            #expect(videoValue.dayNumber == dayNumber)
            #expect(videoValue.url.contains("youtube.com"))
            #expect(!videoValue.title.isEmpty)
            #expect(videoValue.title != "#моястодневка от Антона Кучумова")
        }

        @Test
        func getVideoForInvalidDay() throws {
            // Given
            let dayNumber = 101 // Несуществующий день

            // When
            let video = try youtubeService.getVideo(for: dayNumber)

            // Then
            #expect(video == nil)
        }

        @Test
        func hasVideoForValidDay() throws {
            // Given
            let dayNumber = 1

            // When
            let hasVideo = try youtubeService.hasVideo(for: dayNumber)

            // Then
            #expect(hasVideo)
        }

        @Test
        func hasVideoForInvalidDay() throws {
            // Given
            let dayNumber = 101 // Несуществующий день

            // When
            let hasVideo = try youtubeService.hasVideo(for: dayNumber)

            // Then
            #expect(!hasVideo)
        }

        @Test
        func videoOrder() throws {
            // Given & When
            let videos = try youtubeService.loadVideos()

            // Then
            for (index, video) in videos.enumerated() {
                #expect(video.dayNumber == index + 1)
            }
        }

        @Test
        func videoURLs() throws {
            // Given & When
            let videos = try youtubeService.loadVideos()

            // Then
            for video in videos {
                #expect(video.url.contains("youtube.com"))
                #expect(video.url.contains("embed"))
            }
        }

        @Test
        func loadVideosContainsTitlesFromLocalJSON() throws {
            // Given & When
            let videos = try youtubeService.loadVideos()

            // Then
            #expect(videos.contains(where: { !$0.title.isEmpty }))
        }

        @Test
        func dayDisplayTitleUsesResolvedVideoTitleWhenAvailable() {
            // Given
            let video = YouTubeVideo(dayNumber: 1, url: "https://www.youtube.com/embed/test", title: "Resolved title")

            // When
            let displayTitle = youtubeService.dayDisplayTitle(for: video)

            // Then
            #expect(displayTitle == "Resolved title")
        }

        @Test
        func dayDisplayTitleFallsBackWhenVideoTitleIsEmpty() {
            // Given
            let video = YouTubeVideo(dayNumber: 1, url: "https://www.youtube.com/embed/test", title: "")

            // When
            let displayTitle = youtubeService.dayDisplayTitle(for: video)

            // Then
            #expect(displayTitle == YouTubeVideoService.dayTitleFallback)
        }

        @Test
        func caching() throws {
            // Given
            let firstLoad = try youtubeService.loadVideos()

            // When
            let secondLoad = try youtubeService.loadVideos()

            // Then
            #expect(firstLoad.count == secondLoad.count)
            let firstVideo = try #require(firstLoad.first)
            let secondVideo = try #require(secondLoad.first)
            #expect(firstVideo.url == secondVideo.url)
        }
    }
}
