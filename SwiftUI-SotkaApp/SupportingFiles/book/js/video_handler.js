/**
 * Универсальный обработчик видео для инфопостов
 * Обеспечивает таймаут загрузки и кнопку перезагрузки для всех видео
 */

console.log('🎬 Универсальный обработчик видео загружен');
console.log('🔍 Отладочная информация при загрузке:');
console.log('- jQuery доступен:', typeof $ !== 'undefined');
console.log('- DOM готов:', document.readyState);
console.log('- Все iframe на странице:', document.querySelectorAll('iframe').length);
console.log('- Все video на странице:', document.querySelectorAll('video').length);
console.log('- WebKit messageHandlers доступны:', !!(window.webkit && window.webkit.messageHandlers));
console.log('- consoleLog handler доступен:', !!(window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.consoleLog));

// Общие константы текста
var VIDEO_LOAD_ERROR_TEXT = 'Видео не загрузилось';
// Таймаут ожидания загрузки видео (мс)
var FIVE_SECONDS_MS = 5000;

// Проверяем, что jQuery загружен
if (typeof $ === 'undefined') {
    console.error('jQuery не загружен! Универсальный обработчик видео не может работать.');
    
    // Альтернативная инициализация без jQuery
    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', function() {
            console.log('DOM готов (без jQuery), инициализируем обработку видео');
            initializeVideoHandlersNative();
        });
    } else {
        console.log('DOM уже готов (без jQuery), инициализируем обработку видео');
        initializeVideoHandlersNative();
    }
} else {
    console.log('jQuery загружен, инициализируем обработчик видео');
    
    $(document).ready(function() {
        console.log('DOM готов, инициализируем обработку видео');
        // Инициализируем обработку всех видео на странице
        initializeVideoHandlers();
    });
}

/**
 * Инициализирует обработчики для всех видео на странице
 */
function initializeVideoHandlers() {
    console.log('🎥 Начинаем инициализацию обработчиков видео');
    
    // Обрабатываем все iframe с видео (YouTube, Vimeo и другие)
    var iframes = $('iframe[src*="youtube"], iframe[src*="youtu.be"], iframe[src*="vimeo"], iframe[src*="player"]');
    console.log('🔍 Найдено iframe видео:', iframes.length);
    
    iframes.each(function(index) {
        try {
            var iframe = $(this);
            var originalSrc = iframe.attr('src');
            var videoId = generateVideoId(iframe);
            
            console.log('📺 Обрабатываем iframe', index + 1, ':', originalSrc, 'ID:', videoId);
            console.log('🔍 Проверка jQuery объекта:', {
                isJQuery: typeof iframe.is === 'function',
                hasOnMethod: typeof iframe.on === 'function',
                length: iframe.length,
                elementType: typeof iframe,
                constructor: iframe.constructor ? iframe.constructor.name : 'unknown'
            });
            
            // Сохраняем оригинальный src для возможности восстановления
            if (originalSrc) {
                saveOriginalVideoSrc(videoId, originalSrc);
            }
            
            // Добавляем уникальный ID если его нет
            if (!iframe.attr('id')) {
                iframe.attr('id', 'video-' + videoId);
                console.log('🆔 Добавлен ID для iframe:', 'video-' + videoId);
            }
            
            // Инициализируем обработчик для этого видео
            console.log('🎬 Начинаем инициализацию обработчика для iframe', index + 1);
            
            // Проверяем, является ли iframe уже jQuery объектом
            var freshIframe = iframe;
            console.log('🔍 Проверяем исходный iframe объект:', {
                isJQuery: typeof iframe.is === 'function',
                hasOnMethod: typeof iframe.on === 'function',
                length: iframe.length,
                jquery: iframe.jquery,
                constructor: iframe.constructor ? iframe.constructor.name : 'unknown'
            });
            
            // Если iframe уже jQuery объект, используем его
            if (typeof iframe.on === 'function') {
                console.log('✅ iframe уже является jQuery объектом');
                freshIframe = iframe;
            } else {
                console.log('⚠️ iframe не является jQuery объектом, создаем новый...');
                // Пробуем разные способы создания jQuery объекта
                if (iframe[0]) {
                    freshIframe = $(iframe[0]);
                } else {
                    freshIframe = $(iframe);
                }
                
                console.log('🔄 Создан новый jQuery объект:', {
                    isJQuery: typeof freshIframe.is === 'function',
                    hasOnMethod: typeof freshIframe.on === 'function',
                    length: freshIframe.length,
                    jquery: freshIframe.jquery,
                    constructor: freshIframe.constructor ? freshIframe.constructor.name : 'unknown'
                });
                
                // Если все еще не работает, попробуем найти по ID
                if (typeof freshIframe.on !== 'function') {
                    console.log('⚠️ freshIframe все еще не jQuery объект, ищем по ID...');
                    var iframeId = iframe.attr ? iframe.attr('id') : iframe.id;
                    if (iframeId) {
                        freshIframe = $('#' + iframeId);
                        console.log('🔄 Найден по ID:', {
                            isJQuery: typeof freshIframe.is === 'function',
                            hasOnMethod: typeof freshIframe.on === 'function',
                            length: freshIframe.length,
                            jquery: freshIframe.jquery
                        });
                    }
                }
            }
            
            initializeVideoHandler(freshIframe, originalSrc, videoId);
            console.log('✅ Завершена инициализация обработчика для iframe', index + 1);
        } catch (error) {
            console.error('❌ Ошибка при обработке iframe', index + 1, ':', error);
        }
    });
    
    // Обрабатываем video теги
    var videos = $('video');
    console.log('🔍 Найдено HTML5 видео:', videos.length);
    
    videos.each(function(index) {
        var video = $(this);
        var videoId = generateVideoId(video);
        
        console.log('📺 Обрабатываем HTML5 видео', index + 1, 'ID:', videoId);
        
        // Добавляем уникальный ID если его нет
        if (!video.attr('id')) {
            video.attr('id', 'video-' + videoId);
            console.log('🆔 Добавлен ID для video:', 'video-' + videoId);
        }
        
        // Инициализируем обработчик для этого видео
        initializeVideoHandler(video, null, videoId);
    });
    
    console.log('✅ Инициализация обработчиков видео завершена');
    console.log('📊 Итого обработано iframe:', iframes.length, 'HTML5 видео:', videos.length);
}

