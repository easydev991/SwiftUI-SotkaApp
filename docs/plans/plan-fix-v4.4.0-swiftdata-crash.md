# План исправления краша v4.4.0 (SwiftData, `DayActivity.trainings.getter`)

## Контекст инцидента

- Краш наблюдается в версии `4.4.0 (1)` в логах от `2 апреля 2026`.
- Тип: `EXC_BREAKPOINT (SIGTRAP)`, `Triggered by Thread: 0`.
- Повторяющийся стек:
  - `DayActivity.trainings.getter`
  - `DailyActivitiesService.updateExistingActivity(_:with:user:)` (`SwiftUI-SotkaApp/Services/DailyActivitiesService.swift:409-439`)
  - `DailyActivitiesService.createDailyActivity(_:context:)` (`SwiftUI-SotkaApp/Services/DailyActivitiesService.swift:34-59`)
  - `WorkoutPreviewViewModel.saveTrainingAsPassed(...)` (`SwiftUI-SotkaApp/Screens/WorkoutPreview/WorkoutPreviewViewModel.swift:218`)
- Подтвержденный кодом риск:
  - `DayActivity.trainings` объявлен как `@Relationship(deleteRule: .cascade)` в [DayActivity.swift](/Users/Oleg991/Documents/GitHub/SwiftUI-SotkaApp/SwiftUI-SotkaApp/Models/Workout/DayActivity.swift).
  - В `updateExistingActivity` выполняется `existing.trainings.removeAll()`, а затем итерация по `new.trainings` и повторный append в `existing`.

## Цель

- Устранить краш при повторном сохранении тренировки в `WorkoutPreview`.
- Сохранить offline-first контракт: локальное сохранение первым шагом, синк асинхронный и неблокирующий.
- Не допустить регрессий в iOS и watchOS сценариях, связанных с данными тренировки.

## Границы изменений

- Основная зона: [DailyActivitiesService.swift](/Users/Oleg991/Documents/GitHub/SwiftUI-SotkaApp/SwiftUI-SotkaApp/Services/DailyActivitiesService.swift).
- Смежная зона: [WorkoutPreviewViewModel.swift](/Users/Oleg991/Documents/GitHub/SwiftUI-SotkaApp/SwiftUI-SotkaApp/Screens/WorkoutPreview/WorkoutPreviewViewModel.swift) (без изменения бизнес-логики, только при необходимости для безопасной передачи данных).
- Тесты:
  - iOS unit: `SwiftUI-SotkaAppTests/DailyActivitiesTests/*`, `SwiftUI-SotkaAppTests/WorkoutPreviewViewModelTests/*`.
  - iOS UI: `SwiftUI-SotkaAppUITests/SwiftUI_SotkaAppUITests.swift`.
  - watchOS unit smoke: `SotkaWatch Watch AppTests`.
- Без широкого рефакторинга несвязанных модулей.

## Этап 0. Анализ причины до TDD

- [x] Зафиксирован RCA и путь `saveTrainingAsPassed -> createDailyActivity -> updateExistingActivity`.
- [x] Подтверждены ключевые условия: разные инстансы `new/existing`, выполнение в `@MainActor`.
- [x] Зафиксирована гипотеза фикса через snapshot и отсутствие детерминированного сценария (фокус на regression-тестах по инвариантам).

Критерий завершения этапа:

- Есть зафиксированная и проверяемая гипотеза причины падения и способа исправления.

### Результат этапа 0 (выполнено 2026-04-09)

- Подтвержден основной триггер: мутация `new.trainings` через inverse relationship во время итерации.
- Подтвержден рабочий подход фикса: snapshot до мутации и единый replace relationship.
- Детеминированный сценарий не найден, для этапов 1-3 выбран путь regression-тестов по инвариантам.

## Этап 1. Red: воспроизведение в тестах (с конкретными файлами)

