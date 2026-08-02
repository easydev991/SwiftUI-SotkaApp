# План рефакторинга проверок >= и <= в тестах

## Текущий статус

Этап 1 выполнен. Этапы 2–4 закрыты без выполнения: все указанные в них тестовые файлы удалены при удалении sync-слоя (июль–август 2026), рефакторинг не требуется. Оставшиеся диапазонные проверки в уцелевших файлах корректны и остаются диапазонами по пп. 3–5.

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

**Закрыто:** файлы пунктов 2.1–2.3 удалены вместе с каталогом `SwiftUI-SotkaAppTests/StatusManagerTests/` при удалении sync-слоя, анализ не требуется.

#### 2.1. StatusManagerWatchConnectivityTests.swift — файл удалён

Файл находился в каталоге `SwiftUI-SotkaAppTests/StatusManagerTests/`, удалён вместе с ним. Паттерны `mockSession.sentMessages.count >= 1`, `applicationContexts.count >= 1` и подобные более не существуют.

#### 2.2. StatusManagerWatchConnectivityIntegrationTests+FullStartupScenarios.swift — файл удалён

Файл находился в каталоге `SwiftUI-SotkaAppTests/StatusManagerTests/`, удалён вместе с ним.

#### 2.3. StatusManagerSyncJournalTests.swift — файл удалён

Файл находился в каталоге `SwiftUI-SotkaAppTests/StatusManagerTests/`, удалён вместе с ним. Паттерны `getProgressCallCount >= initialProgressCalls` и аналогичные более не существуют.

### 3. Время выполнения (оставить диапазоны)

**Обоснование:** Время выполнения зависит от времени выполнения кода, диапазоны оправданы.

- **WorkoutScreenViewModelGetWorkoutResultTests.swift:** строки 60-61, 328-329 - проверки `duration`
- **WorkoutScreenViewModelStepCompletionTests.swift:** строки 130-131, 297-298, 359-360 - проверки `totalRestTime`
- **WorkoutScreenViewModelExpiredTimerTests.swift:** строки 142-143, 181-182, 220-221, 302-303 - проверки `totalRestTime`

### 4. Даты (оставить диапазоны)

**Обоснование:** Даты зависят от времени выполнения кода или проверяют логическую корректность, диапазоны оправданы.

- **DayActivityTests.swift:** файл удалён
- **StatusManagerResetProgramTests.swift:** файл удалён
- **StatusManagerStartNewRunTests.swift:** файл удалён
- **StatusManagerSyncJournalTests.swift:** файл удалён
- **ProgressSyncServicePhotoTests.swift:** файл удалён
- **CountriesUpdateServiceTests.swift:** файл удалён
- **WorkoutProgramCreatorDayActivityTests.swift:** строки 110-113 - `createDate`, `modifyDate` (проверки на месте)
- **WorkoutScreenViewModelSetupTests.swift:** строка 39 - `workoutStartTime <= Date()` (проверка на месте)

### 5. Валидация размеров (оставить диапазоны)

**Обоснование:** Проверка ограничений размера, диапазоны оправданы.

- **ImageProcessorTests.swift:** файл переписан (август 2026), проверки `width <= size.width` / `height <= size.height` удалены; валидация идёт через `validateImageSize`/`validateImageFormat`. Пункт неактуален.

### 6. Валидация года (оставить диапазоны)

**Обоснование:** Валидация диапазона года, диапазоны оправданы.

- **UserProgressTests.swift:** файл удалён, пункт неактуален

### 7. Счетчики операций синхронизации (нужно проанализировать)

**Закрыто:** все файлы пункта удалены при удалении sync-слоя, анализ не требуется.

- **DailyActivitiesServiceTests.swift** (SwiftUI-SotkaAppTests/DailyActivitiesTests/): файл удалён
- **CustomExercisesServiceTests.swift** (SwiftUI-SotkaAppTests/Services/): файл удалён
- **ProgressSyncServiceTests.swift** (SwiftUI-SotkaAppTests/ProgressTests/): файл удалён

### 8. Специальные случаи

#### 8.1. InfopostFilenameManagerTests.swift — файл удалён

Файл находился в каталоге `SwiftUI-SotkaAppTests/InfopostsTests/`, удалён при рефакторинге. Паттерн `russianFilenames.count >= englishFilenames.count` более не существует.

## Порядок выполнения рефакторинга

### Этап 1: Номера этапов тренировки ✅ Выполнено

См. п. 1 выше.

### Этап 2: Счетчики вызовов — закрыт (файлы удалены)

1. StatusManagerWatchConnectivityTests.swift — файл удалён
2. StatusManagerWatchConnectivityIntegrationTests+FullStartupScenarios.swift — файл удалён
3. StatusManagerSyncJournalTests.swift — файл удалён

Все файлы этапа удалены вместе с каталогом `StatusManagerTests/` при удалении sync-слоя.

### Этап 3: Счетчики операций синхронизации — закрыт (файлы удалены)

1. DailyActivitiesServiceTests.swift — файл удалён
2. CustomExercisesServiceTests.swift — файл удалён
3. ProgressSyncServiceTests.swift — файл удалён

Все файлы этапа удалены при удалении sync-слоя.

### Этап 4: Специальные случаи — закрыт (файл удалён)

1. InfopostFilenameManagerTests.swift — файл удалён

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
