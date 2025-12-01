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
- **Статус авторизации** читается напрямую из UserDefaults (App Group), без отдельного кэширования на часах
- **Текущий день** запрашивается с iPhone через WatchConnectivity в реальном времени, без кэширования
- **iPhone приложение является единственным хранилищем данных** (SwiftData)
- **Приложение для часов работает только после успешной авторизации в iPhone приложении**
- **iPhone приложение является единственным источником истины для всех данных**

## Архитектура

### Структура проекта

```
SotkaWatch Watch App/
├── DTOs/
│   ├── WorkoutResultDTO.swift          # DTO для передачи результата тренировки
│   ├── WorkoutPreviewTrainingDTO.swift # DTO для передачи данных упражнений
│   └── WorkoutDataDTO.swift            # DTO для передачи данных тренировки
├── Services/
│   ├── WatchConnectivityService.swift  # Сервис для связи с iPhone
│   ├── WatchAuthService.swift          # Сервис для проверки авторизации
│   └── WatchWorkoutService.swift       # Логика выполнения тренировки (UI логика)
├── ViewModels/
│   ├── HomeViewModel.swift             # ViewModel для главного экрана
│   └── WorkoutViewModel.swift          # ViewModel для экрана тренировки
├── Screens/
│   ├── AuthRequiredView.swift          # Экран для неавторизованных пользователей
│   ├── HomeView.swift                   # Главный экран часов
│   ├── DayActivityView.swift           # Экран активности дня (выбор/отображение) ✅
│   ├── DayActivitySelectionView.swift  # Выбор типа активности ✅
│   ├── SelectedActivityView.swift      # Отображение выбранной активности ✅
│   ├── WorkoutView.swift               # Экран выполнения тренировки (еще не создан)
│   └── WorkoutRestTimerView.swift      # Таймер отдыха между кругами/подходами (еще не создан)
└── Utilities/
    └── WatchConstants.swift            # Константы для часов (enum команд WatchConnectivity)

Примечание: 
- Модели данных используются из основного приложения (без изменений):
  - Models/Workout/WorkoutResult.swift
  - Models/Workout/WorkoutPreviewTraining.swift
  - Models/Workout/DayActivityType.swift
  - Models/Workout/ExerciseExecutionType.swift
  - Models/Workout/ExerciseType.swift
- DTO-структуры создаются отдельно для передачи данных через WatchConnectivity
- Существующие модели не изменяются (не добавляется Codable)
```

### Технологии

- **SwiftUI** - для UI (watchOS поддерживает SwiftUI)
- **WatchConnectivity** - для связи с iPhone
- **UserDefaults** (App Group) - только для чтения статуса авторизации (напрямую из основного приложения)
- **OSLog** - для логирования

**Важно:** 
- Часы не используют SwiftData или другое постоянное хранилище. Все данные запрашиваются с iPhone в реальном времени.
- **Модели переиспользуются из основного приложения** - не создаем дубликаты моделей для часов.
- **Существующие модели не изменяются** - не добавляем Codable к моделям.
- **DTO-структуры** создаются отдельно для передачи данных через WatchConnectivity.
- Модели с `@Model` (SwiftData) не используются напрямую на часах, только для преобразования в DTO.

### Обмен данными между часами и iPhone

#### WatchConnectivity Service

**Архитектура связи:**
- **iPhone является единственным хранилищем данных** (SwiftData)
- **Часы не хранят данные локально** - все данные запрашиваются с iPhone в реальном времени
- **Все действия с часов передаются в iPhone** для сохранения в SwiftData
- Связь выполняется через WatchConnectivity Framework
- **Чтение статуса авторизации** напрямую из UserDefaults (App Group) - без отдельного кэширования на часах
- **Текущий день** запрашивается с iPhone через WatchConnectivity в реальном времени, без кэширования

**Команды синхронизации:**

1. **От часов к iPhone:**
   - `WATCH_COMMAND_SET_ACTIVITY` - установка типа активности для дня (сохранение в SwiftData)
   - `WATCH_COMMAND_SAVE_WORKOUT` - сохранение результата тренировки (сохранение в SwiftData)
   - `WATCH_COMMAND_GET_CURRENT_DAY` - запрос текущего дня программы
   - `WATCH_COMMAND_GET_CURRENT_ACTIVITY` - запрос текущей активности дня
   - `WATCH_COMMAND_GET_USER_DATA` - запрос данных пользователя (опционально)
   - `WATCH_COMMAND_GET_WORKOUT_DATA` - запрос данных тренировки для дня
   - **Примечание:** Команда `WATCH_COMMAND_CHECK_AUTH` не нужна, так как статус авторизации читается напрямую из UserDefaults (App Group)

2. **От iPhone к часам:**
   - `PHONE_COMMAND_USER_DATA` - данные пользователя (User, опционально)
   - `PHONE_COMMAND_UPDATE_CURRENT_DAY` - обновление текущего дня
   - `PHONE_COMMAND_CURRENT_ACTIVITY` - текущая активность дня
   - `PHONE_COMMAND_SEND_WORKOUT_DATA` - отправка данных тренировки для дня
   - `PHONE_COMMAND_LOGOUT` - команда выхода из аккаунта (опционально, так как статус обновляется в UserDefaults)
   - **Примечание:** Команда `PHONE_COMMAND_AUTH_STATUS` не нужна, так как статус авторизации читается напрямую из UserDefaults (App Group)

