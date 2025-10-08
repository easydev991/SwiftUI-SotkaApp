/**
 * Обработчик размера шрифта для инфопостов
 * Читает размер шрифта из data-атрибута body и применяет соответствующий CSS
 */

/**
 * Определяет, является ли устройство iPad
 * Для iOS 17+ достаточно проверить Macintosh + touch points
 * @returns {boolean} true если устройство iPad, false если iPhone
 */
function isIPad() {
    // На iPad с iPadOS 13+ (включая iOS 17+) Safari притворяется десктопным браузером
    // User Agent содержит "Macintosh", но maxTouchPoints > 1 указывает на сенсорный экран
    return navigator.userAgent.match(/Macintosh/i) != null && navigator.maxTouchPoints > 1;
}

console.log('🔤 Обработчик размера шрифта загружен');
console.log('🔍 Отладочная информация при загрузке:');
console.log('- jQuery доступен:', typeof $ !== 'undefined');
console.log('- DOM готов:', document.readyState);
console.log('- Body элемент найден:', !!document.body);
console.log('- Data-атрибут font-size:', document.body ? document.body.getAttribute('data-font-size') : 'N/A');

// Проверяем, что jQuery загружен
if (typeof $ === 'undefined') {
    console.error('jQuery не загружен! Обработчик размера шрифта не может работать.');
    
    // Альтернативная инициализация без jQuery
    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', function() {
            console.log('DOM готов (без jQuery), инициализируем обработку размера шрифта');
            initializeFontSizeNative();
        });
    } else {
        console.log('DOM уже готов (без jQuery), инициализируем обработку размера шрифта');
        initializeFontSizeNative();
    }
} else {
    console.log('jQuery загружен, инициализируем обработчик размера шрифта');
    
    $(document).ready(function() {
        console.log('DOM готов, инициализируем обработку размера шрифта');
        initializeFontSize();
    });
}

/**
 * Инициализирует обработку размера шрифта (с jQuery)
 */
function initializeFontSize() {
    console.log('🔤 Начинаем инициализацию обработчика размера шрифта');
    
    // Получаем размер шрифта из data-атрибута body
    var fontSize = $('body').attr('data-font-size');
    console.log('📏 Размер шрифта из data-атрибута:', fontSize);
    
    if (!fontSize) {
        console.warning('⚠️ Data-атрибут data-font-size не найден в body, используем размер по умолчанию: medium');
        fontSize = 'medium';
    }
    
    // Применяем размер шрифта
    applyFontSize(fontSize);
}

/**
 * Инициализирует обработку размера шрифта (без jQuery)
 */
function initializeFontSizeNative() {
    console.log('🔤 Начинаем инициализацию обработчика размера шрифта (без jQuery)');
    
    // Получаем размер шрифта из data-атрибута body
    var fontSize = document.body ? document.body.getAttribute('data-font-size') : null;
    console.log('📏 Размер шрифта из data-атрибута (без jQuery):', fontSize);
    
    if (!fontSize) {
        console.warning('⚠️ Data-атрибут data-font-size не найден в body, используем размер по умолчанию: medium');
        fontSize = 'medium';
    }
    
    // Применяем размер шрифта
    applyFontSizeNative(fontSize);
}

/**
 * Применяет размер шрифта (с jQuery)
 * @param {string} fontSize - Размер шрифта (small, medium, large)
 */
function applyFontSize(fontSize) {
    console.log('🔤 Применяем размер шрифта:', fontSize);
    
    // Определяем CSS файл в зависимости от размера шрифта
    var cssPath = getCSSPathForFontSize(fontSize);
    console.log('📁 CSS файл для размера шрифта:', cssPath);
    
    // Удаляем старые CSS файлы размеров шрифта
    var oldCSSLinks = $('link[href*="style_small"], link[href*="style_medium"], link[href*="style_big"]');
    console.log('🗑️ Найдено старых CSS файлов для удаления:', oldCSSLinks.length);
    
    oldCSSLinks.each(function(index) {
        var link = $(this);
        var href = link.attr('href');
        console.log('🗑️ Удаляем старый CSS файл', index + 1, ':', href);
        link.remove();
    });
    
    // Добавляем новый CSS файл для размера шрифта
    var newCSSLink = '<link rel="stylesheet" href="' + cssPath + '" type="text/css" media="screen" />';
    $('head').append(newCSSLink);
    console.log('✅ Добавлен новый CSS файл:', cssPath);
    
    // Логируем результат
    console.log('✅ Размер шрифта успешно применен:', fontSize, 'CSS файл:', cssPath);
    
    // Проверяем, что CSS файл действительно добавлен
    var addedCSSLink = $('link[href="' + cssPath + '"]');
    if (addedCSSLink.length > 0) {
        console.log('✅ Подтверждено: CSS файл добавлен в head');
    } else {
        console.error('❌ Ошибка: CSS файл не найден в head после добавления');
    }
}

