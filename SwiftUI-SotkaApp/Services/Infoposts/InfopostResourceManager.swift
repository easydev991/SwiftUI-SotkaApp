import Foundation
import OSLog

/// Сервис для управления ресурсами инфопостов (CSS, JS, изображения)
struct InfopostResourceManager {
    private let logger = Logger(subsystem: "SotkaApp", category: "InfopostResourceManager")

    /// Создает временную директорию для инфопоста
    /// - Returns: URL временной директории или nil в случае ошибки
    func createTempDirectory() -> URL? {
        let fileManager = FileManager.default
        let tempDirectory = fileManager.temporaryDirectory.appendingPathComponent("infopost_preview")

        // Удаляем существующую директорию если есть
        if fileManager.fileExists(atPath: tempDirectory.path) {
            try? fileManager.removeItem(at: tempDirectory)
        }

        do {
            try fileManager.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
            logger.debug("✅ Создана временная директория: \(tempDirectory.path)")
            return tempDirectory
        } catch {
            logger.error("❌ Ошибка создания временной директории: \(error.localizedDescription)")
            return nil
        }
    }

    /// Копирует все необходимые ресурсы в временную директорию
    /// - Parameters:
    ///   - tempDirectory: Временная директория
    ///   - htmlContent: HTML контент для обработки
    /// - Returns: Обновленный HTML контент с правильными путями к ресурсам
    func copyResources(to tempDirectory: URL, htmlContent: String) -> String {
        let fileManager = FileManager.default

        // Копируем CSS файлы
        copyDirectory(from: "css", to: tempDirectory.appendingPathComponent("css"), fileManager: fileManager)

        // Копируем JS файлы
        copyDirectory(from: "js", to: tempDirectory.appendingPathComponent("js"), fileManager: fileManager)

        // Копируем изображения и получаем обновленный HTML
        let updatedHTML = copyImagesFromAssets(to: tempDirectory.appendingPathComponent("img"), from: htmlContent)

        return updatedHTML
    }

    /// Копирует директорию ресурсов из бандла
    private func copyDirectory(from sourceName: String, to destination: URL, fileManager: FileManager) {
        do {
            let bundleURL = Bundle.main.bundleURL
            let resourceURLs = try fileManager.contentsOfDirectory(at: bundleURL, includingPropertiesForKeys: nil)

            // Фильтруем файлы по расширению
            let matchingFiles = resourceURLs.filter { url in
                if sourceName == "img" {
                    ["jpg", "jpeg", "png", "gif"].contains(url.pathExtension.lowercased())
                } else {
                    url.pathExtension == sourceName
                }
            }

            if !matchingFiles.isEmpty {
                try fileManager.createDirectory(at: destination, withIntermediateDirectories: true)

                for sourceURL in matchingFiles {
                    let filename = sourceURL.lastPathComponent
                    let destinationURL = destination.appendingPathComponent(filename)

                    if fileManager.fileExists(atPath: destinationURL.path) {
                        try fileManager.removeItem(at: destinationURL)
                    }

                    try fileManager.copyItem(at: sourceURL, to: destinationURL)
                }

                logger.debug("✅ Скопировано \(matchingFiles.count) файлов \(sourceName)")
            } else {
                logger.warning("⚠️ Не найдены файлы ресурсов \(sourceName) в бандле")
            }
        } catch {
            logger.error("❌ Ошибка копирования ресурсов \(sourceName): \(error.localizedDescription)")
        }
    }

    /// Копирует изображения из Assets и обновляет HTML
    private func copyImagesFromAssets(to imgDirectory: URL, from htmlContent: String) -> String {
        let fileManager = FileManager.default

        do {
            try fileManager.createDirectory(at: imgDirectory, withIntermediateDirectories: true)
        } catch {
            logger.error("❌ Ошибка создания папки img: \(error.localizedDescription)")
            return htmlContent
        }

        let imageNames = extractImageNamesFromProcessedHTML(htmlContent)
        logger.debug("🖼️ Найдено изображений для копирования: \(imageNames.count)")

        var copiedCount = 0
        var updatedHTML = htmlContent
        var imageExtensionsMap: [String: String] = [:]

        for imageName in imageNames {
            let extensions = ["png", "jpg", "jpeg", "gif"]
            var copied = false

            for ext in extensions {
                let destinationURL = imgDirectory.appendingPathComponent("\(imageName).\(ext)")

                if ImageAssetManager.copyImageToTemp(imageName: imageName, destinationURL: destinationURL) {
                    copiedCount += 1
                    copied = true
                    imageExtensionsMap[imageName] = ext
                    break
                }
            }

            if !copied {
                logger.warning("⚠️ Не удалось найти изображение в Assets: \(imageName)")
            }
        }

        // Обновляем HTML с правильными расширениями файлов
        updatedHTML = updateImageExtensionsInHTML(updatedHTML, imageExtensionsMap: imageExtensionsMap)

        logger.debug("✅ Скопировано \(copiedCount) из \(imageNames.count) изображений")
        return updatedHTML
    }

