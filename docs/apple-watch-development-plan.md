# План разработки приложения для Apple Watch

## Обзор

Этот документ описывает детальный план разработки приложения для Apple Watch с сокращенным функционалом по сравнению с основным iOS-приложением. Приложение для часов будет поддерживать выбор типа активности на день и выполнение тренировок с синхронизацией данных между часами и iPhone.

## Цели и ограничения

### Функционал для часов
- Выбор типа активности на сегодняшний день из 4 вариантов (`DayActivityType`):
  - `workout` - тренировка
  - `stretch` - растяжка
  - `rest` - отдых
  - `sick` - болезнь
- Выполнение тренировки (если выбран тип `workout`):
  - Упрощенный интерфейс выполнения тренировки
  - Сохранение результата тренировки
- Синхронизация данных между часами и iPhone:
  - Двусторонняя синхронизация через WatchConnectivity
  - Синхронизация выбранных активностей
  - Синхронизация результатов тренировок
  - Синхронизация текущего дня программы

### Ограничения
- Минимальный UI для часов (ограниченный размер экрана)
- Упрощенная логика тренировок (без сложных настроек)
- **Часы не хранят данные локально** - все данные запрашиваются с iPhone и сохраняются через iPhone в SwiftData
- **Статус авторизации и `startDate`** читаются напрямую из App Group UserDefaults (см. раздел 1.3)
- **Текущий день** вычисляется локально на часах из `startDate` с помощью `DayCalculator`
- **iPhone приложение является единственным хранилищем данных** (SwiftData)
- **Приложение для часов работает только после успешной авторизации в iPhone приложении**

## Архитектура

### Структура проекта

```
SotkaWatch Watch App/
├── Models/
│   └── AuthState.swift                 # Модель состояния авторизации для Watch App ✅
├── Services/
│   ├── WatchAuthService.swift          # Сервис авторизации для Watch App ✅
│   ├── WatchAuthServiceProtocol.swift  # Протокол сервиса авторизации ✅
│   ├── WatchConnectivityService.swift  # Сервис связи с iPhone через WatchConnectivity ✅
│   ├── WatchConnectivityServiceProtocol.swift # Протокол сервиса связи ✅
│   ├── WatchWorkoutService.swift       # Сервис тренировок для Watch App ✅
│   └── WCSessionProtocol.swift         # Протокол для WCSession (для тестирования) ✅
├── ViewModels/
│   ├── HomeViewModel.swift              # ViewModel для главного экрана ✅
│   └── WorkoutViewModel.swift          # ViewModel для экрана тренировки ✅
├── Views/
│   ├── AuthRequiredView.swift          # Экран для неавторизованных пользователей ✅
│   ├── HomeView.swift                  # Главный экран часов ✅
│   ├── DayActivityView.swift           # Экран активности дня (выбор/отображение) ✅
│   ├── DayActivitySelectionView.swift  # Выбор типа активности ✅
│   ├── SelectedActivityView.swift      # Отображение выбранной активности ✅
│   ├── WatchDayActivityTrainingView.swift # Компонент отображения данных тренировки ✅
│   ├── WatchDayActivityCommentView.swift  # Компонент отображения комментария ✅
│   ├── WorkoutView.swift               # Экран выполнения тренировки (еще не создан)
│   └── WorkoutRestTimerView.swift      # Таймер отдыха между кругами/подходами (еще не создан)
└── Utilities/
    ├── WatchAppGroupHelper.swift       # Утилита для работы с App Group UserDefaults ✅
    └── WatchAppGroupHelperProtocol.swift # Протокол утилиты (для тестирования) ✅

Примечание: 
- Модели данных используются из основного приложения:
  - Models/SWSharedModels/WorkoutData.swift (общая модель для передачи данных тренировки)
  - Models/SWSharedModels/WorkoutDataResponse.swift (структура для передачи полных данных тренировки с iPhone на Apple Watch, включает WorkoutData, executionCount, comment)
  - Models/Workout/WorkoutResult.swift (добавлен Codable для передачи через WatchConnectivity)
  - Models/Workout/WorkoutPreviewTraining.swift (добавлен Codable для передачи через WatchConnectivity)
  - Models/Workout/DayActivityType.swift (используется rawValue для передачи)
  - Models/Workout/ExerciseExecutionType.swift (используется rawValue для передачи)
  - Models/Workout/ExerciseType.swift (добавлен в Watch App target для использования локализованных названий и иконок упражнений)
  - Models/Workout/DayCalculator.swift (переиспользуется из основного приложения для вычисления текущего дня программы)
- Локальные модели для Watch App размещаются в `Models/` (например, `AuthState`)
- Простые структуры (не SwiftData) получают Codable для прямой передачи через WatchConnectivity
- Модели с `@Model` (SwiftData) не используются напрямую на часах
- Ассеты упражнений находятся в отдельном `ExercisesAssets.xcassets`, доступном обоим таргетам (основное приложение и Watch App)
```

### Технологии

- **SwiftUI** - для UI (watchOS поддерживает SwiftUI)
- **WatchConnectivity** - для связи с iPhone
- **UserDefaults** (App Group) - для чтения статуса авторизации и `startDate` (см. раздел 1.3)
- **DayCalculator** - модель для вычисления текущего дня программы (переиспользуется из основного приложения)
- **OSLog** - для логирования

**Важно:** 
- Часы не используют SwiftData или другое постоянное хранилище. Все данные запрашиваются с iPhone в реальном времени.
- **Модели переиспользуются из основного приложения** - не создаем дубликаты моделей для часов.
- **Простые структуры (не SwiftData)** получают Codable для прямой передачи через WatchConnectivity:
  - `WorkoutResult` - добавлен Codable
  - `WorkoutPreviewTraining` - добавлен Codable
  - `DayActivityType` и `ExerciseExecutionType` - используют rawValue для передачи
- **`ExerciseType`** добавлен в Watch App target для использования локализованных названий упражнений и иконок на экране тренировки
- **Ассеты упражнений** находятся в отдельном `ExercisesAssets.xcassets`, доступном обоим таргетам (основное приложение и Watch App), что позволяет использовать иконки упражнений без дублирования
- Модели с `@Model` (SwiftData) не используются напрямую на часах, только для преобразования в простые структуры.

### Обмен данными между часами и iPhone

#### WatchConnectivity Service

**Архитектура связи:**
- **iPhone является единственным хранилищем данных** (SwiftData)
- **Часы не хранят данные локально** - все данные запрашиваются с iPhone в реальном времени
- **Все действия с часов передаются в iPhone** для сохранения в SwiftData
- Связь выполняется через WatchConnectivity Framework
- **Чтение статуса авторизации и `startDate`** напрямую из App Group UserDefaults (см. раздел 1.3)
- **Текущий день** вычисляется локально на часах из `startDate` с помощью `DayCalculator`
- **Уведомления об изменениях статуса авторизации:**
  - iPhone отправляет команду `PHONE_COMMAND_AUTH_STATUS_CHANGED` только при логауте (при авторизации часы читают статус из App Group UserDefaults)
  - Часы также проверяют статус авторизации при активации приложения (`scenePhase == .active`) для обеспечения актуальности данных даже при отсутствии связи

**Команды синхронизации:** (см. раздел "Команды WatchConnectivity" ниже)

**Формат данных:**
- JSON для передачи сложных структур
- Простые типы (Int, String, Bool) для простых команд

#### Разрешение конфликтов при одновременном изменении активности

**Проблема:**
При одновременном изменении активности на один и тот же день с разных устройств (часы и iPhone) могут возникать конфликты. Например:
- На iPhone начали тренировку (создана активность `.workout`), но не закончили и свернули приложение
- На часах выбрали активность "отдых" для того же дня
- Без специальной обработки активность будет перезаписана на "отдых", что приведет к потере данных о тренировке

**Стратегия разрешения конфликтов:**

1. **Приоритет незавершенных тренировок:**
   - Если на день уже существует активность типа `.workout` (тренировка), изменение на другой тип активности (`.rest`, `.stretch`, `.sick`) должно быть запрещено или требовать подтверждения
   - Это предотвращает случайную потерю данных о начатой тренировке
   - Проверка выполняется на iPhone при обработке команды `WATCH_COMMAND_SET_ACTIVITY` от часов

2. **Last Write Wins (LWW) для других случаев:**
   - Для активностей типа `.rest`, `.stretch`, `.sick` применяется стратегия LWW на основе `modifyDate`
   - Последнее изменение побеждает (обновляется `modifyDate` при каждом изменении)
   - Это соответствует существующей логике разрешения конфликтов при синхронизации с сервером