/**
 * Инициализирует обработчики для всех видео на странице (без jQuery)
 */
function initializeVideoHandlersNative() {
    console.log('🎥 Начинаем инициализацию обработчиков видео (без jQuery)');
    
    // Обрабатываем все iframe с видео (YouTube, Vimeo и другие)
    var iframes = document.querySelectorAll('iframe[src*="youtube"], iframe[src*="youtu.be"], iframe[src*="vimeo"], iframe[src*="player"]');
    console.log('🔍 Найдено iframe видео (без jQuery):', iframes.length);
    
    for (var i = 0; i < iframes.length; i++) {
        var iframe = iframes[i];
        var originalSrc = iframe.getAttribute('src');
        var videoId = generateVideoIdNative(iframe);
        
        console.log('📺 Обрабатываем iframe', i + 1, ':', originalSrc, 'ID:', videoId);
        
        // Сохраняем оригинальный src для возможности восстановления
        if (originalSrc) {
            saveOriginalVideoSrc(videoId, originalSrc);
        }
        
        // Добавляем уникальный ID если его нет
        if (!iframe.getAttribute('id')) {
            iframe.setAttribute('id', 'video-' + videoId);
            console.log('🆔 Добавлен ID для iframe:', 'video-' + videoId);
        }
        
        // Инициализируем обработчик для этого видео
        initializeVideoHandlerNative(iframe, originalSrc, videoId);
    }
    
    // Обрабатываем video теги
    var videos = document.querySelectorAll('video');
    console.log('🔍 Найдено HTML5 видео (без jQuery):', videos.length);
    
    for (var i = 0; i < videos.length; i++) {
        var video = videos[i];
        var videoId = generateVideoIdNative(video);
        
        console.log('📺 Обрабатываем HTML5 видео', i + 1, 'ID:', videoId);
        
        // Добавляем уникальный ID если его нет
        if (!video.getAttribute('id')) {
            video.setAttribute('id', 'video-' + videoId);
            console.log('🆔 Добавлен ID для video:', 'video-' + videoId);
        }
        
        // Инициализируем обработчик для этого видео
        initializeVideoHandlerNative(video, null, videoId);
    }
    
    console.log('✅ Инициализация обработчиков видео завершена (без jQuery)');
}

/**
 * Генерирует уникальный ID для видео
 */
function generateVideoId(element) {
    var src = element.attr('src') || '';
    var index = element.index();
    
    // Исправляем проблему с index = -1 для первого элемента
    if (index === -1) {
        index = 0;
    }
    
    var parent = element.closest('div, section, article').attr('class') || 'container';
    
    // Очищаем parent от недопустимых символов сразу
    parent = parent.replace(/[^a-zA-Z0-9_-]/g, '_');
    
    // Убираем множественные подчеркивания в parent
    parent = parent.replace(/_+/g, '_');
    
    // Убираем подчеркивания в начале и конце parent
    parent = parent.replace(/^_+|_+$/g, '');
    
    // Если parent пустой после очистки, используем fallback
    if (!parent) {
        parent = 'container';
    }
    
    // Создаем ID на основе src, индекса и родительского контейнера
    var id = 'video_' + index + '_' + parent;
    
    // Если есть src, добавляем хеш от него
    if (src) {
        var hash = 0;
        for (var i = 0; i < src.length; i++) {
            var char = src.charCodeAt(i);
            hash = ((hash << 5) - hash) + char;
            hash = hash & hash; // Convert to 32bit integer
        }
        id += '_' + Math.abs(hash).toString(36);
    }
    
    // Финальная очистка ID от недопустимых символов
    id = id.replace(/[^a-zA-Z0-9_-]/g, '_');
    
    // Убираем множественные подчеркивания
    id = id.replace(/_+/g, '_');
    
    // Убираем подчеркивания в начале и конце
    id = id.replace(/^_+|_+$/g, '');
    
    console.log('🆔 Сгенерирован ID для видео:', id, 'из parent:', element.closest('div, section, article').attr('class'), 'index:', index);
    
    return id;
}

/**
 * Генерирует уникальный ID для видео (без jQuery)
 */
function generateVideoIdNative(element) {
    var src = element.getAttribute('src') || '';
    var index = Array.prototype.indexOf.call(element.parentNode.children, element);
    
    // Исправляем проблему с index = -1 для первого элемента
    if (index === -1) {
        index = 0;
    }
    
    var parent = element.parentNode.className || 'container';
    
    // Очищаем parent от недопустимых символов сразу
    parent = parent.replace(/[^a-zA-Z0-9_-]/g, '_');
    
    // Убираем множественные подчеркивания в parent
    parent = parent.replace(/_+/g, '_');
    
    // Убираем подчеркивания в начале и конце parent
    parent = parent.replace(/^_+|_+$/g, '');
    
    // Если parent пустой после очистки, используем fallback
    if (!parent) {
        parent = 'container';
    }
    
    // Создаем ID на основе src, индекса и родительского контейнера
    var id = 'video_' + index + '_' + parent;
    
    // Если есть src, добавляем хеш от него
    if (src) {
        var hash = 0;
        for (var i = 0; i < src.length; i++) {
            var char = src.charCodeAt(i);
            hash = ((hash << 5) - hash) + char;
            hash = hash & hash; // Convert to 32bit integer
        }
        id += '_' + Math.abs(hash).toString(36);
    }
    
    // Финальная очистка ID от недопустимых символов
    id = id.replace(/[^a-zA-Z0-9_-]/g, '_');
    
    // Убираем множественные подчеркивания
    id = id.replace(/_+/g, '_');
    
    // Убираем подчеркивания в начале и конце
    id = id.replace(/^_+|_+$/g, '');
    
    console.log('🆔 Сгенерирован ID для видео (без jQuery):', id, 'из parent:', element.parentNode.className, 'index:', index);
    
    return id;
}

/**
 * Инициализирует обработчик для конкретного видео (без jQuery)
 */
