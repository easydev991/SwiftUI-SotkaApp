# План: интеграция SotkaApp с приложением «Здоровье» (HealthKit)

## Цель

Тренировки, завершённые на **Apple Watch**, должны отображаться в «Здоровье» на iPhone (и в Активность, Фитнес). **Записываем в HealthKit только тренировки с часов:** у Watch есть доступ к пульсу и метрикам (при `HKWorkoutSession`), данные синхронизируются на iPhone. Тренировки только с iPhone в HealthKit не пишем (как в SOTKA-OBJc).

## Текущее состояние

HealthKit не используется (см. [apple-watch-development-plan.md](apple-watch-development-plan.md)). Завершение тренировки: на часах — `WatchWorkoutService.finishWorkout()` → `WorkoutResult` → команда `saveWorkout` → `StatusManager.handleSaveWorkoutCommand`; на iPhone — `WorkoutPreviewViewModel.handleWorkoutResult` → `WorkoutProgramCreator` → SwiftData. Модели: `DayActivity`, `WorkoutResult(count, duration)`, `SaveWorkoutData`.

## Реализация в SOTKA-OBJc (старое приложение)

Детали для переноса функционала в новое приложение.

### iPhone (WorkOut100Days)

- **Файл:** `WorkOut100Days/AppDelegate.m`
- **Инициализация:** `initHealthKit` создаёт `HKHealthStore`, запрашивает:
  - **запись (share):** только `HKObjectType.workoutType`;
  - **чтение (read):** пульс (`HKQuantityTypeIdentifierHeartRate`), дистанция (`DistanceWalkingRunning`), активные калории (`ActiveEnergyBurned`), тип тренировок (`workoutType`).
- Дополнительно: включается фоновая доставка пульса (`enableBackgroundDeliveryForType:HeartRate`) и наблюдатель за изменениями пульса (`setupObserver`). Тренировки **на iPhone в HealthKit не записываются** — только чтение данных для отображения/мониторинга.
- **Разрешения в Info.plist:** `NSHealthShareUsageDescription`, `NSHealthUpdateUsageDescription` (значения в коде — плейсхолдеры; локализованные строки в `ru.lproj/InfoPlist.strings`: «Разрешить обновление Здоровья» / «Разрешить делиться данными Здоровья»).
- Вызов: `initHealthKit` вызывается при старте приложения (в коде есть закомментированный альтернативный вызов).

### Apple Watch (WorkOut100DaysWatch Extension)

- **Файлы:** `WorkOutSessionManager.h`, `WorkOutSessionManager.m`
- **Запись тренировки в HealthKit:** только на часах, через **живую сессию**:
  1. **Старт:** `startSession` — создаётся `HKWorkoutSession` с конфигурацией:
     - `activityType = HKWorkoutActivityTypeCrossTraining`;
     - `locationType = HKWorkoutSessionLocationTypeIndoor`;
     создаётся `HKLiveWorkoutBuilder`, к нему подключается `HKLiveWorkoutDataSource` с сбором **пульса** (`HKQuantityTypeIdentifierHeartRate`). Сессия и сбор данных стартуют (`startActivityWithDate`, `beginCollectionWithStartDate`).
  2. **Во время тренировки:** делегат `workoutBuilder:didCollectDataOfTypes:` получает статистику (пульс: текущий/средний/мин/макс; калории — если включить сбор). Данные пробрасываются в UI через `WorkOutSessionManagerDelegate` (heartRateUpdated, caloriesUpdated).
  3. **Завершение:** `endSession` → `workoutSession end` → `builder endCollectionWithEndDate` → `builder finishWorkoutWithCompletion`. В completion приходит готовый `HKWorkout` — он уже сохранён в HealthKit (с привязанными сэмплами пульса и т.д.). Дополнительно в Core Data на часах сохраняется свой объект дня (`WatchDbDay`) с длительностью и т.д.
- **Режим фона:** в `Info.plist` Watch Extension указан `WKBackgroundModes` → `workout-processing`, чтобы сессия продолжалась при свёрнутом приложении.
- **Проверка доступности:** перед стартом сессии в `HomeInterfaceController.m` проверяется `[HKHealthStore isHealthDataAvailable]`.

### Что использовать в плане

