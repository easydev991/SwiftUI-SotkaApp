# План и статус внедрения исправлений timezone-проблемы через TDD

## Актуальный статус (2026-08-01): план закрыт

Sync-слой удалён, сервер `100.workout.su` закрыт, приложение работает офлайн.
Этапы 2.1–2.4 (client-only fix сериализации/декодинга и sync/LWW) утратили смысл,
а их артефакты удалены вместе с sync-слоем:

- `ed82f6e9` (2026-07-25): удалены `ProgressSyncService.swift`, `SyncDateComparisonPolicy.swift`,
  `ProgressSyncServiceTests.swift`, `StatusManagerSyncDateTests.swift` и весь сетевой слой.
- `2555914a` (2026-07-26): удалены пакеты `SWNetwork`/`SWKeychain`, включая
  `JSONDecoder+.swift` (policy `flexibleDateDecoding` по `Europe/Moscow`) и его тесты.
- `DateFormatterService.stringFromFullDate(..., iso: true)` удалён; в `SWUtils`
  остались только `dateFromString` и `dateWithWeekday` (тесты `DateFormatterServiceTests`
  в `SWUtils` покрывают только `dateFromString`).

Единственный живой артефакт плана — hotfix 1.0: `DailyActivitiesService.getLastPassedNonTurboWorkoutActivity`
(day-based выбор предыдущей тренировки) — сохранён и вызывается из
`WorkoutPreviewViewModel.updateData` и `StatusManager.handleGetWorkoutDataCommand`.

## Цель (историческая)

Подготовить безопасное поэтапное исправление проблемы с датами без изменений на сервере:

1. минимально рискованный hotfix для уже выпущенного приложения;
2. полный client-only fix на уровне сериализации, десериализации и sync-логики;
3. обязательный набор тестов, защищающий от регрессий.

## Контекст проблемы (исторический)

- Серверная сторона сохраняла дату в локальной timezone без явного offset, что
  приводило к ложному смещению времени при чтении на клиенте и ложным выигрышам
  в LWW/conflict resolution.
- Источником истины для дат должен был быть абсолютный момент времени (`Date`),
  а не локальное строковое представление.

## Область изменений (актуальная)

- `SwiftUI-SotkaApp/Services/DailyActivitiesService.swift` — живой hotfix 1.0.
- `SwiftUI-SotkaApp/Services/StatusManager.swift` — вызов hotfix 1.0.
- `SwiftUI-SotkaApp/Screens/WorkoutPreview/WorkoutPreviewViewModel.swift` — вызов hotfix 1.0.
- Удалены вместе с sync-слоем: `ProgressSyncService.swift`, `SyncDateComparisonPolicy.swift`,
  `Libraries/SWNetwork/.../JSONDecoder+.swift`, `DateFormatterService.stringFromFullDate`.

---

## Приоритет 1. Минимально рискованный hotfix ✅ ВЫПОЛНЕНО (код жив)

### Подэтап 1.0. Исправить критерий выбора предыдущей сохраненной тренировки ✅ ВЫПОЛНЕНО

- [x] В `DailyActivitiesService.getLastPassedNonTurboWorkoutActivity` добавлен параметр `currentDay`,
  фильтрация по `day < currentDay`, сортировка по `day`; исключены turbo, `shouldDelete`,
  чужие пользователи. Вызовы обновлены в `WorkoutPreviewViewModel.updateData` и
  `StatusManager.handleGetWorkoutDataCommand`.
- [x] Тесты: `WorkoutPreviewViewModelUpdateDataTests` (переработан после удаления sync-слоя;
  покрывает загрузку данных в `updateData`, включая вызов hotfix-логики). Отдельные suites
  `DailyActivitiesGetLastPassedWorkoutTests` и `StatusManagerWorkoutDataPreviousWorkoutTests`
  удалены вместе с sync-тестами.

---

## Приоритет 2. Полный client-only fix ⛔ ЗАКРЫТ (удалён с sync-слоем)

Этапы были реализованы по TDD, затем их артефакты удалены при чистке sync-слоя.

### Подэтап 2.1. Нормализация отправки дат на сервер ⛔ УДАЛЁН

- [x] `DateFormatterService.stringFromFullDate(..., iso: true)` был переведён на UTC перед суффиксом `Z`.
- [x] Метод и тесты (`DateFormatterServiceTests`, `DayRequestTests`, `ExerciseSnapshotTests`,
  `ProgressSyncServiceTests`, `StatusManagerStartNewRunTests`) удалены.