function initializeVideoHandlerNative(element, originalSrc, videoId) {
    console.log('🎬 Инициализируем обработчик для видео (без jQuery):', videoId, 'src:', originalSrc);
    
    var isIframe = element.tagName.toLowerCase() === 'iframe';
    var errorTimeout = null;
    var videoLoaded = false;
    var container = element.parentNode;
    
    console.log('📋 Параметры видео (без jQuery):', {
        videoId: videoId,
        isIframe: isIframe,
        originalSrc: originalSrc,
        container: container ? 'найден' : 'не найден'
    });
    
    // Проверяем доступность интернета
    if (!navigator.onLine) {
        console.log('❌ Нет подключения к интернету для видео:', videoId);
        showVideoErrorNative(videoId, 'Нет подключения к интернету', originalSrc, container);
        return;
    }
    
    console.log('✅ Подключение к интернету есть, настраиваем обработчики для видео:', videoId);
    
    // Отслеживаем успешную загрузку видео
    element.addEventListener('load', function() {
        videoLoaded = true;
        if (errorTimeout) {
            clearTimeout(errorTimeout);
            errorTimeout = null;
        }
        console.log('✅ Видео загружено успешно (без jQuery):', videoId);
        
        // Скрываем контейнер с ошибкой, если он есть
        var errorContainer = document.getElementById('error-' + videoId);
        if (errorContainer) {
            errorContainer.style.display = 'none';
            console.log('✅ Контейнер с ошибкой скрыт для загруженного видео (без jQuery):', videoId);
        }
    });
    
        // Для iframe видео не делаем автоматических проверок загруженности
        // Полагаемся только на событие 'load' и таймаут ошибки
        if (isIframe && originalSrc) {
            console.log('🎬 Настроен мониторинг для iframe (без jQuery):', videoId);
        }
    
    // Для video тегов также отслеживаем событие canplay
    if (!isIframe) {
        element.addEventListener('canplay', function() {
            videoLoaded = true;
            if (errorTimeout) {
                clearTimeout(errorTimeout);
                errorTimeout = null;
            }
            console.log('✅ Видео готово к воспроизведению (без jQuery):', videoId);
        });
    }
    
    // Если видео не загрузилось за 5 секунд, показываем ошибку
    errorTimeout = setTimeout(function() {
        if (!videoLoaded) {
            console.log('⏰ Таймаут загрузки для видео (без jQuery):', videoId);
            console.log('📋 Состояние видео при таймауте:', {
                videoId: videoId,
                videoLoaded: videoLoaded,
                isIframe: isIframe,
                originalSrc: originalSrc,
                elementExists: !!element,
                elementSrc: element ? element.getAttribute('src') : 'N/A',
                elementId: element ? element.getAttribute('id') : 'N/A'
            });
            showVideoErrorNative(videoId, VIDEO_LOAD_ERROR_TEXT, originalSrc, container);
        } else {
            console.log('✅ Видео уже загружено, таймаут отменен (без jQuery):', videoId);
        }
    }, FIVE_SECONDS_MS);
    
    console.log('⏱️ Установлен таймаут 5 секунд для видео (без jQuery):', videoId);
    
    // Дополнительная отладка - проверяем состояние через 5 секунд
    setTimeout(function() {
        console.log('🔍 Промежуточная проверка через 5 секунд (без jQuery):', videoId, 'загружено:', videoLoaded);
    }, FIVE_SECONDS_MS);
}

/**
 * Показывает ошибку загрузки видео с кнопкой перезагрузки (без jQuery)
 */
function showVideoErrorNative(videoId, errorMessage, originalSrc, container) {
    console.log('❌ Показываем ошибку для видео (без jQuery):', videoId, 'сообщение:', errorMessage);
    
    console.log('🔍 Отладка контейнера:', {
        container: container,
        containerType: typeof container,
        hasQuerySelector: typeof container.querySelector === 'function',
        hasInnerHTML: typeof container.innerHTML !== 'undefined',
        tagName: container.tagName,
        className: container.className,
        id: container.id
    });
    
    if (!container) {
        console.error('❌ Контейнер для видео не найден (без jQuery):', videoId);
        return;
    }
    
    if (typeof container.querySelector !== 'function') {
        console.error('❌ Контейнер не является DOM элементом (без jQuery):', videoId, container);
        return;
    }
    
    // Находим iframe или video элемент внутри контейнера
    var videoElement = container.querySelector('iframe, video');
    if (!videoElement) {
        console.error('❌ Не найден iframe или video элемент в контейнере (без jQuery):', videoId);
        return;
    }
    
    var isIframe = videoElement.tagName.toLowerCase() === 'iframe';
    
    console.log('📋 Параметры ошибки (без jQuery):', {
        videoId: videoId,
        errorMessage: errorMessage,
        originalSrc: originalSrc,
        isIframe: isIframe,
        containerFound: !!container,
        videoElementFound: !!videoElement
    });
    
    // Создаем HTML для ошибки с поддержкой темной темы
    var errorHtml = '<div id="error-' + videoId + '" class="video-error-container" style="text-align:center; padding:40px; background-color:#f8f9fa; border:1px solid #dee2e6; border-radius:8px; margin:10px 0; color-scheme: light dark;">' +
        '<div style="font-size:18px; color:#dc3545; margin-bottom:10px;">' + errorMessage + '</div>' +
        '<div style="font-size:14px; color:#6c757d; margin-bottom:15px;">Проверьте подключение к интернету</div>' +
        '<button onclick="reloadAllVideos()" ' +
        'style="background-color:#007AFF; color:white; border:none; padding:10px 20px; border-radius:6px; font-size:16px; cursor:pointer; transition:background-color 0.2s;" ' +
        'onmouseover="this.style.backgroundColor=\'#0056CC\'" ' +
        'onmouseout="this.style.backgroundColor=\'#007AFF\'">' +
        'Обновить</button>' +
        '</div>';
    
    // Заменяем только iframe/video элемент, а не весь контейнер
    videoElement.outerHTML = errorHtml;
    console.log('✅ Ошибка отображена для видео (без jQuery):', videoId);
}

/**
 * Перезагружает видео после ошибки (без jQuery)
 */
