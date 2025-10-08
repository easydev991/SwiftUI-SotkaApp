// Отслеживание достижения места добавления YouTube видео
(function() {
    let hasReachedVideoSection = false;
    let messageSent = false;
    
    function checkScrollPosition() {
        // Если сообщение уже отправлено, прекращаем проверки
        if (messageSent) {
            return;
        }
        
        // Ищем элемент с классом video-container (YouTube видео)
        const videoContainer = document.querySelector('.video-container');
        
        if (!videoContainer) {
            // Если видео нет, проверяем footer (место где должно быть видео)
            const footer = document.querySelector('footer');
            if (!footer) {
                // Если нет ни видео, ни footer, считаем что достигли конца
                const scrollTop = window.pageYOffset || document.documentElement.scrollTop;
                const windowHeight = window.innerHeight;
                const documentHeight = document.documentElement.scrollHeight;
                
                // Проверяем, достигли ли конца документа (с небольшим отступом)
                const isAtEnd = scrollTop + windowHeight >= documentHeight - 50;
                
                if (isAtEnd && !hasReachedVideoSection) {
                    hasReachedVideoSection = true;
                    sendReachedEndMessage();
                }
            } else {
                // Проверяем, виден ли footer
                checkElementVisibility(footer);
            }
        } else {
            // Проверяем, видно ли видео
            checkElementVisibility(videoContainer);
        }
    }
    
    function checkElementVisibility(element) {
        // Если сообщение уже отправлено, прекращаем проверки
        if (messageSent) {
            return;
        }
        
        const rect = element.getBoundingClientRect();
        const windowHeight = window.innerHeight;
        
        // Элемент считается видимым, если его верхняя часть видна на экране
        const isVisible = rect.top <= windowHeight && rect.bottom >= 0;
        
        if (isVisible && !hasReachedVideoSection) {
            hasReachedVideoSection = true;
            sendReachedEndMessage();
        }
    }
    
    function sendReachedEndMessage() {
        // Проверяем, что сообщение еще не отправлено
        if (messageSent) {
            return;
        }
        
        // Отправляем сообщение в iOS приложение
        if (window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.scrollReachedEnd) {
            window.webkit.messageHandlers.scrollReachedEnd.postMessage({
                message: "reached_video_section"
            });
            
            // Помечаем, что сообщение отправлено
            messageSent = true;
        }
    }
    
    // Отслеживаем скролл с debouncing
    let scrollTimeout;
    window.addEventListener('scroll', function() {
        clearTimeout(scrollTimeout);
        scrollTimeout = setTimeout(checkScrollPosition, 100);
    });
    
    // Проверяем сразу при загрузке
    document.addEventListener('DOMContentLoaded', checkScrollPosition);
    
    // Проверяем при изменении размера окна
    window.addEventListener('resize', checkScrollPosition);
})();