3. **Проверка перед изменением:**
   - При получении команды `WATCH_COMMAND_SET_ACTIVITY` на iPhone:
     - Проверить существующую активность для указанного дня
     - Если активность существует и имеет тип `.workout`:
       - Отклонить изменение (вернуть ошибку на часы)
       - Или запросить подтверждение у пользователя (если изменение запрошено с iPhone)
     - Если активность не существует или имеет другой тип - выполнить изменение

4. **Уведомление пользователя:**
   - При попытке изменить активность на часах, если на iPhone есть незавершенная тренировка:
     - Показать сообщение об ошибке на часах: "Нельзя изменить активность: на телефоне начата тренировка"
     - Предложить завершить тренировку на телефоне или отменить её перед изменением активности

5. **Специальный случай - завершенные тренировки:**
   - Если тренировка завершена (есть `count` и `duration`), изменение на другой тип активности разрешено
   - Это позволяет пользователю изменить активность после завершения тренировки

**Реализация:**
- Логика проверки конфликтов реализуется в `WatchConnectivityManager` на iPhone при обработке команды `WATCH_COMMAND_SET_ACTIVITY`
- Используется `DailyActivitiesService` для проверки существующей активности
- При обнаружении конфликта возвращается ошибка на часы через WatchConnectivity
- Часы обрабатывают ошибку и показывают соответствующее сообщение пользователю

**Примечание:**
- Эта стратегия применяется только для конфликтов между часами и iPhone
- Конфликты при синхронизации с сервером разрешаются по существующей логике LWW в `DailyActivitiesService.downloadServerActivities()`

## Детальный план реализации

**Важно:** План следует принципам TDD (Test-Driven Development). Сначала пишутся тесты, затем реализация. UI реализуется в последнюю очередь.

### Принципы локализации для Watch App

1. **Использование общего файла локализации:**
   - Файл `SupportingFiles/Localizable.xcstrings` уже добавлен в Watch App target
   - Все строки для часов добавляются в этот же файл с префиксом `Watch.*`
   - Использование общего файла упрощает поддержку и позволяет переиспользовать общие строки

2. **Локализация displayName для часов:** ✅ Выполнено (см. раздел 1.2)

3. **Избежание дублей ключей:**
   - Перед добавлением новых ключей обязательно проверять существующие ключи в `Localizable.xcstrings`
   - Использовать существующие ключи там, где возможно:
     - `Home.Activity` для "Активность"
     - `.workoutDay`, `.stretchDay`, `.restDay`, `.sickDay` для типов активности (из `DayActivityType`)
     - Другие общие ключи из основного приложения
   - Добавлять новые ключи только если они специфичны для часов и не существуют в основном приложении

4. **Статус переводов:**
   - Все новые переводы должны иметь статус `"state" : "needs_review"`
   - Переводы добавляются на русский и английский языки

### Этап 1: Настройка проекта и инфраструктуры ✅ Выполнено

#### 1.1 Настройка Watch App Target
- [x] ✅ Минимальная версия watchOS: 10.0 (совместимо с iOS 17.0+)
- [x] ✅ App Group `group.com.sotka.app` настроен в обоих targets
- [x] ✅ WatchConnectivity доступен (встроен в watchOS 10.0+)
- [x] ✅ OSLog для логирования на русском языке
- [x] ✅ **Target Membership для общих моделей:** Добавлены модели из `Models/Workout/` и `Models/SWSharedModels/` в Watch App target (WorkoutResult, WorkoutPreviewTraining, DayActivityType, ExerciseExecutionType, ExerciseType, DayCalculator, Constants, WorkoutData, WorkoutDataResponse)
- [x] ✅ `AuthHelper` переведен на App Group с автоматической миграцией

#### 1.2 Константы и утилиты
- [x] ✅ Enum `Constants.WatchCommand` в `Models/SWSharedModels/Constants.swift` (доступен обоим таргетам)
- [x] ✅ `WatchAppGroupHelper.swift` для чтения данных из App Group UserDefaults
- [x] ✅ Локализация displayName для часов (`InfoPlist.xcstrings`)

#### 1.3 App Group для обмена данными
- [x] ✅ App Group `group.com.sotka.app` настроен
- [x] ✅ `WatchAppGroupHelper` - структура с вычисляемыми свойствами: `isAuthorized`, `startDate`, `currentDay` (вычисляется локально через `DayCalculator`)
- [x] ✅ **Принципы:** Данные читаются напрямую из App Group UserDefaults без кэширования, текущий день вычисляется локально на часах
- [x] ✅ **Ключи:** `isAuthorized`, `startDate`, `restTime` (синхронизация через WatchConnectivity не требуется)

#### 1.4 Ассеты упражнений
- [x] ✅ `ExercisesAssets.xcassets` создан и добавлен в оба таргета, доступен через `ExerciseType.image`

### Этап 2: Добавление Codable к моделям ✅ Выполнено

- [x] ✅ Codable добавлен к `WorkoutResult` и `WorkoutPreviewTraining`
- [x] ✅ Создана структура `WorkoutData` в `Models/SWSharedModels/`
- [x] ✅ Добавлено вычисляемое свойство `workoutData` в `DayActivity` для преобразования в Codable

### Этап 3: Сервисы ✅ Выполнено

- [x] ✅ `WatchAuthService` - @Observable сервис авторизации
- [x] ✅ `WatchConnectivityService` - сервис связи с iPhone через WatchConnectivity (dependency injection через `WCSessionProtocol`)
- [x] ✅ `WatchWorkoutService` - сервис тренировок (использует App Group для `restTime`)

### Этап 4: ViewModels ✅ Выполнено

- [x] ✅ `HomeViewModel` - @Observable класс с методами `loadData()`, `checkAuthStatusOnActivation()`, `selectActivity()`, `startWorkout()`
- [x] ✅ `WorkoutViewModel` - @Observable класс с методами `completeRound()`, `handleRestTimerFinish()`, `finishWorkout()`, `cancelWorkout()`

### Этап 5: Интеграция с iPhone ✅ Выполнено

- [x] ✅ `WatchConnectivityManager` реализован как вложенный класс в `StatusManager`
- [x] ✅ Обработка команд: `WATCH_COMMAND_SET_ACTIVITY`, `WATCH_COMMAND_SAVE_WORKOUT`, `WATCH_COMMAND_GET_CURRENT_ACTIVITY`, `WATCH_COMMAND_GET_WORKOUT_DATA`, `WATCH_COMMAND_DELETE_ACTIVITY`
- [x] ✅ Очередь запросов (`pendingRequests`) для решения проблем с actor isolation
- [x] ✅ Проверка конфликтов при изменении активности (защита незавершенных тренировок)

**Важные примечания:**
- ⚠️ **WCSessionDelegate для watchOS:** НЕ добавлять методы `sessionDidBecomeInactive` и `sessionDidDeactivate` (unavailable на watchOS, баг Cursor IDE)
- **Actor isolation:** Методы делегата `nonisolated` добавляют запросы в очередь через `Task { @MainActor in }`, обработка через `processPendingRequests(context:)` во вьюхе
- **Авторизация:** При авторизации часы читают статус из App Group UserDefaults, при логауте отправляется `PHONE_COMMAND_AUTH_STATUS_CHANGED`

### Этап 6: UI экранов

#### 6.1 Экран авторизации ✅ Выполнено
- [x] ✅ `AuthRequiredView` создан и интегрирован в `HomeView` через условный рендеринг

#### 6.2 Главный экран
- [x] Создать `HomeView.swift`: ✅ Частично выполнено (основной функционал реализован, локализация добавлена)
  - [x] **Логика открытия экрана превью тренировки:** ✅ Частично выполнено
    - ✅ Реализована обработка выбора активности `.workout` в `onSelect` callback в `HomeView` (строки 12-19)
    - ✅ При выборе активности `.workout` устанавливается `showEditWorkout = true`
    - ✅ Добавлен `.fullScreenCover(isPresented: $showEditWorkout)` в `HomeView` (строки 49-53)
    - [ ] **Осталось:** Подключить экран превью тренировки (`WorkoutPreviewView`) - заменить `EmptyView()` с TODO комментарием на реальный экран (см. раздел 6.3.1)

