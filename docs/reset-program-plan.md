# План реализации функционала сброса программы

## Обзор

Добавление функциональности сброса программы для начала прохождения заново. При сбросе удаляются все данные дневника тренировок, прогресс, и программа начинается с первого дня. Функционал должен работать как в офлайн, так и в онлайн режиме, с синхронизацией на сервер при наличии интернета.

## Архитектурные решения

### API интеграция
- **Использование существующего API**: `StatusClient.start(date:)` - метод реализован в `SWClient` через протокол `StatusClient`
- **Endpoint**: `POST 100/start` (тот же endpoint, что используется для старта программы)
- **Примечание**: На сервере при вызове `100/start` автоматически удаляются все записи `StoStatistics`, `StoDay` и `StoProgress` для пользователя

### Сервис сброса ✅
- **StatusManager.resetProgram(client:context:)** - реализован async метод
- **Логика**:
  - Удаление всех `DayActivity` и `UserProgress` через отношения пользователя (`user.dayActivities`, `user.progressResults`)
  - `DayActivityTraining` удаляются автоматически через каскад
  - Очистка данных инфопостов в User (избранные, прочитанные дни)
  - Сохранение `CustomExercise` и `User`
  - Вызов `await startNewRun(client:appDate:)` для установки новой даты старта
  - Обновление `currentDayCalculator` и установка `state = .idle`
  - Обработка ошибок с логированием через OSLog

### Тестирование ✅
- Реализовано 12 unit-тестов в `StatusManagerResetProgramTests.swift`
- Покрыты все сценарии: офлайн режим, синхронизация с сервером, ошибки API, каскадное удаление, сохранение данных
- Проверяется удаление через отношения пользователя и через `FetchDescriptor`

## Оставшиеся задачи

### Итерация 1.3: Исправление MockExerciseClient для тестов ✅
- [x] Создан отдельный `MockExerciseClient` с `MockError` в extension, обновлены тесты

### Итерация 2: UI компоненты

#### Шаг 2.1: Добавление локализации
- [ ] Добавить ключи локализации в `Localizable.xcstrings`:
  - `MoreScreen.ResetProgramSection` - "Начать с нуля"
  - `MoreScreen.ResetProgramButton` - "Сбросить всё"
  - `MoreScreen.ResetProgramDialogTitle` - "Сброс прохождения программы"
  - `MoreScreen.ResetProgramDialogMessage` - "Дневник тренировок будет удалён, тренировки начнутся с первого дня. Это действие нельзя отменить."
  - `MoreScreen.ResetProgramDialogConfirm` - "Сбросить"
  - `MoreScreen.ResetProgramDialogCancel` - "Отмена"

#### Шаг 2.2: Добавление секции на MoreScreen
- [ ] Добавить новую секцию `Section(.resetProgram)` в `MoreScreen.swift` после `.settings` и перед `.aboutApp`
- [ ] Добавить кнопку с текстом из локализации, которая устанавливает `showResetDialog = true`

#### Шаг 2.3: Реализация confirmationDialog
- [ ] Добавить `@State private var showResetDialog = false` в `MoreScreen`
- [ ] Добавить `@Environment(StatusManager.self)`, `@Environment(AuthHelperImp.self)` и `@Environment(\.modelContext)` в `MoreScreen`
- [ ] Добавить `confirmationDialog` модификатор к List с локализованными ключами
- [ ] При подтверждении вызвать `Task { 
      let client = SWClient(with: authHelper)
      await statusManager.resetProgram(client: client, context: modelContext) 
    }`

## Детали реализации

### Реализованный функционал ✅

**Метод**: `StatusManager.resetProgram(client: StatusClient, context: ModelContext) async`

**Логика**:
- Удаление всех `DayActivity` и `UserProgress` через отношения пользователя
- `DayActivityTraining` удаляются автоматически через каскад
- Очистка данных инфопостов в User (избранные, прочитанные дни)
- Сохранение `CustomExercise` и `User`
- Вызов `await startNewRun(client:appDate:)` для установки новой даты старта
- Обработка ошибок с логированием через OSLog

**API**: Использует `StatusClient.start(date:)` (endpoint `POST 100/start`), на сервере автоматически удаляются все записи тренировок и прогресса для пользователя.

## Примечания

1. **Офлайн-приоритет**: Сброс работает даже без интернета. Если API запрос не удался, локальный сброс продолжается с `startDate = Date.now`.
2. **Безопасность**: Диалог подтверждения обязателен, так как действие необратимо.
3. **Локализация**: Все строки должны быть локализованы через ключи в `Localizable.xcstrings` (см. Итерация 2.1).
4. **Форматирование**: После каждого шага запускать `make format` для форматирования кода.