| Аспект | SOTKA-OBJc | Использование в плане |
|--------|------------|------------------------|
| Тип активности | `HKWorkoutActivityTypeCrossTraining` | Сохраняем в этапе 1 (уже указано). |
| Тип локации | `HKWorkoutSessionLocationTypeIndoor` | При реализации фазы с `HKWorkoutSession` на часах — задать в конфигурации. |
| Запись тренировки | Только на Watch, через `HKWorkoutSession` + `HKLiveWorkoutBuilder`; iPhone только читает | В новом приложении так же: запись в «Здоровье» только с Watch (часы имеют доступ к пульсу и др.); iPhone не пишет. |
| Пульс и калории | Сбор в реальном времени на Watch через `HKLiveWorkoutDataSource` и статистику builder | Расширение после базовой интеграции; в плане уже отмечено как отдельный шаг (этап 3, риски). |
| Разрешения | Share: workoutType; Read: heart rate, distance, active energy, workout | Для базовой записи достаточно запроса на запись `workoutType`; чтение — по необходимости (дедупликация, аналитика). |
| Локализация описаний | `InfoPlist.strings`: «Разрешить обновление Здоровья», «Разрешить делиться данными Здоровья» | Взять формулировки как референс для этапа 2 и 5 (можно уточнить под контекст записи/чтения). |
| WKBackgroundModes | `workout-processing` для Watch | Добавить в этап 2 при реализации на часах живой сессии (HKWorkoutSession). |
| Ошибки | NSLog в completion; при ошибке beginCollection — остановка сессии | OSLog, не ронять приложение (этап 3). |

Для первой версии — простая запись `HKWorkout` по датам/длительности; полная схема (сессия + пульс/калории) — при расширении.

## Этап 1: Доменный слой и контракт сервиса HealthKit

- [ ] Определить **что записывать в HealthKit** для одной тренировки:
  - тип активности: `HKWorkoutActivityType.crossTraining` (как в плане по часам и в SOTKA-OBJc: `WorkOutSessionManager.m`, конфигурация сессии);
  - при использовании живой сессии на часах — тип локации `HKWorkoutSessionLocationTypeIndoor` (как в старом приложении);
  - `startDate` и `endDate` (по длительности из `WorkoutResult.duration` или по `createDate`/`modifyDate` из `DayActivity`);
  - опционально: активные калории, пульс — на первом этапе можно не передавать (для калорий/пульса позже потребуется `HKWorkoutSession` на часах, см. раздел про SOTKA-OBJc выше).
- [ ] Ввести **протокол сервиса** записи тренировки в HealthKit (например, `HealthKitWorkoutWriting` или `HealthKitWorkoutServiceProtocol`) с методом вида: «сохранить тренировку с датами и длительностью».
- [ ] Описать **источник данных** для вызова: только на часах — `WorkoutResult` + время начала (`workoutStartTime` в `WatchWorkoutService`). На iPhone запись в HealthKit не выполняем.
- [ ] Учесть **офлайн-first**: запись в HealthKit не должна блокировать сохранение в SwiftData; при недоступности HealthKit или отказе в разрешении — только логировать, не ломать основной сценарий.

**Критерий завершения:** протокол и описание формата данных зафиксированы (в коде или в документации), согласованы с правилами проекта (без force unwrap, OSLog).

---

## Этап 2: Разрешения и конфигурация (HealthKit capability)

- [ ] **watchOS:** включить capability **HealthKit** в таргете SotkaWatch; добавить в Info.plist Watch-приложения:
  - `NSHealthShareUsageDescription` — зачем приложение читает данные из «Здоровье» (если понадобится чтение);
  - `NSHealthUpdateUsageDescription` — зачем приложение записывает тренировки в «Здоровье» (основной текст для пользователя).
- [ ] **iOS:** для текущей версии (запись только с часов) capability HealthKit и ключи в Info.plist **не требуются** в таргете SwiftUI-SotkaApp. Если позже появится чтение из «Здоровье» на iPhone — добавить.
- [ ] Убедиться, что запись с часов попадает в то же хранилище Health пользователя, что и на iPhone (стандартное поведение при одном Apple ID).
- [ ] **watchOS (при расширении до живой сессии):** при переходе к `HKWorkoutSession` на часах добавить в Info.plist Watch-приложения `WKBackgroundModes` → `workout-processing`, как в SOTKA-OBJc, чтобы тренировка продолжала записываться в фоне.

**Критерий завершения:** Watch-таргет собирается с включённым HealthKit; при первом обращении к HealthKit на часах система показывает диалог с указанными описаниями.

---

## Этап 3: Реализация записи тренировок в HealthKit (Data Layer)

- [ ] Реализовать **сервис записи** (класс/структура, реализующая протокол из этапа 1):
  - запрос разрешения на **запись** типа `HKObjectType.workoutType()`;
  - при необходимости чтения (например, для проверки дубликатов или будущей аналитики) — запрос разрешения на чтение тренировок и, при желании, активных калорий/пульса;
  - метод: по `startDate` и `endDate` (или по `startDate` + `duration` в секундах) создать `HKWorkout` с типом `HKWorkoutActivityType.crossTraining` и сохранить через `HKHealthStore.save(_:withCompletion:)`.