#### 6.3 Экран выбора активности
- [x] **Создать экран выбора активности:** ✅ Выполнено (`DayActivitySelectionView.swift` с 4 вариантами активности)
- [x] **Базовый UI для выбора и изменения активности:** ✅ Выполнено (`DayActivityView`, `SelectedActivityView`, `DayActivitySelectionView`)
- [x] **Доработать `SelectedActivityView` для отображения данных тренировки:** ✅ Выполнено
  - ✅ Создана верстка для отображения данных тренировки через `WatchDayActivityTrainingView` и `WatchDayActivityCommentView`
  - ✅ Реализован enum `Mode` для разделения логики отображения тренировки и других активностей
  - ✅ Добавлены toolbar кнопки для редактирования и удаления активности
  - ✅ Адаптировано отображение для маленького экрана часов (упрощенный формат)
  - [x] **Добавить unit-тесты для `SelectedActivityView.Mode`:** ✅ Выполнено
    - ✅ Тесты для инициализатора `Mode.init(activity:data:executionCount:)`
    - ✅ Тесты для вычисляемых свойств `isWorkout` и `activity`
    - ✅ Проверка корректного создания `.workout` и `.nonWorkout` кейсов
  - [x] **Реализовать удаление активности:** ✅ Выполнено
    - ✅ Добавлено замыкание `onDelete: (Int) -> Void` в инициализатор `SelectedActivityView`
    - ✅ Реализован вызов `onDelete(dayNumber)` при подтверждении удаления в `deleteButton`
    - ✅ Интегрировано с `HomeViewModel` для отправки команды удаления на iPhone через `WatchConnectivityService`
    - ✅ Добавлена команда `deleteActivity` в `Constants.WatchCommand`
    - ✅ Реализован метод `deleteActivity` в `WatchConnectivityService` и протокол
    - ✅ Добавлена обработка команды `deleteActivity` в `StatusManager` на стороне iPhone
    - ✅ Реализован метод `deleteActivity` в `HomeViewModel`
  - [x] **Реализовать редактирование тренировки:**
    - ✅ **Выполнено:** Кнопка редактирования для тренировки реализована в `SelectedActivityView` (строки 138-143)
    - ✅ **Выполнено:** При нажатии на кнопку редактирования вызывается `onSelect(.workout)`, который обрабатывается в `HomeView` (строки 12-19)
    - ✅ **Выполнено:** В `HomeView` открывается `fullScreenCover` с `showEditWorkout` при выборе активности `.workout` (строки 49-53)
    - ✅ **Выполнено:** Для не-тренировочных активностей редактирование реализовано через `DayActivitySelectionView` (NavigationLink на строках 145-152 в `SelectedActivityView`)
    - [ ] **Осталось:** Подключить экран превью тренировки (`WorkoutPreviewView`) к навигации - заменить `EmptyView` на строке 51 в `HomeView` на реальный экран (см. раздел 6.3.1)
  - [x] **Получить данные тренировки для текущего дня:**
    - ✅ **Выполнено:** Расширен `HomeViewModel` для загрузки данных тренировки:
      - ✅ Добавлены свойства `workoutData: WorkoutData?`, `workoutExecutionCount: Int?`, `workoutComment: String?` в `HomeViewModel`
      - ✅ В методе `loadData()` при наличии активности типа `.workout` загружаются данные через `connectivityService.requestWorkoutData(day:)`
      - ✅ Добавлена обработка ошибок для данных тренировки (данные не очищаются при ошибке загрузки)
    - ✅ **Выполнено:** Передаются загруженные данные в `DayActivityView` и далее в `SelectedActivityView`:
      - ✅ Добавлены параметры `workoutData`, `workoutExecutionCount`, `comment` в `DayActivityView`
      - ✅ Параметры передаются из `HomeView` через `viewModel.workoutData`, `viewModel.workoutExecutionCount`, `viewModel.workoutComment`
      - ✅ Параметры передаются в `SelectedActivityView` (уже поддерживается в инициализаторе)
    - ✅ **Выполнено:** Расширен протокол `WatchConnectivityServiceProtocol` для возврата `WorkoutDataResponse` вместо `WorkoutData`
    - ✅ **Выполнено:** Создана структура `WorkoutDataResponse` с полями `workoutData`, `executionCount`, `comment`
    - ✅ **Выполнено:** Обновлен `StatusManager.handleGetWorkoutData` для отправки полных данных (включая `count` и `comment`)
    - ✅ **Выполнено:** Логика создания сообщения для WatchConnectivity вынесена в `WorkoutDataResponse.makeMessageForWatch(command:)`
    - ✅ **Выполнено:** Написаны тесты для новой функциональности
- [ ] **Реализовать логику выбора/изменения активности:**
  - ✅ **Выполнено:** В `HomeView` передается реальная выбранная активность для текущего дня (`selectedActivity: viewModel.currentActivity` на строке 21)
  - ✅ **Выполнено:** Реализована обработка выбора активности через `onSelect` callback в `DayActivityView` (строки 10-13 в `HomeView`)
  - ✅ **Выполнено:** Вызов `HomeViewModel.selectActivity(_:)` для отправки на iPhone через `WatchConnectivityService` (строки 89-111 в `HomeViewModel`)
  - ✅ **Выполнено:** Показ индикатора отправки активности на iPhone (строки 34-40 в `HomeView` через `viewModel.isLoading`)
  - ✅ **Выполнено:** Обработка ошибок связи (строки 19, 51-52 в `HomeViewModel`, строки 51-52 в `HomeView`)
  - ✅ **Выполнено:** Если выбранная активность = `.workout`, открыть экран превью тренировки (`WorkoutPreviewView`) после успешного сохранения:
    - ✅ Реализовано через `.fullScreenCover(isPresented: $showEditWorkout)` в `HomeView` или `DayActivityView`
    - ✅ В `HomeViewModel.selectActivity(_:)` после успешной отправки проверяется, если `activityType == .workout`, устанавливается флаг для открытия экрана
    - ✅ Загрузка данных тренировки через `connectivityService.requestWorkoutData(day:)` перед открытием `WorkoutPreviewView`
    - ✅ Передача `workoutData` в `WorkoutPreviewView`
    - **Важно:** `WorkoutPreviewView` всегда должен идти до экрана тренировки (`WorkoutView`)
    - С `WorkoutPreviewView` пользователь может перейти к экрану выполнения тренировки (`WorkoutView`) через кнопку "Начать тренировку"
  - ✅ **Выполнено:** Если выбранная активность != `.workout`, остаться на текущем экране (обновление отображения происходит автоматически через `viewModel.currentActivity`)
  - [ ] **Требуется:** Локализованные строки для индикаторов и ошибок в `Localizable.xcstrings` (общий файл):
    - `Watch.Activity.Saving` - "Сохранение..." (новый ключ, специфичен для часов) - **Примечание:** Сейчас используется общий индикатор загрузки через `ProgressView()`, можно добавить текстовую подсказку
    - `Watch.Activity.Error` - "Ошибка сохранения" (новый ключ, специфичен для часов) - **Примечание:** Сейчас ошибки обрабатываются через `viewModel.error`, но не отображаются в UI
    - Добавить переводы на русский и английский языки
    - Установить статус новых переводов: `"state" : "needs_review"`

