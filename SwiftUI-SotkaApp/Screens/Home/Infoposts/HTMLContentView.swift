import OSLog
import SwiftUI
import WebKit

/// Компонент для отображения HTML контента с использованием WKWebView
struct HTMLContentView: UIViewRepresentable {
    private let logger = Logger(subsystem: "SotkaApp", category: "HTMLContentView")
    let filename: String
    let fontSize: FontSize

    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.defaultWebpagePreferences.allowsContentJavaScript = true

        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator
        webView.backgroundColor = .clear
        webView.scrollView.backgroundColor = .clear
        webView.allowsLinkPreview = false

        return webView
    }

    func updateUIView(_ webView: WKWebView, context _: Context) {
        loadContent(in: webView)
    }

    private func loadContent(in webView: WKWebView) {
        // Создаем временную директорию для ресурсов
        guard let tempDirectory = createTempDirectory() else {
            logger.error("Не удалось создать временную директорию")
            return
        }

        // Загружаем HTML файл из бандла
        logger.debug("Пытаемся найти файл: \(filename).html")
        guard let htmlFileURL = Bundle.main.url(forResource: filename, withExtension: "html") else {
            logger.error("Файл не найден: \(filename).html в бандле")
            logger.error("Проверяем доступные файлы в бандле:")
            do {
                let bundleURL = Bundle.main.bundleURL
                let contents = try FileManager.default.contentsOfDirectory(at: bundleURL, includingPropertiesForKeys: nil)
                let htmlFiles = contents
                    .filter { $0.pathExtension == "html" && $0.lastPathComponent.contains(filename.split(separator: "_").first ?? "") }
                logger.error("Найдено похожих файлов: \(htmlFiles.map(\.lastPathComponent))")
            } catch {
                logger.error("Ошибка при поиске файлов: \(error.localizedDescription)")
            }
            return
        }
        logger.debug("Файл найден: \(htmlFileURL.path)")

        do {
            // Загружаем HTML контент
            let htmlContent = try String(contentsOf: htmlFileURL, encoding: .utf8)

            // Подготавливаем HTML для отображения через парсер
            let modifiedHTML = InfopostParser.prepareHTMLForDisplay(htmlContent, fontSize: fontSize)

            // Добавляем отладочную информацию о HTML после обработки
            logger.debug("🔍 HTML после обработки содержит пути к изображениям:")
            let processedImagePaths = modifiedHTML.components(separatedBy: .newlines)
                .compactMap { line in
                    if line.contains("src="), line.contains("img") {
                        return line.trimmingCharacters(in: .whitespaces)
                    }
                    return nil
                }
            for path in processedImagePaths {
                logger.debug("📋 Обработанный путь: \(path)")
            }

            // Создаем временный HTML файл
            let tempHTMLFile = tempDirectory.appendingPathComponent("preview.html")

            // Копируем ресурсы (CSS, JS, изображения) и получаем обновленный HTML
            let finalHTML = copyResources(to: tempDirectory, htmlContent: modifiedHTML)

            // Создаем финальный HTML файл с обновленными путями к изображениям
            try finalHTML.write(to: tempHTMLFile, atomically: true, encoding: .utf8)

            // Добавляем отладочную информацию о созданном HTML файле
            logger.debug("📄 Создан временный HTML файл: \(tempHTMLFile.path)")
            logger.debug("📄 Содержимое HTML файла:")
            let htmlLines = finalHTML.components(separatedBy: .newlines)
            for (index, line) in htmlLines.enumerated() {
                if line.contains("img") || line.contains("src=") {
                    logger.debug("📄 Строка \(index + 1): \(line.trimmingCharacters(in: .whitespaces))")
                }
            }

            // Загружаем файл с доступом ко всей временной директории
            logger.debug("🌐 Загружаем HTML в WKWebView:")
            logger.debug("🌐 HTML файл: \(tempHTMLFile.path)")
            logger.debug("🌐 Временная директория: \(tempDirectory.path)")
            logger.debug("🌐 Папка img: \(tempDirectory.appendingPathComponent("img").path)")

            // Проверяем, что изображения действительно существуют
            let imgDirectory = tempDirectory.appendingPathComponent("img")
            do {
                let imgFiles = try FileManager.default.contentsOfDirectory(at: imgDirectory, includingPropertiesForKeys: nil)
                logger.debug("🌐 Файлы в папке img: \(imgFiles.map(\.lastPathComponent))")
            } catch {
                logger.error("🌐 Ошибка чтения папки img: \(error.localizedDescription)")
            }

            webView.loadFileURL(tempHTMLFile, allowingReadAccessTo: tempDirectory)

            logger.debug("Загружен инфопост: \(filename).html с размером шрифта: \(fontSize.rawValue)")
        } catch {
            logger.error("Ошибка подготовки контента: \(error.localizedDescription)")
        }
    }

    private func createTempDirectory() -> URL? {
        let fileManager = FileManager.default
        let tempDirectory = fileManager.temporaryDirectory.appendingPathComponent("infopost_preview")

        // Удаляем существующую директорию если есть
        if fileManager.fileExists(atPath: tempDirectory.path) {
            try? fileManager.removeItem(at: tempDirectory)
        }

        do {
            try fileManager.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
            return tempDirectory
        } catch {
            logger.error("Ошибка создания временной директории: \(error.localizedDescription)")
            return nil
        }
    }

    private func copyResources(to tempDirectory: URL, htmlContent: String) -> String {
        let fileManager = FileManager.default

        // Копируем CSS файлы из Assets
        copyDirectory(from: "css", to: tempDirectory.appendingPathComponent("css"), fileManager: fileManager)

        // Копируем JS файлы из Assets
        copyDirectory(from: "js", to: tempDirectory.appendingPathComponent("js"), fileManager: fileManager)

        // Копируем изображения из Assets.xcassets и получаем обновленный HTML
        let updatedHTML = copyImagesFromAssets(to: tempDirectory.appendingPathComponent("img"), from: htmlContent)

        return updatedHTML
    }

    private func copyDirectory(from sourceName: String, to destination: URL, fileManager: FileManager) {
        do {
            // Получаем все файлы в бандле с нужным расширением
            let bundleURL = Bundle.main.bundleURL
            let resourceURLs = try fileManager.contentsOfDirectory(at: bundleURL, includingPropertiesForKeys: nil)

            // Фильтруем файлы по расширению
            let matchingFiles = resourceURLs.filter { url in
                if sourceName == "img" {
                    // Для изображений ищем файлы с расширениями изображений
                    ["jpg", "jpeg", "png", "gif"].contains(url.pathExtension.lowercased())
                } else {
                    url.pathExtension == sourceName
                }
            }

            if !matchingFiles.isEmpty {
                // Создаем директорию назначения
                try fileManager.createDirectory(at: destination, withIntermediateDirectories: true)

                // Копируем файлы
                for sourceURL in matchingFiles {
                    let filename = sourceURL.lastPathComponent
                    let destinationURL = destination.appendingPathComponent(filename)

                    if fileManager.fileExists(atPath: destinationURL.path) {
                        try fileManager.removeItem(at: destinationURL)
                    }

                    try fileManager.copyItem(at: sourceURL, to: destinationURL)
                }

                logger.debug("Скопировано \(matchingFiles.count) файлов \(sourceName) в \(destination.path)")
            } else {
                logger.warning("Не найдены файлы ресурсов \(sourceName) в бандле")
            }
        } catch {
            logger.error("Ошибка копирования ресурсов \(sourceName): \(error.localizedDescription)")
        }
    }

    private func copyImagesFromAssets(to imgDirectory: URL, from htmlContent: String) -> String {
        let fileManager = FileManager.default

        // Создаем папку для изображений
        do {
            try fileManager.createDirectory(at: imgDirectory, withIntermediateDirectories: true)
        } catch {
            logger.error("Ошибка создания папки img: \(error.localizedDescription)")
            return htmlContent
        }

        // Получаем список всех изображений из обработанного HTML
        let imageNames = extractImageNamesFromProcessedHTML(htmlContent)

        logger.debug("Начинаем копирование изображений из Assets. Найдено изображений: \(imageNames.count)")

        var copiedCount = 0
        var updatedHTML = htmlContent
        var imageExtensionsMap: [String: String] = [:]

        for imageName in imageNames {
            logger.debug("Пытаемся скопировать изображение: \(imageName)")

            // Пробуем разные расширения
            let extensions = ["jpg", "png", "jpeg", "gif"]
            var copied = false

            for ext in extensions {
                let destinationURL = imgDirectory.appendingPathComponent("\(imageName).\(ext)")

                if ImageAssetManager.copyImageToTemp(imageName: imageName, destinationURL: destinationURL) {
                    logger.debug("✅ Успешно скопировано изображение: \(imageName).\(ext)")
                    copiedCount += 1
                    copied = true
                    // Сохраняем информацию о том, какое расширение было использовано
                    imageExtensionsMap[imageName] = ext
                    break
                } else {
                    logger.debug("❌ Не удалось скопировать изображение: \(imageName).\(ext)")
                }
            }

            if !copied {
                logger.warning("⚠️ Не удалось найти изображение в Assets: \(imageName)")
            }
        }

        // Обновляем HTML с правильными расширениями файлов
        updatedHTML = updateImageExtensionsInHTML(updatedHTML, imageExtensionsMap: imageExtensionsMap)

        logger.debug("Скопировано \(copiedCount) из \(imageNames.count) изображений из Assets")
        return updatedHTML
    }

    /// Обновляет расширения файлов изображений в HTML контенте
    /// - Parameters:
    ///   - htmlContent: Исходный HTML контент
    ///   - imageExtensionsMap: Карта соответствия имен изображений и их расширений
    /// - Returns: HTML с обновленными расширениями файлов
    private func updateImageExtensionsInHTML(_ htmlContent: String, imageExtensionsMap: [String: String]) -> String {
        var updatedHTML = htmlContent

        logger.debug("🔄 Обновляем расширения файлов в HTML...")
        logger.debug("🔄 Карта расширений: \(imageExtensionsMap)")

        for (imageName, actualExtension) in imageExtensionsMap {
            logger.debug("🔄 Обрабатываем изображение: \(imageName) -> \(actualExtension)")

            // Ищем все возможные варианты путей к изображению
            let possibleExtensions = ["jpg", "png", "jpeg", "gif"]

            for oldExtension in possibleExtensions {
                if oldExtension != actualExtension {
                    // Используем регулярное выражение для более гибкого поиска
                    // Ищем src="img/filename.oldExtension" с любыми дополнительными атрибутами
                    let oldPattern = "src=\"img/\(imageName)\\.\(oldExtension)\""
                    let newPattern = "src=\"img/\(imageName)\\.\(actualExtension)\""

                    logger.debug("🔄 Ищем паттерн: \(oldPattern)")

                    if updatedHTML.contains(oldPattern) {
                        updatedHTML = updatedHTML.replacingOccurrences(of: oldPattern, with: newPattern)
                        logger.debug("🔄 ✅ Обновлен путь: \(imageName).\(oldExtension) -> \(imageName).\(actualExtension)")
                    } else {
                        logger.debug("🔄 ❌ Паттерн не найден: \(oldPattern)")

                        // Попробуем найти с помощью регулярного выражения
                        do {
                            let regexPattern = "src=\"img/\(imageName)\\.\(oldExtension)\""
                            let regex = try NSRegularExpression(pattern: regexPattern)
                            let matches = regex.matches(in: updatedHTML, range: NSRange(updatedHTML.startIndex..., in: updatedHTML))

                            if !matches.isEmpty {
                                logger.debug("🔄 Найдено \(matches.count) совпадений через regex")
                                updatedHTML = regex.stringByReplacingMatches(
                                    in: updatedHTML,
                                    options: [],
                                    range: NSRange(updatedHTML.startIndex..., in: updatedHTML),
                                    withTemplate: newPattern
                                )
                                logger
                                    .debug("🔄 ✅ Обновлен путь через regex: \(imageName).\(oldExtension) -> \(imageName).\(actualExtension)")
                            }
                        } catch {
                            logger.error("🔄 ❌ Ошибка regex: \(error.localizedDescription)")
                        }
                    }
                }
            }
        }

        logger.debug("✅ Обновление расширений файлов завершено")
        return updatedHTML
    }

    private func extractImageNamesFromProcessedHTML(_ htmlContent: String) -> Set<String> {
        // Добавляем отладочную информацию
        logger.debug("🔍 Анализируем HTML контент для поиска изображений...")

        // Ищем все возможные варианты путей к изображениям
        let patterns = [
            #"src="img/([^"]+)\.""#, // src="img/filename.jpg"
            #"src="\.\./img/([^"]+)\.""#, // src="../img/filename.jpg"
            #"src="\.\.\\img\\([^"]+)\.""#, // src="..\img\filename.jpg"
            #"src="img/([^"]*\.(jpg|png|jpeg|gif))""# // src="img/filename.jpg" - исправленный паттерн
        ]

        var imageNames = Set<String>()

        for (index, pattern) in patterns.enumerated() {
            do {
                let regex = try NSRegularExpression(pattern: pattern)
                let matches = regex.matches(in: htmlContent, range: NSRange(htmlContent.startIndex..., in: htmlContent))

                logger.debug("📋 Паттерн \(index + 1) (\(pattern)): найдено \(matches.count) совпадений")

                for match in matches {
                    if let range = Range(match.range(at: 1), in: htmlContent) {
                        let imageName = String(htmlContent[range])
                        let cleanName = imageName.replacingOccurrences(of: ".jpg", with: "")
                            .replacingOccurrences(of: ".png", with: "")
                            .replacingOccurrences(of: ".jpeg", with: "")
                            .replacingOccurrences(of: ".gif", with: "")
                        imageNames.insert(cleanName)
                        logger.debug("🖼️ Найдено изображение: \(imageName) -> \(cleanName)")
                    }
                }
            } catch {
                logger.error("❌ Ошибка в паттерне \(index + 1): \(error.localizedDescription)")
            }
        }

        // Если ничего не найдено, попробуем найти все img теги
        if imageNames.isEmpty {
            logger.debug("🔍 Изображения не найдены, ищем все img теги...")
            do {
                let imgPattern = #"<img[^>]+src="([^"]+)""#
                let regex = try NSRegularExpression(pattern: imgPattern)
                let matches = regex.matches(in: htmlContent, range: NSRange(htmlContent.startIndex..., in: htmlContent))

                logger.debug("📋 Найдено \(matches.count) img тегов")

                for match in matches {
                    if let range = Range(match.range(at: 1), in: htmlContent) {
                        let src = String(htmlContent[range])
                        logger.debug("🖼️ Найден img src: \(src)")

                        // Пытаемся извлечь имя изображения из src
                        if src.contains("img/") {
                            let components = src.components(separatedBy: "img/")
                            if components.count > 1 {
                                let filename = components[1]
                                let cleanName = filename.replacingOccurrences(of: ".jpg", with: "")
                                    .replacingOccurrences(of: ".png", with: "")
                                    .replacingOccurrences(of: ".jpeg", with: "")
                                    .replacingOccurrences(of: ".gif", with: "")
                                imageNames.insert(cleanName)
                                logger.debug("🖼️ Извлечено имя изображения: \(filename) -> \(cleanName)")
                            }
                        }
                    }
                }
            } catch {
                logger.error("❌ Ошибка поиска img тегов: \(error.localizedDescription)")
            }
        }

        logger.debug("✅ Итого найдено \(imageNames.count) уникальных изображений: \(Array(imageNames).sorted())")
        return imageNames
    }

    private func extractImageNamesFromHTML() -> Set<String> {
        // Загружаем HTML файл и извлекаем имена изображений
        guard let htmlFileURL = Bundle.main.url(forResource: filename, withExtension: "html") else {
            logger.warning("Не удалось найти HTML файл для извлечения имен изображений: \(filename).html")
            return []
        }

        do {
            let htmlContent = try String(contentsOf: htmlFileURL, encoding: .utf8)

            // Регулярное выражение для поиска src="..\img\filename.jpg" или src="../img/filename.jpg"
            let pattern = #"src="\.\.(?:\\|/)img(?:\\|/)([^"]+)\.""#
            let regex = try NSRegularExpression(pattern: pattern)
            let matches = regex.matches(in: htmlContent, range: NSRange(htmlContent.startIndex..., in: htmlContent))

            var imageNames = Set<String>()
            for match in matches {
                if let range = Range(match.range(at: 1), in: htmlContent) {
                    let imageName = String(htmlContent[range])
                    let cleanName = imageName.replacingOccurrences(of: ".jpg", with: "")
                        .replacingOccurrences(of: ".png", with: "")
                        .replacingOccurrences(of: ".jpeg", with: "")
                        .replacingOccurrences(of: ".gif", with: "")
                    imageNames.insert(cleanName)
                }
            }

            logger.debug("Найдено \(imageNames.count) уникальных изображений в HTML: \(Array(imageNames).sorted())")
            return imageNames
        } catch {
            logger.error("Ошибка извлечения имен изображений: \(error.localizedDescription)")
            return []
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    final class Coordinator: NSObject, WKNavigationDelegate {
        private let logger = Logger(subsystem: "SotkaApp", category: "HTMLContentView.Coordinator")

        func webView(_: WKWebView, didFinish _: WKNavigation!) {
            logger.debug("🌐 WKWebView загрузка завершена")
        }

        func webView(_: WKWebView, didFail _: WKNavigation!, withError error: Error) {
            logger.error("🌐 WKWebView ошибка загрузки: \(error.localizedDescription)")
        }

        func webView(_: WKWebView, didFailProvisionalNavigation _: WKNavigation!, withError error: Error) {
            logger.error("🌐 WKWebView ошибка предварительной загрузки: \(error.localizedDescription)")
        }
    }
}
