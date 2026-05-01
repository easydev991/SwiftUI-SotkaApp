@testable import SwiftUI_SotkaApp
import Testing

extension AllInfopostsTests {
    /// Тесты для InfopostParser с YouTube видео
    struct InfopostParserYouTubeTests {
        private let youtubeService = YouTubeVideoService(analytics: AnalyticsService(providers: [NoopAnalyticsProvider()]))

        @Test("Для дневного инфопоста добавляется внешний блок видео вместо iframe")
        func prepareHTMLForDisplayWithDayVideoUsesExternalBlock() throws {
            // Given
            let htmlContent = """
            <html>
            <body>
            <div class="text post-body-text">
            <p>Контент инфопоста</p>
            </div>
            <footer></footer>
            </body>
            </html>
            """

            let infopost = Infopost(
                id: "d1",
                title: "День 1",
                content: htmlContent,
                section: .base,
                dayNumber: 1,
                language: "ru"
            )

            // When
            let parser = InfopostParser(filename: "d1", language: "ru")
            let modifiedHTML = parser.prepareHTMLForDisplay(
                htmlContent,
                fontSize: .medium,
                infopost: infopost,
                youtubeService: youtubeService
            )

            // Then
            #expect(!modifiedHTML.contains("<iframe"))
            #expect(modifiedHTML.contains("video-external-container"))
            #expect(modifiedHTML.contains("data-video-kind=\"youtube\""))
            #expect(modifiedHTML.contains("data-video-source=\"day\""))
            #expect(modifiedHTML.contains("sotka://youtube?url="))
            #expect(modifiedHTML.contains("Смотреть видео"))
            #expect(modifiedHTML.contains("YouTube"))
            #expect(!modifiedHTML.contains("#моястодневка от Антона Кучумова"))

            let dayTitleIndex = try #require(modifiedHTML.range(of: "video-external-title")?.lowerBound)
            let buttonIndex = try #require(modifiedHTML.range(of: "video-external-link")?.lowerBound)
            #expect(dayTitleIndex < buttonIndex)
        }

        @Test("Для инфопоста без dayNumber внешний YouTube-блок не добавляется")
        func prepareHTMLForDisplayWithoutDayVideoKeepsContentWithoutInjectedYouTubeBlock() {
            // Given
            let htmlContent = """
            <html>
            <body>
            <div class="text post-body-text">
            <p>Контент инфопоста</p>
            </div>
            <footer></footer>
            </body>
            </html>
            """

            let infopost = Infopost(
                id: "about",
                title: "О программе",
                content: htmlContent,
                section: .preparation,
                dayNumber: nil,
                language: "ru"
            )

            // When
            let parser = InfopostParser(filename: "about", language: "ru")
            let modifiedHTML = parser.prepareHTMLForDisplay(
                htmlContent,
                fontSize: .medium,
                infopost: infopost,
                youtubeService: youtubeService
            )

            // Then
            #expect(!modifiedHTML.contains("sotka://youtube?url="))
            #expect(!modifiedHTML.contains("video-external-container"))
        }

        @Test("Для dayNumber равного нулю блок видео не добавляется")
        func prepareHTMLForDisplayWithZeroDayNumberDoesNotInjectVideo() {
            // Given
            let htmlContent = """
            <html>
            <body>
            <div class="text post-body-text">
            <p>Контент инфопоста</p>
            </div>
            <footer></footer>
            </body>
            </html>
            """

            let infopost = Infopost(
                id: "d0",
                title: "День 0",
                content: htmlContent,
                section: .preparation,
                dayNumber: 0,
                language: "ru"
            )

            // When
            let parser = InfopostParser(filename: "d0", language: "ru")
            let modifiedHTML = parser.prepareHTMLForDisplay(
                htmlContent,
                fontSize: .medium,
                infopost: infopost,
                youtubeService: youtubeService
            )

            // Then
            #expect(!modifiedHTML.contains("sotka://youtube?url="))
            #expect(!modifiedHTML.contains("video-external-container"))
        }

        @Test("В HTML добавляются актуальные скрипты без legacy video_handler.js")
        func prepareHTMLForDisplayAddsScriptsWithoutLegacyVideoHandler() {
            // Given
            let htmlContent = """
            <html>
            <head></head>
            <body>
            <div class="text post-body-text">
            <p>Контент инфопоста</p>
            </div>
            </body>
            </html>
            """

            let infopost = Infopost(
                id: "d1",
                title: "День 1",
                content: htmlContent,
                section: .base,
                dayNumber: 1,
                language: "ru"
            )

            // When
            let parser = InfopostParser(filename: "d1", language: "ru")
            let modifiedHTML = parser.prepareHTMLForDisplay(
                htmlContent,
                fontSize: .medium,
                infopost: infopost,
                youtubeService: youtubeService
            )

            // Then
            #expect(modifiedHTML.contains("console_interceptor.js"))
            #expect(modifiedHTML.contains("scroll_tracker.js"))
            #expect(modifiedHTML.contains("font_size_handler.js"))
            #expect(!modifiedHTML.contains("video_handler.js"))
        }

        @Test("Дневной блок видео вставляется в конец статьи")
        func dayVideoBlockIsAddedAtBottomOfArticle() throws {
            // Given
            let htmlContent = """
            <html>
            <body>
            <div class="text post-body-text">
            <p>Контент инфопоста</p>
            </div>
            </body>
            </html>
            """

            let infopost = Infopost(
                id: "d5",
                title: "День 5",
                content: htmlContent,
                section: .base,
                dayNumber: 5,
                language: "ru"
            )

            // When
            let parser = InfopostParser(filename: "d5", language: "ru")
            let modifiedHTML = parser.prepareHTMLForDisplay(
                htmlContent,
                fontSize: .medium,
                infopost: infopost,
                youtubeService: youtubeService
            )

            // Then
            let contentIndex = try #require(modifiedHTML.range(of: "Контент инфопоста")?.lowerBound)
            let blockIndex = try #require(modifiedHTML.range(of: "video-external-container")?.lowerBound)
            #expect(blockIndex > contentIndex)
        }

        @Test("Для английского языка используется английская локализация внешнего блока")
        func externalBlockUsesEnglishLocalizationForEnglishParserLanguage() {
            // Given
            let htmlContent = """
            <html>
            <body>
            <div class="text post-body-text">
            <iframe src="https://www.youtube.com/embed/OM0m9CEjq2Y"></iframe>
            </div>
            </body>
            </html>
            """

            let infopost = Infopost(
                id: "d1",
                title: "Day 1",
                content: htmlContent,
                section: .base,
                dayNumber: nil,
                language: "en"
            )

            // When
            let parser = InfopostParser(filename: "d1", language: "en")
            let modifiedHTML = parser.prepareHTMLForDisplay(
                htmlContent,
                fontSize: .medium,
                infopost: infopost,
                youtubeService: youtubeService
            )

            // Then
            #expect(modifiedHTML.contains("Watch video"))
            #expect(modifiedHTML.contains("YouTube"))
        }
    }
}