#### 6.3.1 Экран превью тренировки (упрощенная версия для часов)
- [x] **Создать `WorkoutPreviewView.swift` (упрощенная версия `WorkoutPreviewScreen`):**
  - **Архитектурный принцип:** Вся бизнес-логика должна быть в ViewModel, View только отображает данные и вызывает методы ViewModel (по аналогии с `WorkoutPreviewScreen`)
  - **Отличия для первой итерации часов:**
    - ✅ При настройке 0 повторов для упражнения - удалять его с экрана на часах (реализовано в `makeTrainingRowView`, но логика удаления должна быть в ViewModel)
    - Остальная логика остается по аналогии с основным приложением
  - **Структура экрана:**
    - ✅ NavigationStack с заголовком (номер дня через `.day(number:)`)
    - ✅ ScrollView с VStack (spacing: 8) для упрощенной верстки для маленького экрана часов:
      - ✅ `executionTypePicker` (если нужно показывать) - перед списком упражнений
      - ✅ Divider после executionTypePicker
      - ✅ `workoutContentView` со списком упражнений и другими секциями
      - ✅ `bottomButtonsView` с кнопками внизу экрана
    - ✅ **Инициализация ViewModel:**
      - ✅ View вызывает `viewModel.loadData(day:)` в `.task` (аналогично `HomeView`)
      - ✅ ViewModel сам получает данные через свои зависимости:
        - `connectivityService.requestWorkoutData(day:)` для получения `WorkoutDataResponse`
        - `appGroupHelper.restTime` для получения времени отдыха из App Group UserDefaults
      - **Примечание:** View не получает данные напрямую через сервисы - это ответственность ViewModel. View только вызывает метод ViewModel для загрузки данных
    - ✅ **Toolbar кнопка редактирования:**
      - ✅ В `toolbar` (`.topBarTrailing`) добавлена кнопка с иконкой `pencil` для редактирования порядка и набора упражнений
      - ✅ Показывается кнопка только если `viewModel.shouldShowEditButton` (computed property в ViewModel, аналогично `WorkoutPreviewScreen`)
      - ✅ По нажатию на кнопку показывается модальное окно через `.sheet(isPresented: $showEditView)`
      - [ ] **TODO:** Реализовать `WorkoutEditView` (без `customExercisesSection` для первой итерации) - сейчас показывается `ProgressView()` заглушка
      - [ ] **TODO:** Передавать `viewModel` в `WorkoutEditView` (аналогично `WorkoutExerciseEditorScreen(viewModel: viewModel)`)
  - **Обязательные секции (те же, что и в `WorkoutPreviewScreen`):**
    - ✅ **`executionTypePicker`** (контрол для выбора типа выполнения):
      - ✅ Показывается перед списком упражнений через `@ViewBuilder`
      - ✅ Логика показа вызывает `viewModel.shouldShowExecutionTypePicker(day:isPassed:)` (аналогично `WorkoutPreviewScreen`)
        - Показывается только если данные загружены (dayNumber установлен и trainings не пустой)
        - Показывается только для не пройденных дней (если `isPassed == false`)
        - Показывается только если доступно больше одного типа выполнения
      - ✅ Используется стиль `.pickerStyle(.navigationLink)` для часов (вместо `.segmented` как планировалось, т.к. `.navigationLink` лучше подходит для часов)
      - ✅ При изменении типа выполнения вызывается `viewModel.updateExecutionType(with: newValue)` (аналогично `WorkoutPreviewScreen`)
      - ✅ Доступные типы берутся из `viewModel.availableExecutionTypes` (из ViewModel, а не из локального состояния)
    - ✅ Список упражнений из `viewModel.trainings` через `LazyVStack` (из ViewModel, а не из локального состояния)
    - ✅ Отображение планового количества кругов/подходов через `makePlannedCountView` (если `viewModel.selectedExecutionType` установлен)
    - ✅ Выбор времени отдыха через `makeRestTimePicker` (если `viewModel.selectedExecutionType` установлен и `!viewModel.wasOriginallyPassed`)
    - [ ] **TODO:** Редактор комментария через `TextFieldLink` (для часов):
      - [ ] **TODO:** Показывать редактор комментария только если `viewModel.canEditComment` (computed property в ViewModel, аналогично `WorkoutPreviewScreen`)
      - [ ] **TODO:** Использовать `TextFieldLink` для редактирования комментария (вместо `SWTextEditor` как в основном приложении)
      - [ ] **TODO:** При изменении значения вызывать `viewModel.updateComment(newValue)` (аналогично `WorkoutPreviewScreen`)
      - [ ] **TODO:** Использовать `viewModel.comment` для отображения текущего значения комментария
      - [ ] **TODO:** Использовать placeholder `.dayActivityCommentPlaceholder` для пустого комментария
      - [ ] **TODO:** Добавить `Divider` перед редактором комментария (аналогично `WorkoutPreviewScreen`)
  - **Отображение упражнений:**
    - ✅ Список упражнений из `viewModel.trainings` через `visibleTrainings` (фильтрует упражнения с `count > 0`, логика фильтрации в View)
    - ✅ Для каждого упражнения через `makeTrainingRowView`:
      - ✅ Иконка упражнения через `ExerciseType.image` (из `makeExerciseImage`) - логика отображения остается в View
      - ✅ Название упражнения через `ExerciseType.makeLocalizedTitle(day:executionType:sortOrder:)` или `ExerciseType.localizedTitle` (из `makeExerciseTitle`) - логика отображения остается в View
      - ✅ **Используется `NavigationLink` + `WorkoutStepperView`** для изменения количества повторений:
        - Диапазон значений: от 1 (через параметр `from: 1` в `WorkoutStepperView`)
        - Текущее значение: `training.count ?? 0` (из `viewModel.trainings`)
        - ✅ При изменении значения вызывается `viewModel.updateTrainingCount(for:newValue:)` (логика обновления в ViewModel)
        - ✅ **При выборе 0 повторений:** логика удаления реализована в ViewModel (через `updateTrainingCount` с удалением упражнения из списка)
      - ✅ Отображение через `WatchActivityRowView` с иконкой, названием и количеством
    - ✅ Отображение типа выполнения (`ExerciseExecutionType`) с количеством кругов/подходов через `makePlannedCountView`:
      - ✅ Используется `viewModel.displayExecutionType(for:)` для получения типа выполнения для отображения
      - ✅ Используется `viewModel.displayedCount` для отображения количества
      - ✅ Вызывается `viewModel.updatePlannedCount(for: newValue)` при изменении
  - **Кнопки управления:**
    - ✅ Используется `WorkoutPreviewButtonsView` для отображения кнопок управления (аналогично основному приложению)
    - ✅ Кнопка "Начать тренировку" (`onStartTraining: () -> Void`):
      - ✅ Переход к экрану выполнения тренировки через `.fullScreenCover(isPresented: $showWorkoutView)`
      - [ ] **TODO:** Реализовать `WorkoutView` - сейчас показывается `ProgressView()` заглушка
      - [ ] **TODO:** Передавать данные из ViewModel в `WorkoutView`: `viewModel.buildWorkoutData()` или отдельные свойства
      - [ ] **TODO:** Передавать `onWorkoutCompleted` callback, который вызывает `viewModel.handleWorkoutResult(result)` (аналогично `WorkoutPreviewScreen`)
    - ✅ Кнопка "Сохранить как пройденную" (`onSave: () -> Void`):
      - ✅ Вызывается `viewModel.saveTrainingAsPassed()` (аналогично `WorkoutPreviewScreen.saveTrainingAsPassed()`)
      - ✅ ViewModel реализует сохранение через `WatchConnectivityService.sendWorkoutResult(day:result:executionType:)`
      - ✅ ViewModel строит `WorkoutResult` из текущих значений через `buildWorkoutResult()`
    - ✅ Передаются реальные данные в `WorkoutPreviewButtonsView` из ViewModel (аналогично `WorkoutPreviewScreen`):
      - ✅ `isPassed: viewModel.wasOriginallyPassed` - флаг, был ли день изначально пройден
      - ✅ `hasChanges: viewModel.hasChanges` - флаг, были ли внесены изменения в тренировку (computed property в ViewModel)
      - ✅ `isWorkoutCompleted: viewModel.isWorkoutCompleted` - флаг, завершена ли тренировка
      - **Примечание:** Все эти данные находятся в ViewModel, View только передает их в компонент
  - **Упрощения по сравнению с `WorkoutPreviewScreen`:**
    - [ ] **TODO:** Редактор комментария через `TextFieldLink` (см. раздел "Обязательные секции" выше)
    - ✅ Picker для времени отдыха через `makeRestTimePicker`:
      - ✅ Используется `viewModel.restTime` (из ViewModel, а не из локального состояния)
      - ✅ Диапазон значений из `Constants.restPickerOptions` (аналогично основному приложению)
      - ✅ Используется `.pickerStyle(.navigationLink)` для часов
      - ✅ Показывается пикер времени отдыха только если `!viewModel.wasOriginallyPassed` по аналогии с `WorkoutPreviewScreen`
      - ✅ При изменении значения вызывается `viewModel.updateRestTime(newValue)` (аналогично `WorkoutPreviewScreen`)
    - ✅ Редактирование списка упражнений доступно через кнопку редактирования в toolbar (открывает `WorkoutEditView` без `customExercisesSection` для первой итерации)
    - ✅ Отображение планового количества кругов/подходов:
      - ✅ Используется `NavigationLink` + `WorkoutStepperView` (вместо `Stepper` как планировалось, т.к. `WorkoutStepperView` лучше подходит для часов)
      - ✅ Позволяет изменять плановое количество кругов/подходов через вызов `viewModel.updatePlannedCount(for: newValue)` (аналогично `WorkoutPreviewScreen`)
      - ✅ Отключено для типа `.turbo` через `.disabled(viewModel.isPlannedCountDisabled)` (computed property в ViewModel)
  - **ViewModel для экрана превью:**
    - ✅ Создан `WorkoutPreviewViewModel` (TDD подход) - реализован полностью
    - ✅ **Реализация ViewModel (по аналогии с `WorkoutPreviewViewModel` и `HomeViewModel`):**
      - **Архитектурный принцип:** Вся бизнес-логика должна быть в ViewModel, View только отображает данные и вызывает методы ViewModel
      - **Зависимости (через конструктор):**
        - `connectivityService: any WatchConnectivityServiceProtocol` - сервис связи с iPhone для получения данных тренировки
        - `appGroupHelper: any WatchAppGroupHelperProtocol` - хелпер для чтения данных из App Group UserDefaults (для получения `restTime`)
      - **Инициализация:**
        - Инициализатор принимает зависимости: `init(connectivityService:any WatchConnectivityServiceProtocol, appGroupHelper:any WatchAppGroupHelperProtocol?)`
        - По умолчанию `appGroupHelper` создается как `WatchAppGroupHelper()` (аналогично `HomeViewModel`)
      - **Метод загрузки данных:**
        - `loadData(day: Int) async` - загружает данные тренировки и инициализирует ViewModel:
          - Вызывает `connectivityService.requestWorkoutData(day:)` для получения `WorkoutDataResponse`
          - Получает `restTime` через `appGroupHelper.restTime`
          - Вызывает внутренний метод `updateData(workoutDataResponse:restTime:)` для инициализации всех свойств
          - Устанавливает `isLoading` и обрабатывает ошибки
      - **Внутренний метод инициализации:**
        - `updateData(workoutDataResponse: WorkoutDataResponse, restTime: Int)` - инициализирует/обновляет данные ViewModel:
          - Принимает `workoutDataResponse: WorkoutDataResponse` от `connectivityService.requestWorkoutData(day:)`:
            - `workoutDataResponse.workoutData` - данные тренировки (содержит `day`, `executionType`, `trainings`, `plannedCount`)
            - `workoutDataResponse.executionCount` - фактическое количество выполнений из `DayActivity.count` (используется для инициализации `count`)
            - `workoutDataResponse.comment` - комментарий к тренировке из `DayActivity.comment` (используется для инициализации `comment`)
          - Принимает `restTime: Int` от `appGroupHelper.restTime` (время отдыха из App Group UserDefaults)
          - Инициализирует все свойства ViewModel из полученных данных:
            - `dayNumber` из `workoutData.day`
            - `selectedExecutionType` из `workoutData.exerciseExecutionType`
            - `availableExecutionTypes` вычисляется на основе `dayNumber` (аналогично `WorkoutProgramCreator`)
            - `trainings` из `workoutData.trainings`
            - `count` из `workoutDataResponse.executionCount` (фактическое количество выполнений)
            - `plannedCount` из `workoutData.plannedCount`
            - `restTime` из параметра `restTime`
            - `comment` из `workoutDataResponse.comment`
            - `wasOriginallyPassed` вычисляется на основе `count != nil` (если `count` установлен, значит день был пройден)
          - Создает `originalSnapshot` для отслеживания изменений (для вычисления `hasChanges`)
      - **Состояние (State):**
        - `private(set) var isLoading = false` - флаг загрузки данных (аналогично `HomeViewModel`)
        - `private(set) var error: Error?` - ошибка загрузки данных или валидации
        - `dayNumber: Int` - номер дня программы
        - `selectedExecutionType: ExerciseExecutionType?` - выбранный тип выполнения
        - `availableExecutionTypes: [ExerciseExecutionType]` - доступные типы выполнения
        - `trainings: [WorkoutPreviewTraining]` - массив упражнений с возможностью изменения `count`
        - `count: Int?` - фактическое количество кругов/подходов (после выполнения тренировки)
        - `plannedCount: Int?` - плановое количество кругов/подходов
        - `restTime: Int` - время отдыха между подходами/кругами (в секундах)
        - `wasOriginallyPassed: Bool` - флаг, был ли день изначально пройден (для определения, нужно ли показывать пикер времени отдыха)
        - `isWorkoutCompleted: Bool` - флаг, завершена ли тренировка (устанавливается после выполнения тренировки)
        - `workoutDuration: Int?` - длительность выполненной тренировки в секундах
        - `error: TrainingError?` - ошибка валидации при сохранении (может быть объединено с общим `error`)
        - `@ObservationIgnored private var originalSnapshot: DataSnapshot?` - снимок исходных данных для отслеживания изменений
      - **Вычисляемые свойства (Computed Properties):**
        - ✅ `isPlannedCountDisabled: Bool` - определяет, должен ли степпер для `plannedCount` быть отключен (для `.turbo` типа)
        - ✅ `displayedCount: Int?` - отображаемое количество кругов/подходов (`count ?? plannedCount`)
        - ✅ `shouldShowEditButton: Bool` - определяет, нужно ли показывать кнопку редактирования упражнений (только для `.cycles` и `.sets`)
        - ✅ `hasChanges: Bool` - определяет, были ли внесены изменения после первоначальной загрузки (сравнение с `originalSnapshot`)
        - ✅ `selectedExecutionTypeForPicker: ExerciseExecutionType` - выбранный тип выполнения для Picker (неопциональное значение)
        - [ ] **TODO:** `canEditComment: Bool` - определяет, можно ли редактировать комментарий (только если `isWorkoutCompleted || wasOriginallyPassed`, аналогично `WorkoutPreviewScreen`)
      - **Методы (вся бизнес-логика в ViewModel):**
        - ✅ `shouldShowExecutionTypePicker(day: Int, isPassed: Bool) -> Bool` - определяет, нужно ли показывать пикер типа выполнения:
          - Показывается только если данные загружены (dayNumber установлен и trainings не пустой)
          - Показывается только для не пройденных дней (если `isPassed == false`)
          - Показывается только если доступно больше одного типа выполнения
        - ✅ `updateExecutionType(with newType: ExerciseExecutionType)` - обновление типа выполнения и пересчет упражнений (аналогично `WorkoutPreviewViewModel.updateExecutionType()`)
        - ✅ `updatePlannedCount(id: String, action: TrainingRowAction)` - обновление количества повторений для конкретной тренировки или `plannedCount` (аналогично `WorkoutPreviewViewModel.updatePlannedCount()`)
        - ✅ `updatePlannedCount(for newValue: Int)` - обновление планового количества кругов/подходов напрямую по новому значению
        - ✅ `updateTrainingCount(for trainingId: String, newValue: Int)` - обновление количества повторений для конкретной тренировки с удалением при count = 0
        - ✅ `updateRestTime(_ newValue: Int)` - обновление времени отдыха между подходами/кругами
        - ✅ `updateTrainings(_ newTrainings: [WorkoutPreviewTraining])` - обновление списка упражнений тренировки (пересчитывает sortOrder)
        - ✅ `displayExecutionType(for executionType: ExerciseExecutionType) -> ExerciseExecutionType` - получение типа выполнения для отображения (для турбо-режима использует `getEffectiveExecutionType`)
        - ✅ `buildWorkoutResult() -> WorkoutResult` - создание результата тренировки из текущих значений (для отправки на iPhone)
        - ✅ `buildWorkoutData() -> WorkoutData` - получение обновленных данных тренировки (для передачи в `WorkoutView`)
        - ✅ `handleWorkoutResult(_ result: WorkoutResult)` - обработка результата тренировки после выполнения (устанавливает `count`, `workoutDuration`, `isWorkoutCompleted`)
        - ✅ `saveTrainingAsPassed()` - сохранение тренировки через `WatchConnectivityService.sendWorkoutResult()` (аналогично `WorkoutPreviewViewModel.saveTrainingAsPassed()`, но для часов)
        - [ ] **TODO:** `updateComment(_ newComment: String?)` - обновление комментария тренировки (для использования с `TextFieldLink`)
      - **Внутренние структуры:**
        - `DataSnapshot: Equatable` - снимок данных для отслеживания изменений (используется для вычисления `hasChanges`)
        - `TrainingError: Error, LocalizedError, Equatable` - ошибки валидации при сохранении тренировки
      - **Интеграция с View:**
        - View должна использовать `@State private var viewModel = WorkoutPreviewViewModel(connectivityService:appGroupHelper:)` (аналогично `HomeViewModel`)
        - View должна передавать зависимости в ViewModel через конструктор:
          - `WatchConnectivityService` - для запроса данных тренировки с iPhone
          - `WatchAppGroupHelper` - для получения `restTime` из App Group UserDefaults (опционально, по умолчанию создается новый экземпляр)
        - View должна в `.onAppear` или `.task` вызывать `await viewModel.loadData(day:)` (аналогично `HomeView`)
        - ViewModel сам получает данные через свои зависимости и инициализирует себя
        - View должна вызывать методы ViewModel для всех действий пользователя (обновление значений, сохранение и т.д.)
        - View должна получать все данные для отображения из ViewModel (через свойства ViewModel, а не из локального `@State`)
        - View должна передавать данные из ViewModel в дочерние компоненты (`WorkoutPreviewButtonsView`, `WorkoutStepperView` и т.д.)
        - View не должна содержать бизнес-логику (только логику отображения)
        - View должна использовать Binding для двусторонней связи с ViewModel (например, `Binding(get: { viewModel.restTime }, set: { viewModel.updateRestTime($0) })`)
        - View должна обрабатывать ошибки из ViewModel (через `viewModel.error`, аналогично `WorkoutPreviewScreen`)
        - View должна отображать состояние загрузки (через `viewModel.isLoading`, аналогично `HomeViewModel`)
  - **Интеграция:**
    - **Важно:** `WorkoutPreviewView` всегда должен идти до экрана тренировки (`WorkoutView`)
    - **Сценарий 1:** Если активность для дня еще не выбрана и пользователь выбирает `.workout`:
      - ✅ Реализовано: В `HomeViewModel.selectActivity(_:)` после успешной отправки активности `.workout` загружаются данные тренировки через `connectivityService.requestWorkoutData(day:)`
      - При загрузке данных тренировки также получать информацию о доступных типах выполнения (`availableExecutionTypes`) и статусе пройденности дня (`isPassed`) для правильной работы `executionTypePicker`
      - ✅ Реализовано: Открытие `WorkoutPreviewView` с загруженными данными через `.fullScreenCover(isPresented: $showEditWorkout)` в `HomeView` или `DayActivityView`
      - Пользователь может выбрать тип выполнения (если доступно), настроить количество повторений и начать тренировку или сохранить как пройденную
    - **Сценарий 2:** Если активность `.workout` уже выбрана и пользователь нажимает кнопку редактирования в `SelectedActivityView`:
      - В `SelectedActivityView` добавить замыкание `onEditWorkout: (Int, WorkoutData) -> Void`
      - Вызывать `onEditWorkout(dayNumber, workoutData)` при нажатии на кнопку редактирования (убрать TODO на строке 140)
      - При открытии `WorkoutPreviewView` также получать информацию о доступных типах выполнения (`availableExecutionTypes`) и статусе пройденности дня (`isPassed`) для правильной работы `executionTypePicker`
      - Открыть `WorkoutPreviewView` с переданными данными через `.fullScreenCover(isPresented: $showEditWorkout)` в `HomeView` или `DayActivityView`
    - ✅ Реализовано: В `HomeView` или `DayActivityView` открытие `WorkoutPreviewView` обрабатывается через `.fullScreenCover(isPresented: $showEditWorkout)`
    - ✅ Реализовано: Передача `workoutData` из `HomeViewModel` в `WorkoutPreviewView`
  - **Локализация:**
    - Использовать существующие ключи из основного приложения где возможно:
      - `.workoutPreviewStartTraining` для "Начать тренировку"
      - `.workoutPreviewSaveAsPassed` для "Сохранить как пройденную"
    - Добавить новые ключи только если они специфичны для часов и не существуют
    - Добавить переводы на русский и английский языки
    - Установить статус новых переводов: `"state" : "needs_review"`
  - **Примечание:** Экран превью тренировки открывается в двух случаях:
    1. При выборе активности `.workout` для дня (если активность еще не выбрана) - после успешного сохранения активности
    2. При нажатии на кнопку редактирования в `SelectedActivityView` для уже выбранной тренировки
    - Для не-тренировочных активностей редактирование уже реализовано через `DayActivitySelectionView` (NavigationLink на строках 145-152)

