@testable import SwiftUI_SotkaApp
import Testing

extension AllInfopostsTests {
    struct InfopostYouTubeIframeReplacementTests {
        private let youtubeService = YouTubeVideoService(analytics: AnalyticsService(providers: [NoopAnalyticsProvider()]))

        @Test("Заменяет YouTube iframe внутри вложенных контейнеров на внешний блок")
        func replacesYouTubeIframesInsideNestedContainers() {
            // Given
            let html = """
            <html>
            <body>
              <div class="text post-body-text">
                <center>
                  <iframe width="560" height="315" src="https://www.youtube.com/embed/OM0m9CEjq2Y?si=abc" title="Video Title"></iframe>
                </center>
              </div>
            </body>
            </html>
            """

            let infopost = Infopost(
                id: "organiz",
                title: "Organiz",
                content: html,
                section: .preparation,
                dayNumber: nil,
                language: "ru"
            )

            // When
            let parser = InfopostParser(filename: "organiz", language: "ru")
            let result = parser.prepareHTMLForDisplay(
                html,
                fontSize: .medium,
                infopost: infopost,
                youtubeService: youtubeService
            )

            // Then
            #expect(!result.contains("<iframe"))
            #expect(result.contains("video-external-container"))
            #expect(result.contains("sotka://youtube?url="))
            #expect(result.contains("Video Title"))
            #expect(result.contains("https%3A%2F%2Fwww.youtube.com%2Fwatch%3Fv%3DOM0m9CEjq2Y"))
        }

        @Test("Не изменяет iframe, которые не относятся к YouTube")
        func keepsNonYouTubeIframesUntouched() {
            // Given
            let html = """
            <html>
            <body>
              <div class="text post-body-text">
                <iframe src="https://example.com/embed/42"></iframe>
              </div>
            </body>
            </html>
            """

            let infopost = Infopost(
                id: "aims",
                title: "Aims",
                content: html,
                section: .preparation,
                dayNumber: nil,
                language: "ru"
            )

            // When
            let parser = InfopostParser(filename: "aims", language: "ru")
            let result = parser.prepareHTMLForDisplay(
                html,
                fontSize: .medium,
                infopost: infopost,
                youtubeService: youtubeService
            )

            // Then
            #expect(result.contains("<iframe src=\"https://example.com/embed/42\">"))
            #expect(!result.contains("video-external-container"))
        }

        @Test("Одновременно заменяет встроенный и дневной YouTube-блоки")
        func replacesBothEmbeddedAndDayYouTubeBlocks() {
            // Given
            let html = """
            <html>
            <body>
              <div class="text post-body-text">
                <iframe src="https://youtu.be/OM0m9CEjq2Y"></iframe>
                <p>Some text</p>
              </div>
            </body>
            </html>
            """

            let infopost = Infopost(
                id: "d7",
                title: "Day 7",
                content: html,
                section: .base,
                dayNumber: 7,
                language: "ru"
            )

            // When
            let parser = InfopostParser(filename: "d7", language: "ru")
            let result = parser.prepareHTMLForDisplay(
                html,
                fontSize: .medium,
                infopost: infopost,
                youtubeService: youtubeService
            )

            // Then
            let blockCount = result.components(separatedBy: "video-external-container").count - 1
            #expect(!result.contains("<iframe"))
            #expect(blockCount == 2)
        }
    }
}
