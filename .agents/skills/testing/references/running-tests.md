# Запуск тестов

## Приоритет: xcode MCP

Точечный запуск — основной рабочий цикл агента:

1. **`GetTestList`** — список доступных тестов активного тест-плана (до 100 инлайн, полный список в файле). Grep по `TEST_IDENTIFIER` / `TEST_FILE_PATH` / `TEST_TARGET`.
2. **`RunSomeTests`** — запуск 1–2 конкретных тестов по идентификаторам:

```json
{ "tests": [
    { "targetName": "SwiftUI-SotkaAppTests",
      "testIdentifier": "ReviewManagerTests/setsPendingOnFirstMilestone()" }
] }
```

3. **`RunAllTests`** — полный прогон, один раз в конце работы. Не гоняй его итеративно.
4. Упавший тест → **`GetConsoleOutput`** (можно с `pattern` по тексту ошибки и `contextLines`) — читай вывод, не перезапускай.

Правило «один прогон → один отчёт»: `.agents/rules/test-execution.mdc`.

## Тест-таргеты и планы

| Таргет | Тип | Фреймворк | Тест-план |
|---|---|---|---|
| `SwiftUI-SotkaAppTests` | unit, iOS | Swift Testing | `SwiftUI-SotkaAppTests/SwiftUI-SotkaAppTests.xctestplan` |
| `SwiftUI-SotkaAppUITests` | UI, iOS | XCTest | `SwiftUI-SotkaAppUITests/SwiftUI-SotkaAppUITests.xctestplan` |
| `SotkaWatch Watch AppTests` | unit, watchOS | Swift Testing | `SotkaWatch Watch AppTests/SotkaWatch-UnitTests.xctestplan` |

## Фоллбек: make

Когда xcode MCP недоступен или упал:

- `make test` — все iOS unit-тесты, назначение из `IOS_SIM_DEST` (по умолчанию iPhone 18 Pro).
- `make test_watch` — watchOS unit-тесты на симуляторе из `WATCH_SIM_DEST`; нужен свой тест-план `SotkaWatch-UnitTests`. Запускать только при изменениях watch-таргета.

Не хардкодь имена симуляторов в командах — используй переменные Makefile или дай xcode MCP выбрать назначение самому. Полный вывод, если make-вывод обрезан rtk: `rtk proxy <cmd>`.

## Что запускать когда

| Ситуация | Действие |
|---|---|
| Проверка одного теста после правки | `RunSomeTests` по его идентификатору |
| Разбор падения | `GetConsoleOutput` → чтение, без перезапуска |
| Готовая пачка правок | Один `RunAllTests` (или `make test`), один отчёт |
| Изменения в watch-таргете | `make test_watch` |
| Изменения UI-флоу | UI-тесты: XCTest, приложение запускается с аргументом `UITest` |
