# Конвенции тестирования из правил проекта

Источники: `.agents/rules/test-driven-development.mdc`, `.agents/rules/safe-optional-unwrapping.mdc`, `AGENTS.md` (Test Strategy, Read-Only Mode, Hard Constraints).

## TDD: Красный → Зелёный → Рефакторинг

- Пиши тест для целевой логики **до** реализации — тест должен падать (красный).
- Реализуй минимальный код до прохождения (зелёный).
- Улучши код после успешного теста (рефакторинг).
- Не меняй код, пока тесты зелёные. `make format` — после правок кода.
- Тесты прогоняются через xcode MCP (`RunAllTests`/`RunSomeTests`).

## Опционалы: без force unwrap

- `!` запрещён везде, включая тесты (`.agents/rules/safe-optional-unwrapping.mdc`).
- В тестах единственный санкционированный способ разворота — `try #require(optionalValue)`.
- В production-коде: `if let`, `guard let`, `??`, optional chaining — никогда `!`.

## Офлайн-first и read-only

- Сервер закрыт, сеть и auth недоступны: в тестах — только моки и локальные сторы (SwiftData, UserDefaults). Реальных запросов нет и быть не может.
- `AppConfiguration.isReadOnlyMode = true` — константа; не пытайся «чинить» её в тестах.
- Юнит-тесты это не затрагивает; сценарии офлайн-поведения тестируются на моках.

## UI-тесты (отдельный контур)

- Фреймворк — XCTest, `SwiftUI-SotkaAppUITests`.
- Запуск приложения с launch-аргументом `UITest` — обязателен.
- DEBUG-бутстрап в `SwiftUI_SotkaAppApp`: сид `ScreenshotDemoData` + офлайн-логин с `isReadOnlyMode: false` (имитация нормального режима). Не полагайся на этот флаг вне UI-тестов.
- Unit-логику из UI-тестов не тестируем — она живёт в `SwiftUI-SotkaAppTests`.

## Структура и стиль

- Предпочитай детерминированные тесты: in-memory `ModelContainer` для SwiftData, изолированный `UserDefaults` (см. EXAMPLE.md).
- Моки — из `SwiftUI-SotkaAppTests/Mocks/` (`MockUserDefaults`, `MockStatusManager`, `MockReviewEventReporter`); новые добавляй туда же, если готовых нет.
- Внедрение зависимостей — через init-параметры (см. `makeSUT` в EXAMPLE.md).
- Русские описания в `@Test`/`@Suite`; комментарии в теле теста не нужны.
- В тестах нет ветвлений вида `if shouldThrow {} else {}` — один тест, один сценарий.