**Формат данных:**
- JSON для передачи сложных структур
- Простые типы (Int, String, Bool) для простых команд

## Детальный план реализации

**Важно:** План следует принципам TDD (Test-Driven Development). Сначала пишутся тесты, затем реализация. UI реализуется в последнюю очередь.

### Принципы локализации для Watch App

1. **Использование общего файла локализации:**
   - Файл `SupportingFiles/Localizable.xcstrings` уже добавлен в Watch App target
   - Все строки для часов добавляются в этот же файл с префиксом `Watch.*`
   - Использование общего файла упрощает поддержку и позволяет переиспользовать общие строки

2. **Локализация displayName для часов:**
   - ✅ **Выполнено:** Создан файл `InfoPlist.xcstrings` для Watch App target
   - ✅ **Выполнено:** Настроена локализация `CFBundleDisplayName` (название приложения на часах)
   - ✅ **Выполнено:** Настроен Target Membership в Xcode

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

### Этап 1: Настройка проекта и инфраструктуры

#### 1.1 Настройка Watch App Target
- [ ] Проверить настройки Watch App в Xcode проекте
- [ ] Настроить App Groups для обмена данными между iPhone и часами (см. детали в разделе 1.3)
- [ ] Настроить WatchConnectivity capabilities
- [ ] Настроить минимальную версию watchOS (совместимо с iOS 17.0+)
- [ ] Добавить необходимые разрешения (если нужны)
- [ ] Настроить OSLog для логирования на часах (русский язык в логах)
- [ ] **Настроить Target Membership для общих моделей:**
  - Добавить `Models/Workout/WorkoutResult.swift` в Watch App target
  - Добавить `Models/Workout/WorkoutPreviewTraining.swift` в Watch App target
  - Добавить `Models/Workout/DayActivityType.swift` в Watch App target
  - Добавить `Models/Workout/ExerciseExecutionType.swift` в Watch App target
  - Добавить `Models/Workout/ExerciseType.swift` в Watch App target (если нужен)
  - Проверить, что зависимости (например, SWUtils) доступны для Watch App target
- [ ] Проверить зависимости моделей:
  - Убедиться, что все импорты доступны для Watch App (Foundation, SwiftUI и т.д.)
  - Если модели используют SwiftData (@Model), они не нужны на часах напрямую
  - Модели используются только для преобразования в DTO и обратно
- [ ] **Доработать AuthHelper для использования App Group** (см. детали в разделе 1.3):
  - Проверить, использует ли `AuthHelperImp` App Group для UserDefaults
  - Если нет - доработать `AuthHelperImp` для использования `UserDefaults(suiteName: "group.com.sotka.app")` вместо `UserDefaults.standard`
  - Убедиться, что ключ `isAuthorized` сохраняется в App Group UserDefaults
  - Обновить тесты для AuthHelper (если нужно)

#### 1.2 Создание констант и утилит
- [ ] Создать `WatchConstants.swift` - enum для команд WatchConnectivity
  - Команды от часов к iPhone: `WATCH_COMMAND_SET_ACTIVITY`, `WATCH_COMMAND_SAVE_WORKOUT`, `WATCH_COMMAND_GET_CURRENT_DAY`, `WATCH_COMMAND_GET_CURRENT_ACTIVITY`, `WATCH_COMMAND_GET_WORKOUT_DATA`
  - Команды от iPhone к часам: `PHONE_COMMAND_USER_DATA`, `PHONE_COMMAND_UPDATE_CURRENT_DAY`, `PHONE_COMMAND_CURRENT_ACTIVITY`, `PHONE_COMMAND_SEND_WORKOUT_DATA`, `PHONE_COMMAND_LOGOUT`
  - **Примечание:** Команды `WATCH_COMMAND_CHECK_AUTH` и `PHONE_COMMAND_AUTH_STATUS` не нужны, так как статус авторизации читается напрямую из UserDefaults (App Group)
- [ ] Создать утилиты для работы с UserDefaults (App Group) для чтения статуса авторизации (см. детали в разделе 1.3)
- [x] **Настроить локализацию displayName для часов:** ✅ **Выполнено**
  - ✅ Создан `InfoPlist.xcstrings` для Watch App target
  - ✅ Добавлен ключ `CFBundleDisplayName` с локализованными значениями
  - ✅ Настроен Target Membership для `InfoPlist.xcstrings` в Watch App target
  - ✅ Настроено использование `InfoPlist.xcstrings` в build settings Watch App

#### 1.3 Настройка App Group для обмена данными между iPhone и часами

**Цель:** Настроить App Group для обмена данными через UserDefaults между основным iOS-приложением и Watch App. Это необходимо для чтения статуса авторизации на часах без использования WatchConnectivity.

**Шаги настройки в Xcode:**

1. **Настройка App Group для основного iOS-приложения:**
   - Открыть проект в Xcode
   - Выбрать основной iOS target (SwiftUI-SotkaApp)
   - Перейти в раздел "Signing & Capabilities"
   - Нажать "+ Capability" и добавить "App Groups"
   - Добавить новый App Group с идентификатором: `group.com.sotka.app`
   - Убедиться, что App Group включен (галочка установлена)

2. **Настройка App Group для Watch App:**
   - Выбрать Watch App target (SotkaWatch Watch App)
   - Перейти в раздел "Signing & Capabilities"
   - Нажать "+ Capability" и добавить "App Groups"
   - Добавить тот же App Group с идентификатором: `group.com.sotka.app`
   - Убедиться, что App Group включен (галочка установлена)
   - **Важно:** Идентификатор App Group должен быть одинаковым для обоих targets

