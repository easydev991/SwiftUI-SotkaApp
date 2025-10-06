/**
 * Перехватчик консоли для отправки логов в iOS приложение
 * Обеспечивает передачу console.log, console.warn, console.error в WKWebView
 */

// Перехватываем console.log и отправляем в iOS
(function() {
    const originalLog = console.log;
    const originalWarn = console.warn;
    const originalError = console.error;

    console.log = function(...args) {
        originalLog.apply(console, args);
        if (window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.consoleLog) {
            window.webkit.messageHandlers.consoleLog.postMessage({
                message: args.join(' ')
            });
        }
    };

    console.warn = function(...args) {
        originalWarn.apply(console, args);
        if (window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.consoleWarn) {
            window.webkit.messageHandlers.consoleWarn.postMessage({
                message: args.join(' ')
            });
        }
    };

    console.error = function(...args) {
        originalError.apply(console, args);
        if (window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.consoleError) {
            window.webkit.messageHandlers.consoleError.postMessage({
                message: args.join(' ')
            });
        }
    };
})();
