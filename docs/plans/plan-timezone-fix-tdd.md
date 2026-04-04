# План и статус внедрения исправлений timezone-проблемы через TDD

## Цель

Подготовить безопасное поэтапное исправление проблемы с датами без изменений на сервере:

1. минимально рискованный hotfix для уже выпущенного приложения;
2. полный client-only fix на уровне сериализации, десериализации и sync-логики;
3. обязательный набор тестов, который должен защитить от регрессий.

## Принципы выполнения

- Использовать TDD на всех этапах: `Red -> Green -> Refactor`.
- Сначала писать узкие целевые тесты на текущее некорректное поведение, затем вносить минимальное исправление.
- Для hotfix не затрагивать лишние части sync-логики, пока они не покрыты тестами.
- После каждого этапа запускать форматирование и только самые целевые тесты, затем расширять прогон.
- Для дат в клиенте считать источником истины абсолютный момент времени (`Date`), а не локальное строковое представление.

## Контекст проблемы

Этот документ является основным источником истины по статусу timezone-fix и заменяет собой отдельные черновые заметки по решению проблемы.

### Корневая причина

- Серверная сторона сохраняет дату в локальной timezone сервера, а в БД хранит строку без явного offset.
- При обратном чтении timezone-less строка снова интерпретируется как серверное локальное время.
- Если на клиенте дата была сериализована не как абсолютный UTC-момент, это может приводить к ложному смещению времени на несколько часов.
- На уровне клиента это проявляется как ложные выигрыши в LWW/conflict resolution, нестабильный порядок данных и ложные конфликты для дат старта.

### Что важно из исторического контекста

- Старое iOS-приложение отправляло даты в UTC и меньше зависело от `modifyDate` вне sync-конфликтов.
- Этот опыт полезен как референс, но не означает, что нужно переводить всю новую sync-логику на day-based поведение.
- В текущем плане day-based сравнение допустимо только там, где бизнес-логика реально про календарный день, а не про временной порядок изменений.

## Область изменений

План ориентирован на следующие зоны проекта:

- `SwiftUI-SotkaApp/Services/DailyActivitiesService.swift`
- `SwiftUI-SotkaApp/Libraries/SWUtils/Sources/SWUtils/DateFormatter/DateFormatterService.swift`
- `SwiftUI-SotkaApp/Libraries/SWNetwork/Sources/SWNetwork/Public/JSONDecoder+.swift`
- `SwiftUI-SotkaApp/Services/ProgressSyncService.swift`
- `SwiftUI-SotkaApp/Services/CustomExercisesService.swift`
- `SwiftUI-SotkaApp/Services/StatusManager.swift`
- связанные unit-тесты в `SwiftUI-SotkaAppTests/`

---

## Приоритет 1. Минимально рискованный hotfix

### Подэтап 1.0. Исправить критерий выбора предыдущей сохраненной тренировки ✅ ВЫПОЛНЕНО

- [x] В `DailyActivitiesService.getLastPassedNonTurboWorkoutActivity` добавлен параметр `currentDay`, фильтрация по `day < currentDay`, сортировка по `day`; исключены turbo, `shouldDelete`, чужие пользователи. Вызовы обновлены в `WorkoutPreviewViewModel` и `StatusManager`. Тесты: `DailyActivitiesGetLastPassedWorkoutTests`, `WorkoutPreviewViewModelUpdateDataTests`, `StatusManagerWorkoutDataPreviousWorkoutTests` (40 passed).

---

## Приоритет 2. Полный client-only fix

### Цель этапа

Унифицировать работу клиента с датами без серверных изменений и убрать источник timezone-сдвига на клиенте.

### Подэтап 2.1. Нормализация отправки дат на сервер ✅ ВЫПОЛНЕНО

- [x] `DateFormatterService.stringFromFullDate(..., iso: true)` переведён на UTC перед суффиксом `Z`. Тесты: `DateFormatterServiceTests`, `DayRequestTests`, `ExerciseSnapshotTests`, `ProgressSyncServiceTests`, `StatusManagerStartNewRunTests` (21 passed).

