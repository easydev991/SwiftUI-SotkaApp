# План: Использование данных предыдущей тренировки для новой тренировки

## Описание задачи

При создании новой тренировки данные должны подставляться из последней пройденной тренировки, а не рассчитываться по дню программы.

## Текущий статус

**Этап 1:** ✅ Выполнено (2026-03-07)
**Этап 2:** ✅ Выполнено (2026-03-07)
**Этап 3:** ✅ Выполнено (2026-03-07)
**Этап 4:** ⏳ Требуется реализация

---

## Требования

### Бизнес-логика (обновлено)

1. **Поиск предыдущей тренировки**:
   - Искать по **дате создания** (`createDate`), а не по номеру дня
   - Самая недавняя пройденная тренировка (с `count != nil`)
   - **Исключить turbo-тренировки** из поиска

2. **Подставляемые данные**:
   - `plannedCount` — количество кругов/подходов
   - `executionType` — тип выполнения (cycles/sets)
   - `trainings` — повторы для **каждого упражнения** отдельно

3. **Приоритет значений**:
   - Для `plannedCount`: `count` (фактическое) → `plannedCount` (плановое)
   - Для упражнений: `count` (фактическое) → дефолт по дню

4. **Fallback**: если предыдущая тренировка не найдена — использовать текущую логику (расчет по дню)

### Критерии приемки

- [x] ~~При создании новой тренировки `plannedCount` берется из последней пройденной тренировки~~
- [x] Поиск предыдущей тренировки по **дате создания** (createDate DESC)
- [x] **Исключение turbo-тренировок** из поиска
- [x] Подстановка `plannedCount` из предыдущей тренировки
- [x] Подстановка `executionType` из предыдущей тренировки
- [x] Подстановка повторов для **каждого упражнения** отдельно
- [x] Приоритет: `count` → `plannedCount` для `plannedCount`
- [x] Приоритет: `count` → дефолт для упражнений
- [x] Если нет предыдущей пройденной тренировки — используется дефолтное значение по дню
- [x] Существующие активности не изменяются (только новые тренировки)
- [x] Добавлено логирование для отладки
- [x] Написаны unit-тесты

---

## Этап 1: Domain Layer — Поиск предыдущей тренировки ✅

### 1.1. Обновить метод поиска в DailyActivitiesService ✅

**Файл**: `SwiftUI-SotkaApp/Services/DailyActivitiesService.swift`

**Выполнено:**

1. ✅ Переименован метод: `getLastPassedWorkoutActivity` → `getLastPassedNonTurboWorkoutActivity`
2. ✅ Изменена сортировка: `day` DESC → `createDate` DESC
3. ✅ Добавлен фильтр: исключить `executionType == turbo`

**Предикат:**

```swift
let predicate = #Predicate<DayActivity> { activity in
    activity.activityTypeRaw == workoutTypeRaw &&
        activity.count != nil &&
        !activity.shouldDelete &&
        (activity.executeTypeRaw == nil || activity.executeTypeRaw != turboTypeRaw)
}
```

**Сортировка:**

```swift
sortBy: [SortDescriptor(\.createDate, order: .reverse)]
```

---

## Этап 2: Data Layer — Подстановка данных ✅

### 2.1. Создать метод `withData(from:)` в WorkoutProgramCreator ✅

**Файл**: `SwiftUI-SotkaApp/Services/WorkoutProgramCreator+DayActivity.swift`

**Метод:**

```swift
func withData(from previousActivity: DayActivity) -> WorkoutProgramCreator
```

**Функциональность:**

- ✅ Подставляет `plannedCount` (приоритет `count` над `plannedCount`)
- ✅ Подставляет `executionType` из предыдущей тренировки
- ✅ Подставляет повторы для каждого упражнения по `typeId` или `customTypeId`

### 2.2. Обновить StatusManager.handleGetWorkoutDataCommand ✅

**Файл**: `SwiftUI-SotkaApp/Services/StatusManager.swift`

**Изменения:**

```swift
let baseCreator = WorkoutProgramCreator(day: day)
let lastWorkout = dailyActivitiesService.getLastPassedNonTurboWorkoutActivity(context: context)
let creator: WorkoutProgramCreator

if let lastWorkout {
    creator = baseCreator.withData(from: lastWorkout)
} else {
    creator = baseCreator
}
```

