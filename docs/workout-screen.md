# Экран тренировки (Workout Screen)

## Общая информация

Экран тренировки отображает процесс выполнения тренировки с пошаговой навигацией между этапами (разминка, упражнения, заминка). После каждого этапа показывается таймер отдыха. При завершении тренировки данные возвращаются на предыдущий экран через замыкание, где происходит сохранение.

## Структура файлов ✅

```
Screens/
└── Workout/
    ├── WorkoutScreen.swift                    # Основной экран ✅
    ├── WorkoutScreenViewModel.swift          # ViewModel с логикой тренировки ✅
    ├── WorkoutTimerScreen.swift              # Экран таймера отдыха ✅
    └── Views/
        ├── WorkoutRowView.swift              # Компонент строки этапа ✅
        └── CircularTimerView.swift           # Компонент кругового таймера ✅
```

## Модели данных ✅

### WorkoutStep ✅
Существует в `Models/Workout/WorkoutStep.swift`:
- `case warmUp` - разминка
- `case exercise(ExerciseExecutionType, number: Int)` - упражнение (круг/подход) с номером
- `case coolDown` - заминка

### WorkoutState ✅
Существует в `Models/Workout/WorkoutState.swift`:
- `case active` - текущий активный этап
- `case completed` - завершенный этап
- `case inactive` - еще не начатый этап

### WorkoutStepState ✅
Реализовано в `Models/Workout/WorkoutStepState.swift`:
```swift
struct WorkoutStepState: Identifiable {
    let step: WorkoutStep
    var state: WorkoutState
    var id: String { step.id }
}
```

### WorkoutResult ✅
Реализовано в `Models/Workout/WorkoutResult.swift`:
```swift
struct WorkoutResult {
    let count: Int
    let duration: Int?
}
```

## ViewModel: WorkoutScreenViewModel ✅

### Зависимости ✅
ViewModel получает `AppSettings` через параметры методов (не хранит их). Данные тренировки передаются через `setupWorkoutData()`. ViewModel не занимается сохранением - данные возвращаются через замыкание.

### Публичные свойства ✅
- Данные тренировки: `dayNumber`, `executionType`, `trainings`, `plannedCount`, `restTime`
- Состояние: `stepStates`, `currentStepIndex`, `showTimer`
- Вычисляемые: `currentStep`, `isWorkoutCompleted`
- Отслеживание времени: `workoutStartTime`, `totalRestTime`, `currentRestStartTime`

### Методы ✅

#### Инициализация ✅
- `setupWorkoutData(...)` ✅ - настраивает данные тренировки
- `initializeStepStates()` ✅ - инициализирует этапы для `.cycles`, `.sets`, `.turbo`

#### Управление тренировкой ✅
- `completeCurrentStep(appSettings:)` ✅ - завершает этап, показывает таймер (кроме warmUp и перед coolDown)
- `onTimerCompleted(appSettings:)` ✅ - обрабатывает завершение таймера, воспроизводит звук/вибрацию
- `scheduleRestTimerNotification(appSettings:)` ✅ - планирует уведомление
- `cancelRestTimerNotification()` ✅ - отменяет уведомление
- `getWorkoutResult(interrupt: Bool = false) -> WorkoutResult?` ✅ - возвращает результат тренировки (при `interrupt == true` возвращает результат даже для незавершенной тренировки)

#### Вспомогательные методы ✅
- `getStepState(for:)` ✅ - возвращает состояние этапа
- `getExerciseSteps(for:)` ✅ - возвращает подходы для упражнения
- `getCycleSteps()` ✅ - возвращает круги для `.cycles`/`.turbo`
- `getExerciseTitleWithCount(for:modelContext:)` ✅ - название упражнения с количеством

## View: WorkoutScreen ✅

### Структура экрана ✅
Экран отображает список этапов тренировки (разминка, упражнения, заминка) с возможностью завершения каждого этапа. После каждого этапа показывается таймер отдыха (кроме warmUp и перед coolDown).

### Параметры экрана ✅
- `dayNumber: Int` - номер дня программы
- `executionType: ExerciseExecutionType` - тип выполнения тренировки
- `trainings: [WorkoutPreviewTraining]` - список упражнений
- `plannedCount: Int?` - запланированное количество кругов/подходов
- `restTime: Int` - время отдыха между подходами/кругами (в секундах)
- `onWorkoutCompleted: (WorkoutResult) -> Void` ✅ - замыкание для возврата результата тренировки

### Секции экрана ✅
- `exercisesReminderSection` ✅ - список упражнений как напоминалка (только для `.cycles`)
- `warmUpSection` ✅ - этап разминки
- `workoutStepsSection` ✅ - этапы тренировки (круги или подходы)
- `coolDownSection` ✅ - этап заминки с обработкой завершения тренировки

## Тестирование ✅

### Этап 1: Инициализация данных ✅
- `testSetupWorkoutData()` ✅ - настройка данных тренировки (`WorkoutScreenViewModelSetupTests.swift`)

### Этап 2: Инициализация этапов ✅
- `testInitializeStepStatesForCycles()` ✅ - инициализация для `.cycles` (`WorkoutScreenViewModelSetupTests.swift`)
- `testInitializeStepStatesForSets()` ✅ - инициализация для `.sets` (`WorkoutScreenViewModelSetupTests.swift`)
- `testInitializeStepStatesForTurbo()` ✅ - инициализация для `.turbo` (`WorkoutScreenViewModelSetupTests.swift`)

### Этап 3: Завершение этапов ✅
- `testCompleteCurrentStep()` ✅ - завершение этапа с таймером (`WorkoutScreenViewModelStepCompletionTests.swift`)
- `testCompleteCurrentStepForLastStep()` ✅ - завершение последнего этапа (`WorkoutScreenViewModelStepCompletionTests.swift`)
- `testOnTimerCompleted()` ✅ - обработка завершения таймера (`WorkoutScreenViewModelStepCompletionTests.swift`)
- `testCompleteCurrentStepDoesNotShowTimerAfterWarmUp()` ✅ - нет таймера после warmUp
- `testCompleteCurrentStepDoesNotShowTimerBeforeCoolDown()` ✅ - нет таймера перед coolDown
- `testCompleteCurrentStepShowsTimerAfterRegularStep()` ✅ - таймер после обычного этапа