function retryVideoLoadNative(videoId, originalSrc, isIframe) {
    console.log('🔄 Перезагружаем видео (без jQuery):', videoId, 'src:', originalSrc, 'isIframe:', isIframe);
    
    // Находим контейнер с ошибкой
    var errorContainer = document.querySelector('.video-error-container');
    console.log('🔍 Поиск контейнера с ошибкой:', {
        errorContainer: errorContainer,
        hasParent: errorContainer ? !!errorContainer.parentNode : false,
        parentNode: errorContainer ? errorContainer.parentNode : null
    });
    
    if (errorContainer && errorContainer.parentNode) {
        var container = errorContainer.parentNode;
        console.log('✅ Найден контейнер с ошибкой для видео (без jQuery):', videoId);
        console.log('🔍 Детали контейнера:', {
            container: container,
            tagName: container.tagName,
            className: container.className,
            innerHTML: container.innerHTML.substring(0, 200) + '...'
        });
        
        // Восстанавливаем оригинальный элемент
        var elementHtml;
        if (isIframe && originalSrc) {
            // Создаем iframe с правильным контейнером
            elementHtml = '<div class="video-container" style="text-align: center;"><iframe id="' + videoId + '" src="' + originalSrc + '" frameborder="0" allowfullscreen style="max-width:100%; height:auto;"></iframe></div>';
            console.log('🔄 Восстанавливаем iframe с контейнером для видео (без jQuery):', videoId);
        } else {
            // Для video тегов или если нет originalSrc, создаем заглушку
            elementHtml = '<div style="text-align:center; padding:40px; background-color:#f8f9fa; border:1px solid #dee2e6; border-radius:8px; margin:10px 0;"><div style="font-size:16px; color:#6c757d;">Видео недоступно</div></div>';
            console.log('⚠️ Создаем заглушку для видео (без jQuery):', videoId);
        }
        
        container.innerHTML = elementHtml;
        console.log('✅ HTML восстановлен для видео (без jQuery):', videoId);
        console.log('🔍 Проверка после восстановления:', {
            container: container,
            innerHTML: container.innerHTML.substring(0, 200) + '...',
            hasIframe: container.querySelector('iframe') ? 'да' : 'нет'
        });
        
        // Перезапускаем мониторинг загрузки для iframe с задержкой
        if (isIframe && originalSrc) {
            var newElement = container.querySelector('iframe');
            console.log('🔄 Перезапускаем мониторинг для iframe (без jQuery):', videoId);
            
            // Даем время iframe загрузиться перед установкой таймаута
            setTimeout(function() {
                console.log('⏱️ Запускаем мониторинг после задержки для видео (без jQuery):', videoId);
                
                // Проверяем, загрузился ли iframe за это время
                // Не проверяем readyState сразу, так как iframe может еще не начать загрузку
                console.log('🔄 Запускаем мониторинг для восстановленного видео (без jQuery):', videoId);
                
                // Добавляем обработчик успешной загрузки для скрытия кнопки "обновить"
                if (newElement && newElement.addEventListener) {
                    // Проверяем, не добавлены ли уже обработчики
                    if (!newElement.hasAttribute('data-handlers-added')) {
                        console.log('🔧 Добавляем обработчик load для восстановленного iframe (без jQuery):', videoId);
                        newElement.setAttribute('data-handlers-added', 'true');
                        
                        // Основной обработчик load
                        newElement.addEventListener('load', function() {
                            console.log('✅ Iframe загрузился, скрываем кнопку "обновить" (без jQuery):', videoId);
                            hideErrorContainer(videoId);
                        });
                        
                        // Резервный обработчик canplay
                        newElement.addEventListener('canplay', function() {
                            console.log('✅ Iframe canplay, скрываем кнопку "обновить" (без jQuery):', videoId);
                            hideErrorContainer(videoId);
                        });
                        
                        // Дополнительная проверка через MutationObserver для YouTube iframe
                        if (newElement.src && newElement.src.includes('youtube')) {
                            console.log('🔧 Добавляем MutationObserver для YouTube iframe (без jQuery):', videoId);
                            var observer = new MutationObserver(function(mutations) {
                                mutations.forEach(function(mutation) {
                                    if (mutation.type === 'attributes' && mutation.attributeName === 'src') {
                                        console.log('✅ YouTube iframe src изменился, скрываем кнопку "обновить" (без jQuery):', videoId);
                                        hideErrorContainer(videoId);
                                        observer.disconnect(); // Отключаем наблюдатель после срабатывания
                                    }
                                });
                            });
                            observer.observe(newElement, { attributes: true, attributeFilter: ['src'] });
                            
                            // Таймаут для принудительного скрытия через 5 секунд
                            setTimeout(function() {
                                console.log('⏰ Принудительно скрываем кнопку "обновить" через 5 секунд (без jQuery):', videoId);
                                hideErrorContainer(videoId);
                                observer.disconnect();
                            }, FIVE_SECONDS_MS);
                        }
                    } else {
                        console.log('⚠️ Обработчики уже добавлены для iframe (без jQuery):', videoId);
                    }
                } else {
                    console.log('❌ Не удалось добавить обработчик load для восстановленного iframe (без jQuery):', videoId);
                }
                
                // Функция для скрытия контейнера с ошибкой
                function hideErrorContainer(videoId) {
                    var errorContainer = document.getElementById('error-' + videoId);
                    if (errorContainer) {
                        errorContainer.style.display = 'none';
                        console.log('✅ Контейнер с ошибкой скрыт для загруженного видео (без jQuery):', videoId);
                    } else {
                        console.log('❌ Контейнер с ошибкой не найден для скрытия (без jQuery):', videoId);
                    }
                }
                
                initializeVideoHandlerNative(newElement, originalSrc, videoId);
            }, 3000); // 3 секунды задержки
        }
    } else {
        console.error('❌ Контейнер с ошибкой не найден для видео (без jQuery):', videoId);
    }
}

/**
 * Инициализирует обработчик для конкретного видео
 */