### Подэтап 2.2. Нормализация чтения дат с сервера ✅ ВЫПОЛНЕНО

- [x] В `JSONDecoder.DateDecodingStrategy.flexibleDateDecoding` timezone-less `yyyy-MM-dd'T'HH:mm:ss` интерпретируется по фиксированной policy `Europe/Moscow`; парсинг с offset и short date не изменён. Round-trip в исходящий UTC детерминирован. Тесты: `JSONDecoderExtensionTests`, `DateDecodingRoundTripTests` (14 passed).

### Подэтап 2.3. Выравнивание sync и LWW-поведения ✅ ВЫПОЛНЕНО

#### Что исправляем

- Пересмотреть места, где клиент напрямую доверяет server `modifyDate/createDate` в conflict resolution.
- Сохранить текущий принцип offline-first, но убрать ложные выигрыши из-за timezone skew.

#### Зоны изменений

- `DailyActivitiesService`
- `ProgressSyncService`
- `CustomExercisesService`
- `StatusManager`

#### Текущее состояние

- [x] В `DailyActivitiesService`, `ProgressSyncService` и `CustomExercisesService` используется единая policy сравнения дат через `SyncDateComparisonPolicy`.
- [x] В `StatusManager` сравнение app/site start date уже выполняется по календарному дню через `isTheSameDayIgnoringTime`, а не по полному timestamp.
- [x] Для этих зон уже существуют unit-тесты на общие conflict-resolution сценарии и корректный wire-format исходящих дат.
- [x] Добавлены timezone-oriented regression-сценарии, которые воспроизводят ложный конфликт/ложный проигрыш из-за timezone skew.
- [x] Дублирование прямого сравнения дат в sync-сервисах устранено через общий helper/policy.

#### Как этап был выполнен по TDD

##### Red

- [x] Добавлены интеграционно-подобные unit-тесты на общие sync/LWW-сценарии для `DailyActivitiesService`, `ProgressSyncService` и `CustomExercisesService`: local newer, server newer, equal dates, unsynced local changes, identical data.
- [x] Для `DailyActivitiesService` уже покрыты сценарии `applySyncEvents` и `downloadServerActivities` на базовом уровне conflict resolution.
- [x] Для `ProgressSyncService` и `CustomExercisesService` уже покрыто сравнение локальной и серверной версий при одинаковых данных и при реальном конфликте.
- [x] Для `StatusManager` уже покрыты базовые сценарии совпадающего/разного календарного дня и корректной отправки даты старта новой программы.
- [x] Добавлены timezone-specific тесты на сценарии sync:
  - локальная запись не проигрывает серверной только из-за смещенной timezone-строки;
  - после успешной синхронизации серверный ответ не ломает локальный порядок данных именно в timezone-sensitive сценарии;
  - start date не создает ложный conflict screen при одинаковом календарном дне, но разном timestamp/offset.

##### Green

- [x] Внесены минимальные изменения в LWW-сравнение и conflict resolution в `DailyActivitiesService`, `ProgressSyncService`, `CustomExercisesService`, `StatusManager`.
- [x] В `StatusManager` сохранена day-based логика только для сравнения start date, где нужен календарный день.
- [x] В sync/LWW местах, где нужен временной порядок, сравнение осталось на уровне `Date`, а не `day`.
- [x] После добавления timezone-specific тестов точечно скорректировано проблемное место в `ProgressSyncService`: при равных нормализованных датах локальная версия больше не проигрывает серверной только из-за timezone skew.

##### Refactor

- [x] Унифицированы общие правила сравнения дат в sync-слое.
- [x] Логика вынесена в `SyncDateComparisonPolicy`, чтобы не дублировать одно и то же сравнение в нескольких сервисах.

### Подэтап 2.4. Осторожная работа с уже существующими локальными данными ⏳ НЕ ВЫПОЛНЕНО

#### Что осталось сделать

- Не начинать с массовой миграции данных.
- Сначала собрать факты после уже реализованных client-only фиксов и убедиться, что новые записи больше не искажаются.
- Только после этого решать, нужен ли узкий data-repair для уже поврежденных локальных timestamp.

#### Отдельный незавершенный этап

