# План рефакторинга проверок >= и <= в тестах

## Цель
Конкретизировать проверки с диапазонами (`>=`, `<=`) до однозначных сравнений (`==`) там, где это возможно и имеет смысл, для повышения точности тестов.

## Принципы рефакторинга

### Проверки, которые МОЖНО конкретизировать
1. **Номера этапов тренировки** - генерируются последовательно от 1 до plannedCount, можно проверить конкретные значения
2. **Счетчики вызовов** - если логика гарантирует точное количество вызовов, можно конкретизировать
3. **Количество элементов в списках** - если логика гарантирует точное количество

### Проверки, которые НУЖНО оставить диапазонами
1. **Время выполнения (duration, totalRestTime)** - зависит от времени выполнения кода, диапазоны оправданы
2. **Даты (createDate, modifyDate)** - зависят от времени выполнения, диапазоны оправданы
3. **Валидация размеров изображений** - проверка ограничений, диапазоны оправданы
4. **Валидация года** - проверка диапазона значений, диапазоны оправданы
5. **Счетчики с недетерминированным поведением** - если количество может варьироваться

## Детальный план рефакторинга

### 1. Номера этапов тренировки ✅ Выполнено

- **WorkoutViewModelStepManagementTests.swift:** Заменены диапазоны на конкретные значения для `getCycleSteps()` и `getExerciseSteps()`
- **WorkoutScreenViewModelHelperMethodsTests.swift:** Заменены диапазоны на конкретные значения для циклов, turbo дня и подходов

### 2. Счетчики вызовов (нужно проанализировать каждый случай)

#### 2.1. StatusManagerWatchConnectivityTests.swift
**Файл:** `SwiftUI-SotkaAppTests/StatusManagerTests/StatusManagerWatchConnectivityTests.swift`

**Строки 182, 201, 327, 344, 383, 535:**
```swift
#expect(mockSession.sentMessages.count >= 1)
```
**Контекст:** Проверка отправки сообщений
**Действие:** Проанализировать логику - если гарантируется отправка ровно одного сообщения, заменить на `== 1`
**Требуется анализ:** Изучить контекст каждого теста, определить точное ожидаемое количество

**Строки 641, 662, 692, 819, 836, 855, 897:**
```swift
#expect(mockSession.applicationContexts.count >= 1)
```
**Контекст:** Проверка отправки applicationContext
**Действие:** Проанализировать логику - если гарантируется отправка ровно одного контекста, заменить на `== 1`
**Требуется анализ:** Изучить контекст каждого теста, определить точное ожидаемое количество

**Строка 761:**
```swift
#expect(mockSession.applicationContexts.count > initialContextCount)
```
**Контекст:** Проверка увеличения количества контекстов
**Действие:** Определить точное ожидаемое увеличение
**Требуется анализ:** Изучить логику, определить на сколько именно должно увеличиться

**Строка 802:**
```swift
#expect(mockSession.applicationContexts.count <= initialContextCount + 1)
```
**Контекст:** Проверка, что контекст не был отправлен при удалении активности не текущего дня
**Действие:** Заменить на точное равенство
**Новая проверка:** `#expect(mockSession.applicationContexts.count == initialContextCount + 1)` или `== initialContextCount` в зависимости от логики
**Требуется анализ:** Изучить логику, определить точное ожидаемое значение

**Строка 904:**
```swift
#expect(currentDay > 0)
```
**Контекст:** Проверка, что currentDay установлен
**Действие:** Если в тесте устанавливается конкретное значение (например, 42), заменить на `== 42`
**Требуется анализ:** Изучить контекст теста

#### 2.2. StatusManagerWatchConnectivityIntegrationTests+FullStartupScenarios.swift
**Файл:** `SwiftUI-SotkaAppTests/StatusManagerTests/StatusManagerWatchConnectivityIntegrationTests+FullStartupScenarios.swift`

**Строки 357, 396:**
```swift
#expect(mockSession.applicationContexts.count >= initialApplicationContextCount + 2)
#expect(mockSession.applicationContexts.count >= initialApplicationContextCount + 5)
```
**Контекст:** Проверка отправки applicationContext в интеграционных тестах
**Действие:** Определить точное ожидаемое количество
**Требуется анализ:** Изучить логику, определить точное ожидаемое значение

#### 2.3. StatusManagerSyncJournalTests.swift
**Файл:** `SwiftUI-SotkaAppTests/StatusManagerTests/StatusManagerSyncJournalTests.swift`

**Строки 53-55:**
```swift
#expect(mockProgressClient.getProgressCallCount >= initialProgressCalls)
#expect(mockExerciseClient.getCustomExercisesCallCount >= initialExerciseCalls)
#expect(mockDaysClient.getDaysCallCount >= initialDaysCalls)
```
**Контекст:** Проверка вызовов клиентов при синхронизации
**Действие:** Определить точное ожидаемое количество вызовов
**Требуется анализ:** Изучить логику синхронизации, определить точное количество вызовов