function initializeVideoHandler(element, originalSrc, videoId) {
    console.log('🎬 Инициализируем обработчик для видео:', videoId, 'src:', originalSrc);
    
    var isIframe = false;
    var errorTimeout = null;
    var videoLoaded = false;
    var container = null;
    
    try {
        // Проверяем, является ли element уже jQuery объектом
        if (!element || typeof element.on !== 'function') {
            console.log('🔍 Element не является jQuery объектом, проверяем:', {
                element: element,
                hasOnMethod: typeof element.on,
                hasIsMethod: typeof element.is,
                elementType: typeof element,
                length: element ? element.length : 'undefined'
            });
            
            // Попробуем создать новый jQuery объект
            if (element && element[0]) {
                element = $(element[0]);
                console.log('✅ Создан новый jQuery объект из element[0]:', {
                    isJQuery: typeof element.is === 'function',
                    hasOnMethod: typeof element.on === 'function',
                    length: element.length,
                    jquery: element.jquery
                });
            } else if (element && typeof element === 'object') {
                // Попробуем обернуть весь объект
                element = $(element);
                console.log('✅ Создан новый jQuery объект из element:', {
                    isJQuery: typeof element.is === 'function',
                    hasOnMethod: typeof element.on === 'function',
                    length: element.length,
                    jquery: element.jquery
                });
            } else {
                console.error('❌ Не удалось создать jQuery объект');
                return;
            }
        } else {
            console.log('✅ Element уже является jQuery объектом');
        }
        
        isIframe = element.is('iframe');
        container = element.parent();
        
        console.log('📋 Параметры видео:', {
            videoId: videoId,
            isIframe: isIframe,
            originalSrc: originalSrc,
            container: container.length > 0 ? 'найден' : 'не найден',
            elementType: typeof element,
            hasOnMethod: typeof element.on === 'function',
            hasIsMethod: typeof element.is === 'function',
            elementLength: element.length,
            constructor: element.constructor ? element.constructor.name : 'unknown'
        });
    } catch (error) {
        console.error('❌ Ошибка при инициализации обработчика видео:', videoId, error);
        return;
    }
    
    // Проверяем доступность интернета
    if (!navigator.onLine) {
        console.log('❌ Нет подключения к интернету для видео:', videoId);
        showVideoError(videoId, 'Нет подключения к интернету', originalSrc, container);
        return;
    }
    
    console.log('✅ Подключение к интернету есть, настраиваем обработчики для видео:', videoId);
    
    // Финальная проверка перед использованием element.on()
    if (typeof element.on !== 'function') {
        console.error('❌ element.on не является функцией после всех проверок:', {
            element: element,
            hasOnMethod: typeof element.on,
            isJQuery: typeof element.is === 'function',
            elementType: typeof element,
            constructor: element.constructor ? element.constructor.name : 'unknown',
            length: element.length,
            jquery: element.jquery,
            prototype: Object.getPrototypeOf(element)
        });
        
        // Попробуем найти элемент по ID и создать новый jQuery объект
        console.log('🔍 Попытка найти элемент по ID и создать новый jQuery объект...');
        var elementById = $('#' + element.attr('id'));
        if (elementById.length > 0 && typeof elementById.on === 'function') {
            console.log('✅ Найден элемент по ID, заменяем element');
            element = elementById;
        } else {
            console.error('❌ Не удалось найти элемент по ID или создать jQuery объект');
            console.log('🔄 Попытка использовать нативные методы вместо jQuery...');
            
            // Используем нативные методы как fallback
            var nativeElement = element[0] || element;
            if (nativeElement && typeof nativeElement.addEventListener === 'function') {
                console.log('✅ Используем нативные методы для обработки событий');
                
                // Получаем нативный контейнер
                var nativeContainer = container[0] || container;
                if (!nativeContainer || typeof nativeContainer.querySelector !== 'function') {
                    // Если container не DOM элемент, используем parentNode
                    nativeContainer = nativeElement.parentNode;
                    console.log('🔄 Используем parentNode как контейнер:', nativeContainer);
                }
                
                // Отслеживаем успешную загрузку видео через нативные методы
                nativeElement.addEventListener('load', function() {
                    videoLoaded = true;
                    if (errorTimeout) {
                        clearTimeout(errorTimeout);
                        errorTimeout = null;
                    }
                    console.log('✅ Видео загружено успешно (нативные методы):', videoId);
                });
                
                // Для video тегов также отслеживаем событие canplay
                if (!isIframe) {
                    nativeElement.addEventListener('canplay', function() {
                        videoLoaded = true;
                        if (errorTimeout) {
                            clearTimeout(errorTimeout);
                            errorTimeout = null;
                        }
                        console.log('✅ Видео готово к воспроизведению (нативные методы):', videoId);
                    });
                }
                
                // Устанавливаем таймаут для показа ошибки (5 секунд)
                errorTimeout = setTimeout(function() {
                    if (!videoLoaded) {
                        console.log('⏰ Таймаут загрузки для видео (нативные методы):', videoId);
                        showVideoErrorNative(videoId, VIDEO_LOAD_ERROR_TEXT, originalSrc, nativeContainer);
                    }
                }, FIVE_SECONDS_MS);
                
                return; // Выходим из функции, так как используем нативные методы
            } else {
                console.error('❌ Не удалось использовать нативные методы');
                return;
            }
        }
    }
    
    // Отслеживаем успешную загрузку видео
    element.on('load', function() {
        videoLoaded = true;
        if (errorTimeout) {
            clearTimeout(errorTimeout);
            errorTimeout = null;
        }
        console.log('✅ Видео загружено успешно:', videoId);
        
        // Скрываем контейнер с ошибкой, если он есть
        var errorContainer = $('#error-' + videoId);
        if (errorContainer.length > 0) {
            errorContainer.hide();
            console.log('✅ Контейнер с ошибкой скрыт для загруженного видео:', videoId);
        }
    });
    
    // Для iframe видео не делаем автоматических проверок загруженности
    // Полагаемся только на событие 'load' и таймаут ошибки
    if (isIframe && originalSrc) {
        console.log('🎬 Настроен мониторинг для iframe:', videoId);
    }
    
    // Для video тегов также отслеживаем событие canplay
    if (!isIframe) {
        element.on('canplay', function() {
            videoLoaded = true;
            if (errorTimeout) {
                clearTimeout(errorTimeout);
                errorTimeout = null;
            }
            console.log('✅ Видео готово к воспроизведению:', videoId);
        });
    }
    
    // Если видео не загрузилось за 5 секунд, показываем ошибку
    errorTimeout = setTimeout(function() {
        if (!videoLoaded) {
            console.log('⏰ Таймаут загрузки для видео:', videoId);
            console.log('📋 Состояние видео при таймауте:', {
                videoId: videoId,
                videoLoaded: videoLoaded,
                isIframe: isIframe,
                originalSrc: originalSrc,
                elementExists: element.length > 0,
                elementSrc: element.length > 0 ? element.attr('src') : 'N/A',
                elementId: element.length > 0 ? element.attr('id') : 'N/A'
            });
            showVideoError(videoId, VIDEO_LOAD_ERROR_TEXT, originalSrc, container);
        } else {
            console.log('✅ Видео уже загружено, таймаут отменен:', videoId);
        }
    }, FIVE_SECONDS_MS);
    
    console.log('⏱️ Установлен таймаут 5 секунд для видео:', videoId);
    
    // Дополнительная отладка - проверяем состояние через 5 секунд
    setTimeout(function() {
        console.log('🔍 Промежуточная проверка через 5 секунд:', videoId, 'загружено:', videoLoaded);
    }, FIVE_SECONDS_MS);
    
    console.log('✅ Инициализация обработчика завершена для видео:', videoId);
}