### Этап 4: Завершение тренировки ✅
- Тесты для `getWorkoutResult()` ✅ (`WorkoutScreenViewModelGetWorkoutResultTests.swift`)

### Этап 5: Вспомогательные методы ✅
- `testGetStepState()` ✅ - состояние этапа (`WorkoutScreenViewModelHelperMethodsTests.swift`)
- `testCurrentStep()` ✅ - текущий этап (`WorkoutScreenViewModelHelperMethodsTests.swift`)
- `testGetCycleSteps()` ✅ - круги для `.cycles`/`.turbo` (`WorkoutScreenViewModelHelperMethodsTests.swift`)
- `testGetExerciseSteps()` ✅ - подходы для упражнения (`WorkoutScreenViewModelHelperMethodsTests.swift`)
- `testGetExerciseTitleWithCount()` ✅ - название с количеством (`WorkoutScreenViewModelHelperMethodsTests.swift`)

### Этап 6: Тесты для WorkoutPreviewViewModel ✅
- `canEditComment` ✅ - 3 теста (`WorkoutPreviewViewModelCanEditCommentTests.swift`)
- `shouldShowEditButton` ✅ - 4 теста (`WorkoutPreviewViewModelShouldShowEditButtonTests.swift`)

## Интеграция с другими экранами ✅

### Переход из WorkoutPreviewScreen ✅
Переход к экрану тренировки происходит через навигацию с передачей параметров тренировки.

### Возврат после завершения тренировки ✅
После завершения тренировки данные возвращаются на `WorkoutPreviewScreen` через замыкание `onWorkoutCompleted` с результатом тренировки (`WorkoutResult`). Экран `WorkoutPreviewScreen` обрабатывает результат через `handleWorkoutResult()` и обновляет свое состояние для отображения формы сохранения.

## Принципы реализации

### Разделение ответственности ✅

- **WorkoutScreenViewModel**: Логика тренировки (управление этапами, состояние, завершение). Не занимается сохранением - возвращает результат через замыкание.
- **WorkoutScreen**: Визуальное отображение состояния из ViewModel. Возвращает результат тренировки через замыкание.
- **WorkoutPreviewViewModel**: Сохранение тренировки с данными из результата тренировки (count, duration, comment).
- **WorkoutPreviewScreen**: Отображение формы сохранения после завершения тренировки.

### Офлайн-приоритет

- Все операции сначала сохраняются локально в SwiftData
- Синхронизация с сервером выполняется асинхронно через `DailyActivitiesService`
- Работа без интернета полностью поддерживается

### TDD подход

1. **Красный**: Написать тесты для целевой логики ДО реализации кода
2. **Зеленый**: Реализовать минимальный код для прохождения тестов
3. **Рефакторинг**: Улучшить код после успешных тестов
4. Запускать `make format` и `make test` после каждого этапа

### Логирование

Все логи на русском языке через `OSLog`:
- Загрузка данных с указанием дня и статуса
- Завершение этапов с указанием типа и номера
- Завершение тренировки с указанием дня
- Ошибки валидации при сохранении

## Порядок реализации ✅

### Этап 1: Инициализация данных ✅
- Тесты и логика ViewModel для `setupWorkoutData()` и `initializeStepStates()`

### Этап 2: Завершение этапов ✅
- Тесты и логика ViewModel для `completeCurrentStep()` и `onTimerCompleted()`

### Этап 3: Уведомления таймера отдыха ✅
- Тесты и логика ViewModel для `scheduleRestTimerNotification()` и `cancelRestTimerNotification()`

### Этап 4: Завершение тренировки ✅
- Тесты и логика ViewModel для `getWorkoutResult()`
- Создана модель `WorkoutResult`
- Удален метод `finishWorkout()`

### Этап 5: Вспомогательные методы ✅
- Тесты и логика ViewModel для всех вспомогательных методов

### Этап 6: UI (верстка) ✅
- Реализован `WorkoutScreen` с использованием ViewModel
- Интегрирован `WorkoutTimerScreen`
- Добавлена локализация для уведомления

### Этап 7: Интеграция ✅
- Добавлен переход из `WorkoutPreviewScreen`
- Реализован возврат результата через `onWorkoutCompleted`
- Обновлен `WorkoutPreviewViewModel` с методом `handleWorkoutResult()`
- Обновлен UI `WorkoutPreviewScreen` для обработки результата

### Этап 8: Исправление логики таймера отдыха ✅
- Исправлена логика в `completeCurrentStep`: проверка типа следующего этапа вместо `isLastStep`
- Таймер не показывается после warmUp и перед coolDown
- Добавлены соответствующие тесты

### Этап 9: Исправление проблем с таймером отдыха ⏳

#### Проблема 1: Структура уведомления о завершении отдыха ✅

**Описание:** Уведомление `RestCompleted` не умещается и выделено жирным, так как весь текст находится в `title`. Нужно использовать структуру как в ежедневном уведомлении: заголовок "SOTKA" и тело сообщения с текстом о завершении отдыха.

**Логика звука и вибрации:**
- **Если приложение свернуто** при срабатывании уведомления:
  - Звук: стандартный звук `.default` через уведомление (если `appSettings.playTimerSound == true`)
  - Вибрация: автоматически через уведомление (если звук включен, вибрация происходит автоматически в iOS)
- **Если приложение открыто** и таймер закончился на экране:
  - Звук: выбранный звук из `appSettings.timerSound` через `AudioPlayerManager` (если `appSettings.playTimerSound == true`)
  - Вибрация: через `VibrationService().perform()` (если `appSettings.vibrate == true`)
- **При открытии приложения по нажатию на уведомление**:
  - Звук: НЕ воспроизводить (пользователь уже получил уведомление)
  - Вибрация: НЕ делать (пользователь уже получил уведомление)