##### Red

- Если будет принято решение о repair-логике, сначала добавить тесты на точечные случаи поврежденных данных.

##### Green

- Реализовать только узкий и идемпотентный repair, если он действительно нужен.

##### Refactor

- Документировать repair-механику и версионирование флага миграции.

#### Статус и границы этапа

- На текущий момент repair-логика не реализована намеренно.
- Это не блокирует исправление будущих sync-сценариев, сериализации и декодинга.
- Это влияет только на возможное восстановление уже исторически поврежденных локальных timestamp, если такие данные существуют у части пользователей.

### Критерии завершения полного client-only fix

- [x] Исходящие даты сериализуются консистентно и детерминированно.
- [x] Входящие даты парсятся одинаково независимо от timezone устройства.
- [x] Sync-сценарии не зависят от ложного timezone-смещения.
- [x] Поведение покрыто автоматическими тестами, а не только ручной проверкой.

---

## Приоритет 3. Обязательные тесты

### 1. Тесты на hotfix логики предыдущей тренировки ✅

- [x] `DailyActivitiesGetLastPassedWorkoutTests`: day < currentDay, сортировка по day, исключения turbo/deleted/другой пользователь.
- [x] `WorkoutPreviewViewModelUpdateDataTests`: подстановка данных из предыдущей по дню.
- [x] `StatusManagerWorkoutDataPreviousWorkoutTests`: watch-ответ с day-based логикой.

### 2. Тесты на network date formatting ✅

- [x] `DateFormatterServiceTests`: UTC serialization, non-UTC локаль, отсутствие ложного `Z`, стабильность при смене timezone.

### 3. Тесты на request mapping ✅

- [x] `DayRequestTests`, `ExerciseSnapshotTests`, `ProgressSyncServiceTests`, `StatusManagerStartNewRunTests`: даты в корректном wire-format.

### 4. Тесты на date decoding ✅

- [x] `JSONDecoder+Tests`: ISO8601 (Z, fractional, offset), timezone-less по Europe/Moscow, optional Date?, round-trip UTC, short date.

### 5. Тесты на sync conflict resolution

- `DailyActivitiesService`:
  - [x] локальная запись с несинхронизированными изменениями не перетирается сервером;
  - [x] синхронизированная запись корректно обновляется только при реально более новой серверной версии;
  - [x] одинаковые данные не вызывают лишнего обновления.
  - [x] добавлен явный timezone-skew сценарий для `downloadServerActivities`.
- `ProgressSyncService`:
  - [x] корректное сравнение `lastModified` и server dates в типовых LWW-сценариях;
  - [x] отсутствие ложного конфликта при timezone skew.
- `CustomExercisesService`:
  - [x] те же базовые LWW-сценарии для упражнений.
  - [x] добавлен отдельный timezone-skew сценарий.

### 6. Тесты на start date conflict handling

- `StatusManagerTests`:
  - [x] одинаковый календарный день между app/site не создает conflict screen;
  - [x] действительно разные дни создают conflict screen;
  - [x] старт новой программы отправляет корректную дату.
  - [x] добавлен explicit timezone-edge-case: один календарный день при разном timestamp/offset не создает conflict screen.

---

## Рекомендуемый порядок реализации

### ~~Шаг 1. Hotfix~~ ✅ Выполнено

- [x] Тесты на выбор предыдущей тренировки и currentDay; минимальное исправление; целевые тесты.

### ~~Шаг 2. Безопасная починка исходящих дат~~ ✅ Выполнено

- [x] Тесты на форматирование и request mapping; исправление network date formatting; целевые тесты sync-слоя.

### Шаг 3. Починка входящего парсинга ✅ Выполнено

- [x] Decoder tests с Europe/Moscow policy; исправление fallback date parsing; проверка совместимости с API.

### Шаг 4. Починка sync/LWW ✅ Выполнено

- [x] Написать тесты на базовые конфликтные сценарии.
- [x] Точечно обновить `DailyActivitiesService`, `ProgressSyncService`, `CustomExercisesService`, `StatusManager`.
- [x] Добавить timezone-specific тесты на ложные конфликты и ложные проигрыши из-за skew.
- [x] После них точечно скорректировать comparison policy в проблемных местах.
- [x] Прогнать расширенный набор тестов.