    /// Извлекает имена изображений из HTML контента
    private func extractImageNamesFromProcessedHTML(_ htmlContent: String) -> Set<String> {
        let patterns = [
            #"src="img/([^"]+)\.""#,
            #"src="\.\./img/([^"]+)\.""#,
            #"src="\.\.\\img\\([^"]+)\.""#,
            #"src="img/([^"]*\.(jpg|png|jpeg|gif))""#
        ]

        var imageNames = Set<String>()

        for pattern in patterns {
            do {
                let regex = try NSRegularExpression(pattern: pattern)
                let matches = regex.matches(in: htmlContent, range: NSRange(htmlContent.startIndex..., in: htmlContent))

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
            } catch {
                logger.error("❌ Ошибка в паттерне: \(error.localizedDescription)")
            }
        }

        // Если ничего не найдено, ищем все img теги
        if imageNames.isEmpty {
            do {
                let imgPattern = #"<img[^>]+src="([^"]+)""#
                let regex = try NSRegularExpression(pattern: imgPattern)
                let matches = regex.matches(in: htmlContent, range: NSRange(htmlContent.startIndex..., in: htmlContent))

                for match in matches {
                    if let range = Range(match.range(at: 1), in: htmlContent) {
                        let src = String(htmlContent[range])

                        if src.contains("img/") {
                            let components = src.components(separatedBy: "img/")
                            if components.count > 1 {
                                let filename = components[1]
                                let cleanName = filename.replacingOccurrences(of: ".jpg", with: "")
                                    .replacingOccurrences(of: ".png", with: "")
                                    .replacingOccurrences(of: ".jpeg", with: "")
                                    .replacingOccurrences(of: ".gif", with: "")
                                imageNames.insert(cleanName)
                            }
                        }
                    }
                }
            } catch {
                logger.error("❌ Ошибка поиска img тегов: \(error.localizedDescription)")
            }
        }

        return imageNames
    }

    /// Обновляет расширения файлов изображений в HTML контенте
    private func updateImageExtensionsInHTML(_ htmlContent: String, imageExtensionsMap: [String: String]) -> String {
        var updatedHTML = htmlContent

        for (imageName, actualExtension) in imageExtensionsMap {
            let possibleExtensions = ["jpg", "png", "jpeg", "gif"]

            for oldExtension in possibleExtensions {
                if oldExtension != actualExtension {
                    let oldPattern = "src=\"img/\(imageName)\\.\(oldExtension)\""
                    let newPattern = "src=\"img/\(imageName)\\.\(actualExtension)\""

                    if updatedHTML.contains(oldPattern) {
                        updatedHTML = updatedHTML.replacingOccurrences(of: oldPattern, with: newPattern)
                    } else {
                        // Попробуем найти с помощью регулярного выражения
                        do {
                            let regexPattern = "src=\"img/\(imageName)\\.\(oldExtension)\""
                            let regex = try NSRegularExpression(pattern: regexPattern)
                            let matches = regex.matches(in: updatedHTML, range: NSRange(updatedHTML.startIndex..., in: updatedHTML))

                            if !matches.isEmpty {
                                updatedHTML = regex.stringByReplacingMatches(
                                    in: updatedHTML,
                                    options: [],
                                    range: NSRange(updatedHTML.startIndex..., in: updatedHTML),
                                    withTemplate: newPattern
                                )
                            }
                        } catch {
                            logger.error("❌ Ошибка regex: \(error.localizedDescription)")
                        }
                    }
                }
            }
        }

        return updatedHTML
    }
}