#### 6.4 Экран выполнения тренировки
- [ ] **Создать `WorkoutView.swift`:**
  - **Важно:** Экран открывается только из `WorkoutPreviewView` при нажатии на кнопку "Начать тренировку"
  - **Важно:** `WorkoutPreviewView` всегда должен идти до экрана тренировки - пользователь не может попасть на `WorkoutView` напрямую, минуя экран превью
  - Экран выполнения тренировки
  - Упрощенный интерфейс для часов:
    - Отображение текущего упражнения (название через `ExerciseType.localizedTitle` или `ExerciseType.makeLocalizedTitle`, иконка через `ExerciseType.image` из `ExercisesAssets.xcassets`)
    - Отображение текущего круга/подхода
    - Кнопка "Завершить круг/подход"
    - Кнопка "Завершить тренировку"
    - Кнопка "Прервать тренировку"
    - Отображение времени тренировки
  - **Таймер отдыха между кругами/подходами:**
    - Создать `WorkoutRestTimerView.swift` - упрощенная версия таймера отдыха для часов (аналогично `WorkoutTimerScreen` из основного приложения)
    - Показывать таймер отдыха после завершения круга/подхода (если есть время отдыха)
    - Отображать оставшееся время отдыха в формате MM:SS
    - Круговой прогресс-бар (адаптированный для маленького экрана часов)
    - Кнопка "Завершить" для досрочного завершения отдыха
    - Автоматическое завершение при достижении 0 секунд
    - Обработка фонового режима (сворачивание/разворачивание приложения) - вычисление правильного оставшегося времени на основе реального прошедшего времени
    - Отслеживание `scenePhase` для обработки сворачивания/разворачивания
    - Показывать через `fullScreenCover` или модальный экран поверх `WorkoutView`
    - Интеграция с `WorkoutViewModel.handleRestTimerFinish(force:)` для обработки завершения
    - **Планирование уведомлений об отдыхе:**
      - Планировать уведомление об окончании отдыха по аналогии с основным приложением
      - Если пользователь начал отдых и свернул приложение на часах или заблокировал экран, после окончания отдыха должно показаться уведомление
      - Важно сохранить ту же логику для уведомления, что и в основном приложении
      - Уведомления не должны конфликтовать между часами и iPhone (использовать уникальные идентификаторы для уведомлений на часах)
      - При досрочном завершении отдыха (кнопка "Завершить") отменять запланированное уведомление
      - При завершении тренировки или её прерывании отменять все запланированные уведомления об отдыхе
    - **Отличия для первой итерации часов:**
      - НЕ нужно делать вибрацию при окончании отдыха между кругами/подходами
      - НЕ нужно воспроизводить звук при окончании отдыха между кругами/подходами
      - Остальная логика остается по аналогии с основным приложением
  - Индикатор сохранения результата
  - Обработка ошибок
  - Локализованные строки в `Localizable.xcstrings` (общий файл):
    - Проверить наличие ключей для "Упражнение", "Круг" - если есть, использовать их, иначе добавить новые
    - `Watch.Workout.Exercise` - "Упражнение" (новый ключ, если не существует в основном приложении)
    - `Watch.Workout.Round` - "Круг" (новый ключ, если не существует в основном приложении)
    - `Watch.Workout.CompleteRound` - "Завершить круг" (новый ключ, специфичен для часов)
    - Проверить наличие ключа для "Завершить тренировку" - если есть, использовать его, иначе добавить `Watch.Workout.Finish`
    - Проверить наличие ключа для "Прервать тренировку" - если есть, использовать его, иначе добавить `Watch.Workout.Cancel`
    - `Watch.Workout.Saving` - "Сохранение..." (новый ключ, специфичен для часов)
    - `Watch.Workout.Error` - "Ошибка сохранения" (новый ключ, специфичен для часов)
    - Для таймера отдыха:
      - Использовать существующий ключ `TimerScreen.Title` для "Отдых" (если есть в основном приложении)
      - Использовать существующий ключ `TimerScreen.FinishButton` для "Завершить" (если есть в основном приложении)
      - Если ключи не существуют, добавить `Watch.Timer.Title` и `Watch.Timer.FinishButton`
  - Добавить переводы на русский и английский языки
  - Установить статус новых переводов: `"state" : "needs_review"`
  - Минималистичный дизайн для часов