### Шаг 5. Решение по repair уже сохраненных данных

- [ ] Сначала собрать факты после основных фиксов.
- [ ] Только потом решать, нужен ли отдельный repair step.

---

## Что не делать в первой итерации

- Не менять сервер.
- Не делать широкую миграцию локальных данных без тестов и подтвержденной необходимости.
- Не переводить всю sync-логику на сортировку по `day`.
- Не смешивать hotfix с полным рефакторингом date infrastructure в одном PR.

## Результат реализации 2.3

- В `DailyActivitiesService`, `CustomExercisesService` и `ProgressSyncService` используется общий helper `SyncDateComparisonPolicy`.
- Добавлены regression-тесты на timezone skew для активностей, упражнений, прогресса и start date conflict handling.
- `ProgressSyncService` приведен к тому же поведению, что и остальные sync-сервисы: при равных нормализованных датах локальная версия не проигрывает серверной автоматически.

## Что уже реализовано

- Hotfix выбора предыдущей тренировки переведен на day-based критерий и закрыт тестами.
- Исходящие даты сериализуются в UTC через `DateFormatterService`.
- Входящие timezone-less даты декодируются по фиксированной policy `Europe/Moscow`.
- Sync/LWW-логика в ключевых сервисах унифицирована и защищена regression-тестами на timezone skew.
- Для `StatusManager` сохранено day-based сравнение только там, где бизнес-смысл действительно про календарный день.

## Что еще осталось

- Собрать факты по уже существующим локальным данным после выката реализованного client-only fix.
- Принять решение, нужен ли вообще отдельный repair для исторически поврежденных timestamp.
- Если repair понадобится, сделать его узким, идемпотентным и сначала покрыть тестами.
- По возможности дополнительно задокументировать новые правила работы с датами рядом с кодом и тестами, а не только в этом документе.

## Релизный вывод

- Релиз с timezone-fix в текущем виде публиковать можно, если цель релиза:
  - остановить дальнейшее искажение дат на клиенте;
  - стабилизировать sync/LWW-поведение;
  - закрыть риск новых timezone-regression в основных пользовательских сценариях.
- До релиза не требуется обязательно реализовывать `2.4`, потому что это отдельная задача про возможное восстановление уже существующих локальных данных, а не про исправление основной причины для новых операций.
- Отдельная доработка нужна только в том случае, если перед релизом есть подтвержденные кейсы, что у пользователей уже массово накоплены локально поврежденные timestamp и их нужно автоматически чинить без переcоздания данных вручную.
- Без этапа `2.4` остается остаточный риск: если у пользователя уже есть исторически испорченные локальные даты, текущий релиз предотвратит новые искажения, но не гарантирует автоматическое исправление старых.

## Definition of Done

- [x] Созданы и зафиксированы failing tests для каждого подэтапа до изменения кода.
- [x] Каждый подэтап доведен до зеленого состояния отдельным минимальным изменением.
- [x] После Green выполнен небольшой Refactor без смены поведения.
- [ ] Все новые правила работы с датами задокументированы рядом с тестами и кодом.
- [x] Для релиза timezone-fix не требуется ждать data-repair, если нет подтвержденной необходимости чинить исторически поврежденные локальные данные автоматически.
- [ ] Для hotfix и полного fix можно сделать отдельные PR/релизные поставки при необходимости релизного разделения.

---

## Прогресс выполнения

| Подэтап | Статус | Тесты |
|---------|--------|-------|
| 1.0 Hotfix (previous workout) | ✅ Выполнено | 40 passed |
| 2.1 Outgoing dates (UTC) | ✅ Выполнено | 21 passed |
| 2.2 Incoming dates (decoding) | ✅ Выполнено | 14 passed |
| 2.3 Sync/LWW | ✅ Выполнено | добавлены timezone-regression тесты и общий `SyncDateComparisonPolicy`; полный unit test plan green |
| 2.4 Data repair | ⏳ Ожидает | — |