### 2.3. Обновить WorkoutPreviewViewModel.updateData ✅

**Файл**: `SwiftUI-SotkaApp/Screens/WorkoutPreview/WorkoutPreviewViewModel.swift`

**Изменения:**

```swift
let baseCreator = WorkoutProgramCreator(day: dayNumber)
let lastWorkout = activitiesService.getLastPassedNonTurboWorkoutActivity(context: modelContext)

if let lastWorkout {
    creator = baseCreator.withData(from: lastWorkout)
} else {
    creator = baseCreator
}
```

---

## Этап 3: Тестирование ✅

### 3.1. Unit-тесты для DailyActivitiesService ✅

**Файл**: `SwiftUI-SotkaAppTests/DailyActivitiesTests/GetLastPassedNonTurboWorkoutTests.swift`

**Тесты (9):**

- ✅ Сортировка по `createDate`
- ✅ Исключение turbo-тренировок
- ✅ Возврат самой недавней по дате

### 3.2. Integration-тесты для StatusManager ✅

**Файл**: `SwiftUI-SotkaAppTests/StatusManagerTests/StatusManagerWorkoutDataPreviousWorkoutTests.swift`

**Тесты (10):**

- ✅ Подстановка `plannedCount` из предыдущей тренировки
- ✅ Приоритет `count` над `plannedCount`
- ✅ Fallback на дефолт
- ✅ Подстановка `executionType`
- ✅ Подстановка повторов для каждого упражнения
- ✅ Приоритет `count` над дефолтом для упражнений

### 3.3. Тесты для WorkoutProgramCreator.withData(from:) ✅

**Файл**: `SwiftUI-SotkaAppTests/WorkoutProgramCreatorTests/WorkoutProgramCreatorWithPreviousDataTests.swift`

**Тесты (10):**

- ✅ Подстановка `plannedCount` из `count`
- ✅ Подстановка `plannedCount` из `plannedCount` (если `count` нет)
- ✅ Подстановка `executionType`
- ✅ Подстановка повторов для каждого упражнения
- ✅ Сопоставление по `typeId` и `customTypeId`
- ✅ Fallback на дефолт

---

## Этап 3.1: Исправление SwiftData в тестах ✅

### Проблема

В `WorkoutProgramCreatorWithPreviousDataTests.swift` объекты `DayActivityTraining` создаются без вставки в `ModelContext`, что приводит к ошибке:

```
Fatal error: This model instance was invalidated because its backing data could no longer be found the store.
```

### Решение ✅

Переписать тесты с использованием `ModelContainer` и `ModelContext`:

1. ✅ Создать `ModelContainer` с `DayActivity`, `DayActivityTraining`, `User`
2. ✅ Вставлять все объекты в `context`
3. ✅ Вызывать `context.save()` перед использованием

**Файл**: `SwiftUI-SotkaAppTests/WorkoutProgramCreatorTests/WorkoutProgramCreatorWithPreviousDataTests.swift`

**Результат**: 29 тестов прошли успешно (10 + 10 + 9)

---

## Этап 4: Документация ⏳

### 4.1. Обновить документацию

**Файл**: `docs/workout-preview-screen.md`

**Задачи:**

- [ ] Описать полную логику подстановки данных
- [ ] Указать исключение turbo-тренировок
- [ ] Документировать подстановку для каждого упражнения

---

## Зависимости между этапами

```
✅ Этап 1.1 (DailyActivitiesService) - ЗАВЕРШЕН
    ↓
✅ Этап 2.1 (WorkoutProgramCreator.withData) - ЗАВЕРШЕН
    ↓
✅ Этап 2.2 (StatusManager) - ЗАВЕРШЕН
    ↓
✅ Этап 2.3 (WorkoutPreviewViewModel) - ЗАВЕРШЕН
    ↓
✅ Этап 3.1 (Исправление SwiftData в тестах) - ЗАВЕРШЕН
    ↓
✅ Этап 3.2-3.3 (Остальные тесты) - ЗАВЕРШЕН
    ↓
⏳ Этап 4.1 (Документация)
```

---

## Оценка трудозатрат