**Решение:** ✅ Реализовано
1. ✅ Обновлен `scheduleRestTimerNotification(appSettings:)` в `WorkoutScreenViewModel`:
   - `content.title = String(localized: .notificationDailyWorkoutTitle)` - "SOTKA"
   - `content.body = String(localized: .restCompleted)` - "Отдых завершён - продолжаем!"
   - `content.sound = appSettings.playTimerSound ? .default : nil` - стандартный звук в уведомлении
   - `userInfo = ["type": "restTimer"]`
2. ✅ Обновлена локализация в `Localizable.xcstrings`:
   - Комментарий для `RestCompleted` обновлен: используется как `body`, а не `title`
3. ✅ Обновлен `onTimerCompleted(appSettings:skipSoundAndVibration:)` в `WorkoutScreenViewModel`:
   - Добавлен параметр `skipSoundAndVibration: Bool = false`
   - Используется `guard !skipSoundAndVibration else { return }` для раннего выхода
   - Если `skipSoundAndVibration == false`: воспроизводится звук и вибрация (если включены в настройках)
   - Если `skipSoundAndVibration == true`: звук и вибрация пропускаются

**Тесты:**
- ✅ Проверить структуру уведомления: `title == "SOTKA"`, `body == "Отдых завершён - продолжаем!"`
- ⏳ Проверить, что при завершении таймера на экране воспроизводится выбранный звук и вибрация
- ⏳ Проверить, что при открытии приложения по уведомлению звук и вибрация НЕ воспроизводятся

#### Проблема 2: Закрытие экрана таймера при открытии приложения по уведомлению ✅

**Описание:** Если свернуть приложение и открыть после завершения отдыха, экран таймера все еще показывает обратный отсчет ускоренным темпом. Экран должен закрыться автоматически при открытии приложения по уведомлению. При этом звук и вибрация НЕ должны воспроизводиться (пользователь уже получил уведомление).

**Решение:** ✅ Реализовано
1. ✅ Добавлен метод `checkAndHandleExpiredRestTimer(appSettings:)` в `WorkoutScreenViewModel`:
   - Проверяет, что `showTimer == true` и `currentRestStartTime != nil`
   - Вычисляет прошедшее время: `Date().timeIntervalSince(restStartTime) >= restTime`
   - Если таймер истек, вызывает `onTimerCompleted(appSettings: skipSoundAndVibration: true)`
   - Это закрывает экран таймера и обновляет состояние, но пропускает звук и вибрацию
2. ✅ Добавлена обработка `scenePhase` в `WorkoutScreen`:
   - Отслеживается `scenePhase` через `.onChange(of: scenePhase)`
   - При `scenePhase == .active` и если `viewModel.showTimer == true`, вызывается `viewModel.checkAndHandleExpiredRestTimer(appSettings:)`

**Тесты:** ✅ Реализовано
- ✅ `checkAndHandleExpiredRestTimerWhenTimerNotShowing` - метод ничего не делает, если таймер не показывается
- ✅ `checkAndHandleExpiredRestTimerWhenRestStartTimeIsNil` - метод ничего не делает, если время начала отдыха не установлено
- ✅ `checkAndHandleExpiredRestTimerWhenTimerNotExpired` - метод ничего не делает, если таймер еще не истек
- ✅ `checkAndHandleExpiredRestTimerWhenTimerExpired` - метод закрывает таймер и обновляет состояние, если таймер истек
- ✅ `checkAndHandleExpiredRestTimerExactlyAtExpiration` - метод закрывает таймер точно в момент истечения

#### Проблема 3: Ускоренная анимация таймера при сворачивании/разворачивании ⏳

**Описание:** При сворачивании приложения на экране `WorkoutTimerScreen` и последующем разворачивании таймер ведет себя неправильно - начинает ускоренно отрабатывать анимацию.

**Причина:** `Timer.publish` продолжает работать в фоне, но обновления UI накапливаются. При разворачивании все накопленные обновления применяются сразу, что вызывает ускоренную анимацию.

**Решение:**
1. В `WorkoutTimerScreen`:
   - Вместо уменьшения `remainingSeconds` каждую секунду использовать вычисление на основе времени начала
   - Добавить `@State private var startTime: Date`
   - Вычислять `remainingSeconds` как `max(0, duration - Int(Date().timeIntervalSince(startTime)))`
   - Отслеживать `scenePhase` для паузы/возобновления таймера
2. Обновить `CircularTimerView`:
   - Убрать `.animation(.linear(duration: 1.0), value: remainingSeconds)` или использовать более точную анимацию
   - Использовать `withAnimation` только при реальном изменении значения
3. Альтернативный подход:
   - Использовать `Task` с `try await Task.sleep(nanoseconds:)` вместо `Timer.publish`
   - Отслеживать `scenePhase` и приостанавливать таймер при сворачивании

**Тесты:**
- Симулировать сворачивание приложения на 10 секунд при таймере 60 секунд
- Проверить, что при разворачивании таймер показывает корректное оставшееся время (50 секунд)
- Проверить, что анимация не ускоряется
- Проверить, что таймер корректно завершается при достижении 0

**Порядок реализации:**
1. Этап 9.1: Исправление структуры уведомления (Проблема 1)
2. Этап 9.2: Исправление логики таймера с использованием времени (Проблема 3)
3. Этап 9.3: Обработка открытия приложения по уведомлению (Проблема 2)

### Этап 10: Добавление функции остановки тренировки ⏳

#### Описание
Добавление возможности прервать тренировку в любой момент с подтверждением через диалог. При прерывании тренировки данные передаются через замыкание `onWorkoutCompleted`, но если `count == 0`, то в `WorkoutPreviewViewModel` не устанавливается `isWorkoutCompleted`, чтобы пользователь мог снова начать тренировку.

#### Локализация
Добавить ключи локализации в `Localizable.xcstrings`:
- `"WorkoutScreen.StopWorkout.Button"` - рус: "Прервать тренировку", англ: "Stop Workout"
- `"WorkoutScreen.StopWorkout.Title"` - рус: "Прервать тренировку", англ: "Stop Workout"
- `"WorkoutScreen.StopWorkout.Message"` - рус: "Вы уверены, что хотите прервать тренировку?", англ: "Are you sure you want to stop the workout?"
- `"WorkoutScreen.StopWorkout.ConfirmButton"` - рус: "Завершить", англ: "Finish"

