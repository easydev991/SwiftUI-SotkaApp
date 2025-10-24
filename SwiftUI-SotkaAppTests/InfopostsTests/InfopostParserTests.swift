import Foundation
@testable import SwiftUI_SotkaApp
import Testing

extension AllInfopostsTests {
    struct InfopostParserTests {
        private let testInfopost = Infopost(id: "test", title: "Test", content: "Test", section: .base, dayNumber: nil, language: "ru")
        private let youtubeService = YouTubeVideoService()

        // MARK: - Тесты для prepareHTMLForDisplay

        @Test
        func prepareHTMLForDisplayCompleteFlow() {
            // Arrange
            let html = """
            <html>
            <head>
            <script type="text/javascript" src="../js/jquery.js"></script>
            <script type="text/javascript" src="../js/script.js"></script>
            </head>
            <body>
            <header>Header content</header>
            <div class="text post-body-text">
            <p>Main content</p>
            <img src="..\\img\\1.jpg" class="bbcode_img" />
            <img src="../img/2.jpg" class="bbcode_img" />
            </div>
            <footer>Footer content</footer>
            </body>
            </html>
            """

            // Act
            let parser = InfopostParser(filename: "test", language: "ru")
            let result = parser.prepareHTMLForDisplay(html, fontSize: .large, infopost: testInfopost, youtubeService: youtubeService)

            // Assert
            // Проверяем, что header удален
            #expect(!result.contains("<header>"))
            #expect(!result.contains("Header content"))

            // Проверяем, что footer удален
            #expect(!result.contains("<footer>"))
            #expect(!result.contains("Footer content"))

            // Проверяем исправление путей к изображениям
            #expect(result.contains("src=\"img/1.jpg\""))
            #expect(result.contains("src=\"img/2.jpg\""))

            // Проверяем применение размера шрифта
            #expect(result.contains("data-font-size=\"large\""))
            #expect(result.contains("font_size_handler.js"))

            // Проверяем, что основной контент остался
            #expect(result.contains("Main content"))
        }

        @Test
        func prepareHTMLForDisplayWithBackLinks() {
            // Arrange
            let html = """
            <html>
            <body>
            <div class="text post-body-text">
            <p>Main content</p>
            <p><a href="index.html">Вернуться к оглавлению</a></p>
            <p><a href="index.html"><==== Вернуться к оглавлению</a></p>
            </div>
            </body>
            </html>
            """

            // Act
            let parser = InfopostParser(filename: "test", language: "ru")
            let result = parser.prepareHTMLForDisplay(html, fontSize: .small, infopost: testInfopost, youtubeService: youtubeService)

            // Assert
            #expect(!result.contains("Вернуться к оглавлению"))
            #expect(!result.contains("<==== Вернуться к оглавлению"))
            #expect(result.contains("Main content"))
        }

        @Test
        func prepareHTMLForDisplayWithFullDiv() {
            // Arrange
            let html = """
            <html>
            <body>
            <div class="text post-body-text">
            <p>Main content</p>
            </div>
            <div class="full">
            <p>Full div content to be removed</p>
            </div>
            </body>
            </html>
            """

            // Act
            let parser = InfopostParser(filename: "test", language: "ru")
            let result = parser.prepareHTMLForDisplay(html, fontSize: .medium, infopost: testInfopost, youtubeService: youtubeService)

            // Assert
            #expect(!result.contains("<div class=\"full\">"))
            #expect(!result.contains("Full div content to be removed"))
            #expect(result.contains("Main content"))
        }

        @Test
        func prepareHTMLForDisplayEmptyFullDiv() {
            // Arrange
            let html = """
            <html>
            <body>
            <div class="text post-body-text">
            <p>Main content</p>
            </div>
            <div class="full"></div>
            </body>
            </html>
            """

            // Act
            let parser = InfopostParser(filename: "test", language: "ru")
            let result = parser.prepareHTMLForDisplay(html, fontSize: .large, infopost: testInfopost, youtubeService: youtubeService)

            // Assert
            #expect(!result.contains("<div class=\"full\"></div>"))
            #expect(result.contains("Main content"))
        }

        // MARK: - Интеграционные тесты

        @Test
        func prepareHTMLForDisplayRealWorldExample() {
            // Arrange - имитируем реальный HTML инфопоста
            let html = """
            <!DOCTYPE html>
            <html>
            <head>
            <meta charset="utf-8">
            <title>День 1</title>
            <script type="text/javascript" src="../js/jquery.js"></script>
            <script type="text/javascript" src="../js/script.js"></script>
            </head>
            <body>
            <header>
            <h1>Header</h1>
            </header>
            <div class="text post-body-text">
            <h2 class="dayname">День 1: Начало пути</h2>
            <p>Добро пожаловать в программу Сотка!</p>
            <img src="..\\img\\1.jpg" class="bbcode_img" />
            <p>Сегодня мы начинаем наше путешествие к здоровому образу жизни.</p>
            <img src="../img/1-1.jpg" class="bbcode_img" />
            <p><a href="index.html">Вернуться к оглавлению</a></p>
            </div>
            <div class="full">
            <p>Дополнительная информация</p>
            </div>
            <footer>
            <p>Footer content</p>
            </footer>
            </body>
            </html>
            """

            // Act
            let parser = InfopostParser(filename: "test", language: "ru")
            let result = parser.prepareHTMLForDisplay(html, fontSize: .medium, infopost: testInfopost, youtubeService: youtubeService)

            // Assert
            // Проверяем очистку от лишних элементов
            #expect(!result.contains("<header>"))
            #expect(!result.contains("<footer>"))
            #expect(!result.contains("Вернуться к оглавлению"))
            #expect(!result.contains("<div class=\"full\">"))

            // Проверяем исправление путей к изображениям
            #expect(result.contains("src=\"img/1.jpg\""))
            #expect(result.contains("src=\"img/1-1.jpg\""))

            // Проверяем применение размера шрифта
            #expect(result.contains("data-font-size=\"medium\""))
            #expect(result.contains("font_size_handler.js"))

            // Проверяем, что основной контент остался
            #expect(result.contains("День 1: Начало пути"))
            #expect(result.contains("Добро пожаловать в программу Сотка!"))
            #expect(result.contains("Сегодня мы начинаем наше путешествие"))
        }

        @Test
        func prepareHTMLForDisplayAllFontSizes() {
            // Arrange
            let html = """
            <html>
            <body>
            <div class="text post-body-text">
            <p>Content</p>
            <img src="..\\img\\1.jpg" />
            </div>
            </body>
            </html>
            """

            // Act & Assert для всех размеров шрифта
            let parser = InfopostParser(filename: "test", language: "ru")

            let smallResult = parser.prepareHTMLForDisplay(
                html,
                fontSize: .small,
                infopost: testInfopost,
                youtubeService: youtubeService
            )
            #expect(smallResult.contains("data-font-size=\"small\""))
            #expect(smallResult.contains("font_size_handler.js"))

            let mediumResult = parser.prepareHTMLForDisplay(
                html,
                fontSize: .medium,
                infopost: testInfopost,
                youtubeService: youtubeService
            )
            #expect(mediumResult.contains("data-font-size=\"medium\""))
            #expect(mediumResult.contains("font_size_handler.js"))

            let largeResult = parser.prepareHTMLForDisplay(
                html,
                fontSize: .large,
                infopost: testInfopost,
                youtubeService: youtubeService
            )
            #expect(largeResult.contains("data-font-size=\"large\""))
            #expect(largeResult.contains("font_size_handler.js"))
        }
    }
}
