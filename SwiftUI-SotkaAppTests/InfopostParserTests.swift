import Foundation
@testable import SwiftUI_SotkaApp
import Testing

struct InfopostParserTests {
    // MARK: - Тесты для fixImagePaths

    @Test
    func fixImagePathsWithBackslashes() {
        // Arrange
        let html = """
        <html>
        <body>
        <img src="..\\img\\1.jpg" class="bbcode_img" />
        <img src="..\\img\\2.jpg" class="bbcode_img" />
        <p>Some text</p>
        </body>
        </html>
        """

        // Act
        let result = InfopostParser.fixImagePaths(html)

        // Assert
        #expect(result.contains("src=\"img/1.jpg\""))
        #expect(result.contains("src=\"img/2.jpg\""))
        #expect(!result.contains("..\\img\\"))
    }

    @Test
    func fixImagePathsWithForwardSlashes() {
        // Arrange
        let html = """
        <html>
        <body>
        <img src="../img/1.jpg" class="bbcode_img" />
        <img src="../img/2.jpg" class="bbcode_img" />
        <p>Some text</p>
        </body>
        </html>
        """

        // Act
        let result = InfopostParser.fixImagePaths(html)

        // Assert
        #expect(result.contains("src=\"img/1.jpg\""))
        #expect(result.contains("src=\"img/2.jpg\""))
        #expect(!result.contains("../img/"))
    }

    @Test
    func fixImagePathsMixedPaths() {
        // Arrange
        let html = """
        <html>
        <body>
        <img src="..\\img\\1.jpg" class="bbcode_img" />
        <img src="../img/2.jpg" class="bbcode_img" />
        <img src="..\\img\\3.jpg" class="bbcode_img" />
        <p>Some text</p>
        </body>
        </html>
        """

        // Act
        let result = InfopostParser.fixImagePaths(html)

        // Assert
        #expect(result.contains("src=\"img/1.jpg\""))
        #expect(result.contains("src=\"img/2.jpg\""))
        #expect(result.contains("src=\"img/3.jpg\""))
        #expect(!result.contains("..\\img\\"))
        #expect(!result.contains("../img/"))
    }

    @Test
    func fixImagePathsNoImages() {
        // Arrange
        let html = """
        <html>
        <body>
        <p>Some text without images</p>
        <div>Another div</div>
        </body>
        </html>
        """

        // Act
        let result = InfopostParser.fixImagePaths(html)

        // Assert
        #expect(result == html) // HTML должен остаться неизменным
    }

    // MARK: - Тесты для applyFontSize

    @Test
    func applyFontSizeSmall() {
        // Arrange
        let html = """
        <html>
        <head>
        <script type="text/javascript" src="../js/jquery.js"></script>
        <script type="text/javascript" src="../js/script.js"></script>
        </head>
        <body>
        <p>Content</p>
        </body>
        </html>
        """

        // Act
        let result = InfopostParser.applyFontSize(html, fontSize: .small)

        // Assert
        #expect(result.contains("src=\"js/jquery.js\""))
        #expect(result.contains("src=\"js/script_small.js\""))
        #expect(!result.contains("src=\"../js/script.js\""))
        #expect(result.contains("css/style_small.css"))
        #expect(result.contains("</body>"))
    }

    @Test
    func applyFontSizeMedium() {
        // Arrange
        let html = """
        <html>
        <head>
        <script type="text/javascript" src="../js/jquery.js"></script>
        <script type="text/javascript" src="../js/script.js"></script>
        </head>
        <body>
        <p>Content</p>
        </body>
        </html>
        """

        // Act
        let result = InfopostParser.applyFontSize(html, fontSize: .medium)

        // Assert
        #expect(result.contains("src=\"js/jquery.js\""))
        #expect(result.contains("src=\"js/script_medium.js\""))
        #expect(!result.contains("src=\"../js/script.js\""))
        #expect(result.contains("css/style_medium.css"))
    }

    @Test
    func applyFontSizeLarge() {
        // Arrange
        let html = """
        <html>
        <head>
        <script type="text/javascript" src="../js/jquery.js"></script>
        <script type="text/javascript" src="../js/script.js"></script>
        </head>
        <body>
        <p>Content</p>
        </body>
        </html>
        """

        // Act
        let result = InfopostParser.applyFontSize(html, fontSize: .large)

        // Assert
        #expect(result.contains("src=\"js/jquery.js\""))
        #expect(result.contains("src=\"js/script_big.js\""))
        #expect(!result.contains("src=\"../js/script.js\""))
        #expect(result.contains("css/style_big.css"))
    }

    @Test
    func applyFontSizeWithoutScriptTags() {
        // Arrange
        let html = """
        <html>
        <body>
        <p>Content without script tags</p>
        </body>
        </html>
        """

        // Act
        let result = InfopostParser.applyFontSize(html, fontSize: .medium)

        // Assert
        #expect(result.contains("src=\"js/script_medium.js\""))
        #expect(result.contains("css/style_medium.css"))
        #expect(result.contains("</body>"))
    }

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
        let result = InfopostParser.prepareHTMLForDisplay(html, fontSize: .large)

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
        #expect(result.contains("src=\"js/script_big.js\""))
        #expect(result.contains("css/style_big.css"))

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
        let result = InfopostParser.prepareHTMLForDisplay(html, fontSize: .small)

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
        let result = InfopostParser.prepareHTMLForDisplay(html, fontSize: .medium)

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
        let result = InfopostParser.prepareHTMLForDisplay(html, fontSize: .large)

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
        let result = InfopostParser.prepareHTMLForDisplay(html, fontSize: .medium)

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
        #expect(result.contains("src=\"js/script_medium.js\""))
        #expect(result.contains("css/style_medium.css"))

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
        let smallResult = InfopostParser.prepareHTMLForDisplay(html, fontSize: .small)
        #expect(smallResult.contains("script_small.js"))
        #expect(smallResult.contains("style_small.css"))

        let mediumResult = InfopostParser.prepareHTMLForDisplay(html, fontSize: .medium)
        #expect(mediumResult.contains("script_medium.js"))
        #expect(mediumResult.contains("style_medium.css"))

        let largeResult = InfopostParser.prepareHTMLForDisplay(html, fontSize: .large)
        #expect(largeResult.contains("script_big.js"))
        #expect(largeResult.contains("style_big.css"))
    }
}