#### ViewModel: WorkoutScreenViewModel

**Изменения в методе `getWorkoutResult()`:**
- Добавить параметр `interrupt: Bool = false` в метод `getWorkoutResult(interrupt:) -> WorkoutResult?`
- Если `interrupt == true`:
  - Не проверять `isWorkoutCompleted` (пропустить проверку)
  - Подсчитывать только завершенные упражнения (этапы с `state == .completed` и `step == .exercise`)
  - Вычислять длительность тренировки (если `workoutStartTime` установлен)
  - Возвращать `WorkoutResult` даже если тренировка не завершена полностью
- Если `interrupt == false` (по умолчанию):
  - Работать как раньше: проверять `isWorkoutCompleted`, возвращать `nil` если тренировка не завершена

**Тесты (TDD - сначала тесты):**
- `testGetWorkoutResultWithInterruptWhenNoExercisesCompleted()` - пользователь начал выполнять первый круг/подход, но не нажал "готово" → `count == 0` при `interrupt == true`
- `testGetWorkoutResultWithInterruptWhenSomeExercisesCompleted()` - пользователь выполнил несколько кругов/подходов и прервал → `count` равен количеству выполненных упражнений при `interrupt == true`
- `testGetWorkoutResultWithInterruptWithDuration()` - проверка вычисления длительности при прерывании (`interrupt == true`)
- `testGetWorkoutResultWithInterruptWithoutStartTime()` - проверка, что `duration == nil`, если `workoutStartTime` не установлен при `interrupt == true`
- `testGetWorkoutResultWithoutInterruptStillWorksAsBefore()` - проверка, что при `interrupt == false` метод работает как раньше (возвращает `nil` для незавершенной тренировки)

**Реализация:**
- Доработать метод `getWorkoutResult(interrupt:)` согласно тестам
- При `interrupt == true` фильтровать `stepStates` по `.exercise` и считать только те, у которых `state == .completed`
- Вычислять длительность аналогично текущей логике, но без проверки `isWorkoutCompleted`

#### View: WorkoutScreen

**Изменения:**
- Добавить кнопку "Прервать тренировку" внизу экрана (после всех секций в `List`)
- Стиль кнопки: `SWButtonStyle(mode: .tinted, size: .large)` (как у кнопки завершения отдыха в `WorkoutTimerScreen`)
- Добавить `@State private var showStopWorkoutConfirmation = false`
- Добавить модификатор `.confirmationDialog` к кнопке с:
  - `title`: `"WorkoutScreen.StopWorkout.Title"`
  - `message`: `"WorkoutScreen.StopWorkout.Message"`
  - Кнопка подтверждения: `"WorkoutScreen.StopWorkout.ConfirmButton"` с действием:
    - Вызвать `viewModel.getWorkoutResult(interrupt: true)`
    - Если результат не `nil`, передать его через `onWorkoutCompleted(result)`
    - Вызвать `dismiss()`
    - Отменить уведомление о таймере отдыха: `viewModel.cancelRestTimerNotification()`
  - Кнопка отмены добавляется системой автоматически

#### ViewModel: WorkoutPreviewViewModel

**Изменения в методе `handleWorkoutResult()`:**
- Добавить проверку: если `result.count == 0`, не устанавливать `isWorkoutCompleted` и не обновлять `count`/`workoutDuration`
- Это позволит пользователю снова начать тренировку по обычной кнопке "Начать тренировку"
- Если `result.count > 0`, выполнять текущую логику (устанавливать `isWorkoutCompleted`, обновлять `count` и `workoutDuration`)

**Тесты (TDD - сначала тесты):**
- `testHandleWorkoutResultWithZeroCount()` - при `count == 0` не устанавливается `isWorkoutCompleted`, `count` и `workoutDuration` не обновляются
- `testHandleWorkoutResultWithPositiveCount()` - при `count > 0` устанавливается `isWorkoutCompleted`, обновляются `count` и `workoutDuration`

**Реализация:**
- Доработать метод `handleWorkoutResult()` согласно тестам

#### Порядок реализации (TDD)

1. **Этап 10.1: Локализация** ⏳
   - Добавить ключи локализации в `Localizable.xcstrings`

2. **Этап 10.2: Тесты для `getWorkoutResult(interrupt:)`** ⏳
   - Написать тесты в `WorkoutScreenViewModelGetWorkoutResultTests.swift`
   - Тесты должны падать (красный этап TDD)

3. **Этап 10.3: Реализация `getWorkoutResult(interrupt:)`** ⏳
   - Доработать метод `getWorkoutResult()` в `WorkoutScreenViewModel`
   - Добавить параметр `interrupt: Bool = false`
   - Реализовать логику для `interrupt == true`
   - Тесты должны проходить (зеленый этап TDD)
   - Запустить `make format` и `make test`

4. **Этап 10.4: Тесты для `handleWorkoutResult()`** ⏳
   - Написать тесты в `WorkoutPreviewViewModelTests` (создать файл, если его нет)
   - Тесты должны падать (красный этап TDD)

5. **Этап 10.5: Реализация `handleWorkoutResult()`** ⏳
   - Доработать метод в `WorkoutPreviewViewModel`
   - Тесты должны проходить (зеленый этап TDD)
   - Запустить `make format` и `make test`

6. **Этап 10.6: UI - кнопка остановки** ⏳
   - Добавить кнопку в `WorkoutScreen`
   - Добавить `confirmationDialog`
   - Реализовать логику прерывания тренировки
   - Запустить `make format`

7. **Этап 10.7: Финальная проверка** ⏳
   - Запустить все тесты: `make test`
   - Проверить форматирование: `make format`
   - Проверить сборку: `make build`

### Этап 11: Исправление падающих тестов и добавление тестов для displayedCount ✅

#### Описание
Исправление падающих тестов в `WorkoutScreenViewModelGetWorkoutResultTests.swift` и добавление тестов для свойства `displayedCount` в `WorkoutPreviewViewModel`.

