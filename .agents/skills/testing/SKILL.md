---
name: testing
description: Экспертные правила тестирования iOS/watchOS-приложения на SwiftUI + SwiftData + Observation (MVVM @Observable). Использовать при написании новых unit-тестов, рефакторинге существующих, отладке flaky-тестов, изоляции SwiftData/UserDefaults в тестах, написании и переиспользовании моков, точечном запуске тестов через xcode MCP (GetTestList → RunSomeTests) или make-фоллбек. Unit-тесты — только Swift Testing (@Test, #expect, #require); UI-тесты — XCTest с launch-аргументом UITest.
---

# Тестирование: unit-тесты на Swift Testing

## When to use

- Пишешь новый unit-тест для сервиса, ViewModel или модели
- Рефакторишь существующий тест под стандарты проекта
- Отлаживаешь упавший или flaky-тест
- Настраиваешь изоляцию SwiftData (in-memory container) или UserDefaults
- Создаёшь мок или ищешь готовый в `SwiftUI-SotkaAppTests/Mocks/`
- Запускаешь тесты и не уверен, чем: xcode MCP или make

## Agent behavior contract

1. **Unit-тесты — только Swift Testing**: `import Testing`, `@Test`, `#expect`, `#require`, `@Suite`. XCTest — только в `SwiftUI-SotkaAppUITests` для UI-тестов.
2. **Русские описания обязательно**: `@Test("Должен возвращать пустой массив при отсутствии данных")` и `@Suite("Тесты ReviewManager eligibility и координации")`.
3. **Без force unwrap — нигде, включая тесты** (`.agents/rules/safe-optional-unwrapping.mdc`). Опционал разворачивай так: `let value = try #require(optionalValue)`, тест получает `throws`.
4. **`throws`/`async` только по необходимости**: есть `try` → `throws`; нет — без него. Есть `await` → `async`; нет — без него.
5. **SwiftData — только in-memory**: `ModelConfiguration(isStoredInMemoryOnly: true)`. Тест никогда не пишет в реальный стор. Образец: `ReviewManagerTests.makeContainer()`.
6. **UserDefaults — только изолированный**: `try MockUserDefaults.create()` (UUID-suite на тест). Никогда `UserDefaults.standard`.
7. **Моки — из `SwiftUI-SotkaAppTests/Mocks/`** (`MockUserDefaults`, `MockStatusManager`, `MockReviewEventReporter`). Новые создавай только если готового нет; группируй по функциональности.
8. **TDD: тест раньше реализации** — красный → зелёный → рефакторинг (`.agents/rules/test-driven-development.mdc`).
9. **Запуск — xcode MCP первым**: `GetTestList` → `RunSomeTests` по 1–2 идентификаторам. Полный прогон (`RunAllTests` / `make test`) — один раз в конце. Правило «один прогон → один отчёт»: `.agents/rules/test-execution.mdc`. Фоллбек при недоступном MCP — `make test`.
10. **Watch-тесты** (`make test_watch`, таргет `SotkaWatch Watch AppTests`) — только при изменениях watch-таргета.
11. **UI-тесты — отдельная тема**: XCTest + launch-аргумент `UITest`; DEBUG-бутстрап сидит демо-данными с `isReadOnlyMode: false`. Сюда не смешивать.
12. **Без сети в тестах**: проект офлайн-first, сервер закрыт — только моки и локальные сторы.

## First 60 seconds (triage)

При правке или отладке тестов, в таком порядке:

1. Открой существующий тест-файл рядом с тестируемым кодом как образец (см. «Routing map»).
2. `GetTestList` — найди идентификаторы нужных тестов (grep по `TEST_IDENTIFIER`, `TEST_FILE_PATH`).
3. `RunSomeTests` по 1–2 идентификаторам — точечная проверка гипотезы.
4. Тест упал → **читай вывод** (`GetConsoleOutput` с `pattern` по сообщению ошибки), не перезапускай вслепую. Один прогон → один отчёт.
5. Локально воспроизводишь паттерн из соседнего зелёного теста, правишь, перезапускаешь только затронутые тесты.
6. В конце — один полный прогон и один отчёт.

## Анатомия тест-файла

Канонический скелет (как в `ReviewManagerTests.swift`):

```swift
import Foundation
import SwiftData            // если нужен ModelContainer
@testable import SwiftUI_SotkaApp
import Testing

@Suite("Тесты <Что тестируем> — <аспект>")
@MainActor                  // для ViewModel/сервисов с MainActor-состоянием
struct FooTests {
    private func makeContainer() throws -> ModelContainer { ... }   // in-memory
    private func makeSUT(...) throws -> (Sut, Mock, ...) { ... }     // фабрика SUT

    @Test("Русское описание поведения")
    func doesThing() async throws {
        let (sut, ...) = try makeSUT(...)
        // act
        let value = try #require(sut.result)
        #expect(value == expected)
    }
}
```

- Один файл — один тестируемый тип; группировка по аспектам — отдельные файлы (`WorkoutPreviewViewModelUpdatePlannedCountTests.swift` и т.п.), общий `@Suite`-заглушка допустима (`WorkoutPreviewViewModelTests.swift`).
- Проверки без ветвлений: один тест — один сценарий, без `if/else` внутри.

## Карта таргетов

| Таргет | Фреймворк | Когда трогать |
|---|---|---|
| `SwiftUI-SotkaAppTests` | Swift Testing | Вся unit-логика iOS: сервисы, ViewModel, модели |
| `SwiftUI-SotkaAppUITests` | XCTest + аргумент `UITest` | Только UI-флоу |
| `SotkaWatch Watch AppTests` | Swift Testing | Только при изменениях watch-таргета |

Моки живут в `SwiftUI-SotkaAppTests/Mocks/`: `MockUserDefaults`, `MockStatusManager`, `MockReviewEventReporter`.

## Routing map

| Задача | Reference |
|---|---|
| Синтаксис `@Test`/`#expect`/`#require`, параметризация, моки, in-memory container — готовые сниппеты | [references/EXAMPLE.md](references/EXAMPLE.md) |
| Как запустить тесты: xcode MCP, make-фоллбек, watch, UI-тесты | [references/running-tests.md](references/running-tests.md) |
| Конвенции из правил: TDD, safe unwrapping, офлайн, read-only mode | [references/project-conventions.md](references/project-conventions.md) |

## Common pitfalls → next best move

| Грабли | Next best move |
|---|---|
| `let x = optional!` в тесте | `let x = try #require(optional)` + `throws` на функции |
| Тест с SwiftData без контейнера бьёт по реальному стору | `ModelContainer(for: ..., configurations: ModelConfiguration(isStoredInMemoryOnly: true))` — сниппет в EXAMPLE.md |
| `UserDefaults.standard` в тесте → взаимное загрязнение | `try MockUserDefaults.create()` — UUID-suite на каждый тест |
| Flaky async-тест, «иногда падает» | Пометь suite `@MainActor`, жди через `await`, а не `Task.sleep`; гоняй точечно `RunSomeTests` до стабилизации |
| Хардкод имени симулятора в команде | Не хардкодь: xcode MCP выбирает сам; в make — переменные `IOS_SIM_DEST` / `WATCH_SIM_DEST` из Makefile |
| Тест упал → сразу перезапуск | `GetConsoleOutput` → прочитай assertion → правь причину. Перезапуск — не отладка |
| `#expect(x == true)` | `#expect(x)` / `#expect(!x)` |
| Ожидаемая ошибка через do-catch | `#expect(throws: MyError.userNotFound) { try sut.method() }` |
| Дубль существующего мока | Сначала загляни в `SwiftUI-SotkaAppTests/Mocks/` |

## Verification checklist

- [ ] `import Testing`; у каждого `@Test`/`@Suite` — русское описание
- [ ] Нет `!`; опционалы через `try #require`; `throws`/`async` ровно там, где нужны
- [ ] SwiftData — in-memory container; UserDefaults — изолированный suite, не `.standard`
- [ ] Моки взяты из `SwiftUI-SotkaAppTests/Mocks/` или обоснованно добавлены туда
- [ ] Точечный прогон через `RunSomeTests` зелёный; полный прогон — один раз
- [ ] Отчёт — один, по одному прогону (правило `test-execution.mdc`)
- [ ] Для watch-таргета прогнан `make test_watch`; для UI — аргумент `UITest` учтён