/**
 * Показывает ошибку загрузки видео с кнопкой перезагрузки
 */
function showVideoError(videoId, errorMessage, originalSrc, container) {
    console.log('❌ Показываем ошибку для видео:', videoId, 'сообщение:', errorMessage);
    
    if (!container || container.length === 0) {
        console.error('❌ Контейнер для видео не найден:', videoId);
        return;
    }
    
    // Находим iframe или video элемент внутри контейнера
    var videoElement = container.find('iframe, video').first();
    if (videoElement.length === 0) {
        console.error('❌ Не найден iframe или video элемент в контейнере:', videoId);
        return;
    }
    
    var isIframe = videoElement.is('iframe');
    
    console.log('📋 Параметры ошибки:', {
        videoId: videoId,
        errorMessage: errorMessage,
        originalSrc: originalSrc,
        isIframe: isIframe,
        containerFound: container.length > 0,
        videoElementFound: videoElement.length > 0
    });
    
    // Создаем HTML для ошибки с поддержкой темной темы
    var errorHtml = `
        <div id="error-${videoId}" class="video-error-container" style="text-align:center; padding:40px; background-color:#f8f9fa; border:1px solid #dee2e6; border-radius:8px; margin:10px 0; color-scheme: light dark;">
            <div style="font-size:18px; color:#dc3545; margin-bottom:10px;">${errorMessage}</div>
            <div style="font-size:14px; color:#6c757d; margin-bottom:15px;">Проверьте подключение к интернету</div>
            <button onclick="reloadAllVideos()" 
                    style="background-color:#007AFF; color:white; border:none; padding:10px 20px; border-radius:6px; font-size:16px; cursor:pointer; transition:background-color 0.2s;"
                    onmouseover="this.style.backgroundColor='#0056CC'"
                    onmouseout="this.style.backgroundColor='#007AFF'">
                Обновить
            </button>
        </div>
    `;
    
    // Заменяем только iframe/video элемент, а не весь контейнер
    videoElement.replaceWith(errorHtml);
    console.log('✅ Ошибка отображена для видео:', videoId);
}

/**
 * Перезагружает видео после ошибки
 */
function retryVideoLoad(videoId, originalSrc, isIframe) {
    console.log('🔄 Перезагружаем видео:', videoId, 'src:', originalSrc, 'isIframe:', isIframe);
    
    // Находим контейнер с ошибкой
    var errorContainer = $('.video-error-container').first();
    if (errorContainer && errorContainer.parent().length > 0) {
        var container = errorContainer.parent();
        console.log('✅ Найден контейнер с ошибкой для видео:', videoId);
        
        // Восстанавливаем оригинальный элемент
        var elementHtml;
        if (isIframe && originalSrc) {
            // Создаем iframe с правильным контейнером
            elementHtml = `
                <div class="video-container" style="text-align: center;">
                    <iframe id="${videoId}" 
                            src="${originalSrc}" 
                            frameborder="0" 
                            allowfullscreen
                            style="max-width:100%; height:auto;">
                    </iframe>
                </div>
            `;
            console.log('🔄 Восстанавливаем iframe с контейнером для видео:', videoId);
        } else {
            // Для video тегов или если нет originalSrc, создаем заглушку
            elementHtml = `
                <div style="text-align:center; padding:40px; background-color:#f8f9fa; border:1px solid #dee2e6; border-radius:8px; margin:10px 0;">
                    <div style="font-size:16px; color:#6c757d;">Видео недоступно</div>
                </div>
            `;
            console.log('⚠️ Создаем заглушку для видео:', videoId);
        }
        
        container.html(elementHtml);
        console.log('✅ HTML восстановлен для видео:', videoId);
        
        // Перезапускаем мониторинг загрузки для iframe с задержкой
        if (isIframe && originalSrc) {
            var newElement = container.find('iframe').first();
            console.log('🔄 Перезапускаем мониторинг для iframe:', videoId);
            
            // Даем время iframe загрузиться перед установкой таймаута
            setTimeout(function() {
                console.log('⏱️ Запускаем мониторинг после задержки для видео:', videoId);
                
                // Проверяем, загрузился ли iframe за это время
                // Не проверяем readyState сразу, так как iframe может еще не начать загрузку
                console.log('🔄 Запускаем мониторинг для восстановленного видео:', videoId);
                
                // Добавляем обработчик успешной загрузки для скрытия кнопки "обновить"
                if (newElement && newElement.length > 0 && newElement[0]) {
                    // Проверяем, не добавлены ли уже обработчики
                    if (!newElement[0].hasAttribute('data-handlers-added')) {
                        console.log('🔧 Добавляем обработчик load для восстановленного iframe:', videoId);
                        newElement[0].setAttribute('data-handlers-added', 'true');
                        
                        // Основной обработчик load
                        newElement[0].addEventListener('load', function() {
                            console.log('✅ Iframe загрузился, скрываем кнопку "обновить":', videoId);
                            hideErrorContainerJQuery(videoId);
                        });
                        
                        // Резервный обработчик canplay
                        newElement[0].addEventListener('canplay', function() {
                            console.log('✅ Iframe canplay, скрываем кнопку "обновить":', videoId);
                            hideErrorContainerJQuery(videoId);
                        });
                        
                        // Дополнительная проверка через MutationObserver для YouTube iframe
                        if (newElement[0].src && newElement[0].src.includes('youtube')) {
                            console.log('🔧 Добавляем MutationObserver для YouTube iframe:', videoId);
                            var observer = new MutationObserver(function(mutations) {
                                mutations.forEach(function(mutation) {
                                    if (mutation.type === 'attributes' && mutation.attributeName === 'src') {
                                        console.log('✅ YouTube iframe src изменился, скрываем кнопку "обновить":', videoId);
                                        hideErrorContainerJQuery(videoId);
                                        observer.disconnect(); // Отключаем наблюдатель после срабатывания
                                    }
                                });
                            });
                            observer.observe(newElement[0], { attributes: true, attributeFilter: ['src'] });
                            
                            // Таймаут для принудительного скрытия через 5 секунд
                            setTimeout(function() {
                                console.log('⏰ Принудительно скрываем кнопку "обновить" через 5 секунд:', videoId);
                                hideErrorContainerJQuery(videoId);
                                observer.disconnect();
                            }, FIVE_SECONDS_MS);
                        }
                    } else {
                        console.log('⚠️ Обработчики уже добавлены для iframe:', videoId);
                    }
                } else {
                    console.log('❌ Не удалось добавить обработчик load для восстановленного iframe:', videoId);
                }
                
                // Функция для скрытия контейнера с ошибкой (jQuery версия)
                function hideErrorContainerJQuery(videoId) {
                    var errorContainer = $('#error-' + videoId);
                    if (errorContainer.length > 0) {
                        errorContainer.hide();
                        console.log('✅ Контейнер с ошибкой скрыт для загруженного видео:', videoId);
                    } else {
                        console.log('❌ Контейнер с ошибкой не найден для скрытия:', videoId);
                    }
                }
                
                initializeVideoHandler(newElement, originalSrc, videoId);
            }, 3000); // 3 секунды задержки
        }
    } else {
        console.error('❌ Контейнер с ошибкой не найден для видео:', videoId);
    }
}