3. **Проверка настройки:**
   - Убедиться, что оба target используют один и тот же App Group идентификатор
   - Проверить, что App Group включен для обоих targets
   - Убедиться, что оба target подписаны одним и тем же Team ID (для работы App Group)

**Доработка AuthHelper для использования App Group:**

- [ ] Проверить текущую реализацию `AuthHelperImp`:
  - Открыть файл `Services/AuthHelper.swift`
  - Проверить, использует ли класс `UserDefaults.standard` или `UserDefaults(suiteName:)`
  - Если используется `UserDefaults.standard`, необходимо перейти на App Group

- [ ] Доработать `AuthHelperImp`:
  - Заменить `UserDefaults.standard` на `UserDefaults(suiteName: "group.com.sotka.app")`
  - Убедиться, что используется безопасное извлечение (проверка на nil)
  - Убедиться, что ключ `isAuthorized` сохраняется в App Group UserDefaults
  - Проверить, что все операции с UserDefaults используют App Group

- [ ] Обновить тесты для AuthHelper:
  - Обновить моки UserDefaults в тестах для использования App Group
  - Добавить тесты для проверки работы с App Group UserDefaults
  - Добавить тесты для обработки случая, когда App Group недоступен

**Создание утилит для работы с App Group на часах:**

- [ ] Создать утилиты для чтения статуса авторизации:
  - Создать файл в папке `SotkaWatch Watch App/Utilities/` (например, `WatchAppGroupHelper.swift` или добавить в существующий файл утилит)
  - Реализовать функцию/метод для чтения статуса авторизации из App Group UserDefaults
  - Использовать `UserDefaults(suiteName: "group.com.sotka.app")` для доступа к App Group
  - Использовать тот же ключ, что и в `AuthHelperImp` (Key.isAuthorized.rawValue)
  - Реализовать безопасное извлечение значения (возвращать `false` если значение отсутствует или App Group недоступен)
  - Добавить логирование через OSLog на русском языке для отладки

- [ ] Принципы работы утилит:
  - Утилиты должны только читать данные из App Group UserDefaults
  - Не кэшировать статус отдельно - всегда читать напрямую из UserDefaults
  - Обрабатывать случаи, когда App Group недоступен (возвращать `false` для статуса авторизации)
  - Использовать безопасное извлечение опционалов (без force unwrap)

**Важные замечания:**

- **App Group идентификатор:** `group.com.sotka.app` (должен быть одинаковым для обоих targets)
- **Ключ для статуса авторизации:** Должен совпадать с ключом в `AuthHelperImp` (Key.isAuthorized.rawValue)
- **Безопасность:** Всегда проверять доступность App Group перед использованием
- **Синхронизация:** Статус авторизации обновляется в App Group UserDefaults через `AuthHelper` на iPhone, часы читают его напрямую без дополнительной синхронизации
- **Офлайн-режим:** При отсутствии App Group или значения в нем, часы должны считать пользователя неавторизованным

**Связь с другими компонентами:**

- Утилиты для чтения статуса авторизации будут использоваться в `WatchAuthService` (см. раздел 3.1)
- `AuthHelperImp` на iPhone будет записывать статус авторизации в App Group UserDefaults
- Часы будут читать статус авторизации напрямую из App Group без использования WatchConnectivity

### Этап 2: Модели данных (DTO) и тесты для них

#### 2.1 Создание DTO-структур (TDD подход)
- [ ] **Написать тесты для `WorkoutResultDTO`:**
  - Тест преобразования `WorkoutResult` → `WorkoutResultDTO`
  - Тест преобразования `WorkoutResultDTO` → `WorkoutResult`
  - Тест сериализации/десериализации JSON
  - Тест с nil значениями (duration может быть nil)
- [ ] **Реализовать `WorkoutResultDTO.swift`:**
  - Codable структура с полями: `count: Int`, `duration: Int?`
  - Метод `init(from: WorkoutResult)`
  - Метод `toWorkoutResult() -> WorkoutResult`
  - Безопасное извлечение опционалов (без force unwrap)
- [ ] **Написать тесты для `WorkoutPreviewTrainingDTO`:**
  - Тест преобразования `WorkoutPreviewTraining` → `WorkoutPreviewTrainingDTO`
  - Тест преобразования `WorkoutPreviewTrainingDTO` → `WorkoutPreviewTraining`
  - Тест сериализации/десериализации JSON
  - Тест с опциональными полями (count, typeId, customTypeId, sortOrder)
- [ ] **Реализовать `WorkoutPreviewTrainingDTO.swift`:**
  - Codable структура с полями: `id: String`, `count: Int?`, `typeId: Int?`, `customTypeId: String?`, `sortOrder: Int?`
  - Метод `init(from: WorkoutPreviewTraining)`
  - Метод `toWorkoutPreviewTraining() -> WorkoutPreviewTraining`
  - Безопасное извлечение опционалов
- [ ] **Написать тесты для `WorkoutDataDTO`:**
  - Тест создания DTO с данными тренировки
  - Тест сериализации/десериализации JSON
  - Тест преобразования `executionType` (Int) ↔ `ExerciseExecutionType`
  - Тест с пустым массивом trainings
  - Тест с опциональным plannedCount
