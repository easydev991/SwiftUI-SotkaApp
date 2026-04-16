import OSLog
import SwiftUI
import WebKit

/// Компонент для отображения HTML контента с использованием WKWebView
struct HTMLContentView: UIViewRepresentable, @preconcurrency Equatable {
    static func == (lhs: HTMLContentView, rhs: HTMLContentView) -> Bool {
        lhs.infopost == rhs.infopost && lhs.fontSize == rhs.fontSize
    }

    @Environment(YouTubeVideoService.self) private var youtubeService
    private let logger = Logger(
        subsystem: "SotkaApp",
        category: String(describing: HTMLContentView.self)
    )
    private let resourceManager = InfopostResourceManager()
    private let htmlProcessor = InfopostHTMLProcessor()
    private let fontSize: FontSize
    private let infopost: Infopost
    @Binding private var showError: Bool
    @Binding private var currentError: InfopostError?
    private let onReachedEnd: () -> Void
    private var filename: String {
        infopost.filenameWithLanguage
    }

    init(
        infopost: Infopost,
        fontSize: FontSize,
        showError: Binding<Bool>,
        currentError: Binding<InfopostError?>,
        onReachedEnd: @escaping () -> Void
    ) {
        self.infopost = infopost
        self.fontSize = fontSize
        self._showError = showError
        self._currentError = currentError
        self.onReachedEnd = onReachedEnd
    }

    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.defaultWebpagePreferences.allowsContentJavaScript = true

        // Добавляем обработчик для логов из JavaScript
        configuration.userContentController.add(context.coordinator, name: "consoleLog")
        configuration.userContentController.add(context.coordinator, name: "consoleError")
        configuration.userContentController.add(context.coordinator, name: "consoleWarn")
        // Добавляем обработчик для отслеживания достижения конца контента
        configuration.userContentController.add(context.coordinator, name: "scrollReachedEnd")

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

    func makeCoordinator() -> Coordinator {
        Coordinator(onReachedEnd: onReachedEnd)
    }

    final class Coordinator: NSObject, WKNavigationDelegate, WKScriptMessageHandler {
        private let logger = Logger(
            subsystem: "SotkaApp",
            category: String(describing: Coordinator.self)
        )
        private let onReachedEnd: () -> Void

        init(onReachedEnd: @escaping () -> Void) {
            self.onReachedEnd = onReachedEnd
        }

        func webView(_: WKWebView, didFinish _: WKNavigation!) {
            logger.debug("🌐 WKWebView загрузка завершена")
        }

        func webView(_: WKWebView, didFail _: WKNavigation!, withError error: Error) {
            logger.error("🌐 WKWebView ошибка загрузки: \(error.localizedDescription)")
        }

        func webView(_: WKWebView, didFailProvisionalNavigation _: WKNavigation!, withError error: Error) {
            logger.error("🌐 WKWebView ошибка предварительной загрузки: \(error.localizedDescription)")
        }

        func webView(
            _: WKWebView,
            decidePolicyFor navigationAction: WKNavigationAction
        ) async -> WKNavigationActionPolicy {
            logger.debug("🌐 Решение о навигации: \(navigationAction.request.url?.absoluteString ?? "nil")")

            // Разрешаем все навигационные действия для локальных файлов
            if let url = navigationAction.request.url {
                if url.isFileURL {
                    logger.debug("🌐 Разрешаем навигацию к локальному файлу: \(url.path)")
                    return .allow
                }

                // Для внешних ссылок можем добавить дополнительную логику
                logger.debug("🌐 Внешняя ссылка: \(url.absoluteString)")
            }

            // По умолчанию разрешаем навигацию
            return .allow
        }

        func webView(
            _: WKWebView,
            decidePolicyFor navigationResponse: WKNavigationResponse
        ) async -> WKNavigationResponsePolicy {
            logger.debug("🌐 Решение о навигационном ответе: \(navigationResponse.response.url?.absoluteString ?? "nil")")
            // Разрешаем все навигационные ответы
            return .allow
        }

        func userContentController(_: WKUserContentController, didReceive message: WKScriptMessage) {
            switch message.name {
            case "consoleLog", "consoleWarn", "consoleError":
                guard let messageBody = message.body as? [String: Any],
                      let logMessage = messageBody["message"] as? String else {
                    return
                }

                switch message.name {
                case "consoleLog":
                    logger.info("🟢 JS: \(logMessage)")
                case "consoleWarn":
                    logger.warning("🟡 JS: \(logMessage)")
                case "consoleError":
                    logger.error("🔴 JS: \(logMessage)")
                default:
                    logger.debug("🔵 JS: \(logMessage)")
                }

            case "scrollReachedEnd":
                logger.info("📜 JavaScript сообщает: достигнут конец контента")
                onReachedEnd()

            default:
                logger.debug("🔵 JS: неизвестное сообщение от \(message.name)")
            }
        }
    }
}

extension HTMLContentView {
    /// Ошибки при загрузке инфопостов
    enum InfopostError: Error, LocalizedError {
        case fileNotFound(filename: String)
        case htmlProcessingFailed(filename: String)
        case resourceCopyFailed
        case unknownError

        var errorDescription: String? {
            switch self {
            case let .fileNotFound(filename):
                "Файл не найден: \(filename)"
            case let .htmlProcessingFailed(filename):
                "Ошибка обработки HTML: \(filename)"
            case .resourceCopyFailed:
                "Ошибка копирования ресурсов"
            case .unknownError:
                "Неизвестная ошибка"
            }
        }
    }
}

private extension HTMLContentView {
    func loadContent(in webView: WKWebView) {
        logger.info("🌐 Начинаем загрузку контента: \(filename)")

        // Создаем временную директорию для ресурсов
        guard let tempDirectory = resourceManager.createTempDirectory() else {
            let error = InfopostError.resourceCopyFailed
            showError(error)
            return
        }

        // Загружаем и обрабатываем HTML контент
        guard let processedHTML = htmlProcessor.loadAndProcessHTML(
            filename: filename,
            fontSize: fontSize,
            infopost: infopost,
            youtubeService: youtubeService
        ) else {
            let error = InfopostError.htmlProcessingFailed(filename: filename)
            showError(error)
            return
        }

        // Копируем ресурсы и получаем финальный HTML
        let finalHTML = resourceManager.copyResources(to: tempDirectory, htmlContent: processedHTML)

        // Создаем временный HTML файл
        let tempHTMLFile = tempDirectory.appendingPathComponent("preview.html")

        do {
            try finalHTML.write(to: tempHTMLFile, atomically: true, encoding: .utf8)

            // Загружаем файл в WebView
            DispatchQueue.main.async {
                webView.loadFileURL(tempHTMLFile, allowingReadAccessTo: tempDirectory)
            }

            logger.debug("✅ Инфопост загружен: \(filename).html")
        } catch {
            logger.error("❌ Ошибка записи HTML файла: \(error.localizedDescription)")
            let infopostError = InfopostError.unknownError
            showError(infopostError)
        }
    }

    func showError(_ error: HTMLContentView.InfopostError) {
        logger.error("❌ Ошибка загрузки инфопоста: \(error.localizedDescription)")

        // Устанавливаем состояние для показа ошибки
        DispatchQueue.main.async {
            currentError = error
            showError = true
        }
    }
}
