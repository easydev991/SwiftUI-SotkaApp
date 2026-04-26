# Infopost YouTube External Link Fallback Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Убрать зависимость экрана инфопостов от встроенного YouTube iframe и всегда показывать стабильный кастомный блок с переходом во внешний браузер, сохранив day-видео из `youtube_list.txt` внизу статьи (как сейчас по UX).

**Architecture:** Все YouTube iframe (из исходных HTML и динамически добавляемые для day-постов) преобразуются в единый HTML-блок с кнопкой `Смотреть видео`. Day-видео из `youtube_list.txt` продолжают добавляться внизу инфопоста (как сейчас по поведению), но уже как внешний блок без iframe. Переход обрабатывается через кастомную ссылку `sotka://youtube?url=...` и перехват в `WKNavigationDelegate` с `UIApplication.shared.open(...)`.

**Tech Stack:** SwiftUI, WKWebView, Swift Testing, `Localizable.xcstrings`, HTML/CSS/JS ресурсы инфопостов.

---

## Подтвержденные замечания из ревью

- [x] Все ключевые замечания из ревью учтены (диагноз iframe-ошибки, покрытие встроенных iframe, миграция тестов, формат блока, локализация, судьба `video_handler.js`).

## Границы и решения

- [x] Границы и архитектурные решения зафиксированы и реализованы (глобальная замена YouTube iframe, сохранение day-видео из `youtube_list.txt`, `sotka://youtube`, неизменный `InfopostHTMLProcessor`, маркер `data-video-kind`, YouTube-only scope).

---

## Этап 1: TDD-контракты для полной замены YouTube iframe (Red)

**Файлы:**

- [x] Обновлены/добавлены тестовые файлы инфопостов для TDD-контрактов YouTube.

**Шаги:**

- [x] Добавлены падающие тесты на замену YouTube iframe, day-видео внизу, нормализацию ссылок, локализацию и маркер `data-video-kind`; форматирование выполнено.

**Критерий завершения этапа:**

- [x] Новые тесты добавлены и переведены в зеленое состояние на реализации.

---

## Этап 2: Реализация трансформации HTML и нормализации ссылок (Green)

**Файлы:**

- [x] Обновлены `InfopostParser`, `YouTubeLinkNormalizer`, `Localizable.xcstrings`.

**Шаги:**

- [x] Реализованы нормализация YouTube URL, глобальная замена iframe и вставка day-видео как внешнего блока внизу статьи.
- [x] Зафиксирован HTML-шаблон блока:

```html
<div class="video-external-container" data-video-kind="youtube">
  <div class="video-external-title">{video_title}</div>
  <a class="video-external-link" href="sotka://youtube?url={percent_encoded_watch_url}">
    {localized_watch_button}
  </a>
  <div class="video-external-hint">{localized_open_in_browser_hint}</div>
</div>
```

- [x] Добавлены ключи `infopost.youtube.watchVideo` и `infopost.youtube.openInBrowser`; форматирование выполнено.

**Критерий завершения этапа:**

- [x] Новые тесты из Этапа 1 проходят.

---

## Этап 2.5: Миграция существующих тестов под новую архитектуру

**Файлы:**

- [x] Миграция тестов выполнена в `InfopostParserYouTubeTests` (`InfopostParserTests` без изменений).

**Шаги:**

- [x] Проверки переведены на новую архитектуру (`video-external-container`, `sotka://youtube`) без регрессий интеграционных сценариев; форматирование выполнено.

**Критерий завершения этапа:**

- [x] Тестовый пакет инфопостов зеленый без ожиданий старой iframe-архитектуры.

---

## Этап 3: Внешнее открытие ссылки из WKWebView

**Файлы:**

- [x] Обновлен `HTMLContentView`, добавлены `InfopostExternalURLRouter` и его тесты.

**Шаги:**

- [x] Разбор `sotka://youtube` вынесен в router; в `WKNavigationDelegate` реализован `.cancel` + внешнее открытие и сохранено поведение обычных ссылок; тесты и форматирование выполнены.

**Критерий завершения этапа:**

- [x] Кнопка `Смотреть видео` всегда открывает внешний браузер, iframe внутри `WKWebView` не появляется.

---

## Этап 4: Удаление legacy-обработки iframe

**Файлы:**

- [x] Обновлены `InfopostParser` и CSS-файлы книги; `video_handler.js` удален.

**Шаги:**

- [x] Удален legacy JS-пайплайн iframe, добавлены стили внешнего видеоблока во всех нужных CSS-вариантах, проверены зависимости/исключения; форматирование выполнено.

**Критерий завершения этапа:**

- [x] В runtime не подключается JS-фолбэк iframe, UI видео строится только кастомным HTML-блоком.

---

## Этап 5: Проверка и приемка

**Шаги:**

- [x] Запустить тесты инфопостов (`InfopostParserTests`, `InfopostParserYouTubeTests`, новые тесты трансформации/роутера).
- [x] Сборка iOS-таргета (предпочтительно через `xcodebuild-mcp`, fallback: `make build`).
- [ ] Ручной smoke по сценариям: `VPN OFF`, `VPN ON`, `без интернета`.
- [ ] Ручная проверка `ru`/`en` постов с одиночными и множественными видео-блоками.
- [ ] Проверить, что `about/aims/organiz` и day-посты ведут себя консистентно.

**Критерий завершения этапа:**

- [x] Автопроверки пройдены: iframe отсутствуют, видеоблок кастомный, кнопка открывает внешний браузер.

---

## Этап 6: Технический рефакторинг без изменения поведения

**Файлы:**

- [x] Обновлены `InfopostParser.swift` и `HTMLContentView.swift`.

**Шаги:**

- [x] Выполнен технический рефакторинг без изменения поведения (декомпозиция пайплайна, константы, устранение дублей, защита от лишних reload, форматирование, целевые тесты).

**Критерий завершения этапа:**

- [x] Поведение экрана не изменилось, а код стал проще и менее дублирующимся.

---

## Риски

- Regex-трансформация HTML должна быть устойчивой к разным форматам iframe и атрибутов.
- Нужна аккуратная URL-нормализация/percent-encoding, чтобы исключить битые deep-link.
- Риск неверной позиции day-блока после рефакторинга: нужен регрессионный тест на вставку внизу контента.

## Текущее состояние

- [x] Кодовая реализация, рефакторинг, форматирование и автотесты завершены.
- [ ] Остались только ручные проверки из Этапа 5 (`VPN OFF/ON/без интернета`, `ru/en`, консистентность `about/aims/organiz` и day-постов).

## Definition of Done

- [x] Все критерии DoD по YouTube external-link fallback выполнены.