| Этап | Оценка | Факт |
|------|--------|------|
| Этап 1.1 | 1 час | 1 час |
| Этап 2.1-2.3 | 2-3 часа | 2 часа |
| Этап 3.1-3.3 | 2-3 часа | 2 часа |
| Этап 4.1 | 30 мин | - |
| **Итого** | **5-7 часов** | **~5 часов** |

---

## Риски и митигация

### Риск 1: Средний - Несовпадение упражнений ✅ РЕШЕНО

**Проблема**: В предыдущей тренировке могут быть другие упражнения (другой день программы)

**Митигация**: Подставлять повторы только для совпадающих `typeId`, остальные — дефолт

### Риск 2: Низкий - Нет предыдущей non-turbo тренировки ✅ РЕШЕНО

**Проблема**: Пользователь прошёл только turbo-тренировки

**Митигация**: Fallback на дефолтные значения по дню

### Риск 3: Низкий - Изменение поведения для пользователей ✅ РЕШЕНО

**Митигация**: Это желаемое поведение; fallback обеспечивает обратную совместимость

---

## Rollback план

### Частичный откат (к текущему состоянию)

1. Вернуть сортировку по `day` DESC в `getLastPassedWorkoutActivity`
2. Удалить метод `withData(from:)` из `WorkoutProgramCreator+DayActivity.swift`
3. Вернуть использование `withPlannedCount` в `StatusManager` и `WorkoutPreviewViewModel`

---

## Известные баги 🔴

### ~~Баг 1: Поиск предыдущей тренировки не находит последнюю по дате~~ ✅ ИСПРАВЛЕНО

**Приоритет:** Высокий

**Описание:**
При создании новой тренировки для дня 27 система находит день 19 как "последнюю пройденную тренировку", хотя была сохранена тренировка для дня 24 (с count=8).

**Логи:**

```
// После сохранения тренировки дня 24:
Тренировка для дня 24 сохранена

// При создании тренировки дня 27:
Найдена последняя пройденная тренировка (не turbo): день 19, count=8
```

**Ожидаемое поведение:**
Метод `getLastPassedNonTurboWorkoutActivity` должен возвращать тренировку с самой поздней датой изменения (`modifyDate`), то есть день 24.

**Причина:**
Сортировка производилась по `createDate`, но при обновлении существующей активности (через `updateExistingActivity`) поле `createDate` не изменяется — обновляется только `modifyDate`. Если активность была создана ранее при планировании, а потом обновлена при сохранении результатов — `createDate` остаётся старым.

**Решение:**
Изменена сортировка с `createDate` на `modifyDate` в методе `getLastPassedNonTurboWorkoutActivity`:

```swift
// Было:
sortBy: [SortDescriptor(\.createDate, order: .reverse)]

// Стало:
sortBy: [SortDescriptor(\.modifyDate, order: .reverse)]
```

**Файлы:**

- `SwiftUI-SotkaApp/Services/DailyActivitiesService.swift` — изменена сортировка
- `SwiftUI-SotkaAppTests/DailyActivitiesTests/DailyActivitiesGetLastPassedWorkoutTests.swift` — обновлены тесты

**Статус:** ✅ Исправлено (2026-03-07)

---

### Баг 2: Сброс повторений при переключении режимов на WorkoutPreviewScreen

**Приоритет:** Средний

**Описание:**
На экране `WorkoutPreviewScreen` при переключении между режимами "Круги" и "Подходы" происходит сброс количества повторений для стандартного упражнения (приседания) на значение 6.

**Шаги воспроизведения:**

1. Открыть экран `WorkoutPreviewScreen`
2. Установить количество приседаний = 8
3. Переключиться с "Подходы" на "Круги"
4. Наблюдать: количество приседаний сбросилось на 6

**Ожидаемое поведение:**
Значения повторений должны сохраняться при переключении между режимами выполнения.

**Возможные причины:**

1. При переключении `executionType` происходит пересоздание `trainings` с дефолтными значениями
2. Не сохраняются текущие значения перед переключением режима
3. Проблема в привязке данных (`Binding`) к UI-элементам

**Файлы:**

- `SwiftUI-SotkaApp/Screens/WorkoutPreview/WorkoutPreviewScreen.swift`
- `SwiftUI-SotkaApp/Screens/WorkoutPreview/WorkoutPreviewViewModel.swift`

**Статус:** 🔴 Не начато

---

**Статус задачи:** 🔄 **В РАБОТЕ** (этап 4 - документация)