**Строки 98, 141, 184:**
```swift
#expect(mockProgressClient.getProgressCallCount > initialCalls)
```
**Контекст:** Проверка увеличения счетчиков вызовов
**Действие:** Определить точное ожидаемое увеличение
**Требуется анализ:** Изучить логику, определить на сколько именно должно увеличиться

### 3. Время выполнения (оставить диапазоны)

**Обоснование:** Время выполнения зависит от времени выполнения кода, диапазоны оправданы.

- **WorkoutScreenViewModelGetWorkoutResultTests.swift:** строки 60-61, 328-329 - проверки `duration`
- **WorkoutScreenViewModelStepCompletionTests.swift:** строки 130-131, 297-298, 359-360 - проверки `totalRestTime`
- **WorkoutScreenViewModelExpiredTimerTests.swift:** строки 142-143, 181-182, 220-221, 302-303 - проверки `totalRestTime`

### 4. Даты (оставить диапазоны)

**Обоснование:** Даты зависят от времени выполнения кода или проверяют логическую корректность, диапазоны оправданы.

- **DayActivityTests.swift:** строки 706-707, 858-861 - `modifyDate`, `createDate`
- **StatusManagerResetProgramTests.swift:** строки 433-434 - `startDate`
- **StatusManagerStartNewRunTests.swift:** строки 55-56 - `startDate`
- **StatusManagerSyncJournalTests.swift:** строки 333, 372, 503 - `endDate >= startDate`
- **ProgressSyncServicePhotoTests.swift:** строка 104 - `lastModified >= originalDate`
- **CountriesUpdateServiceTests.swift:** строки 351-352 - `lastUpdateDate`
- **WorkoutProgramCreatorDayActivityTests.swift:** строки 110-113 - `createDate`, `modifyDate`
- **WorkoutScreenViewModelSetupTests.swift:** строка 39 - `workoutStartTime <= Date()`

### 5. Валидация размеров (оставить диапазоны)

**Обоснование:** Проверка ограничений размера, диапазоны оправданы.

- **ImageProcessorTests.swift:** строки 71-72, 81-82 - проверки `width <= size.width`, `height <= size.height`

### 6. Валидация года (оставить диапазоны)

**Обоснование:** Валидация диапазона года, диапазоны оправданы.

- **UserProgressTests.swift:** строки 1127-1128, 1160-1161 - проверки `year >= 2020, <= 2030`

### 7. Счетчики операций (нужно проанализировать)

**Контекст:** Проверка счетчиков операций синхронизации (`created`, `updated`, `deleted >= 0`)  
**Действие:** Определить точное ожидаемое количество операций  
**Требуется анализ:** Изучить логику синхронизации для каждого теста

- **DailyActivitiesServiceTests.swift:** строки 60-62, 158, 212
- **CustomExercisesServiceTests.swift:** строки 434-436, 515, 552
- **ProgressSyncServiceTests.swift:** строки 907-909, 999-1001

### 8. Специальные случаи

#### 8.1. InfopostFilenameManagerTests.swift
**Файл:** `SwiftUI-SotkaAppTests/InfopostsTests/InfopostFilenameManagerTests.swift`

**Строка 60:**
```swift
#expect(russianFilenames.count >= englishFilenames.count)
```
**Контекст:** Проверка, что русских файлов больше или равно английских
**Действие:** Если в тесте проверяется конкретное количество (103 vs 102), заменить на `== 103` и `== 102`
**Требуется анализ:** Изучить контекст теста, определить точные значения

## Порядок выполнения рефакторинга

### Этап 1: Номера этапов тренировки ✅ Выполнено
- WorkoutViewModelStepManagementTests.swift
- WorkoutScreenViewModelHelperMethodsTests.swift

### Этап 2: Счетчики вызовов (приоритет: средний)
1. StatusManagerWatchConnectivityTests.swift
2. StatusManagerWatchConnectivityIntegrationTests+FullStartupScenarios.swift
3. StatusManagerSyncJournalTests.swift

**Обоснование:** Требуется анализ логики для определения точных значений.

### Этап 3: Счетчики операций синхронизации (приоритет: средний)
1. DailyActivitiesServiceTests.swift
2. CustomExercisesServiceTests.swift
3. ProgressSyncServiceTests.swift

**Обоснование:** Требуется анализ логики синхронизации для определения точных значений.

### Этап 4: Специальные случаи (приоритет: низкий)
1. InfopostFilenameManagerTests.swift

**Обоснование:** Требуется анализ контекста теста.

## Правила выполнения рефакторинга

1. **Перед изменением:** Изучить контекст теста и логику тестируемого кода
2. **При сомнениях:** Оставить диапазон, если точное значение не гарантировано
3. **После изменения:** Запустить тесты и убедиться, что они проходят
4. **Документирование:** Добавить комментарии, если точное значение требует пояснения

## Метрики успеха

- Количество проверок с диапазонами уменьшилось
- Все тесты проходят после рефакторинга
- Тесты стали более точными и понятными
- Не нарушена логика тестирования