#### 6.5 Навигация и главный файл приложения
- [ ] Обновить `SotkaWatchApp.swift`:
  - Настройка навигации между экранами
  - Проверка авторизации при запуске
  - Переход на `AuthRequiredView` если не авторизован
  - Переход на `HomeView` если авторизован
  - Настройка NavigationStack для навигации между экранами
  - **Проверка статуса авторизации при активации приложения:**
    - Использовать модификатор `.task(id: scenePhase)` для отслеживания изменений `scenePhase`
    - При переходе `scenePhase` в `.active` вызывать `HomeViewModel.checkAuthStatusOnActivation()` для проверки актуального статуса авторизации из App Group UserDefaults
    - Это обеспечивает получение актуального статуса авторизации даже если команда `PHONE_COMMAND_AUTH_STATUS_CHANGED` не была доставлена при логауте (например, при отсутствии связи)
    - При авторизации часы читают статус из App Group UserDefaults, команда не требуется
- [ ] Настроить навигацию:
  - Простая навигация между экранами
  - Кнопка "Назад" на каждом экране (где нужно)
  - Минимальное количество экранов
  - Быстрый доступ к основным функциям

### Этап 7: UI/UX оптимизация для часов

#### 7.1 Адаптация дизайна
- [ ] Минималистичный дизайн для маленького экрана
- [ ] Крупные кнопки для удобного нажатия
- [ ] Оптимизация шрифтов для читаемости
- [ ] Использование системных цветов и иконок
- [ ] Поддержка темной темы