#### Проблемы с падающими тестами

**Проблема 1: Уведомление не найдено перед вызовом getWorkoutResult()**
- **Описание:** Тесты создают уведомление через `UNUserNotificationCenter.current().add(request)`, но при проверке `notificationBefore` оно не находится. Возможные причины:
  - Асинхронность добавления уведомления
  - Неправильный идентификатор уведомления
  - Уведомление уже было удалено до проверки
- **Решение:** 
  - Добавить задержку после создания уведомления или использовать `await` для получения pending notifications
  - Проверить, что идентификатор уведомления совпадает с тем, что используется в `cancelRestTimerNotification()`
  - Убедиться, что уведомление действительно добавлено перед проверкой

**Проблема 2: Неточность вычисления длительности**
- **Описание:** Тест `getWorkoutResultForCompleteCyclesWorkout()` падает с ошибкой `duration -> 183) <= 182`. Это связано с тем, что время может немного отличаться из-за асинхронности выполнения теста.
- **Решение:**
  - Увеличить диапазон допустимых значений для `duration` (например, `>= 178` и `<= 185`)
  - Или использовать более точное вычисление времени в тесте

#### Тесты для displayedCount в WorkoutPreviewViewModel

**Описание свойства:**
```swift
var displayedCount: Int? {
    count ?? plannedCount
}
```

**Тесты (TDD - сначала тесты):**
- `testDisplayedCountReturnsCountWhenCountIsSet()` - когда `count` установлен, должен возвращать `count`
- `testDisplayedCountReturnsPlannedCountWhenCountIsNil()` - когда `count == nil`, но `plannedCount` установлен, должен возвращать `plannedCount`
- `testDisplayedCountReturnsNilWhenBothAreNil()` - когда оба `count` и `plannedCount` равны `nil`, должен возвращать `nil`
- `testDisplayedCountReturnsCountWhenBothAreSet()` - когда оба установлены, должен возвращать `count` (приоритет у `count`)

**Реализация:**
- Создать файл `WorkoutPreviewViewModelDisplayedCountTests.swift` в `WorkoutPreviewViewModelTests/`
- Написать тесты согласно правилам из `unit-testing-ios-app.mdc`
- Тесты должны проходить (свойство уже реализовано)

#### Порядок реализации (TDD)

1. **Этап 11.1: Тесты для displayedCount** ✅
   - Создать файл `WorkoutPreviewViewModelDisplayedCountTests.swift`
   - Написать тесты для `displayedCount` согласно правилам
   - Тесты должны проходить (зеленый этап TDD)
   - Запустить `make format` и `make test`

2. **Этап 11.2: Исправление тестов с уведомлениями** ✅
   - Изучить проблему с уведомлениями в `WorkoutScreenViewModelGetWorkoutResultTests.swift`
   - Добавить правильную обработку асинхронности при создании уведомлений
   - Исправить проверки `notificationBefore` в тестах
   - Запустить `make format` и `make test`

3. **Этап 11.3: Исправление теста с длительностью** ✅
   - Исправить тест `getWorkoutResultForCompleteCyclesWorkout()` с проблемой длительности
   - Увеличить диапазон допустимых значений или улучшить точность вычисления
   - Запустить `make format` и `make test`

4. **Этап 11.4: Финальная проверка** ✅
   - Запустить все тесты: `make test`
   - Проверить форматирование: `make format`
   - Проверить сборку: `make build`

#### Важные моменты

- **Правила тестирования:** Следовать правилам из `unit-testing-ios-app.mdc`:
  - Использовать `@Test("Описание на русском")` с описанием
  - Использовать `#expect` для проверок
  - Использовать `try #require` для разворачивания опционалов
  - Не использовать `throws` если нет `try` в тесте
  - Не использовать `async` если нет `await` в тесте
- **Асинхронность уведомлений:** Уведомления в iOS добавляются асинхронно, поэтому нужно правильно обрабатывать это в тестах
- **Точность времени:** При тестировании времени учитывать возможные задержки выполнения теста

#### Важные моменты для Этапа 10

- **Подсчет выполненных упражнений**: При прерывании (`interrupt == true`) считаются только этапы с `step == .exercise` и `state == .completed`
- **Обратная совместимость**: Метод `getWorkoutResult()` по умолчанию работает как раньше (`interrupt == false`)
- **Обработка нулевого результата**: Если `count == 0`, пользователь может снова начать тренировку без сохранения
- **Отмена уведомлений**: При прерывании тренировки необходимо отменить уведомление о таймере отдыха
- **Стиль кнопки**: Использовать тот же стиль, что и у кнопки завершения отдыха (`SWButtonStyle(mode: .tinted, size: .large)`)
- **TDD подход**: Всегда начинать с тестов, затем реализовывать функционал

### Этап 12: Исправление логики турбо-дней (92-98) ⏳

#### Описание
Для турбо-дней (92-98) при `executionType == .turbo` нужно определять фактический тип выполнения (круги или подходы) в зависимости от номера дня. Сейчас все турбо-дни обрабатываются как круги, но некоторые дни должны использовать подходы.

#### Требования к настройкам турбо-дней
- **День 92**: 40 кругов (cycles)
- **День 93**: 5 подходов (sets) - по одному подходу на каждое упражнение
- **День 94**: 5 кругов (cycles)
- **День 95**: 5 подходов (sets) - по одному подходу на каждое упражнение
- **День 96**: 5 кругов (cycles)
- **День 97**: 5 кругов (cycles)
- **День 98**: 3 подхода (sets) - по одному подходу на каждое упражнение

#### Проблема
В методе `initializeStepStates()` для `executionType == .turbo` всегда используется тип `.turbo` для этапов упражнений, но для дней 93, 95 и 98 нужно использовать `.sets`, а для остальных - `.cycles`.

Также в `WorkoutProgramCreator` метод `calculateTurboCircles(for:)` возвращает неправильные значения для турбо-дней с подходами (93, 95, 98): возвращает 1 для кругов, но для этих дней нужно использовать подходы с правильным количеством (5 для дней 93 и 95, 3 для дня 98).

