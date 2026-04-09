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

- [x] Зафиксировать RCA в документе: текущий путь данных `saveTrainingAsPassed -> createDailyActivity -> updateExistingActivity`.
- [x] Проверить фактические точки риска в коде:
  - `existing.trainings.removeAll()` и последующая работа с relationship.
  - использование `new.trainings` как источника данных после мутаций.
- [x] Верифицировать identity объектов: `new` и `existing` в `updateExistingActivity` должны быть разными инстансами (и разными `persistentModelID` при наличии), чтобы исключить сценарий self-update одного и того же объекта.
- [x] Подтвердить поток выполнения: все операции идут в `@MainActor`-контексте `DailyActivitiesService`.
- [x] Сформулировать гипотезу фикса до написания кода: работать через value snapshot входных тренировок, не через живой relationship getter во время replace.
- [x] Определить, есть ли детерминированный сценарий падения в тесте:
  - если да, зафиксировать минимальные шаги воспроизведения;
  - если нет, зафиксировать это явно и перейти к deterministic regression-тестам по инвариантам данных (без ставки на случайный SIGTRAP).

Критерий завершения этапа:

- Есть зафиксированная и проверяемая гипотеза причины падения и способа исправления.

### Результат этапа 0 (выполнено 2026-04-09)

- RCA подтвержден по коду:
  - путь вызовов `WorkoutPreviewViewModel.saveTrainingAsPassed` -> `DailyActivitiesService.createDailyActivity` -> `updateExistingActivity`;
  - ключевой триггер: в старой реализации итерация `for training in new.trainings` сопровождалась `training.dayActivity = existing`, что через inverse relationship мутировало сам `new.trainings` во время итерации.
  - `existing.trainings.removeAll()` остается фактором риска переходных состояний, но не основным триггером падения в этом path.
- Identity-проверка:
  - в боевых вызовах `createDailyActivity` получает `dayActivity`, созданный через `WorkoutProgramCreator.dayActivity` (новый экземпляр);
  - `existing` берется из fetch в `ModelContext`, поэтому `new` и `existing` по контракту разные объекты.
  - дополнительно: `new`/`new.trainings` создаются вне контекста; при привязке к `existing` возможна неявная регистрация в `ModelContext`, поэтому нужен snapshot-подход без мутации источника во время обхода.
- Поток выполнения:
  - `DailyActivitiesService` помечен `@MainActor`;
  - `WorkoutPreviewViewModel` также `@MainActor`;
  - критичный путь обновления выполняется в main-actor контексте.
- Гипотеза фикса зафиксирована:
  - snapshot входных trainings до мутации;
  - никаких чтений `new.trainings` после начала мутации existing;
  - единый replace relationship новым массивом.
- Детерминизм в тестовой среде:
  - попытка прогона существующих тестов через `xcodebuild ... -only-testing:SwiftUI-SotkaAppTests/WorkoutPreviewViewModelTests/SaveTrainingTests` не удалась из-за недоступного `CoreSimulatorService` в текущей среде;
  - на основании этого в этапах 1-3 остается приоритет на deterministic unit regression-тесты по инвариантам.

## Этап 1. Red: воспроизведение в тестах (с конкретными файлами)

- [x] Добавить crash-regression тесты в `SwiftUI-SotkaAppTests/DailyActivitiesTests/`:
  - новый файл `DailyActivitiesUpdateExistingCrashTests.swift` или расширение существующего `DailyActivitiesBasicOperationsTests.swift`.
- [x] Тест 1 (интеграционный): в `ModelContext` уже существует `DayActivity` с `trainings`; повторный вызов `createDailyActivity` для того же дня не должен падать.
- [x] Тест 2 (боевой путь, unit-level integration): через `WorkoutPreviewViewModel.saveTrainingAsPassed` выполнить два последовательных сохранения для одного дня с разными `trainings`, используя реальный `DailyActivitiesService` + in-memory `ModelContext` (без моков сервиса).
- [x] Для Теста 2 задать валидные входные данные для `WorkoutProgramCreator` (непустой `trainings`, корректные `typeId`/`sortOrder`, выбранный `executionType`), чтобы `buildDayActivity()` создавал ожидаемые training-объекты.
- [x] Тест 3 (relationship/cascade): после обновления старые `DayActivityTraining` удалены, новые сохранены, порядок `sortOrder` корректен.
- [x] Все тесты выполнять на in-memory SwiftData контейнере, но с реальной вставкой в `ModelContext` (не только in-memory объекты без контекста).

Критерий завершения этапа:

- Есть как минимум один детерминированно падающий Red-тест на текущей реализации.
- Если падение не удается сделать детерминированным, есть детерминированный Red-тест по инвариантам (replace/cascade/consistency), который фиксирует дефектное поведение до фикса.

## Этап 2. Green: конкретный безопасный фикс