- [ ] **Реализовать `WorkoutDataDTO.swift`:**
  - Codable структура с полями: `day: Int`, `executionType: Int`, `trainings: [WorkoutPreviewTrainingDTO]`, `plannedCount: Int?`
  - Метод `toExerciseExecutionType() -> ExerciseExecutionType?` (безопасное преобразование)
  - Безопасное извлечение опционалов

#### 2.2 Локализация для DTO (если нужна)
- [ ] Добавить строки локализации в `Localizable.xcstrings` для ошибок преобразования DTO (если нужны)
- [ ] Добавить переводы на русский и английский языки
- [ ] Установить статус новых переводов: `"state" : "needs_review"`

#### 2.3 Настройка локализации для Watch App
- [ ] **Использование общего файла локализации:**
  - Файл `SupportingFiles/Localizable.xcstrings` уже добавлен в Watch App target (настроено ранее ✅)
  - Все строки для часов добавляются в этот же файл с префиксом `Watch.*`
  - **Важно:** Перед добавлением новых ключей проверять существующие ключи, чтобы не создавать дубли
- [ ] **Проверка существующих ключей локализации:**
  - Использовать существующие ключи там, где возможно:
    - `Home.Activity` - для "Активность" (уже существует)
    - `.workoutDay`, `.stretchDay`, `.restDay`, `.sickDay` - для типов активности (используются в `DayActivityType`)
    - Проверить наличие ключей для "День", "Тренировка", "Круг" и других общих терминов
  - Добавлять новые ключи только если они специфичны для часов и не существуют в основном приложении
  - **Примечание:** Локализация displayName для часов уже настроена (раздел 1.2) через `InfoPlist.xcstrings` ✅

### Этап 3: Сервисы и тесты для них

#### 3.1 WatchAuthService (TDD подход)
- [ ] **Написать тесты для `WatchAuthService`:**
  - Тест чтения статуса авторизации из UserDefaults (App Group)
  - Тест проверки статуса авторизации при отсутствии значения в UserDefaults
  - Тест обработки команды `PHONE_COMMAND_LOGOUT` от iPhone (обновление статуса)
  - Тест обработки случая, когда App Group UserDefaults недоступен
  - Тест использования правильного ключа для чтения статуса (совпадает с ключом в AuthHelper)
- [ ] **Реализовать `WatchAuthService.swift`:**
  - Класс для управления авторизацией на часах
  - Использование `UserDefaults(suiteName: "group.com.sotka.app")` для чтения статуса авторизации
  - Метод `checkAuthStatus() -> Bool` - чтение статуса авторизации напрямую из UserDefaults (App Group)
    - Использовать тот же ключ, что и в `AuthHelperImp` (Key.isAuthorized.rawValue)
    - Возвращать `false` если значение отсутствует или App Group недоступен
  - Обработка команды `PHONE_COMMAND_LOGOUT` от iPhone (опционально, так как статус обновится в UserDefaults автоматически)
  - Логирование через OSLog на русском языке
  - Безопасное извлечение опционалов
  - **Важно:** Не кэшировать статус отдельно - читать напрямую из UserDefaults (App Group)

#### 3.2 WatchConnectivityService (TDD подход)
- [ ] **Написать тесты для `WatchConnectivityService`:**
  - Тест инициализации WCSession
  - Тест проверки доступности сессии
  - Тест отправки типа активности
  - Тест отправки результата тренировки
  - Тест запроса текущего дня
  - Тест запроса текущей активности
  - Тест запроса данных тренировки
  - Тест обработки ответов от iPhone (мок WCSession)
  - Тест обработки ошибок связи
  - Тест преобразования моделей в DTO и обратно
  - Тест сериализации/десериализации JSON
- [ ] **Реализовать `WatchConnectivityService.swift`:**
  - Класс для связи с iPhone через WatchConnectivity
  - Реализация `WCSessionDelegate` для часов
  - Методы запроса данных с iPhone:
    - `requestCurrentDay() async throws -> Int`
    - `requestCurrentActivity(day: Int) async throws -> DayActivityType?`
    - `requestWorkoutData(day: Int) async throws -> WorkoutDataDTO`
  - Методы отправки действий на iPhone:
    - `sendActivityType(day: Int, activityType: DayActivityType) async throws`
    - `sendWorkoutResult(day: Int, result: WorkoutResult, executionType: ExerciseExecutionType) async throws`
  - Обработка ответов от iPhone через делегат
  - Преобразование моделей ↔ DTO
  - Сериализация/десериализация JSON
  - Логирование через OSLog на русском языке
  - Безопасное извлечение опционалов
  - Обработка ошибок связи и недоступности iPhone
  - **Примечание:** Проверка статуса авторизации выполняется через `WatchAuthService`, который читает из UserDefaults (App Group), а не через WatchConnectivity

#### 3.3 WatchWorkoutService (TDD подход)
- [ ] **Написать тесты для `WatchWorkoutService`:**
  - Тест инициализации тренировки из `WorkoutDataDTO`
  - Тест отслеживания прогресса тренировки
  - Тест завершения круга/подхода
  - Тест завершения тренировки
  - Тест прерывания тренировки
  - Тест формирования `WorkoutResult` из прогресса
  - Тест обработки отсутствия данных тренировки