/**
 * Глобальная функция для перезагрузки всех видео на странице
 */
function reloadAllVideos() {
    console.log('🔄 Перезагружаем все видео на странице');
    
    // Сначала сканируем все iframe на странице и сохраняем их src
    scanAndSaveAllVideoSources();
    
    // Восстанавливаем все контейнеры с ошибками обратно к оригинальным iframe
    var errorContainers = document.querySelectorAll('.video-error-container');
    console.log('🔍 Найдено контейнеров с ошибками для восстановления:', errorContainers.length);
    
    errorContainers.forEach(function(container) {
        // Получаем ID видео из ID контейнера
        var containerId = container.getAttribute('id');
        if (containerId && containerId.startsWith('error-')) {
            var videoId = containerId.replace('error-', '');
            console.log('🔄 Восстанавливаем контейнер для видео:', videoId);
            
            // Восстанавливаем оригинальный iframe
            var originalSrc = getOriginalSrcFromVideoId(videoId);
            if (originalSrc) {
                // Создаем iframe с правильным ID (добавляем префикс 'video-')
                var iframeId = 'video-' + videoId;
                var iframeHtml = '<iframe id="' + iframeId + '" src="' + originalSrc + '" frameborder="0" allowfullscreen style="max-width:100%; height:auto;"></iframe>';
                
                // Заменяем только контейнер с ошибкой, а не весь родительский контейнер
                container.outerHTML = iframeHtml;
                console.log('✅ Восстановлен iframe для видео:', videoId, 'src:', originalSrc);
                
                // Перезапускаем мониторинг для восстановленного iframe
                setTimeout(function() {
                    var newIframe = document.getElementById(iframeId);
                    if (newIframe) {
                        console.log('🔄 Перезапускаем мониторинг для восстановленного iframe:', videoId);
                        initializeVideoHandlerNative(newIframe, originalSrc, videoId);
                    }
                }, 1000);
            } else {
                console.log('⚠️ Не удалось найти оригинальный src для видео:', videoId);
                // Если не удалось найти src, создаем заглушку
                var placeholderHtml = '<div style="text-align:center; padding:40px; background-color:#f8f9fa; border:1px solid #dee2e6; border-radius:8px; margin:10px 0;"><div style="font-size:16px; color:#6c757d;">Видео недоступно</div></div>';
                container.outerHTML = placeholderHtml;
                console.log('⚠️ Создана заглушка для видео без src:', videoId);
            }
        }
    });
    
    // Перезагружаем все существующие iframe
    var iframes = document.querySelectorAll('iframe[src*="youtube"], iframe[src*="youtu.be"], iframe[src*="vimeo"]');
    console.log('🔍 Найдено iframe для перезагрузки:', iframes.length);
    
    iframes.forEach(function(iframe, index) {
        var src = iframe.getAttribute('src');
        if (src) {
            console.log('🔄 Перезагружаем iframe', index + 1, ':', src);
            // Временно очищаем src и восстанавливаем для принудительной перезагрузки
            iframe.setAttribute('src', '');
            setTimeout(function() {
                iframe.setAttribute('src', src);
            }, 100);
        }
    });
    
    // Перезагружаем все video теги
    var videos = document.querySelectorAll('video');
    console.log('🔍 Найдено HTML5 видео для перезагрузки:', videos.length);
    
    videos.forEach(function(video, index) {
        console.log('🔄 Перезагружаем HTML5 видео', index + 1);
        video.load();
    });
    
    console.log('✅ Перезагрузка всех видео завершена');
}

/**
 * Получает оригинальный src для видео по его ID
 */
function getOriginalSrcFromVideoId(videoId) {
    // Сначала пытаемся найти в глобальном хранилище оригинальных src
    if (window.originalVideoSources && window.originalVideoSources[videoId]) {
        return window.originalVideoSources[videoId];
    }
    
    // Если не найдено в хранилище, пытаемся найти iframe с таким ID на странице
    var existingIframe = document.getElementById('video-' + videoId);
    if (existingIframe && existingIframe.getAttribute('src')) {
        var src = existingIframe.getAttribute('src');
        console.log('🔍 Найден существующий iframe с src для видео:', videoId, 'src:', src);
        // Сохраняем найденный src для будущего использования
        saveOriginalVideoSrc(videoId, src);
        return src;
    }
    
    // Если ничего не найдено, возвращаем null
    console.log('⚠️ Не удалось найти оригинальный src для видео:', videoId);
    return null;
}