/**
 * Применяет размер шрифта (без jQuery)
 * @param {string} fontSize - Размер шрифта (small, medium, large)
 */
function applyFontSizeNative(fontSize) {
    console.log('🔤 Применяем размер шрифта (без jQuery):', fontSize);
    
    // Определяем CSS файл в зависимости от размера шрифта
    var cssPath = getCSSPathForFontSize(fontSize);
    console.log('📁 CSS файл для размера шрифта (без jQuery):', cssPath);
    
    // Удаляем старые CSS файлы размеров шрифта
    var oldCSSLinks = document.querySelectorAll('link[href*="style_small"], link[href*="style_medium"], link[href*="style_big"]');
    console.log('🗑️ Найдено старых CSS файлов для удаления (без jQuery):', oldCSSLinks.length);
    
    for (var i = 0; i < oldCSSLinks.length; i++) {
        var link = oldCSSLinks[i];
        var href = link.getAttribute('href');
        console.log('🗑️ Удаляем старый CSS файл', i + 1, ':', href);
        link.remove();
    }
    
    // Добавляем новый CSS файл для размера шрифта
    var newCSSLink = document.createElement('link');
    newCSSLink.rel = 'stylesheet';
    newCSSLink.href = cssPath;
    newCSSLink.type = 'text/css';
    newCSSLink.media = 'screen';
    
    document.head.appendChild(newCSSLink);
    console.log('✅ Добавлен новый CSS файл (без jQuery):', cssPath);
    
    // Логируем результат
    console.log('✅ Размер шрифта успешно применен (без jQuery):', fontSize, 'CSS файл:', cssPath);
    
    // Проверяем, что CSS файл действительно добавлен
    var addedCSSLink = document.querySelector('link[href="' + cssPath + '"]');
    if (addedCSSLink) {
        console.log('✅ Подтверждено: CSS файл добавлен в head (без jQuery)');
    } else {
        console.error('❌ Ошибка: CSS файл не найден в head после добавления (без jQuery)');
    }
}

/**
 * Возвращает путь к CSS файлу для указанного размера шрифта
 * @param {string} fontSize - Размер шрифта (small, medium, large)
 * @returns {string} Путь к CSS файлу
 */
function getCSSPathForFontSize(fontSize) {
    var cssPath;
    var deviceSuffix = isIPad() ? '_ipad' : '';
    
    switch (fontSize.toLowerCase()) {
        case 'small':
            cssPath = 'css/style_small' + deviceSuffix + '.css';
            break;
        case 'medium':
            cssPath = 'css/style_medium' + deviceSuffix + '.css';
            break;
        case 'large':
            cssPath = 'css/style_big' + deviceSuffix + '.css';
            break;
        default:
            console.warning('⚠️ Неизвестный размер шрифта:', fontSize, 'используем medium');
            cssPath = 'css/style_medium' + deviceSuffix + '.css';
            break;
    }
    
    console.log('📱 Устройство: ' + (isIPad() ? 'iPad' : 'iPhone'));
    console.log('📁 Маппинг размера шрифта:', fontSize, '-> CSS файл:', cssPath);
    return cssPath;
}

// Дополнительная проверка после загрузки скрипта
console.log('🔤 Обработчик размера шрифта полностью загружен');
console.log('🔍 Финальная проверка:');
console.log('- jQuery доступен:', typeof $ !== 'undefined');
console.log('- DOM готов:', document.readyState);
console.log('- Body элемент найден:', !!document.body);
console.log('- Data-атрибут font-size:', document.body ? document.body.getAttribute('data-font-size') : 'N/A');

// Если DOM уже готов, запускаем инициализацию немедленно
if (document.readyState === 'complete' || document.readyState === 'interactive') {
    console.log('🚀 DOM уже готов, запускаем инициализацию размера шрифта немедленно');
    if (typeof $ !== 'undefined') {
        initializeFontSize();
    } else {
        initializeFontSizeNative();
    }
}
