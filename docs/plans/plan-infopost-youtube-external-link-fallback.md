# Infopost YouTube External Link Fallback Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Убрать зависимость экрана инфопостов от встроенного YouTube iframe и всегда показывать стабильный кастомный блок с переходом во внешний браузер, сохранив day-видео из `youtube_list.txt` внизу статьи (как сейчас по UX).

**Architecture:** Все YouTube iframe (из исходных HTML и динамически добавляемые для day-постов) преобразуются в единый HTML-блок с кнопкой `Смотреть видео`. Day-видео из `youtube_list.txt` продолжают добавляться внизу инфопоста (как сейчас по поведению), но уже как внешний блок без iframe. Переход обрабатывается через кастомную ссылку `sotka://youtube?url=...` и перехват в `WKNavigationDelegate` с `UIApplication.shared.open(...)`.

**Tech Stack:** SwiftUI, WKWebView, Swift Testing, `Localizable.xcstrings`, HTML/CSS/JS ресурсы инфопостов.

---

## Подтвержденные замечания из ревью

- [x] Ошибка YouTube 153 внутри iframe не может быть гарантированно перехвачена текущим JS/WKWebView-потоком.
- [x] Нужно обрабатывать не только `addYouTubeVideo(...)`, но и YouTube iframe, уже встроенные в `SupportingFiles/book/**`.
- [x] Требуется отдельный шаг миграции существующих тестов (`InfopostParserYouTubeTests`).
- [x] Нужно зафиксировать точный HTML-формат кастомного блока и механику навигации.
- [x] Нужно зафиксировать локализационные ключи и место их добавления.
- [x] Нужно явно определить судьбу `video_handler.js`.

## Границы и решения

- [ ] Трансформация YouTube iframe применяется ко всему HTML-контенту инфопоста, независимо от `dayNumber`.
- [ ] `InfopostHTMLProcessor.swift` не изменяется (только мост вызова парсера).
- [ ] Нормализация YouTube URL приводит к `https://www.youtube.com/watch?v=VIDEO_ID`.
- [ ] Обычные ссылки статьи сохраняют текущее поведение; спец-обработка только для кнопки кастомного видеоблока.
- [ ] `YouTubeVideoService` и `youtube_list.txt` сохраняются и остаются источником 100 day-видео.
- [ ] Day-видео из `youtube_list.txt` остается внизу контента (текущая позиция в UX), меняется только тип блока: iframe -> внешний компонент с кнопкой.
- [ ] По состоянию книги (`SupportingFiles/book/*.{html,htm}`) `vimeo/player` iframe не обнаружены; в рамках задачи заменяем только YouTube iframe.
- [ ] Атрибут `data-video-kind="youtube"` сохраняется и используется в CSS-селекторах/тестах как стабильный маркер видеоблока.

---

## Этап 1: TDD-контракты для полной замены YouTube iframe (Red)

**Файлы:**
- [ ] Изменить: `SwiftUI-SotkaAppTests/InfopostsTests/InfopostParserYouTubeTests.swift`
- [ ] Добавить: `SwiftUI-SotkaAppTests/InfopostsTests/InfopostYouTubeIframeReplacementTests.swift`
- [ ] Добавить: `SwiftUI-SotkaAppTests/InfopostsTests/YouTubeLinkNormalizerTests.swift`

**Шаги:**
- [ ] Добавить падающий тест: `prepareHTMLForDisplay(...)` удаляет YouTube iframe, встречающиеся в любом месте HTML (включая `<center>`, вложенные `<div>`, одиночные теги).
- [ ] Добавить падающий тест: day-посты, где раньше вставлялся iframe через `youtube_list.txt`, теперь получают кастомный блок с `sotka://youtube?url=...`.
- [ ] Добавить падающий тест: day-блок из `youtube_list.txt` вставляется внизу контента (регрессия на текущую позицию блока).
- [ ] Добавить падающие тесты нормализации URL: `youtube.com/embed/...`, `youtube.com/watch?v=...`, `youtu.be/...`, `youtube.com` без `www`.
- [ ] Добавить падающий тест на контент без `dayNumber` (например, `about/organiz/aims`), если внутри есть YouTube iframe.
- [ ] Добавить падающий тест на не-YouTube iframe: не удаляется и не заменяется.
- [ ] Добавить падающие тесты на локализованные тексты кнопки/описания для `ru` и `en`.
- [ ] Добавить падающий тест на наличие `data-video-kind="youtube"` в сгенерированном блоке.
- [ ] Выполнить `make format`.

