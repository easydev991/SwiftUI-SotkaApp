import Foundation
import OSLog

/// Парсер HTML файлов инфопостов
struct InfopostParser {
    private let logger = Logger(subsystem: Bundle.sotkaAppBundleId, category: String(describing: InfopostParser.self))

    let filename: String
    let language: String

    /// Парсит HTML содержимое и создает модель Infopost
    /// - Parameter html: HTML содержимое файла
    /// - Returns: Модель Infopost или nil при ошибке парсинга
    func parse(html: String) -> Infopost? {
        guard !html.isEmpty else {
            logger.error("Пустое HTML содержимое для файла: \(filename)")
            return nil
        }

        let title = extractTitle(from: html, filename: filename)
        let content = extractContent(from: html)

        guard !title.isEmpty, !content.isEmpty else {
            logger.error("Не удалось извлечь заголовок или содержимое для файла: \(filename)")
            return nil
        }

        logger.info("Успешно распарсен инфопост: \(filename) - \(title)")

        return Infopost(
            filename: filename,
            title: title,
            content: content,
            language: language
        )
    }

    /// Загружает содержимое HTML файла инфопоста
    /// - Returns: Содержимое HTML файла или nil при ошибке загрузки
    func loadHTMLContent() -> String? {
        // Формируем имя файла с суффиксом языка (например, "d1_ru", "about_ru")
        let filenameWithLanguage = "\(filename)_\(language)"

        // Ищем файл с суффиксом языка в корне бандла
        guard let bundlePath = Bundle.main.path(forResource: filenameWithLanguage, ofType: "html") else {
            logger.error("Файл не найден: \(filenameWithLanguage).html для языка \(language)")
            return nil
        }

        do {
            let content = try String(contentsOfFile: bundlePath, encoding: .utf8)
            logger.debug("Загружен файл: \(filenameWithLanguage).html (\(content.count) символов)")

            // Очищаем HTML от лишнего контента (как в старом приложении SOTKA-ObjC)
            let cleanedContent = cleanHTMLContent(content)
            logger.debug("HTML очищен от лишнего контента (исходно: \(content.count), очищено: \(cleanedContent.count) символов)")

            return cleanedContent
        } catch {
            logger.error("Ошибка загрузки файла \(filenameWithLanguage).html: \(error.localizedDescription)")
            return nil
        }
    }

    /// Подготавливает HTML контент для отображения в WKWebView
    /// - Parameters:
    ///   - html: Исходное HTML содержимое
    ///   - fontSize: Размер шрифта для применения
    ///   - infopost: Инфопост для проверки наличия YouTube видео
    ///   - youtubeService: Сервис для работы с YouTube видео
    /// - Returns: Подготовленный HTML контент
    func prepareHTMLForDisplay(
        _ html: String,
        fontSize: FontSize,
        infopost: Infopost,
        youtubeService: YouTubeVideoService
    ) -> String {
        logger.info("🚀 Начинаем подготовку HTML для отображения инфопоста: \(infopost.id)")
        logger
            .debug(
                "📊 Параметры: fontSize=\(fontSize.rawValue), title=\(infopost.title), dayNumber=\(infopost.dayNumber?.description ?? "nil")"
            )
        logger.debug("📏 Исходный размер HTML: \(html.count) символов")

        // 1. Очищаем HTML от лишних элементов
        logger.debug("🧹 Этап 1: Очистка HTML от лишних элементов")
        let cleanedHTML = cleanHTMLContent(html)
        logger.debug("📏 Размер после очистки: \(cleanedHTML.count) символов")

        // 2. Исправляем пути к изображениям
        logger.debug("🖼️ Этап 2: Исправление путей к изображениям")
        let htmlWithFixedImages = fixImagePaths(cleanedHTML)
        logger.debug("📏 Размер после исправления путей: \(htmlWithFixedImages.count) символов")

        // 3. Применяем размер шрифта
        logger.debug("🔤 Этап 3: Применение размера шрифта")
        let htmlWithFontSize = applyFontSize(htmlWithFixedImages, fontSize: fontSize)
        logger.debug("📏 Размер после применения шрифта: \(htmlWithFontSize.count) символов")

        // 4. Добавляем YouTube видео для постов с номерами дней
        logger.debug("🎬 Этап 4: Добавление YouTube видео")
        let htmlWithYouTube = addYouTubeVideo(to: htmlWithFontSize, infopost: infopost, youtubeService: youtubeService)
        logger.debug("📏 Размер после добавления YouTube: \(htmlWithYouTube.count) символов")

        // 5. Добавляем универсальный обработчик видео
        logger.debug("🎥 Этап 5: Добавление универсального обработчика видео")
        let finalHTML = addUniversalVideoHandler(to: htmlWithYouTube)
        logger.debug("📏 Финальный размер HTML: \(finalHTML.count) символов")

        logger.info("✅ Подготовка HTML завершена для инфопоста: \(infopost.id)")

        return finalHTML
    }
}