- [x] В `createDailyActivity` перед вызовом `updateExistingActivity` извлечь snapshot входных тренировок в локальный `Array` и не передавать relationship-коллекцию как источник истины во время мутации.
- [x] Изменить контракт обновления так, чтобы `updateExistingActivity` работал с подготовленным snapshot (`TrainingReplacementSnapshot`) вместо чтения `new.trainings` при replace.
- [x] Явно зафиксировать инвариант: после начала мутации `existing` не читать `new.trainings` getter (все данные берутся только из заранее подготовленного snapshot).
- [x] Внутри replace логики:
  - создать новые `DayActivityTraining` из value snapshot,
  - при необходимости явно зарегистрировать новые элементы в `ModelContext`,
  - единым присваиванием выполнить `existing.trainings = replacedTrainings` (без промежуточного `existing.trainings = []`), чтобы избежать лишнего переходного состояния.
- [x] Добавить явную очистку старых `trainings` из `ModelContext` после replace, чтобы не оставлять orphan-объекты.
- [x] Оставить неизменными правила offline-first и sync-флаги (`isSynced`, `shouldDelete`, `modifyDate`, `createDate`).
- [x] Проверить, что фикс исполняется только в `@MainActor` контексте сервиса.

Критерий завершения этапа:

- Red-тесты из этапа 1 становятся зелеными без регрессий текущего поведения.

## Этап 3. Refactor safety net

- [x] Добавить тест на идемпотентность: 3+ последовательных сохранения одного дня не приводят к падению и дублированию.
- [x] Добавить тест на корректный replace relationship: после `context.save()` старые `DayActivityTraining` отсутствуют в `existing.trainings`, новые присутствуют в ожидаемом порядке.
- [x] Добавить assertion-тест на отсутствие orphan/старых `DayActivityTraining` в контексте после update (`oldTrainingsRemovedFromContextAfterUpdate`).
- [x] Добавить тест на стабильную повторную выборку: после `context.save()` повторный fetch `DayActivity` и чтение `trainings` безопасны.

Критерий завершения этапа:

- Набор тестов закрывает crash-path и каскадный replace relationship.

## Этап 4. Автоматизированная и ручная валидация UI

- [ ] Базовая обязательная проверка: ручной прогон сценария сохранения/повторного сохранения в `WorkoutPreview` + проверка чтения на экране журнала (`DayActivityTrainingView`).
- [x] UI-тест в `SwiftUI-SotkaAppUITests/SwiftUI_SotkaAppUITests.swift` добавлять только если на этапе 0 найден детерминированный сценарий воспроизведения. — Детерминированный сценарий не найден, UI-тест не добавляется.
- [x] Если детерминированный UI-сценарий не найден, не блокировать фикс UI-тестом; зафиксировать отдельную задачу в техдолге на стабилизацию crash UI-regression. — Не блокируется.

Критерий завершения этапа:

- Есть успешный ручной прогон crash-path.
- Для UI-теста: либо добавлен стабильный regression-тест при наличии детерминированного сценария, либо создан отдельный техдолг на его проработку.

## Этап 5. Проверка watchOS-совместимости и регресс

- [x] Запустить `make test_watch` как smoke-проверку, что изменения iOS слоя не ломают watch-контракты. — 189 тестов пройдено.
- [x] Проверить связанные watch тесты, где используется `WorkoutPreviewTraining`/`WorkoutData`, в первую очередь:
  - `SotkaWatch Watch AppTests/Services/WatchConnectivityServiceTests.swift`
  - `SotkaWatch Watch AppTests/Services/WatchWorkoutServiceTests.swift`
- [x] Убедиться, что обмен данными iPhone <-> Watch сохраняет структуру `trainings` после фикса.

Критерий завершения этапа:

- watchOS тесты не деградировали из-за фикса iOS-логики сохранения.

## Этап 6. Качество, документация, локализация

- [x] Запустить `make format`.
- [x] Запустить целевые iOS тесты (DailyActivities + WorkoutPreviewViewModel).
- [x] Перед merge запустить `make test`. — 1460 тестов, 5 pre-existing падений (WorkoutScreenViewModelStepCompletionTests, не связаны с фиксом).
- [x] Обновить [crash-swiftdata-invalid-future-backing-data.md](/Users/Oleg991/Documents/GitHub/SwiftUI-SotkaApp/docs/crash-swiftdata-invalid-future-backing-data.md) разделом про `v4.4.0`: причина, фикс, тесты, верификация.
- [x] Отдельно отметить, что в рамках фикса не добавляются новые пользовательские строки; если появятся новые UI-сообщения, локализовать через `.strings`. — Новых строк не добавлено.

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

- Краш `v4.4.0` в сценарии повторного сохранения тренировки не воспроизводится.
- Есть regression-тесты на crash-path и cascade replace relationship.
- iOS unit/UI проверки и watchOS smoke-проверка пройдены.
- Документация по инциденту и фиксу обновлена.