#### 7.2 Обратная связь
- [ ] Haptic feedback при действиях
- [ ] Визуальная обратная связь (анимации)
- [ ] Индикаторы загрузки и синхронизации
- [ ] Сообщения об ошибках

### Этап 8: Финальное тестирование и документация

#### 8.1 Интеграционные тесты
- [ ] Тесты синхронизации между часами и iPhone (моки)
- [ ] Тесты обработки команд WatchConnectivity
- [ ] Тесты офлайн-работы (отсутствие связи с iPhone)

#### 8.2 UI-тесты (опционально)
- [ ] Тесты основных сценариев использования
- [ ] Тесты навигации между экранами
- [ ] Тесты выбора активности
- [ ] Тесты выполнения тренировки

#### 8.3 Тестирование на устройствах
- [ ] Тестирование на реальных часах (разные модели)
- [ ] Тестирование синхронизации между часами и iPhone
- [ ] Тестирование офлайн-работы
- [ ] Тестирование производительности

#### 8.4 Документация
- [ ] Обновление `feature-map.md` с информацией о часах
- [ ] Создание документации по архитектуре часов (если нужно)
- [ ] Документация API WatchConnectivity
- [ ] Инструкции по тестированию

#### 8.5 Оптимизация
- [ ] Оптимизация размера приложения
- [ ] Оптимизация производительности
- [ ] Оптимизация энергопотребления
- [ ] Оптимизация синхронизации

#### 8.6 Финальная проверка
- [ ] Проверка всех функций
- [ ] Проверка синхронизации
- [ ] Проверка офлайн-работы
- [ ] Проверка на разных моделях часов
- [ ] Проверка локализации (русский и английский)
- [ ] Проверка логирования (русский язык)
- [ ] Проверка безопасного извлечения опционалов (нет force unwrap)

## Технические детали

### Модели данных

#### Модели с Codable для передачи данных

**WorkoutResult** (обновлена для поддержки Codable):
```swift
// Models/Workout/WorkoutResult.swift
struct WorkoutResult: Equatable, Codable {
    let count: Int
    let duration: Int?
}
```

**WorkoutPreviewTraining** (обновлена для поддержки Codable):
```swift
// Models/Workout/WorkoutPreviewTraining.swift
struct WorkoutPreviewTraining: Equatable, Identifiable, Codable {
    let id: String
    let count: Int?
    let typeId: Int?
    let customTypeId: String?
    let sortOrder: Int?
    // ... остальные методы и свойства
}
```

**WorkoutData** (структура для передачи данных тренировки):
```swift
// Models/SWSharedModels/WorkoutData.swift
struct WorkoutData: Codable, Equatable {
    let day: Int
    let executionType: Int  // ExerciseExecutionType.rawValue
    let trainings: [WorkoutPreviewTraining]
    let plannedCount: Int?
    
    // Вычисляемое свойство для преобразования executionType в enum
    var exerciseExecutionType: ExerciseExecutionType? {
        ExerciseExecutionType(rawValue: executionType)
    }
}
```

**WorkoutDataResponse** (структура для передачи полных данных тренировки с iPhone на Apple Watch):
```swift
// Models/SWSharedModels/WorkoutDataResponse.swift
struct WorkoutDataResponse: Codable, Equatable {
    let workoutData: WorkoutData
    let executionCount: Int?  // Фактическое количество выполнений из DayActivity.count
    let comment: String?      // Комментарий к тренировке из DayActivity.comment
}
```

**Примечание:**
- Простые структуры (`WorkoutResult`, `WorkoutPreviewTraining`) получают Codable для прямой передачи через WatchConnectivity
- Enum'ы (`DayActivityType`, `ExerciseExecutionType`) передаются через rawValue (Int)
- `WorkoutData` - структура для передачи данных тренировки, размещается в общих моделях (`Models/SWSharedModels/`)
- `WorkoutDataResponse` - структура для передачи полных данных тренировки с iPhone на Apple Watch, включает `WorkoutData`, `executionCount`, `comment`
- `ExerciseType` добавлен в Watch App target для использования локализованных названий упражнений и иконок на экране тренировки
- Ассеты упражнений находятся в отдельном `ExercisesAssets.xcassets`, доступном обоим таргетам, что позволяет использовать иконки упражнений без дублирования
- Модели с `@Model` (SwiftData) не используются напрямую на часах, только для преобразования в простые структуры

### Команды WatchConnectivity

```swift
extension Constants {
    /// Команды для обмена данными между часами и iPhone через WatchConnectivity
    enum WatchCommand: String {
        // От часов к iPhone
        case setActivity = "WATCH_COMMAND_SET_ACTIVITY"
        case saveWorkout = "WATCH_COMMAND_SAVE_WORKOUT"
        case getCurrentActivity = "WATCH_COMMAND_GET_CURRENT_ACTIVITY"
        case getWorkoutData = "WATCH_COMMAND_GET_WORKOUT_DATA"
        case deleteActivity = "WATCH_COMMAND_DELETE_ACTIVITY"
        
        // От iPhone к часам
        case currentActivity = "PHONE_COMMAND_CURRENT_ACTIVITY"
        case sendWorkoutData = "PHONE_COMMAND_SEND_WORKOUT_DATA"
        case authStatusChanged = "PHONE_COMMAND_AUTH_STATUS_CHANGED"
    }
}
```

**Примечание:** Enum `Constants.WatchCommand` находится в файле `SwiftUI-SotkaApp/Models/SWSharedModels/Constants.swift` и доступен обоим таргетам (основному приложению и Watch App).

### Формат сообщений WatchConnectivity

**Установка активности:**
```json
{
    "command": "WATCH_COMMAND_SET_ACTIVITY",
    "day": 42,
    "activityType": 0
}
```

**Сохранение тренировки:**
```json
{
    "command": "WATCH_COMMAND_SAVE_WORKOUT",
    "day": 42,
    "result": {
        "count": 4,
        "duration": 1800
    },
    "executionType": 0,
    "trainingType": 1
}
```
*Примечание: `result` содержит сериализованный `WorkoutResult` (Codable) в JSON формате*

**Удаление активности:**
```json
{
    "command": "WATCH_COMMAND_DELETE_ACTIVITY",
    "day": 42
}
```

**Примечание:** Команды проверки авторизации и получения/обновления текущего дня не нужны (см. раздел 1.3). Команды для получения данных пользователя также не нужны - часы не отображают данные пользователя (имя, email и т.д.).

**Ответ с текущей активностью дня:**
```json
{
    "command": "PHONE_COMMAND_CURRENT_ACTIVITY",
    "day": 42,
    "activityType": 0,
    "count": null,
    "duration": null
}
```

**Уведомление об изменении статуса авторизации:**
```json
{
    "command": "PHONE_COMMAND_AUTH_STATUS_CHANGED",
    "isAuthorized": true
}
```
*Примечание: Команда отправляется при успешной авторизации (`isAuthorized: true`) или при логауте (`isAuthorized: false`). Часы также проверяют статус авторизации при активации приложения через `task(id: scenePhase)` для обеспечения актуальности данных даже при отсутствии связи.*

## Риски и митигация

### Риск 1: Ограничения WatchConnectivity
- **Проблема:** WatchConnectivity может быть недоступен или нестабилен
- **Митигация:** Реализовать очередь несинхронизированных действий, повторные попытки синхронизации

### Риск 2: Различия в данных между часами и iPhone
- **Проблема:** Данные на часах могут отличаться от данных на iPhone
- **Митигация:** iPhone является основным источником истины, часы получают обновления от iPhone

### Риск 3: Производительность на часах
- **Проблема:** Ограниченные ресурсы часов могут влиять на производительность
- **Митигация:** Оптимизация кода, минимальное использование ресурсов, кэширование данных

### Риск 4: Сложность синхронизации
- **Проблема:** Синхронизация между часами и iPhone может быть сложной
- **Митигация:** Простая архитектура синхронизации, четкие команды, обработка ошибок

### Риск 5: Работа часов без авторизации
- **Проблема:** Часы могут попытаться работать без авторизации на iPhone
- **Митигация:** Обязательная проверка авторизации при запуске, блокировка функционала без авторизации, экран с сообщением о необходимости авторизации