- [ ] **Реализовать `WatchWorkoutService.swift`:**
  - Класс для логики выполнения тренировки на часах
  - Инициализация из `WorkoutDataDTO`
  - Отслеживание прогресса: текущий круг/подход, завершенные круги/подходы, время тренировки, время отдыха
  - Метод `completeRound()` - завершение круга/подхода
  - Метод `getRestTime() -> Int?` - получение времени отдыха между кругами/подходами (из настроек или параметров тренировки)
  - Метод `finishWorkout() -> WorkoutResult` - завершение тренировки и формирование результата
  - Метод `cancelWorkout()` - прерывание тренировки
  - Логирование через OSLog на русском языке
  - Безопасное извлечение опционалов

### Этап 4: ViewModels и тесты для них

#### 4.1 HomeViewModel (TDD подход)
- [ ] **Написать тесты для `HomeViewModel`:**
  - Тест инициализации ViewModel
  - Тест проверки авторизации при загрузке данных
  - Тест загрузки текущего дня с iPhone (мок WatchConnectivityService)
  - Тест загрузки текущей активности дня (мок WatchConnectivityService)
  - Тест выбора типа активности (отправка на iPhone)
  - Тест начала тренировки (запрос данных тренировки)
  - Тест обработки команды выхода из аккаунта
  - Тест обработки ошибок связи с iPhone
  - Тест обновления данных при получении команды от iPhone (обновление текущего дня через `PHONE_COMMAND_UPDATE_CURRENT_DAY`)
- [ ] **Реализовать `HomeViewModel.swift`:**
  - @Observable класс для главного экрана
  - Зависимости через конструктор: `WatchAuthService`, `WatchConnectivityService`
  - Состояние: `isLoading: Bool`, `error: Error?`, `currentDay: Int?`, `currentActivity: DayActivityType?`, `isAuthorized: Bool`
  - Метод `loadData() async` - загрузка данных (проверка авторизации, запрос текущего дня с iPhone через `WatchConnectivityService.requestCurrentDay()`, запрос активности)
    - **Важно:** Текущий день запрашивается с iPhone в реальном времени, без кэширования в UserDefaults
  - Метод `selectActivity(_ activityType: DayActivityType) async` - выбор активности (отправка на iPhone)
  - Метод `startWorkout() async` - начало тренировки (запрос данных тренировки)
  - Метод `handleLogout()` - обработка выхода из аккаунта
  - Логирование через OSLog на русском языке
  - Безопасное извлечение опционалов

#### 4.2 WorkoutViewModel (TDD подход)
- [ ] **Написать тесты для `WorkoutViewModel`:**
  - Тест инициализации из `WorkoutDataDTO`
  - Тест отслеживания прогресса тренировки
  - Тест завершения круга/подхода
  - Тест запуска таймера отдыха после завершения круга/подхода
  - Тест завершения таймера отдыха (автоматическое и досрочное)
  - Тест обработки фонового режима для таймера отдыха
  - Тест завершения тренировки (формирование результата, отправка на iPhone)
  - Тест прерывания тренировки
  - Тест обработки ошибок при отправке результата
  - Тест обновления UI при изменении прогресса
- [ ] **Реализовать `WorkoutViewModel.swift`:**
  - @Observable класс для экрана тренировки
  - Зависимости через конструктор: `WatchWorkoutService`, `WatchConnectivityService`
  - Состояние: `currentRound: Int`, `completedRounds: Int`, `duration: TimeInterval`, `isFinished: Bool`, `error: Error?`, `showRestTimer: Bool`, `restTime: Int`
  - Инициализация из `WorkoutDataDTO`
  - Метод `completeRound()` - завершение круга/подхода (запускает таймер отдыха, если есть время отдыха)
  - Метод `handleRestTimerFinish(force: Bool)` - обработка завершения таймера отдыха
  - Метод `checkAndHandleExpiredRestTimer()` - проверка истекшего таймера при активации приложения
  - Метод `finishWorkout() async` - завершение тренировки (формирование результата, отправка на iPhone)
  - Метод `cancelWorkout()` - прерывание тренировки
  - Логирование через OSLog на русском языке
  - Безопасное извлечение опционалов

### Этап 5: Интеграция с основным приложением (iPhone)

#### 5.1 WatchConnectivityManager на iPhone (TDD подход)
- [ ] **Написать тесты для `WatchConnectivityManager`:**
  - Тест инициализации WCSession
  - Тест обработки команды `WATCH_COMMAND_SET_ACTIVITY` (мок DailyActivitiesService)
  - Тест обработки команды `WATCH_COMMAND_SAVE_WORKOUT` (мок DailyActivitiesService)
  - Тест обработки команды `WATCH_COMMAND_GET_CURRENT_DAY` (мок StatusManager)
  - Тест обработки команды `WATCH_COMMAND_GET_CURRENT_ACTIVITY` (мок DailyActivitiesService)
  - Тест обработки команды `WATCH_COMMAND_GET_WORKOUT_DATA` (мок WorkoutProgramCreator)
  - Тест отправки обновлений на часы (при изменении дня)
  - Тест обработки ошибок (неавторизованный пользователь, отсутствие данных)
  - **Примечание:** Команда `WATCH_COMMAND_CHECK_AUTH` больше не нужна, так как статус авторизации читается напрямую из UserDefaults (App Group)