- [ ] Размещение кода: сервис записи нужен **только в таргете SotkaWatch** (на iPhone запись в HealthKit не вызывается). Реализация — в Watch-приложении (например, `SotkaWatch Watch App/Services/`). При желании общий протокол или тип данных можно вынести в общий модуль, доступный watchOS.
- [ ] Обработка ошибок: отказ в разрешении, недоступность HealthKit (например, на симуляторе), ошибки `save` — логировать через OSLog (на русском), не прерывать сохранение в SwiftData.
- [ ] Не блокировать UI: вызовы HealthKit выполнять асинхронно (async/await или completion handlers), не вызывать запрос разрешений и сохранение из главного потока без необходимости.

**Критерий завершения:** по вызову метода сервиса с датами и длительностью в «Здоровье» появляется тренировка типа «Кросс-тренинг»; отказ в разрешении не приводит к падению приложения.

---

## Этап 4: Точка вызова записи в HealthKit (только часы)

- [ ] **Apple Watch:** после успешного завершения тренировки (в месте вызова `WatchWorkoutService.finishWorkout()` или перед/после отправки результата на телефон) вызвать сервис записи в HealthKit с `workoutStartTime` и длительностью из `WorkoutResult.duration`; при отсутствии длительности — использовать `workoutStartTime` и текущее время как `endDate`. Запись в HealthKit на часах автоматически синхронизируется в «Здоровье» на iPhone.
- [ ] **iPhone:** запись в HealthKit **не вызываем** — ни в `StatusManager.handleSaveWorkoutCommand`, ни при сохранении тренировки с телефона (`WorkoutPreviewViewModel.handleWorkoutResult`). Тренировки только с iPhone в «Здоровье» не попадают (нет пульса и др. метрик). Дубликатов нет: единственный источник записи — часы.

**Критерий завершения:** тренировка, выполненная и завершённая на часах, отображается в «Здоровье» на iPhone.

---

## Этап 5: UI и настройки

- [ ] **Запрос разрешений (на часах):** в момент первого обращения к HealthKit на часах (например, при первом завершении тренировки на Watch) запрашивать разрешение на запись тренировок; текст — по смыслу `NSHealthUpdateUsageDescription` в Info.plist Watch-приложения.
- [ ] **Настройки (опционально):** переключатель «Синхронизировать тренировки с „Здоровье“» — в настройках на часах или на iPhone (при хранении на iPhone передавать флаг на часы через WatchConnectivity); при выключении на часах не вызывать сервис записи.
- [ ] Локализация: все строки, показываемые пользователю (описания разрешений, подписи в настройках), вынести в Localizable.strings и учесть в skill локализации. Референс формулировок для «Здоровье»: SOTKA-OBJc `WorkOut100Days/ru.lproj/InfoPlist.strings` — «Разрешить обновление Здоровья», «Разрешить делиться данными Здоровья» (уточнить под контекст записи тренировок).

**Критерий завершения:** пользователь видит запрос «Здоровье» с понятным текстом; при необходимости может отключить синхронизацию в настройках.

---

## Этап 6: Тесты и документация

- [ ] **Unit-тесты:** тесты для сервиса записи в HealthKit с моком `HKHealthStore` (или протоколом над ним), чтобы проверять вызов `save` с корректными `HKWorkout` (тип, даты). По правилам проекта — Swift Testing, без force unwrap, при необходимости `#require` для опционалов.
- [ ] **Документация:** обновить [apple-watch-development-plan.md](apple-watch-development-plan.md): в разделе «Интеграция с HealthKit» указать, что базовая запись тренировок реализована (тип, длительность, даты); при необходимости добавить ссылку на этот план. Обновить [feature-map.md](feature-map.md) или аналог, если в нём перечислены интеграции с системными приложениями.

**Критерий завершения:** тесты проходят (`make test`), документация отражает текущее поведение; после изменений выполнен `make format`.

---

## Зависимости между этапами

1. Этап 1 → 2, 3; 2 → 3; 3 → 4 (сервис перед вызовом на Watch). 4 и 5 — частично параллельно. 6 — после 3–5.

## Правила проекта

- Следовать [sotka-development.mdc](../.agents/rules/sotka-development.mdc): MVVM, @Observable, сервисы по протоколам, OSLog, без force unwrap.
- Офлайн-first: отказ или недоступность HealthKit не должны мешать сохранению в SwiftData и основной работе приложения.
- Логи — на русском (см. [logs-language SKILL](../.agents/skills/logs-language/SKILL.md)).
- Локализация — по [localization SKILL](../.agents/skills/localization/SKILL.md).

## Риски и ограничения

- **Симулятор:** HealthKit может быть недоступен; тестировать запись на устройстве.
- **Дубликаты:** не актуальны (один источник — часы).
- **Калории и пульс:** отдельный шаг — `HKWorkoutSession` + `HKLiveWorkoutBuilder` на часах (референс: SOTKA-OBJc `WorkOutSessionManager.m`). В этом плане — только факт и длительность тренировки в «Здоровье».