/**
 * Сохраняет оригинальный src для видео
 */
function saveOriginalVideoSrc(videoId, src) {
    if (!window.originalVideoSources) {
        window.originalVideoSources = {};
    }
    window.originalVideoSources[videoId] = src;
    console.log('💾 Сохранен оригинальный src для видео:', videoId, 'src:', src);
}

/**
 * Сканирует все iframe на странице и сохраняет их src для возможного восстановления
 */
function scanAndSaveAllVideoSources() {
    console.log('🔍 Сканируем все iframe на странице для сохранения src');
    
    var allIframes = document.querySelectorAll('iframe[src*="youtube"], iframe[src*="youtu.be"], iframe[src*="vimeo"], iframe[src*="player"]');
    console.log('🔍 Найдено iframe для сканирования:', allIframes.length);
    
    allIframes.forEach(function(iframe, index) {
        var src = iframe.getAttribute('src');
        var id = iframe.getAttribute('id');
        
        if (src) {
            // Если у iframe есть ID, используем его
            if (id) {
                var videoId = id.replace('video-', ''); // Убираем префикс если есть
                saveOriginalVideoSrc(videoId, src);
                console.log('💾 Сохранен src для iframe с ID:', videoId, 'src:', src);
            } else {
                // Если ID нет, генерируем его и сохраняем
                var videoId = generateVideoIdNative(iframe);
                saveOriginalVideoSrc(videoId, src);
                console.log('💾 Сохранен src для iframe без ID, сгенерирован ID:', videoId, 'src:', src);
            }
        }
    });
    
    console.log('✅ Сканирование iframe завершено');
}

/**
 * Глобальная функция для перезагрузки всех видео на странице (jQuery версия)
 */
function reloadAllVideosJQuery() {
    console.log('🔄 Перезагружаем все видео на странице (jQuery)');
    
    // Сначала сканируем все iframe на странице и сохраняем их src
    scanAndSaveAllVideoSources();
    
    // Восстанавливаем все контейнеры с ошибками обратно к оригинальным iframe
    var errorContainers = $('.video-error-container');
    console.log('🔍 Найдено контейнеров с ошибками для восстановления:', errorContainers.length);
    
    errorContainers.each(function() {
        var container = $(this);
        var containerId = container.attr('id');
        if (containerId && containerId.startsWith('error-')) {
            var videoId = containerId.replace('error-', '');
            console.log('🔄 Восстанавливаем контейнер для видео:', videoId);
            
            // Восстанавливаем оригинальный iframe
            var originalSrc = getOriginalSrcFromVideoId(videoId);
            if (originalSrc) {
                // Создаем iframe с правильным ID (добавляем префикс 'video-')
                var iframeId = 'video-' + videoId;
                var iframeHtml = '<iframe id="' + iframeId + '" src="' + originalSrc + '" frameborder="0" allowfullscreen style="max-width:100%; height:auto;"></iframe>';
                
                // Заменяем только контейнер с ошибкой, а не весь родительский контейнер
                container.replaceWith(iframeHtml);
                console.log('✅ Восстановлен iframe для видео:', videoId, 'src:', originalSrc);
                
                // Перезапускаем мониторинг для восстановленного iframe
                setTimeout(function() {
                    var newIframe = $('#' + iframeId);
                    if (newIframe.length > 0) {
                        console.log('🔄 Перезапускаем мониторинг для восстановленного iframe:', videoId);
                        initializeVideoHandler(newIframe, originalSrc, videoId);
                    }
                }, 1000);
            } else {
                console.log('⚠️ Не удалось найти оригинальный src для видео:', videoId);
                // Если не удалось найти src, создаем заглушку
                var placeholderHtml = '<div style="text-align:center; padding:40px; background-color:#f8f9fa; border:1px solid #dee2e6; border-radius:8px; margin:10px 0;"><div style="font-size:16px; color:#6c757d;">Видео недоступно</div></div>';
                container.replaceWith(placeholderHtml);
                console.log('⚠️ Создана заглушка для видео без src:', videoId);
            }
        }
    });
    
    // Перезагружаем все существующие iframe
    var iframes = $('iframe[src*="youtube"], iframe[src*="youtu.be"], iframe[src*="vimeo"]');
    console.log('🔍 Найдено iframe для перезагрузки:', iframes.length);
    
    iframes.each(function(index) {
        var iframe = $(this);
        var src = iframe.attr('src');
        if (src) {
            console.log('🔄 Перезагружаем iframe', index + 1, ':', src);
            // Временно очищаем src и восстанавливаем для принудительной перезагрузки
            iframe.attr('src', '');
            setTimeout(function() {
                iframe.attr('src', src);
            }, 100);
        }
    });
    
    // Перезагружаем все video теги
    var videos = $('video');
    console.log('🔍 Найдено HTML5 видео для перезагрузки:', videos.length);
    
    videos.each(function(index) {
        var video = $(this);
        console.log('🔄 Перезагружаем HTML5 видео', index + 1);
        video[0].load();
    });
    
    console.log('✅ Перезагрузка всех видео завершена (jQuery)');
}

// Дополнительная проверка после загрузки скрипта
console.log('🎬 Универсальный обработчик видео полностью загружен');
console.log('🔍 Финальная проверка:');
console.log('- jQuery доступен:', typeof $ !== 'undefined');
console.log('- DOM готов:', document.readyState);
console.log('- Все iframe на странице:', document.querySelectorAll('iframe').length);
console.log('- Все video на странице:', document.querySelectorAll('video').length);

// Если DOM уже готов, запускаем инициализацию немедленно
if (document.readyState === 'complete' || document.readyState === 'interactive') {
    console.log('🚀 DOM уже готов, запускаем инициализацию немедленно');
    if (typeof $ !== 'undefined') {
        initializeVideoHandlers();
    } else {
        initializeVideoHandlersNative();
    }
}