- [ ] **Реализовать `WatchConnectivityManager.swift` в основном приложении:**
  - Класс для связи с часами через WatchConnectivity
  - Реализация `WCSessionDelegate` для iPhone
  - Интеграция с `DailyActivitiesService` для сохранения активности и результата тренировки
  - Интеграция с `StatusManager` или `DayCalculator` для получения текущего дня
  - Интеграция с `WorkoutProgramCreator` для получения данных тренировки
  - Обработка команд от часов:
    - `WATCH_COMMAND_SET_ACTIVITY` → сохранение через `DailyActivitiesService.set(_:for:context:)`
    - `WATCH_COMMAND_SAVE_WORKOUT` → преобразование DTO в модель, сохранение через `DailyActivitiesService.createDailyActivity(_:context:)`
    - `WATCH_COMMAND_GET_CURRENT_DAY` → получение из `StatusManager` или `DayCalculator`
    - `WATCH_COMMAND_GET_CURRENT_ACTIVITY` → получение из SwiftData через `DailyActivitiesService`
    - `WATCH_COMMAND_GET_WORKOUT_DATA` → получение через `WorkoutProgramCreator`, преобразование в DTO
  - Отправка обновлений на часы:
    - При изменении текущего дня → отправка обновленного дня
    - При изменении активности дня → отправка обновленной активности
  - **Примечание:** Статус авторизации обновляется в UserDefaults (App Group) через `AuthHelper`, часы читают его напрямую, поэтому команда `WATCH_COMMAND_CHECK_AUTH` не нужна
  - Преобразование моделей ↔ DTO
  - Сериализация/десериализация JSON
  - Логирование через OSLog на русском языке
  - Безопасное извлечение опционалов

### Этап 6: UI экранов (реализуется в последнюю очередь)

#### 6.1 Экран авторизации
- [x] Создать `AuthRequiredView.swift`:
  - Экран для неавторизованных пользователей
  - Отображение сообщения о необходимости авторизации в iPhone приложении
  - Кнопка "Проверить авторизацию" для повторной проверки
  - Индикатор проверки авторизации
  - Локализованные строки в `Localizable.xcstrings` (общий файл, уже настроен ✅):
    - `Watch.AuthRequired.Message` - сообщение о необходимости авторизации (новый ключ)
    - `Watch.AuthRequired.CheckButton` - кнопка проверки (новый ключ)
    - `Watch.AuthRequired.Checking` - индикатор проверки (новый ключ)
    - `Watch.AuthRequired.Error` - сообщение об ошибке авторизации (новый ключ)
  - Добавить переводы на русский и английский языки ✅
  - Установить статус новых переводов: `"state" : "needs_review"` ✅
  - Минималистичный дизайн для часов ✅
- [ ] Использовать `AuthRequiredView` в нужных местах приложения:
  - Передавать в экран соответствующий статус авторизации
  - Интегрировать в навигационную структуру приложения

#### 6.2 Главный экран
- [x] Создать `HomeView.swift` (частично реализовано):
  - ✅ Главный экран часов (только для авторизованных)
  - ✅ Проверка авторизации перед отображением контента
  - ✅ Отображение текущего дня программы
  - ✅ Отображение текущей активности дня (если установлена)
  - ✅ Кнопка выбора активности (реализована через `DayActivityView`)
  - ✅ Отображение выбранной активности (реализовано через `SelectedActivityView`)
  - ✅ Возможность изменения активности (реализовано через NavigationLink в `SelectedActivityView`)
  - [ ] **Логика открытия экрана тренировки:**
    - При выборе активности `.workout` (из `DayActivitySelectionView` или изменении на `.workout` из `SelectedActivityView`) автоматически открывать `WorkoutView`
    - Интегрировать открытие `WorkoutView` в обработку `onSelect` callback в `DayActivityView`
  - ✅ Индикатор синхронизации с iPhone
  - ✅ Индикатор загрузки
  - ✅ Обработка ошибок связи
  - ✅ Локализованные строки в `Localizable.xcstrings` (общий файл):
    - Использовать существующий ключ `Home.Activity` для "Активность" (не создавать дубль)
    - Проверить наличие ключа для "День" - если есть, использовать его, иначе добавить `Watch.Home.Day`
    - `Watch.Home.SelectActivity` - "Выбрать активность" (новый ключ, специфичен для часов)
    - `Watch.Home.StartWorkout` - "Начать тренировку" (новый ключ, специфичен для часов)
    - `Watch.Home.Syncing` - "Синхронизация..." (новый ключ, специфичен для часов)
    - `Watch.Home.Error` - "Ошибка связи с iPhone" (новый ключ, специфичен для часов)
  - ✅ Добавить переводы на русский и английский языки
  - ✅ Установить статус новых переводов: `"state" : "needs_review"`
  - ✅ Минималистичный дизайн для часов

#### 6.3 Экран выбора активности
- [x] **Создать экран выбора активности:** ✅ **Выполнено** - `DayActivitySelectionView.swift` уже создан
  - ✅ Экран выбора активности реализован
  - ✅ Отображение 4 вариантов активности через `DayActivityType.allCases`:
    - Тренировка (workout) - синий цвет, иконка "figure.play"
    - Растяжка (stretch) - фиолетовый цвет, иконка "figure.flexibility"
    - Отдых (rest) - зеленый цвет, иконка "chair.lounge"
    - Болезнь (sick) - красный цвет, иконка "medical.thermometer"
  - ✅ Использует `activity.localizedTitle` для локализации (использует существующие ключи `.workoutDay`, `.stretchDay`, `.restDay`, `.sickDay`)
  - ✅ Использует `activity.image` и `activity.color` из `DayActivityType`
  - ✅ Callback `onSelect` для обработки выбора активности