**Критерий завершения этапа:**
- Новые тесты добавлены и падают по ожидаемой причине отсутствия реализации.

---

## Этап 2: Реализация трансформации HTML и нормализации ссылок (Green)

**Файлы:**
- [ ] Изменить: `SwiftUI-SotkaApp/Services/Infoposts/InfopostParser.swift`
- [ ] Добавить: `SwiftUI-SotkaApp/Services/Infoposts/YouTubeLinkNormalizer.swift`
- [ ] Изменить: `SwiftUI-SotkaApp/SupportingFiles/Localizable.xcstrings`

**Шаги:**
- [ ] Реализовать `YouTubeLinkNormalizer` с извлечением `VIDEO_ID` и выдачей watch-URL формата `https://www.youtube.com/watch?v=VIDEO_ID`.
- [ ] Добавить этап в `prepareHTMLForDisplay(...)`: поиск и замена всех YouTube iframe в исходном HTML на кастомный блок.
- [ ] Обновить `addYouTubeVideo(...)`: вставлять не iframe, а тот же кастомный блок (если day-видео найдено в `youtube_list.txt`).
- [ ] Сохранить текущую точку вставки day-блока (внизу статьи), не переносить его в середину контента.
- [ ] Зафиксировать HTML-шаблон блока:

```html
<div class="video-external-container" data-video-kind="youtube">
  <div class="video-external-title">{video_title}</div>
  <a class="video-external-link" href="sotka://youtube?url={percent_encoded_watch_url}">
    {localized_watch_button}
  </a>
  <div class="video-external-hint">{localized_open_in_browser_hint}</div>
</div>
```

- [ ] Добавить локализационные ключи:
  - [ ] `infopost.youtube.watchVideo`
  - [ ] `infopost.youtube.openInBrowser`
- [ ] Выполнить `make format`.

**Критерий завершения этапа:**
- Новые тесты из Этапа 1 проходят.

---

## Этап 2.5: Миграция существующих тестов под новую архитектуру

**Файлы:**
- [ ] Изменить: `SwiftUI-SotkaAppTests/InfopostsTests/InfopostParserYouTubeTests.swift`
- [ ] Изменить: `SwiftUI-SotkaAppTests/InfopostsTests/InfopostParserTests.swift` (если затронуты ожидания по скриптам/iframe)

**Шаги:**
- [ ] Переписать проверки, ожидавшие `iframe`/`youtube.com/embed`, на проверки `video-external-container`, `sotka://youtube` и локализованные тексты.
- [ ] Оставить интеграционные проверки `prepareHTMLForDisplay(...)` на очистку HTML, пути картинок и размер шрифта без регрессий.
- [ ] Выполнить `make format`.

**Критерий завершения этапа:**
- Тестовый пакет инфопостов зеленый без ожиданий старой iframe-архитектуры.

---

## Этап 3: Внешнее открытие ссылки из WKWebView

**Файлы:**
- [ ] Изменить: `SwiftUI-SotkaApp/Screens/Home/Infoposts/HTMLContentView.swift`
- [ ] Добавить: `SwiftUI-SotkaApp/Screens/Home/Infoposts/InfopostExternalURLRouter.swift`
- [ ] Добавить: `SwiftUI-SotkaAppTests/InfopostsTests/InfopostExternalURLRouterTests.swift`

**Шаги:**
- [ ] Вынести разбор `sotka://youtube?url=...` в отдельный router/helper для unit-тестирования.
- [ ] В `decidePolicyFor navigationAction`:
  - [ ] Для `sotka://youtube` открывать декодированный `https://www.youtube.com/watch?v=...` через `UIApplication.shared.open(...)`.
  - [ ] Возвращать `.cancel` после успешного перехвата.
  - [ ] Для остальных URL сохранить текущую политику (без неожиданного изменения поведения статьи).
- [ ] Добавить тесты:
  - [ ] `sotka://youtube` -> `.cancel` + вызов внешнего открытия.
  - [ ] Некорректный `url` в query -> `.cancel` без крэша.
  - [ ] Обычные ссылки инфопоста не ломаются.
