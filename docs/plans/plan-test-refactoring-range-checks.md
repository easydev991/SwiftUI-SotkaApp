# План рефакторинга проверок >= и <= в тестах

## Текущий статус

Этап 1 выполнен; этапы 2–4 не выполнены (проверки с диапазонами остаются в указанных ниже файлах).

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

Рефакторинг выполнен: в WorkoutViewModelStepManagementTests (Watch) и WorkoutScreenViewModelHelperMethodsTests проверки заменены на точные сравнения (`==`) для номеров этапов и размеров списков.

### 2. Счетчики вызовов (нужно проанализировать каждый случай)

#### 2.1. StatusManagerWatchConnectivityTests.swift

**Файл:** `SwiftUI-SotkaAppTests/StatusManagerTests/StatusManagerWatchConnectivityTests.swift`

**Паттерны в файле (номера строк могут смещаться):**

- `#expect(mockSession.sentMessages.count >= 1)` — в нескольких тестах (порядка строк 188, 207, 333, 350, 389, 541). Контекст: проверка отправки сообщений. Действие: если гарантируется ровно одно сообщение — заменить на `== 1`.
- `#expect(mockSession.applicationContexts.count >= 1)` — в нескольких тестах (порядка строк 647, 668, 698, 825, 842, 861, 903). Контекст: отправка applicationContext. Действие: при гарантии ровно одного контекста — заменить на `== 1`.
- `#expect(mockSession.applicationContexts.count > initialContextCount)` (около строки 767). Действие: определить точное ожидаемое увеличение и заменить на `== initialContextCount + N`.
- `#expect(mockSession.applicationContexts.count <= initialContextCount + 1)` (около строки 808). Действие: заменить на точное равенство после анализа логики (например `== initialContextCount` или `== initialContextCount + 1`).

**Требуется анализ:** по каждому тесту определить точное ожидаемое количество сообщений/контекстов.

#### 2.2. StatusManagerWatchConnectivityIntegrationTests+FullStartupScenarios.swift

**Файл:** `SwiftUI-SotkaAppTests/StatusManagerTests/StatusManagerWatchConnectivityIntegrationTests+FullStartupScenarios.swift`

**Паттерны:** `#expect(mockSession.applicationContexts.count >= initialApplicationContextCount + 2)` и `>= initialApplicationContextCount + 5` (порядка строк 357, 396). Контекст: интеграционные сценарии запуска. Действие: определить точное ожидаемое количество контекстов и заменить на `==`.

#### 2.3. StatusManagerSyncJournalTests.swift

**Файл:** `SwiftUI-SotkaAppTests/StatusManagerTests/StatusManagerSyncJournalTests.swift`

**Паттерны (строки 53–55, 98, 141, 184):**

- `#expect(mockProgressClient.getProgressCallCount >= initialProgressCalls)` и аналоги для `getCustomExercisesCallCount`, `getDaysCallCount` — при синхронизации. Действие: выяснить точное число вызовов и заменить на `==`.
- `#expect(mockProgressClient.getProgressCallCount > initialCalls)` (и аналоги для exercise/days). Действие: определить точное приращение и заменить на `== initialCalls + N`.

**Требуется анализ:** логика синхронизации и количество вызовов клиентов в каждом сценарии.

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

### 7. Счетчики операций синхронизации (нужно проанализировать)

**Контекст:** Проверки вида `details.created >= 0`, `details.updated >= 0`, `details.deleted >= 0` в тестах синхронизации.  
**Действие:** В каждом тесте определить ожидаемое точное количество операций (created/updated/deleted) и заменить на `== N` где это однозначно.  
**Требуется анализ:** Логика сценария и контракт сервиса для каждого теста.

- **DailyActivitiesServiceTests.swift** (SwiftUI-SotkaAppTests/DailyActivitiesTests/): строки 60–62, 158, 212
- **CustomExercisesServiceTests.swift** (SwiftUI-SotkaAppTests/Services/): строки 486–488, 567, 604
- **ProgressSyncServiceTests.swift** (SwiftUI-SotkaAppTests/ProgressTests/): строки 1001–1003, 1093–1095 (и при необходимости 1166: `totalOperations > 0`)

### 8. Специальные случаи

#### 8.1. InfopostFilenameManagerTests.swift

**Файл:** `SwiftUI-SotkaAppTests/InfopostsTests/InfopostFilenameManagerTests.swift` (строка ~60)

**Паттерн:** `#expect(russianFilenames.count >= englishFilenames.count)`. Контекст: сравнение количества русских и английских имён файлов. Действие: если в тесте подразумеваются конкретные числа (например 103 и 102), заменить на проверки `== 103` и `== 102`. Требуется анализ контекста теста.

## Порядок выполнения рефакторинга

### Этап 1: Номера этапов тренировки ✅ Выполнено

См. п. 1 выше.

### Этап 2: Счетчики вызовов (приоритет: средний) — не выполнен

1. StatusManagerWatchConnectivityTests.swift  
2. StatusManagerWatchConnectivityIntegrationTests+FullStartupScenarios.swift  
3. StatusManagerSyncJournalTests.swift  

Требуется анализ логики для определения точных значений в каждом тесте.

### Этап 3: Счетчики операций синхронизации (приоритет: средний) — не выполнен

1. DailyActivitiesServiceTests.swift (папка DailyActivitiesTests/)  
2. CustomExercisesServiceTests.swift  
3. ProgressSyncServiceTests.swift  

Требуется анализ логики синхронизации и контракта сервисов.

### Этап 4: Специальные случаи (приоритет: низкий) — не выполнен

1. InfopostFilenameManagerTests.swift — проверка `russianFilenames.count >= englishFilenames.count`.

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