- [x] **Базовый UI для выбора и изменения активности:** ✅ **Выполнено**
  - ✅ `DayActivityView` - основной экран, который показывает либо `SelectedActivityView` (если активность выбрана), либо `DayActivitySelectionView` (если не выбрана)
  - ✅ `SelectedActivityView` - отображает выбранную активность с кнопкой редактирования (NavigationLink к `DayActivitySelectionView`)
  - ✅ `DayActivitySelectionView` - отображает список всех активностей для выбора
  - ✅ Возможность изменения ранее выбранной активности на другую через кнопку редактирования
- [ ] **Доработать `SelectedActivityView` для отображения данных тренировки (TODO в коде):**
  - **Важно:** Это экран результата тренировки - после завершения тренировки пользователь возвращается сюда и видит результат выполненной тренировки
  - Для кейса `.workout` отобразить данные тренировки аналогично `DayActivityContentView` + `DayActivityCommentView` (как в основном приложении)
  - Отобразить информацию о выполненной тренировке:
    - Тип выполнения (`ExerciseExecutionType`) с количеством кругов/подходов
    - Список упражнений (`DayActivityTraining`) с количеством повторений для каждого
    - Комментарий пользователя (если есть)
  - Получить данные тренировки для текущего дня через `WatchConnectivityService.requestWorkoutData(day:)` или из сохраненной активности (`DayActivity`)
  - Адаптировать отображение для маленького экрана часов (упрощенный формат)
  - После завершения тренировки в `WorkoutView` пользователь возвращается в `SelectedActivityView` и видит результат выполненной тренировки
- [ ] **Реализовать логику выбора/изменения активности:**
  - В `HomeView` передать реальную выбранную активность для текущего дня (убрать TODO)
  - Реализовать обработку выбора активности через `onSelect` callback в `DayActivityView`:
    - Вызов `HomeViewModel.selectActivity(_:)` для отправки на iPhone через `WatchConnectivityService`
    - Показ индикатора отправки активности на iPhone
    - Обработка ошибок связи
    - **Важно:** Если выбранная активность = `.workout`, открыть экран выполнения тренировки (`WorkoutView`) после успешного сохранения
    - Если выбранная активность != `.workout`, остаться на текущем экране (обновить отображение)
  - Локализованные строки для индикаторов и ошибок в `Localizable.xcstrings` (общий файл):
    - `Watch.Activity.Saving` - "Сохранение..." (новый ключ, специфичен для часов)
    - `Watch.Activity.Error` - "Ошибка сохранения" (новый ключ, специфичен для часов)
  - Добавить переводы на русский и английский языки
  - Установить статус новых переводов: `"state" : "needs_review"`

#### 6.4 Экран выполнения тренировки
- [ ] **Создать `WorkoutView.swift`:**
  - **Важно:** Экран открывается автоматически при выборе активности `.workout` (из `SelectedActivityView` или `DayActivitySelectionView`)
  - Экран выполнения тренировки
  - Упрощенный интерфейс для часов:
    - Отображение текущего упражнения
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

#### DTO-структуры для передачи данных

**WorkoutResultDTO** (новая структура для передачи):
```swift
// SotkaWatch Watch App/DTOs/WorkoutResultDTO.swift
struct WorkoutResultDTO: Codable {
    let count: Int
    let duration: Int?
    
    init(from result: WorkoutResult) {
        self.count = result.count
        self.duration = result.duration
    }
    
    func toWorkoutResult() -> WorkoutResult {
        WorkoutResult(count: count, duration: duration)
    }
}
```

**WorkoutPreviewTrainingDTO** (новая структура для передачи):
```swift
// SotkaWatch Watch App/DTOs/WorkoutPreviewTrainingDTO.swift
struct WorkoutPreviewTrainingDTO: Codable {
    let id: String
    let count: Int?
    let typeId: Int?
    let customTypeId: String?
    let sortOrder: Int?
    
    init(from training: WorkoutPreviewTraining) {
        self.id = training.id
        self.count = training.count
        self.typeId = training.typeId
        self.customTypeId = training.customTypeId
        self.sortOrder = training.sortOrder
    }
    
    func toWorkoutPreviewTraining() -> WorkoutPreviewTraining {
        WorkoutPreviewTraining(
            id: id,
            count: count,
            typeId: typeId,
            customTypeId: customTypeId,
            sortOrder: sortOrder
        )
    }
}
```

**WorkoutDataDTO** (новая структура для передачи полных данных тренировки):
```swift
// SotkaWatch Watch App/DTOs/WorkoutDataDTO.swift
struct WorkoutDataDTO: Codable {
    let day: Int
    let executionType: Int  // ExerciseExecutionType.rawValue
    let trainings: [WorkoutPreviewTrainingDTO]
    let plannedCount: Int?
    
    // Методы преобразования в модели (если нужны на часах)
    func toExerciseExecutionType() -> ExerciseExecutionType? {
        ExerciseExecutionType(rawValue: executionType)
    }
}
```

**Примечание:**
- Существующие модели (`WorkoutResult`, `WorkoutPreviewTraining`, `DayActivityType`, `ExerciseExecutionType`) **не изменяются**
- DTO-структуры создаются отдельно и используются только для передачи данных через WatchConnectivity
- Преобразование между моделями и DTO выполняется в `WatchConnectivityService`

### Команды WatchConnectivity

