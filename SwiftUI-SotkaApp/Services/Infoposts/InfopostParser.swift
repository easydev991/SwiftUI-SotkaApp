import Foundation
import OSLog

/// Парсер HTML файлов инфопостов
enum InfopostParser {
    private static let logger = Logger(subsystem: "SotkaApp", category: "InfopostParser")

    /// Очищает HTML контент от лишних элементов (как в старом приложении SOTKA-ObjC)
    /// - Parameter html: Исходное HTML содержимое
    /// - Returns: Очищенное HTML содержимое
    static func cleanHTMLContent(_ html: String) -> String {
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

    /// Парсит HTML содержимое и создает модель Infopost
    /// - Parameters:
    ///   - html: HTML содержимое файла
    ///   - filename: Имя файла (например, "d1", "about", "aims")
    ///   - language: Язык файла ("ru" или "en")
    /// - Returns: Модель Infopost или nil при ошибке парсинга
    static func parse(html: String, filename: String, language: String) -> Infopost? {
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

        return Infopost.from(
            filename: filename,
            title: title,
            content: content,
            language: language
        )
    }

    /// Загружает содержимое HTML файла инфопоста
    /// - Parameters:
    ///   - filename: Имя файла без расширения (например, "d1", "about")
    ///   - language: Язык файла ("ru" или "en")
    /// - Returns: Содержимое HTML файла или nil при ошибке загрузки
    static func loadInfopostFile(filename: String, language: String) -> String? {
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

    /// Извлекает заголовок из HTML содержимого
    /// - Parameters:
    ///   - html: HTML содержимое
    ///   - filename: Имя файла для специальной обработки
    /// - Returns: Заголовок инфопоста
    private static func extractTitle(from html: String, filename: String) -> String {
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
            return NSLocalizedString("infopost.organizational", comment: "Title for the 'organiz' infopost with organizational information")
        case "aims":
            return NSLocalizedString("infopost.aims", comment: "Title for the 'aims' infopost describing program goals")
        case "about":
            return NSLocalizedString("infopost.about", comment: "Title for the 'about' infopost describing the SOTKA program")
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
    private static func extractContent(from html: String) -> String {
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

    /// Исправляет пути к изображениям в HTML контенте
    /// - Parameter html: Исходное HTML содержимое
    /// - Returns: HTML с исправленными путями к изображениям
    static func fixImagePaths(_ html: String) -> String {
        var modifiedHTML = html

        // Исправляем пути к изображениям: ..\img\ -> img/ и ../img/ -> img/
        modifiedHTML = modifiedHTML.replacingOccurrences(of: "..\\img\\", with: "img/")
        modifiedHTML = modifiedHTML.replacingOccurrences(of: "../img/", with: "img/")

        logger.debug("Исправлены пути к изображениям в HTML")

        return modifiedHTML
    }

    /// Модифицирует HTML для применения размера шрифта
    /// - Parameters:
    ///   - html: Исходное HTML содержимое
    ///   - fontSize: Размер шрифта для применения
    /// - Returns: HTML с примененным размером шрифта
    static func applyFontSize(_ html: String, fontSize: FontSize) -> String {
        var modifiedHTML = html

        // Определяем скрипт в зависимости от размера шрифта (как в старом проекте)
        let scriptName = switch fontSize {
        case .small:
            "script_small.js"
        case .medium:
            "script_medium.js"
        case .large:
            "script_big.js"
        }

        // Исправляем путь к jQuery для временной директории
        modifiedHTML = modifiedHTML.replacingOccurrences(of: "src=\"../js/jquery.js\"", with: "src=\"js/jquery.js\"")

        // Заменяем весь тег script с script.js на нужный скрипт
        let originalScriptTag = "<script type=\"text/javascript\" src=\"../js/script.js\"></script>"
        let newScriptTag = "<script type=\"text/javascript\" src=\"js/\(scriptName)\"></script>"
        modifiedHTML = modifiedHTML.replacingOccurrences(of: originalScriptTag, with: newScriptTag)

        // Если тег script.js не найден, добавляем нужный скрипт в head
        if !modifiedHTML.contains("src=\"js/\(scriptName)\"") {
            let scriptTagToAdd = "<script type=\"text/javascript\" src=\"js/\(scriptName)\"></script>"
            if modifiedHTML.contains("</head>") {
                modifiedHTML = modifiedHTML.replacingOccurrences(of: "</head>", with: "\(scriptTagToAdd)\n</head>")
            } else {
                // Если нет </head>, добавляем в начало body
                modifiedHTML = modifiedHTML.replacingOccurrences(of: "<body>", with: "<body>\n\(scriptTagToAdd)")
            }
        }

        // Добавляем инлайн скрипт для исправления путей к CSS в зависимости от размера шрифта
        let cssPath = switch fontSize {
        case .small:
            "css/style_small.css"
        case .medium:
            "css/style_medium.css"
        case .large:
            "css/style_big.css"
        }

        let inlineScript = """
        <script>
        $(document).ready(function() {
            // Удаляем старые CSS файлы размеров шрифта
            $('link[href*="style_small.css"], link[href*="style_medium.css"], link[href*="style_big.css"]').remove();

            // Добавляем новый CSS файл для размера шрифта
            $('head').append('<link rel="stylesheet" href="\(cssPath)" type="text/css" media="screen" />');
        });
        </script>
        """

        // Добавляем инлайн скрипт перед закрывающим тегом body
        modifiedHTML = modifiedHTML.replacingOccurrences(of: "</body>", with: "\(inlineScript)</body>")

        logger.debug("Заменен скрипт на: \(scriptName) для размера шрифта: \(fontSize.rawValue)")

        return modifiedHTML
    }

    /// Подготавливает HTML контент для отображения в WKWebView
    /// - Parameters:
    ///   - html: Исходное HTML содержимое
    ///   - fontSize: Размер шрифта для применения
    /// - Returns: Подготовленный HTML контент
    static func prepareHTMLForDisplay(_ html: String, fontSize: FontSize) -> String {
        logger.debug("Начинаем подготовку HTML для отображения с размером шрифта: \(fontSize.rawValue)")

        // 1. Очищаем HTML от лишних элементов
        let cleanedHTML = cleanHTMLContent(html)

        // 2. Исправляем пути к изображениям
        let htmlWithFixedImages = fixImagePaths(cleanedHTML)

        // 3. Применяем размер шрифта
        let finalHTML = applyFontSize(htmlWithFixedImages, fontSize: fontSize)

        logger.debug("Подготовка HTML завершена")

        return finalHTML
    }
}