#### Service: WorkoutProgramCreator ✅

**Реализовано:**
- Добавлен метод `getEffectiveExecutionType(for:executionType:)` - определяет фактический тип выполнения для турбо-дней (дни 93, 95, 98 → `.sets`, дни 92, 94, 96, 97 → `.cycles`)
- Обновлен метод `calculatePlannedCircles(for:executionType:)` для использования `getEffectiveExecutionType` с правильными значениями для турбо-дней
- Обновлен метод `calculateTurboCircles(for:)` для корректной работы с новыми настройками
- Создан файл `WorkoutProgramCreatorTurboDaysTests.swift` с тестами для всех турбо-дней (92-98)

#### ViewModel: WorkoutPreviewViewModel ✅

**Реализовано:**
- Метод `displayExecutionType(for:)` обновлен для использования `WorkoutProgramCreator.getEffectiveExecutionType(for:executionType:)` с `dayNumber` из ViewModel
- Для турбо-дней с подходами (93, 95, 98) возвращает `.sets`, для турбо-дней с кругами (92, 94, 96, 97) возвращает `.cycles`
- Добавлены параметризированные тесты для всех турбо-дней в `WorkoutPreviewViewModelDisplayExecutionTypeTests.swift`

#### ViewModel: WorkoutScreenViewModel

**Добавить вспомогательный метод:**
- `getEffectiveExecutionType() -> ExerciseExecutionType` - определяет фактический тип выполнения для турбо-дней:
  - Если `executionType == .turbo` и `dayNumber` в [93, 95, 98] → возвращает `.sets`
  - Если `executionType == .turbo` и `dayNumber` в [92, 94, 96, 97] → возвращает `.cycles`
  - Иначе → возвращает `executionType` без изменений

**Изменения в методе `initializeStepStates()`:**
- Использовать `getEffectiveExecutionType()` вместо прямого использования `executionType`
- Для турбо-дней с подходами (93, 95, 98) использовать логику как для `.sets`
- Для турбо-дней с кругами (92, 94, 96, 97) использовать логику как для `.cycles`

**Изменения в методе `getCycleSteps()`:**
- Обновить фильтрацию: для турбо-дней с кругами (92, 94, 96, 97) этапы должны иметь тип `.cycles` (не `.turbo`)
- Для турбо-дней с подходами (93, 95, 98) этапы не должны попадать в `getCycleSteps()`

**Изменения в методе `getExerciseSteps(for:)`:**
- Обновить проверку: для турбо-дней с подходами (93, 95, 98) метод должен возвращать подходы
- Для турбо-дней с кругами (92, 94, 96, 97) метод должен возвращать пустой массив

**Добавить вычисляемое свойство:**
- `shouldShowExercisesReminder: Bool` - определяет, нужно ли показывать секцию со списком упражнений:
  - Если `executionType == .cycles` → возвращает `true`
  - Если `executionType == .turbo` и `getEffectiveExecutionType() == .cycles` → возвращает `true`
  - Иначе → возвращает `false`

#### View: WorkoutScreen

**Изменения в `body`:**
- Обновить условие отображения `exercisesReminderSection`: использовать `viewModel.shouldShowExercisesReminder` вместо `vm.executionType == .cycles`
- Это позволит показывать секцию упражнений для турбо-дней с кругами (92, 94, 96, 97) и скрывать для турбо-дней с подходами (93, 95, 98)

**Изменения в `workoutStepsSection`:**
- Обновить логику: использовать `viewModel.getEffectiveExecutionType()` вместо `viewModel.executionType` для определения типа отображения этапов
- Для турбо-дней с кругами (92, 94, 96, 97) использовать логику как для `.cycles`
- Для турбо-дней с подходами (93, 95, 98) использовать логику как для `.sets`

**Тесты (TDD - сначала тесты):**

1. **Тесты для `getEffectiveExecutionType()`** (`WorkoutScreenViewModelTurboDaysTests.swift`):
   - `testGetEffectiveExecutionTypeForTurboDay92()` - день 92 с `.turbo` → `.cycles`
   - `testGetEffectiveExecutionTypeForTurboDay93()` - день 93 с `.turbo` → `.sets`
   - `testGetEffectiveExecutionTypeForTurboDay94()` - день 94 с `.turbo` → `.cycles`
   - `testGetEffectiveExecutionTypeForTurboDay95()` - день 95 с `.turbo` → `.sets`
   - `testGetEffectiveExecutionTypeForTurboDay96()` - день 96 с `.turbo` → `.cycles`
   - `testGetEffectiveExecutionTypeForTurboDay97()` - день 97 с `.turbo` → `.cycles`
   - `testGetEffectiveExecutionTypeForTurboDay98()` - день 98 с `.turbo` → `.sets`
   - `testGetEffectiveExecutionTypeForNonTurbo()` - для `.cycles` и `.sets` возвращает исходный тип

2. **Тесты для `initializeStepStates()` с турбо-днями** (`WorkoutScreenViewModelTurboDaysTests.swift`):
   - `testInitializeStepStatesForTurboDay92()` - день 92 создает этапы с типом `.cycles` (40 кругов)
   - `testInitializeStepStatesForTurboDay93()` - день 93 создает этапы с типом `.sets` (5 подходов)
   - `testInitializeStepStatesForTurboDay94()` - день 94 создает этапы с типом `.cycles` (5 кругов)
   - `testInitializeStepStatesForTurboDay95()` - день 95 создает этапы с типом `.sets` (5 подходов)
   - `testInitializeStepStatesForTurboDay96()` - день 96 создает этапы с типом `.cycles` (5 кругов)
   - `testInitializeStepStatesForTurboDay97()` - день 97 создает этапы с типом `.cycles` (5 кругов)
   - `testInitializeStepStatesForTurboDay98()` - день 98 создает этапы с типом `.sets` (3 подхода)

