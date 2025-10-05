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

            // Создаем временный HTML файл
            let tempHTMLFile = tempDirectory.appendingPathComponent("preview.html")
            try modifiedHTML.write(to: tempHTMLFile, atomically: true, encoding: .utf8)

            // Копируем ресурсы (CSS, JS, изображения)
            copyResources(to: tempDirectory)

            // Загружаем файл с доступом ко всей временной директории
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

    private func copyResources(to tempDirectory: URL) {
        let fileManager = FileManager.default

        // Копируем CSS файлы из Assets
        copyDirectory(from: "css", to: tempDirectory.appendingPathComponent("css"), fileManager: fileManager)

        // Копируем JS файлы из Assets
        copyDirectory(from: "js", to: tempDirectory.appendingPathComponent("js"), fileManager: fileManager)

        // Копируем изображения из Assets
        copyDirectory(from: "img", to: tempDirectory.appendingPathComponent("img"), fileManager: fileManager)
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

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    final class Coordinator: NSObject, WKNavigationDelegate {
        // Обработка навигации при необходимости
    }
}
