@testable import SwiftUI_SotkaApp
import Testing

/// Тесты для InfopostParser с YouTube видео
struct InfopostParserYouTubeTests {
    private let youtubeService = YouTubeVideoService()

    @Test
    func prepareHTMLForDisplayWithYouTubeVideo() throws {
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
        let modifiedHTML = InfopostParser.prepareHTMLForDisplay(
            htmlContent,
            fontSize: .medium,
            infopost: infopost,
            youtubeService: youtubeService
        )

        // Then
        #expect(modifiedHTML.contains("youtube.com"))
        #expect(modifiedHTML.contains("iframe"))
        #expect(modifiedHTML.contains("#моястодневка от Антона Кучумова"))
        #expect(modifiedHTML.contains("video-container"))
        #expect(modifiedHTML.contains("script"))
    }

    @Test
    func prepareHTMLForDisplayWithoutYouTubeVideo() throws {
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
        let modifiedHTML = InfopostParser.prepareHTMLForDisplay(
            htmlContent,
            fontSize: .medium,
            infopost: infopost,
            youtubeService: youtubeService
        )

        // Then
        #expect(!modifiedHTML.contains("youtube.com"))
        #expect(!modifiedHTML.contains("iframe"))
        #expect(!modifiedHTML.contains("#моястодневка от Антона Кучумова"))
    }

    @Test
    func prepareHTMLForDisplayWithZeroDayNumber() throws {
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
        let modifiedHTML = InfopostParser.prepareHTMLForDisplay(
            htmlContent,
            fontSize: .medium,
            infopost: infopost,
            youtubeService: youtubeService
        )

        // Then
        #expect(!modifiedHTML.contains("youtube.com"))
    }

    @Test
    func youTubeVideoBlockStructure() throws {
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
        let modifiedHTML = InfopostParser.prepareHTMLForDisplay(
            htmlContent,
            fontSize: .medium,
            infopost: infopost,
            youtubeService: youtubeService
        )

        // Then
        // Проверяем структуру YouTube блока
        #expect(modifiedHTML.contains("<h2>&nbsp;&nbsp;&nbsp;&nbsp;#моястодневка от Антона Кучумова</h2>"))
        #expect(modifiedHTML.contains("video-container"))
        #expect(modifiedHTML.contains("frameborder=\"0\""))
        #expect(modifiedHTML.contains("allowfullscreen"))
        #expect(modifiedHTML.contains("iframe"))
    }

    @Test
    func javaScriptErrorHandling() throws {
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
        let modifiedHTML = InfopostParser.prepareHTMLForDisplay(
            htmlContent,
            fontSize: .medium,
            infopost: infopost,
            youtubeService: youtubeService
        )

        // Then
        // Проверяем, что добавлены скрипты для обработки видео
        #expect(modifiedHTML.contains("video_handler.js"))
        #expect(modifiedHTML.contains("console_interceptor.js"))
        #expect(modifiedHTML.contains("script"))
    }

    @Test
    func multipleYouTubeVideosInHTML() throws {
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
            id: "d5",
            title: "День 5",
            content: htmlContent,
            section: .base,
            dayNumber: 5,
            language: "ru"
        )

        // When
        let modifiedHTML = InfopostParser.prepareHTMLForDisplay(
            htmlContent,
            fontSize: .medium,
            infopost: infopost,
            youtubeService: youtubeService
        )

        // Then
        // Проверяем, что добавлен YouTube блок для дня 5
        #expect(modifiedHTML.contains("youtube.com"))
        #expect(modifiedHTML.contains("iframe"))
        #expect(modifiedHTML.contains("video-container"))
    }
}