### Подэтап 2.2. Нормализация чтения дат с сервера ⛔ УДАЛЁН

- [x] `JSONDecoder.DateDecodingStrategy.flexibleDateDecoding` интерпретировал timezone-less
  даты по фиксированной policy `Europe/Moscow`.
- [x] Удалён вместе с пакетом `SWNetwork` (`JSONDecoder+.swift`, `JSONDecoderExtensionTests`,
  `DateDecodingRoundTripTests`).

### Подэтап 2.3. Выравнивание sync и LWW-поведения ⛔ УДАЛЁН

- [x] Общая policy `SyncDateComparisonPolicy` использовалась в `DailyActivitiesService`,
  `ProgressSyncService`, `CustomExercisesService`; day-based сравнение start date в `StatusManager`.
- [x] Удалены `SyncDateComparisonPolicy.swift`, `ProgressSyncService.swift` и sync/regression-тесты
  (`ProgressSyncServiceTests`, `StatusManagerSyncDateTests` и др.).

### Подэтап 2.4. Осторожная работа с уже существующими локальными данными ⏳ НЕ ВЫПОЛНЯЛСЯ

- [ ] Repair-логика для исторически повреждённых timestamp не реализована.
- [ ] Стал неактуальным: sync-слой и серверные сравнения удалены, данные локальные
  и одно-пользовательские.

---

## Приоритет 3. Обязательные тесты

### Выжившие

- [x] `WorkoutPreviewViewModelUpdateDataTests` — загрузка данных в `updateData`
  (переработан после удаления sync-слоя).

### Удалены вместе с sync-слоем

- [x] `DailyActivitiesGetLastPassedWorkoutTests`, `StatusManagerWorkoutDataPreviousWorkoutTests`
  (покрытие hotfix 1.0).
- [x] `DateFormatterServiceTests` (UTC serialization), `DayRequestTests`, `ExerciseSnapshotTests`,
  `StatusManagerStartNewRunTests` (wire-format исходящих дат).
- [x] `JSONDecoderExtensionTests`, `DateDecodingRoundTripTests` (входящий парсинг).
- [x] `ProgressSyncServiceTests`, `StatusManagerSyncDateTests` и прочие sync/LWW-тесты.

---

## Что уже реализовано (итог)

- Hotfix выбора предыдущей тренировки (1.0) живёт в коде и вызывается из
  `WorkoutPreviewViewModel.updateData` и `StatusManager.handleGetWorkoutDataCommand`.
- Исходящая UTC-сериализация, декодинг по `Europe/Moscow` и единая sync/LWW-policy были
  реализованы, но удалены вместе с sync-слоем — они больше не нужны офлайн-приложению.

## Что ещё осталось

- Ничего из scope плана: оставшийся пункт 2.4 (data repair) неактуален, т.к. sync
  и серверные сравнения удалены.

## Релизный вывод

- План закрыт. Дальнейшие timezone-исправления не требуются: приложение офлайн,
  единственная day-based логика (hotfix 1.0) сохранена.

## Definition of Done

- [x] Hotfix 1.0: failing tests → минимальное исправление → рефактор выполнены.
- [x] Этапы 2.1–2.3 реализованы по TDD и защищены тестами на момент реализации.
- [ ] Этап 2.4 (data repair) не выполнялся и закрыт как неактуальный.
- [x] Для релиза timezone-fix не требуется data-repair.

---

## Прогресс выполнения

| Подэтап | Статус | Комментарий |
|---------|--------|-------------|
| 1.0 Hotfix (previous workout) | ✅ Живёт в коде | day-based логика + вызовы в `WorkoutPreviewViewModel`/`StatusManager` |
| 2.1 Outgoing dates (UTC) | ⛔ Удалён с sync-слоем | `stringFromFullDate` удалён |
| 2.2 Incoming dates (decoding) | ⛔ Удалён с sync-слоем | `SWNetwork`/`JSONDecoder+` удалены |
| 2.3 Sync/LWW | ⛔ Удалён с sync-слоем | `SyncDateComparisonPolicy`/`ProgressSyncService` удалены |
| 2.4 Data repair | ⏳ Не выполнялся | Неактуален для офлайн-приложения |