private extension InfopostParser {
    /// Очищает HTML контент от лишних элементов (как в старом приложении SOTKA-ObjC)
    /// - Parameter html: Исходное HTML содержимое
    /// - Returns: Очищенное HTML содержимое
    func cleanHTMLContent(_ html: String) -> String {
        var cleanedHTML = html

        logger.debug("Начинаем очистку HTML контента")

        // 1. Удаляем содержимое между <header> и </header>
        if let headerStartRange = cleanedHTML.range(of: "<header[^>]*>", options: .regularExpression),
           let headerEndRange = cleanedHTML.range(
               of: "</header>",
               options: .regularExpression,
               range: headerStartRange.upperBound ..< cleanedHTML.endIndex
           ) {
            let contentToRemove = String(cleanedHTML[headerStartRange.lowerBound ..< headerEndRange.upperBound])
            cleanedHTML = cleanedHTML.replacingOccurrences(of: contentToRemove, with: "")
            logger.debug("Удален header контент")
        }

        // 2. Удаляем ссылки "Вернуться к оглавлению"
        let backLinks = [
            #"<p><a[^>]*ID="lnkIndex"[^>]*href="[^"]*index\.html"[^>]*><==== Вернуться к оглавлению</a></p>"#,
            #"<p><a[^>]*ID="lnkIndex"[^>]*href="[^"]*index\.html"[^>]*>Вернуться к оглавлению</a></p>"#,
            #"<p><a[^>]*href="[^"]*index\.html"[^>]*><==== Вернуться к оглавлению</a></p>"#,
            #"<p><a[^>]*href="[^"]*index\.html"[^>]*>Вернуться к оглавлению</a></p>"#
        ]

        for linkPattern in backLinks {
            cleanedHTML = cleanedHTML.replacingOccurrences(of: linkPattern, with: "", options: .regularExpression)
        }

        if backLinks.contains(where: { cleanedHTML.range(of: $0, options: .regularExpression) != nil }) {
            logger.debug("Удалены ссылки на оглавление")
        }

        // 3. Удаляем содержимое между <div class="full"> и </div>
        if let fullDivStartRange = cleanedHTML.range(of: #"<div class="full">"#, options: .regularExpression) {
            if let fullDivEndRange = cleanedHTML.range(
                of: "</div>",
                options: .regularExpression,
                range: fullDivStartRange.upperBound ..< cleanedHTML.endIndex
            ) {
                let contentToRemove = String(cleanedHTML[fullDivStartRange.lowerBound ..< fullDivEndRange.upperBound])
                cleanedHTML = cleanedHTML.replacingOccurrences(of: contentToRemove, with: "")
                logger.debug("Удален full div контент")
            }
        }

        // 4. Удаляем содержимое футера между <footer> и </footer>
        if let footerStartRange = cleanedHTML.range(of: "<footer[^>]*>", options: .regularExpression) {
            if let footerEndRange = cleanedHTML.range(
                of: "</footer>",
                options: .regularExpression,
                range: footerStartRange.upperBound ..< cleanedHTML.endIndex
            ) {
                let contentToRemove = String(cleanedHTML[footerStartRange.lowerBound ..< footerEndRange.upperBound])
                cleanedHTML = cleanedHTML.replacingOccurrences(of: contentToRemove, with: "")
                logger.debug("Удален footer контент")
            }
        }

        // 5. Удаляем пустые div элементы <div class="full"></div>
        cleanedHTML = cleanedHTML.replacingOccurrences(of: #"<div class="full"></div>"#, with: "", options: .regularExpression)

        logger.debug("Очистка HTML контента завершена")
        return cleanedHTML
    }

    /// Извлекает заголовок из HTML содержимого
    /// - Parameters:
    ///   - html: HTML содержимое
    ///   - filename: Имя файла для специальной обработки
    /// - Returns: Заголовок инфопоста
    func extractTitle(from html: String, filename: String) -> String {
        // Ищем заголовок в теге <h2 class="dayname">
        if let range = html.range(of: #"<h2 class="dayname">(.*?)</h2>"#, options: .regularExpression) {
            let titleWithTags = String(html[range])
            let title = titleWithTags
                .replacingOccurrences(of: #"<h2 class="dayname">"#, with: "", options: .regularExpression)
                .replacingOccurrences(of: "</h2>", with: "")
                .trimmingCharacters(in: .whitespacesAndNewlines)

            if !title.isEmpty {
                return title
            }
        }

        // Fallback: ищем любой заголовок h2
        if let range = html.range(of: #"<h2[^>]*>(.*?)</h2>"#, options: .regularExpression) {
            let titleWithTags = String(html[range])
            let title = titleWithTags
                .replacingOccurrences(of: #"<h2[^>]*>"#, with: "", options: .regularExpression)
                .replacingOccurrences(of: "</h2>", with: "")
                .trimmingCharacters(in: .whitespacesAndNewlines)

            if !title.isEmpty {
                return title
            }
        }

        // Fallback: ищем заголовок h1
        if let range = html.range(of: #"<h1[^>]*>(.*?)</h1>"#, options: .regularExpression) {
            let titleWithTags = String(html[range])
            let title = titleWithTags
                .replacingOccurrences(of: #"<h1[^>]*>"#, with: "", options: .regularExpression)
                .replacingOccurrences(of: "</h1>", with: "")
                .trimmingCharacters(in: .whitespacesAndNewlines)

            if !title.isEmpty {
                return title
            }
        }

        // Специальная обработка для файлов organiz, aims и about
        switch filename {
        case "organiz":
            return String(localized: .infopostOrganizational)
        case "aims":
            return String(localized: .infopostAims)
        case "about":
            return String(localized: .infopostAbout)
        default:
            break
        }

        // Fallback: ищем первый h3 заголовок в контенте
        if let range = html.range(of: #"<h3[^>]*>(.*?)</h3>"#, options: .regularExpression) {
            let titleWithTags = String(html[range])
            let title = titleWithTags
                .replacingOccurrences(of: #"<h3[^>]*>"#, with: "", options: .regularExpression)
                .replacingOccurrences(of: "</h3>", with: "")
                .trimmingCharacters(in: .whitespacesAndNewlines)

            if !title.isEmpty {
                return title
            }
        }

        logger.warning("Не удалось извлечь заголовок из HTML для файла: \(filename)")
        return ""
    }

    /// Извлекает основное содержимое из HTML
    /// - Parameter html: HTML содержимое
    /// - Returns: Основное содержимое инфопоста
    func extractContent(from html: String) -> String {
        // Ищем содержимое в теге <div class="text post-body-text">
        if let startRange = html.range(of: #"<div class="text post-body-text">"#, options: .regularExpression) {
            let startIndex = startRange.upperBound

            // Находим позицию закрывающего тега </div> после начала контента
            if let endRange = html.range(of: "</div>", options: .regularExpression, range: startIndex ..< html.endIndex) {
                let content = String(html[startIndex ..< endRange.lowerBound])
                    .trimmingCharacters(in: .whitespacesAndNewlines)

                if !content.isEmpty {
                    return content
                }
            }
        }

        // Fallback: ищем содержимое в теге <section>
        if let startRange = html.range(of: "<section[^>]*>", options: .regularExpression) {
            let startIndex = startRange.upperBound

            if let endRange = html.range(of: "</section>", options: .regularExpression, range: startIndex ..< html.endIndex) {
                let content = String(html[startIndex ..< endRange.lowerBound])
                    .trimmingCharacters(in: .whitespacesAndNewlines)

                if !content.isEmpty {
                    return content
                }
            }
        }

        // Fallback: ищем содержимое в теге <body>
        if let startRange = html.range(of: "<body[^>]*>", options: .regularExpression) {
            let startIndex = startRange.upperBound

            if let endRange = html.range(of: "</body>", options: .regularExpression, range: startIndex ..< html.endIndex) {
                let content = String(html[startIndex ..< endRange.lowerBound])
                    .trimmingCharacters(in: .whitespacesAndNewlines)

                if !content.isEmpty {
                    return content
                }
            }
        }

        logger.warning("Не удалось извлечь содержимое из HTML")
        return ""
    }

    /// Добавляет YouTube видео блок в HTML контент
    /// - Parameters:
    ///   - html: HTML контент
    ///   - infopost: Инфопост для проверки наличия видео
    ///   - youtubeService: Сервис для работы с YouTube видео
    /// - Returns: HTML с добавленным YouTube блоком
    func addYouTubeVideo(
        to html: String,
        infopost: Infopost,
        youtubeService: YouTubeVideoService
    ) -> String {
        logger.info("🎬 Начинаем добавление YouTube видео для инфопоста: \(infopost.id)")
        logger
            .debug(
                "📋 Инфопост: title=\(infopost.title), dayNumber=\(infopost.dayNumber?.description ?? "nil"), section=\(infopost.section.rawValue)"
            )

        // Проверяем, есть ли у инфопоста номер дня
        guard let dayNumber = infopost.dayNumber else {
            logger.debug("❌ У инфопоста \(infopost.id) нет номера дня, пропускаем добавление видео")
            return html
        }

        logger.debug("✅ Инфопост имеет номер дня: \(dayNumber)")

        // Получаем видео для инфопоста
        do {
            guard let video = try youtubeService.getVideo(for: dayNumber) else {
                logger.warning("⚠️ YouTube видео для дня \(dayNumber) не найдено в сервисе")
                return html
            }

            logger.info("🎥 Найдено YouTube видео для дня \(dayNumber): \(video.url)")
            logger.debug("📺 Заголовок видео: \(video.title)")

            // Создаем простой HTML блок с правильным контейнером для обработки ошибок
            let videoBlock = """
            <br><h2 class="video-title">&nbsp;&nbsp;&nbsp;&nbsp;\(video.title)</h2>
            <div class="video-container">
                <iframe src="\(video.url)" 
                        frameborder="0" 
                        allowfullscreen>
                </iframe>
            </div>
            <br><br><footer>
            """

            // Проверяем, есть ли тег <footer> в HTML
            if html.contains("<footer>") {
                logger.debug("✅ Найден тег <footer> в HTML, вставляем видео блок")
                let modifiedHTML = html.replacingOccurrences(of: "<footer>", with: videoBlock)
                logger.info("🎬 YouTube видео успешно добавлено в HTML для дня \(dayNumber)")
                return modifiedHTML
            } else {
                logger.warning("⚠️ Тег <footer> не найден в HTML, добавляем видео блок в конец")
                let modifiedHTML = html + videoBlock
                logger.info("🎬 YouTube видео добавлено в конец HTML для дня \(dayNumber)")
                return modifiedHTML
            }

        } catch {
            logger.error("❌ Ошибка при получении YouTube видео для дня \(dayNumber): \(error.localizedDescription)")
            return html
        }
    }

    /// Добавляет универсальный обработчик видео в HTML контент
    /// - Parameter html: HTML контент
    /// - Returns: HTML с добавленным универсальным обработчиком видео
    func addUniversalVideoHandler(to html: String) -> String {
        logger.debug("🎥 Добавляем универсальный обработчик видео")

        // Создаем скрипт для подключения перехватчика консоли
        let consoleInterceptorScript = """
        <script type="text/javascript" src="js/console_interceptor.js"></script>
        """

        // Создаем скрипт для подключения универсального обработчика видео
        let videoHandlerScript = """
        <script type="text/javascript" src="js/video_handler.js"></script>
        """

        // Создаем скрипт для подключения отслеживания скролла
        let scrollTrackerScript = """
        <script type="text/javascript" src="js/scroll_tracker.js"></script>
        """

        // Создаем скрипт для подключения обработчика размера шрифта
        let fontSizeHandlerScript = """
        <script type="text/javascript" src="js/font_size_handler.js"></script>
        """

        // Добавляем скрипты в head, если он есть
        if html.contains("</head>") {
            let scripts = consoleInterceptorScript + "\n" + videoHandlerScript + "\n" + scrollTrackerScript + "\n" + fontSizeHandlerScript
            let modifiedHTML = html.replacingOccurrences(of: "</head>", with: "\(scripts)\n</head>")
            logger
                .debug(
                    "✅ Универсальный обработчик видео, перехватчик консоли, отслеживание скролла и обработчик размера шрифта добавлены в head"
                )
            return modifiedHTML
        } else {
            // Если нет head, добавляем перед закрывающим тегом body
            let scripts = consoleInterceptorScript + "\n" + videoHandlerScript + "\n" + scrollTrackerScript + "\n" + fontSizeHandlerScript
            let modifiedHTML = html.replacingOccurrences(of: "</body>", with: "\(scripts)\n</body>")
            logger
                .debug(
                    "✅ Универсальный обработчик видео, перехватчик консоли, отслеживание скролла и обработчик размера шрифта добавлены перед </body>"
                )
            return modifiedHTML
        }
    }

    /// Исправляет пути к изображениям в HTML контенте (встроенная версия)
    /// - Parameter html: Исходное HTML содержимое
    /// - Returns: HTML с исправленными путями к изображениям
    func fixImagePaths(_ html: String) -> String {
        var modifiedHTML = html

        // Исправляем пути к изображениям: ..\img\ -> img/ и ../img/ -> img/
        modifiedHTML = modifiedHTML.replacingOccurrences(of: "..\\img\\", with: "img/")
        modifiedHTML = modifiedHTML.replacingOccurrences(of: "../img/", with: "img/")

        return modifiedHTML
    }

    /// Модифицирует HTML для применения размера шрифта (встроенная версия)
    /// - Parameters:
    ///   - html: Исходное HTML содержимое
    ///   - fontSize: Размер шрифта для применения
    /// - Returns: HTML с примененным размером шрифта
    func applyFontSize(_ html: String, fontSize: FontSize) -> String {
        var modifiedHTML = html

        // Исправляем путь к jQuery для временной директории
        modifiedHTML = modifiedHTML.replacingOccurrences(of: "src=\"../js/jquery.js\"", with: "src=\"js/jquery.js\"")

        // Добавляем data-атрибут размера шрифта в тег body
        let bodyWithFontSize = modifiedHTML.replacingOccurrences(
            of: "<body[^>]*>",
            with: "<body class=\"pattern\" data-font-size=\"\(fontSize.rawValue)\">",
            options: .regularExpression
        )

        logger.debug("✅ Добавлен data-атрибут размера шрифта: \(fontSize.rawValue)")

        return bodyWithFontSize
    }
}