- [x] Добавлен набор crash-regression тестов в `DailyActivitiesUpdateExistingCrashTests.swift` (интеграционный путь, боевой путь через ViewModel, replace/cascade и корректный `sortOrder`).

Критерий завершения этапа:

- Есть как минимум один детерминированно падающий Red-тест на текущей реализации.
- Если падение не удается сделать детерминированным, есть детерминированный Red-тест по инвариантам (replace/cascade/consistency), который фиксирует дефектное поведение до фикса.

## Этап 2. Green: конкретный безопасный фикс

- [x] Реализован snapshot-based replace в `createDailyActivity/updateExistingActivity` без чтения `new.trainings` после начала мутации.
- [x] Добавлены создание/регистрация новых trainings и явная очистка старых из `ModelContext` без изменения offline-first контрактов.

Критерий завершения этапа:

- Red-тесты из этапа 1 становятся зелеными без регрессий текущего поведения.

## Этап 3. Refactor safety net

- [x] Добавлены тесты safety net: идемпотентность 3+ сохранений, корректный replace, отсутствие orphan в контексте и стабильный повторный fetch после `context.save()`.

Критерий завершения этапа:

- Набор тестов закрывает crash-path и каскадный replace relationship.

## Этап 4. Автоматизированная и ручная валидация UI

- [x] Базовая обязательная проверка: ручной прогон сценария сохранения/повторного сохранения в `WorkoutPreview` + проверка чтения на экране журнала (`DayActivityTrainingView`).
- [x] Детерминированный UI-сценарий не найден, UI-тест не добавлялся и не блокирует фикс.

Критерий завершения этапа:

- [x] Успешный ручной прогон crash-path (2026-04-10, iOS Simulator).
- Для UI-теста: либо добавлен стабильный regression-тест при наличии детерминированного сценария, либо создан отдельный техдолг на его проработку.

## Этап 5. Проверка watchOS-совместимости и регресс

- [x] Выполнен watchOS smoke/regression: `make test_watch` (189 тестов), деградаций и проблем с `WorkoutPreviewTraining/WorkoutData` не найдено.

Критерий завершения этапа:

- watchOS тесты не деградировали из-за фикса iOS-логики сохранения.

## Этап 6. Качество, документация, локализация

- [x] Выполнены форматирование и целевые iOS тесты, `make test` запущен.
- [x] Стабилизирован и перепроверен `WorkoutScreenViewModelStepCompletionTests`.
- [x] Обновлена документация по инциденту `v4.4.0`; новых пользовательских строк не добавлено.

Критерий завершения этапа:

- Формат и тесты проходят, RCA и верификация зафиксированы в документации.

## Техдолг вне scope фикса

- Оптимизировать поиск существующей активности в `createDailyActivity`: заменить fetch всех `DayActivity` на целевой `FetchDescriptor` с predicate по `day` и `user`.

## Зависимости этапов

- Этап 0 выполняется до написания Red-тестов.
- Этап 1 обязателен перед этапом 2.
- Этап 3 выполняется после прохождения этапа 2.
- Этапы 4-6 выполняются после зеленых unit-тестов.

## Риски и меры

- Риск: фикс уберет краш, но нарушит каскадное поведение relationship.
- Мера: отдельный тест на корректную замену relationship (старые отсутствуют в `existing.trainings`, новые присутствуют в нужном порядке).
- Риск: flaky UI-test даст ложную уверенность.
- Мера: комбинировать UI-test и ручной прогон с логами.
- Риск: скрытая регрессия в watch-цепочке.
- Мера: обязательный `make test_watch` перед завершением задачи.

## Definition of Done

- [x] Краш `v4.4.0` в сценарии повторного сохранения тренировки не воспроизводится.
- [x] Есть regression-тесты на crash-path и cascade replace relationship.
- [x] iOS unit/UI проверки и watchOS smoke-проверка пройдены.
- [x] Документация по инциденту и фиксу обновлена.
- [x] Ручная проверка сценария на `WorkoutPreview`/`Journal` из Этапа 4 выполнена.