3. **Тесты для `getCycleSteps()` с турбо-днями** (`WorkoutScreenViewModelTurboDaysTests.swift`):
   - `testGetCycleStepsForTurboDay92()` - день 92 возвращает круги (этапы с типом `.cycles`)
   - `testGetCycleStepsForTurboDay93()` - день 93 возвращает пустой массив (этапы с типом `.sets`)
   - `testGetCycleStepsForTurboDay94()` - день 94 возвращает круги (этапы с типом `.cycles`)
   - `testGetCycleStepsForTurboDay95()` - день 95 возвращает пустой массив (этапы с типом `.sets`)
   - `testGetCycleStepsForTurboDay96()` - день 96 возвращает круги (этапы с типом `.cycles`)
   - `testGetCycleStepsForTurboDay97()` - день 97 возвращает круги (этапы с типом `.cycles`)
   - `testGetCycleStepsForTurboDay98()` - день 98 возвращает пустой массив (этапы с типом `.sets`)

4. **Тесты для `getExerciseSteps(for:)` с турбо-днями** (`WorkoutScreenViewModelTurboDaysTests.swift`):
   - `testGetExerciseStepsForTurboDay92()` - день 92 возвращает пустой массив (этапы с типом `.cycles`)
   - `testGetExerciseStepsForTurboDay93()` - день 93 возвращает подходы для каждого упражнения (этапы с типом `.sets`)
   - `testGetExerciseStepsForTurboDay94()` - день 94 возвращает пустой массив (этапы с типом `.cycles`)
   - `testGetExerciseStepsForTurboDay95()` - день 95 возвращает подходы для каждого упражнения (этапы с типом `.sets`)
   - `testGetExerciseStepsForTurboDay96()` - день 96 возвращает пустой массив (этапы с типом `.cycles`)
   - `testGetExerciseStepsForTurboDay97()` - день 97 возвращает пустой массив (этапы с типом `.cycles`)
   - `testGetExerciseStepsForTurboDay98()` - день 98 возвращает подходы для каждого упражнения (этапы с типом `.sets`)

5. **Тесты для `shouldShowExercisesReminder`** (`WorkoutScreenViewModelTurboDaysTests.swift`):
   - `testShouldShowExercisesReminderForCycles()` - для `.cycles` возвращает `true`
   - `testShouldShowExercisesReminderForSets()` - для `.sets` возвращает `false`
   - `testShouldShowExercisesReminderForTurboDay92()` - день 92 с `.turbo` возвращает `true` (круги)
   - `testShouldShowExercisesReminderForTurboDay93()` - день 93 с `.turbo` возвращает `false` (подходы)
   - `testShouldShowExercisesReminderForTurboDay94()` - день 94 с `.turbo` возвращает `true` (круги)
   - `testShouldShowExercisesReminderForTurboDay95()` - день 95 с `.turbo` возвращает `false` (подходы)
   - `testShouldShowExercisesReminderForTurboDay96()` - день 96 с `.turbo` возвращает `true` (круги)
   - `testShouldShowExercisesReminderForTurboDay97()` - день 97 с `.turbo` возвращает `true` (круги)
   - `testShouldShowExercisesReminderForTurboDay98()` - день 98 с `.turbo` возвращает `false` (подходы)

**Реализация:**
- Создать файл `WorkoutScreenViewModelTurboDaysTests.swift` в `WorkoutScreenViewModelTests/`
- Написать тесты согласно правилам из `unit-testing-ios-app.mdc`
- Реализовать метод `getEffectiveExecutionType()` в `WorkoutScreenViewModel`
- Реализовать вычисляемое свойство `shouldShowExercisesReminder` в `WorkoutScreenViewModel`
- Обновить метод `initializeStepStates()` для использования `getEffectiveExecutionType()`
- Обновить методы `getCycleSteps()` и `getExerciseSteps(for:)` для корректной работы с турбо-днями
- Обновить `WorkoutScreen.swift` для использования `shouldShowExercisesReminder` и `getEffectiveExecutionType()`

#### Порядок реализации (TDD)

1. **Этап 12.1: Тесты для `getEffectiveExecutionType()` в `WorkoutProgramCreator`** ✅
2. **Этап 12.2: Реализация `getEffectiveExecutionType()` в `WorkoutProgramCreator`** ✅
3. **Этап 12.3: Тесты для `calculatePlannedCircles(for:executionType:)` с турбо-днями** ✅
4. **Этап 12.4: Реализация `calculatePlannedCircles(for:executionType:)` для турбо-дней** ✅

5. **Этап 12.5: Тесты для `displayExecutionType(for:)` в `WorkoutPreviewViewModel`** ⏳
   - Обновить существующие тесты в `WorkoutPreviewViewModelDisplayExecutionTypeTests.swift`
   - Добавить тесты для всех турбо-дней (92-98)
   - Тесты должны падать (красный этап TDD)
   - Запустить `make format` и `make test`

6. **Этап 12.6: Реализация `displayExecutionType(for:)` в `WorkoutPreviewViewModel`** ⏳
   - Обновить метод `displayExecutionType(for:)` для использования `WorkoutProgramCreator.getEffectiveExecutionType(for:executionType:)`
   - Метод должен принимать `day: Int` как параметр
   - Обновить вызов метода в `WorkoutPreviewScreen.makePlannedCountView` для передачи `day`
   - Тесты должны проходить (зеленый этап TDD)
   - Запустить `make format` и `make test`

7. **Этап 12.7: Тесты для `getEffectiveExecutionType()` в `WorkoutScreenViewModel`** ⏳
   - Создать файл `WorkoutScreenViewModelTurboDaysTests.swift`
   - Написать тесты для `getEffectiveExecutionType()` для всех турбо-дней (92-98)
   - Тесты должны падать (красный этап TDD)
   - Запустить `make format` и `make test`

8. **Этап 12.8: Реализация `getEffectiveExecutionType()` в `WorkoutScreenViewModel`** ⏳
   - Реализовать метод `getEffectiveExecutionType()` в `WorkoutScreenViewModel`
   - Тесты должны проходить (зеленый этап TDD)
   - Запустить `make format` и `make test`

9. **Этап 12.9: Тесты для `initializeStepStates()` с турбо-днями** ⏳
   - Написать тесты для `initializeStepStates()` для всех турбо-дней (92-98)
   - Тесты должны падать (красный этап TDD)
   - Запустить `make format` и `make test`