### Риск 6: Отсутствие связи с iPhone
- **Проблема:** Часы могут быть недоступны для связи с iPhone
- **Митигация:** Показ сообщения об ошибке, блокировка действий, требующих сохранения данных. Минимальное кэширование только для отображения текущего дня (опционально)

## Приоритеты разработки

### Высокий приоритет (MVP)
1. **Добавление Codable к простым моделям** для передачи данных
2. **Проверка авторизации и блокировка функционала без авторизации**
3. **Запрос данных с iPhone** (текущий день, активность, данные тренировки)
4. **Отправка действий в iPhone** для сохранения в SwiftData (с использованием Codable моделей)
5. Главный экран с отображением текущего дня (только для авторизованных)
6. Выбор типа активности (сохранение через iPhone)
7. Обработка отсутствия связи с iPhone

### Средний приоритет
1. Выполнение тренировки
2. Сохранение результата тренировки
3. Полная синхронизация данных

### Низкий приоритет (будущие улучшения)
1. Расширенная статистика тренировок
2. Интеграция с HealthKit
3. Уведомления о тренировках
4. Циферблаты с данными программы

## Отличия от реализации в старом приложении (SOTKA-OBJc)

Этот раздел описывает ключевые отличия планируемой реализации в новом приложении от реализации в старом приложении SOTKA-OBJc.

### Архитектура хранения данных

**Старое приложение (SOTKA-OBJc):**
- Часы используют **CoreData** для локального хранения данных
- Модели: `WatchDbDay`, `WatchDbTraining`, `WatchDbCustomExercise`, `WatchDbSettings`
- Данные сохраняются локально на часах с флагом `synched` для отслеживания синхронизации
- Двусторонняя синхронизация: часы работают независимо, синхронизируются периодически
- Очередь несинхронизированных данных на часах

**Новое приложение:**
- Часы **не хранят данные локально** (статус авторизации читается напрямую из UserDefaults App Group, без отдельного кэширования)
- Все данные запрашиваются с iPhone в реальном времени
- iPhone является **единственным хранилищем данных** (SwiftData)
- Часы работают как **клиент iPhone приложения**
- Нет очереди синхронизации - все действия передаются немедленно

### Формат передачи данных

**Старое приложение:**
- Используются **JSON строки** (NSString) в Dictionary
- Команды передаются как **числовые константы** (enum WATCH_COMMANDS: 0, 1, 2...)
- Данные сериализуются в JSON строку через `toJSONString()`
- Пример: `@{@"command": @"0", @"days": jsonString}`

**Новое приложение:**
- Используются **модели с Codable** для прямой передачи данных (без DTO)
- Команды передаются как **строковые enum** (WatchCommand: "WATCH_COMMAND_GET_TRAIN_LIST")
- Данные сериализуются через JSONEncoder/JSONDecoder
- Пример: `{"command": "WATCH_COMMAND_SAVE_WORKOUT", "result": {...}}`

### Команды WatchConnectivity

**Старое приложение:**
- `WATCH_COMMAND_GET_TRAIN_LIST` (0) - запрос данных тренировки
- `WATCH_COMMAND_SAVE_TRAININGS` (1) - сохранение тренировок (массив дней)
- `PHONE_COMMAND_UPDATE_CURRENT_DAY` (2) - обновление текущего дня
- `PHONE_SYNC_REQUEST` (3) - запрос синхронизации
- `PHONE_COMMAND_GET_UNSYNCED_TRAININGS` (4) - запрос несинхронизированных тренировок

**Новое приложение:**
- Расширенный набор команд с явными названиями
- Более детальное разделение команд (отдельно для активности и тренировки)
- **Примечание:** Команды проверки авторизации и выхода из аккаунта не нужны, так как статус авторизации читается напрямую из App Group UserDefaults (см. раздел 1.3). Команды для получения данных пользователя также не нужны - часы не отображают данные пользователя.

### Авторизация

**Старое приложение:**
- Не видно явной проверки авторизации при запуске часов
- Часы могут работать без явной проверки статуса авторизации

**Новое приложение:**
- **Обязательная проверка авторизации** при запуске приложения на часах
- Блокировка функционала без авторизации
- Экран `AuthRequiredView` для неавторизованных пользователей
- Статус авторизации читается напрямую из App Group UserDefaults (см. раздел 1.3)

### Обработка данных тренировки

**Старое приложение:**
- Данные тренировки передаются как `WatchObject` (JSON строка)
- Сохранение тренировок происходит пакетами (массив дней)
- Локальное сохранение на часах перед синхронизацией

**Новое приложение:**
- Данные тренировки передаются через модели с Codable (`WorkoutData`, `WorkoutResult`)
- Сохранение происходит по одной активности/тренировке
- Немедленная передача в iPhone без локального сохранения

### Синхронизация

**Старое приложение:**
- Двусторонняя синхронизация с флагом `synched`
- Часы могут работать офлайн с последующей синхронизацией
- Очередь несинхронизированных данных на часах
- iPhone может запрашивать несинхронизированные данные с часов

**Новое приложение:**
- Односторонняя передача данных: часы → iPhone (для сохранения)
- Часы запрашивают данные с iPhone в реальном времени
- Нет очереди синхронизации - все действия передаются немедленно
- При отсутствии связи показывается ошибка, действия не выполняются

### Технологии

**Старое приложение:**
- Objective-C
- CoreData на часах
- UIKit для часов (WatchKit)
- JSON строки для передачи данных

**Новое приложение:**
- Swift 6.0
- SwiftData на iPhone (не используется на часах)
- SwiftUI для часов
- Codable модели для прямой передачи данных (без DTO)

### Преимущества нового подхода

1. **Упрощенная архитектура:**
   - Нет дублирования данных между часами и iPhone
   - Нет конфликтов данных
   - Проще поддержка и отладка

2. **Актуальность данных:**
   - Данные всегда актуальны (запрашиваются в реальном времени)
   - Нет рассинхронизации между устройствами

3. **Безопасность:**
   - Обязательная проверка авторизации
   - Данные хранятся только на iPhone

4. **Современные технологии:**
   - SwiftUI вместо WatchKit
   - SwiftData вместо CoreData
   - Codable модели вместо ручной сериализации JSON и DTO

### Недостатки нового подхода

1. **Зависимость от связи:**
   - Часы не могут работать полностью офлайн
   - Требуется постоянная связь с iPhone для работы

2. **Производительность:**
   - Каждый запрос требует связи с iPhone
   - Может быть медленнее при плохой связи

3. **Ограничения:**
   - Меньше автономности часов
   - Зависимость от доступности iPhone

## Заключение

Этот план описывает детальную разработку приложения для Apple Watch с сокращенным функционалом по сравнению с основным iOS-приложением. Основные компоненты:

1. **Авторизация** - проверка статуса авторизации и блокировка функционала без авторизации
2. **Локальное вычисление текущего дня** - вычисляется локально на часах из `startDate` с помощью `DayCalculator` (см. раздел 1.3)
3. **Запрос данных с iPhone** - данные активности и тренировок запрашиваются с iPhone в реальном времени
4. **Сохранение через iPhone** - все действия передаются в iPhone для сохранения в SwiftData
5. **Главный экран** - отображение текущего дня и активности (только для авторизованных)
6. **Выбор активности** - выбор типа активности из 4 вариантов (сохранение через iPhone)
7. **Выполнение тренировки** - упрощенный интерфейс для выполнения тренировки (данные с iPhone, сохранение через iPhone)

### Ключевые принципы

- **iPhone приложение - единственное хранилище данных**: все данные хранятся только на iPhone в SwiftData, часы не хранят данные локально
- **Часы как клиент**: часы запрашивают данные с iPhone и отправляют действия для сохранения, не хранят данные самостоятельно
- **Обязательная авторизация**: приложение для часов работает только после успешной авторизации в iPhone приложении
- **Чтение статуса авторизации и `startDate`**: напрямую из App Group UserDefaults (см. раздел 1.3)
- **Текущий день**: вычисляется локально на часах из `startDate` с помощью `DayCalculator`
- **Безопасность**: при выходе из аккаунта статус обновляется в App Group UserDefaults
- **Обработка офлайн-режима**: при отсутствии связи с iPhone показывать сообщение об ошибке, не выполнять действия, требующие сохранения

Приложение для часов работает как клиент iPhone приложения, запрашивая данные и отправляя действия для сохранения. Все данные хранятся только на iPhone в SwiftData, что упрощает архитектуру и исключает конфликты данных.