- [ ] Выполнить `make format`.

**Критерий завершения этапа:**
- Кнопка `Смотреть видео` всегда открывает внешний браузер, iframe внутри `WKWebView` не появляется.

---

## Этап 4: Удаление legacy-обработки iframe

**Файлы:**
- [ ] Изменить: `SwiftUI-SotkaApp/Services/Infoposts/InfopostParser.swift`
- [ ] Удалить: `SwiftUI-SotkaApp/SupportingFiles/book/js/video_handler.js`
- [ ] Изменить: `SwiftUI-SotkaApp/SupportingFiles/book/css/style_small.css`
- [ ] Изменить: `SwiftUI-SotkaApp/SupportingFiles/book/css/style_medium.css`
- [ ] Изменить: `SwiftUI-SotkaApp/SupportingFiles/book/css/style_big.css`
- [ ] Изменить: `SwiftUI-SotkaApp/SupportingFiles/book/css/style_small_ipad.css`
- [ ] Изменить: `SwiftUI-SotkaApp/SupportingFiles/book/css/style_medium_ipad.css`
- [ ] Изменить: `SwiftUI-SotkaApp/SupportingFiles/book/css/style_big_ipad.css`
- [ ] Изменить: `SwiftUI-SotkaApp/SupportingFiles/book/css/style.css`

**Шаги:**
- [ ] Удалить подключение `video_handler.js` из `addUniversalVideoHandler(...)`.
- [ ] Проверить, что `scroll_tracker.js`, `font_size_handler.js`, `console_interceptor.js` продолжают использоваться и не затронуты.
- [ ] Проверить по книге (`SupportingFiles/book/*.{html,htm}`), что нет вызовов `reloadAllVideos()` и других функций из `video_handler.js`.
- [ ] Добавить стили `video-external-container` / `video-external-link` / `video-external-hint` (включая селекторы по `data-video-kind="youtube"`) для светлой и темной темы во всех CSS-вариантах (`style.css`, `style_small*.css`, `style_medium*.css`, `style_big*.css`).
- [ ] Проверить, что `normalize.css` не требует изменений и осознанно исключен из scope.
- [ ] Выполнить `make format`.

**Критерий завершения этапа:**
- В runtime не подключается JS-фолбэк iframe, UI видео строится только кастомным HTML-блоком.

---

## Этап 5: Проверка и приемка

**Шаги:**
- [ ] Запустить тесты инфопостов (`InfopostParserTests`, `InfopostParserYouTubeTests`, новые тесты трансформации/роутера).
- [ ] Сборка iOS-таргета (предпочтительно через `xcodebuild-mcp`, fallback: `make build`).
- [ ] Ручной smoke по сценариям: `VPN OFF`, `VPN ON`, `без интернета`.
- [ ] Ручная проверка `ru`/`en` постов с одиночными и множественными видео-блоками.
- [ ] Проверить, что `about/aims/organiz` и day-посты ведут себя консистентно.

**Критерий завершения этапа:**
- На экране инфопоста отсутствуют YouTube iframe.
- Видеоблок всегда отображается как кастомный компонент.
- Клик `Смотреть видео` открывает браузер, а не внутренний плеер.

---

## Риски

- Regex-трансформация HTML должна быть устойчивой к разным форматам iframe и атрибутов.
- Нужна аккуратная URL-нормализация/percent-encoding, чтобы исключить битые deep-link.
- Риск неверной позиции day-блока после рефакторинга: нужен регрессионный тест на вставку внизу контента.

## Definition of Done

- [ ] YouTube iframe из исходных HTML и динамических вставок полностью заменены.
- [ ] Реализован стабильный переход во внешний браузер через `sotka://youtube`.
- [ ] Старый `video_handler.js` удален из пайплайна.
- [ ] Локализация `ru`/`en` добавлена в `Localizable.xcstrings`.
- [ ] `youtube_list.txt` и day-сопоставление `1...100` сохранены.
- [ ] Day-видео из `youtube_list.txt` по-прежнему показывается внизу статьи, но как внешний блок с кнопкой.
- [ ] Тесты, форматирование и сборка зеленые.