10. **Этап 12.10: Реализация `initializeStepStates()` для турбо-дней** ⏳
   - Обновить метод `initializeStepStates()` для использования `getEffectiveExecutionType()`
   - Тесты должны проходить (зеленый этап TDD)
   - Запустить `make format` и `make test`

11. **Этап 12.11: Тесты для `getCycleSteps()` и `getExerciseSteps(for:)` с турбо-днями** ⏳
   - Написать тесты для `getCycleSteps()` и `getExerciseSteps(for:)` для всех турбо-дней (92-98)
   - Тесты должны падать (красный этап TDD)
   - Запустить `make format` и `make test`

12. **Этап 12.12: Реализация `getCycleSteps()` и `getExerciseSteps(for:)` для турбо-дней** ⏳
   - Обновить методы `getCycleSteps()` и `getExerciseSteps(for:)` для корректной работы с турбо-днями
   - Тесты должны проходить (зеленый этап TDD)
   - Запустить `make format` и `make test`

13. **Этап 12.13: Тесты для `shouldShowExercisesReminder`** ⏳
   - Написать тесты для `shouldShowExercisesReminder` для всех типов выполнения и турбо-дней (92-98)
   - Тесты должны падать (красный этап TDD)
   - Запустить `make format` и `make test`

14. **Этап 12.14: Реализация `shouldShowExercisesReminder`** ⏳
   - Реализовать вычисляемое свойство `shouldShowExercisesReminder` в `WorkoutScreenViewModel`
   - Тесты должны проходить (зеленый этап TDD)
   - Запустить `make format` и `make test`

15. **Этап 12.15: Обновление `WorkoutScreen.swift`** ⏳
   - Обновить условие отображения `exercisesReminderSection`: использовать `viewModel.shouldShowExercisesReminder`
   - Обновить логику в `workoutStepsSection`: использовать `viewModel.getEffectiveExecutionType()` вместо `viewModel.executionType`
   - Проверить корректность отображения для всех турбо-дней (92-98)
   - Запустить `make format` и `make build`

16. **Этап 12.16: Обновление существующих тестов** ⏳
   - Проверить существующие тесты для `.turbo` в `WorkoutProgramCreator` и `WorkoutScreenViewModel`
   - Обновить тесты, если они больше не соответствуют новой логике
   - Запустить `make format` и `make test`

17. **Этап 12.17: Финальная проверка** ⏳
   - Запустить все тесты: `make test`
   - Проверить форматирование: `make format`
   - Проверить сборку: `make build`

#### Важные моменты для Этапа 12

- **Определение типа выполнения**: Для турбо-дней фактический тип выполнения определяется по номеру дня, а не по `executionType`
- **Обратная совместимость**: Для не-турбо дней (`.cycles`, `.sets`) логика остается без изменений
- **Типы этапов**: Этапы упражнений для турбо-дней должны иметь тип `.cycles` или `.sets`, а не `.turbo`
- **Количество подходов**: Для турбо-дней с подходами (93, 95, 98) количество подходов равно количеству упражнений (по одному подходу на каждое упражнение)
- **Отображение секции упражнений**: Секция `exercisesReminderSection` показывается для `.cycles` и для турбо-дней с кругами (92, 94, 96, 97), но не показывается для `.sets` и для турбо-дней с подходами (93, 95, 98)
- **Настройки `plannedCount` для турбо-дней**: В `WorkoutProgramCreator` для турбо-дней с подходами (93, 95, 98) `plannedCount` должен быть равен количеству подходов (5 для дней 93 и 95, 3 для дня 98), а не количеству кругов
- **Единая логика определения типа выполнения**: Метод `getEffectiveExecutionType` должен быть реализован и в `WorkoutProgramCreator`, и в `WorkoutScreenViewModel` с одинаковой логикой
- **TDD подход**: Всегда начинать с тестов, затем реализовывать функционал
- **Правила тестирования**: Следовать правилам из `unit-testing-ios-app.mdc`:
  - Использовать `@Test("Описание на русском")` с описанием
  - Использовать `#expect` для проверок
  - Использовать `try #require` для разворачивания опционалов
  - Не использовать `throws` если нет `try` в тесте
  - Не использовать `async` если нет `await` в тесте

## Примечания

- ViewModel не хранит ссылки на `ModelContext` или сервисы - они передаются в методы как параметры
- ViewModel не занимается сохранением тренировки - данные возвращаются через замыкание `onWorkoutCompleted`
- Таймер отдыха показывается после всех этапов кроме `warmUp` и перед `coolDown`
- Состояние следующего этапа обновляется после завершения таймера в `onTimerCompleted()`, кроме `coolDown` (устанавливается сразу)
- Длительность тренировки: (время окончания - время начала) + сумма фактического времени всех отдыхов
- Фактическое время отдыха засекается в момент исчезновения `WorkoutTimerScreen` (в `onDismiss`)
- `WorkoutTimerScreen` показывается через `fullScreenCover`
- Уведомление о завершении отдыха планируется при показе таймера и отменяется при закрытии
- **Звук и вибрация при завершении таймера:**
  - Если приложение **свернуто** при срабатывании уведомления: стандартный звук `.default` через уведомление (если `playTimerSound == true`), вибрация автоматически через уведомление
  - Если приложение **открыто** и таймер закончился: выбранный звук из `appSettings.timerSound` через `AudioPlayerManager` (если `playTimerSound == true`), вибрация через `VibrationService` (если `vibrate == true`)
  - При открытии приложения по уведомлению: звук и вибрация НЕ воспроизводятся (пользователь уже получил уведомление)
- `AppSettings` передается из environment View в методы ViewModel
- Локализация уведомления: ключ `"RestCompleted"` в `Localizable.xcstrings` (используется как `body`)
- **Уведомление о завершении отдыха**: Использует структуру как в ежедневном уведомлении (`title = "SOTKA"`, `body = "Отдых завершён - продолжаем!"`). В уведомлении используется стандартный звук `.default` (кастомные звуки нельзя использовать напрямую в уведомлениях iOS)