```swift
enum WatchCommand: String {
    // От часов к iPhone
    case getUserData = "WATCH_COMMAND_GET_USER_DATA"
    case setActivity = "WATCH_COMMAND_SET_ACTIVITY"
    case saveWorkout = "WATCH_COMMAND_SAVE_WORKOUT"
    case getCurrentDay = "WATCH_COMMAND_GET_CURRENT_DAY"
    case getCurrentActivity = "WATCH_COMMAND_GET_CURRENT_ACTIVITY"
    case getWorkoutData = "WATCH_COMMAND_GET_WORKOUT_DATA"
    
    // От iPhone к часам
    case userData = "PHONE_COMMAND_USER_DATA"
    case updateCurrentDay = "PHONE_COMMAND_UPDATE_CURRENT_DAY"
    case currentActivity = "PHONE_COMMAND_CURRENT_ACTIVITY"
    case sendWorkoutData = "PHONE_COMMAND_SEND_WORKOUT_DATA"
    case logout = "PHONE_COMMAND_LOGOUT"
    
    // Примечание: Команды checkAuth и authStatus не нужны,
    // так как статус авторизации читается напрямую из UserDefaults (App Group)
}
```

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
*Примечание: `result` содержит сериализованный `WorkoutResultDTO` в JSON формате*

**Запрос текущего дня:**
```json
{
    "command": "WATCH_COMMAND_GET_CURRENT_DAY"
}
```

**Ответ с текущим днем:**
```json
{
    "command": "PHONE_COMMAND_UPDATE_CURRENT_DAY",
    "currentDay": 42,
    "startDate": "2024-01-01T00:00:00Z"
}
```

**Примечание:** Команды проверки авторизации (`WATCH_COMMAND_CHECK_AUTH` и `PHONE_COMMAND_AUTH_STATUS`) не нужны, так как статус авторизации читается напрямую из UserDefaults (App Group) через `WatchAuthService`.

**Ответ с данными пользователя (опционально, если нужны для отображения):**
```json
{
    "command": "PHONE_COMMAND_USER_DATA",
    "user": {
        "id": 123,
        "userName": "username",
        "email": "user@example.com",
        "fullName": "Full Name"
    }
}
```

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

**Команда выхода из аккаунта (опционально):**
```json
{
    "command": "PHONE_COMMAND_LOGOUT"
}
```
*Примечание: Команда `PHONE_COMMAND_LOGOUT` опциональна, так как статус авторизации обновляется в UserDefaults (App Group) через `AuthHelper`, и часы автоматически получают актуальный статус при следующей проверке.*

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
1. **Создание DTO-структур** для передачи данных
2. **Проверка авторизации и блокировка функционала без авторизации**
3. **Запрос данных с iPhone** (текущий день, активность, данные пользователя)
4. **Отправка действий в iPhone** для сохранения в SwiftData (с преобразованием в DTO)
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
- Используются **DTO-структуры с Codable** для передачи данных
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
- Отдельные команды для проверки авторизации, получения данных пользователя
- Более детальное разделение команд (отдельно для активности, тренировки, данных пользователя)
- Команда выхода из аккаунта (`PHONE_COMMAND_LOGOUT`)

### Авторизация

**Старое приложение:**
- Не видно явной проверки авторизации при запуске часов
- Часы могут работать без явной проверки статуса авторизации

**Новое приложение:**
- **Обязательная проверка авторизации** при запуске приложения на часах
- Блокировка функционала без авторизации
- Экран `AuthRequiredView` для неавторизованных пользователей
- Синхронизация данных пользователя между iPhone и часами

### Обработка данных тренировки

**Старое приложение:**
- Данные тренировки передаются как `WatchObject` (JSON строка)
- Сохранение тренировок происходит пакетами (массив дней)
- Локальное сохранение на часах перед синхронизацией

**Новое приложение:**
- Данные тренировки передаются через DTO (`WorkoutDataDTO`, `WorkoutResultDTO`)
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
- Codable DTO-структуры для передачи данных

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
   - Codable вместо ручной сериализации JSON

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
2. **Запрос данных с iPhone** - все данные запрашиваются с iPhone в реальном времени
3. **Сохранение через iPhone** - все действия передаются в iPhone для сохранения в SwiftData
4. **Главный экран** - отображение текущего дня и активности (только для авторизованных)
5. **Выбор активности** - выбор типа активности из 4 вариантов (сохранение через iPhone)
6. **Выполнение тренировки** - упрощенный интерфейс для выполнения тренировки (данные с iPhone, сохранение через iPhone)

### Ключевые принципы

- **iPhone приложение - единственное хранилище данных**: все данные хранятся только на iPhone в SwiftData, часы не хранят данные локально
- **Часы как клиент**: часы запрашивают данные с iPhone и отправляют действия для сохранения, не хранят данные самостоятельно
- **Обязательная авторизация**: приложение для часов работает только после успешной авторизации в iPhone приложении
- **Чтение статуса авторизации**: напрямую из UserDefaults (App Group), без отдельного кэширования на часах
- **Текущий день**: запрашивается с iPhone через WatchConnectivity в реальном времени, без кэширования
- **Безопасность**: при выходе из аккаунта на iPhone статус обновляется в UserDefaults, часы автоматически получают актуальный статус
- **Обработка офлайн-режима**: при отсутствии связи с iPhone показывать сообщение об ошибке, не выполнять действия, требующие сохранения

Приложение для часов работает как клиент iPhone приложения, запрашивая данные и отправляя действия для сохранения. Все данные хранятся только на iPhone в SwiftData, что упрощает архитектуру и исключает конфликты данных.

