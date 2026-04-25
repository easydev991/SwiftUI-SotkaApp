# Документация: Продление календаря (Calendar Extension)

## Назначение

Функционал позволяет продолжать программу после 100-го дня блоками по 100 дней.
В текущей реализации продление бесплатное и доступно из Home.

- Авторизованный пользователь: продления синхронизируются с сервером.
- `offline-only` пользователь: продления хранятся только локально.

---

## Ключевые правила

- Продление доступно на границах: `100`, `200`, `300` и т.д.
- При нажатии на границе в тот же момент `currentDay` не «прыгает» вперёд.
- Если продление нажато позже границы, день пересчитывается по фактически прошедшему времени в рамках нового лимита.
- Инфопосты показываются только для диапазона `1...100`.
- KPI прогресса остаются 100-дневными.
- Уведомления не зависят от продлений.
- На watch передаётся и показывается только `currentDay`.

---

## Математика дня

```swift
let maxExtensionCount = 100
let normalizedExtensionCount = min(extensionCount, maxExtensionCount)

let totalDays = 100 + normalizedExtensionCount * 100
let currentDay = min(daysBetween + 1, totalDays)
let daysLeft = totalDays - currentDay

let shouldShowExtensionButton =
    currentDay > 0 &&
    currentDay % 100 == 0 &&
    normalizedExtensionCount < currentDay / 100 &&
    normalizedExtensionCount < maxExtensionCount

let isOver = currentDay >= totalDays
let shouldShowInfopost = currentDay <= 100
```

---

## Данные и хранение

### Локальная модель

Используется SwiftData-сущность `CalendarExtensionRecord` с sync-флагами:

- `isSynced`
- `shouldDelete`
- `lastModified`
- связь с `User`

### Очистка данных

Локальные продления очищаются при:

- `didLogout()`
- `resetProgram()`

---

## Серверная синхронизация покупок

Для авторизованного пользователя используется серверный контракт покупок календаря:

- `GET /100/purchases`
- `POST /100/purchases/calendars`

Поле `calendars` содержит массив ISO-дат.

### Merge-логика

- источник `extensionCount` = `union(serverDates, localDates)`;
- дедуп по нормализованной UTC-дате (точность до секунд);
- unsynced локальная запись, уже присутствующая на сервере, не дублируется и переводится в `isSynced=true`.

### Retry

Retry unsynced выполняется детерминированно в:

- `getStatus()`
- `syncJournalAndProgress()`

---

## UI-поведение

### Home

- добавлена кнопка продления (`HomeCalendarExtensionView`);
- `showActivitySection` работает и после 100-го дня;
- `showProgressSection` зависит от `isMaximumsFilled`, а не от номера дня;
- счётчик поддерживает 3+ цифры;
- добавлен `extendedFinishedView` для 200/300/...;
- аналитика по tap: `extendCalendar(targetTotalDays:)`.

### Journal

- поддержан `totalDays > 100`;
- grid/list используют единый toolbar-контрол пагинации по 100 дней (показывается только при `totalDays > 100`);
- для страниц `101+` в list используется плоский список без базовых секций;
- выбранная страница journal персистится в `UserDefaults` (ключ `Journal.SelectedPage`) и валидируется через clamp по `totalDays`;
- один и тот же persisted-ключ используется для online и `offline-only` режимов;
- persisted-страница очищается при `logout`/`resetProgram()`.

### Debug/Preview

- `setCurrentDayForDebug(_ day: Int, extensionCount: Int? = nil)`;
- debug picker использует `StatusManager.debugPickerMaxDay`;
- preview-режимы для дней `>100` стабилизированы.

---

## Уведомления и Watch

### Уведомления

Ежедневные уведомления зависят только от:

- флага активности уведомлений;
- выбранного времени.

Продление календаря на логику уведомлений не влияет.

### Watch

Контракт без изменений:

- передаётся только `currentDay`;
- `totalDays` на watch не передаётся и не отображается.

---

## Стабилизация UI-тестов и скриншотов

Для `make test_ui` и `make screenshots` внедрён единый preflight симулятора:

- boot/check симулятора;
- `xcrun simctl privacy grant ...` для обязательных permissions;
- понятные ошибки при невозможности настройки.

Документация по запуску и troubleshooting:

- `docs/ui-tests-and-screenshots.md`

В `Makefile` добавлены команды preflight и отдельный target `test_ui_preflight_script` для unit-тестов preflight-скрипта.

---

## Проверка и покрытие

Реализация покрыта unit/integration/regression тестами, включая:

- математику DayCalculator;
- StatusManager (sync/merge/retry/offline-only);
- Home/Journal/Analytics;
- cleanup при logout/reset;
- SwiftData migration-тесты для legacy-store.

---

## Миграция SwiftData: текущее решение и отложенный шаг

### Что сделано сейчас

- Используется явная текущая `Schema([...])`.
- Подтверждён safe-open legacy-store тестами, включая апгрейд с релизных схем `4.0/4.1`.
- Для текущего изменения (`CalendarExtensionRecord`) применяется lightweight-подход.

### Анализ референса `SwiftUI-Days`

В проекте `SwiftUI-Days` после изменения схемы (`colorTag`) наблюдались проблемы, и затем был внедрён явный migration-подход:

- `VersionedSchema` (`ItemSchemaV1/V2/V3`)
- `SchemaMigrationPlan` (`ItemMigrationPlan`)
- `ModelContainer(..., migrationPlan: ItemMigrationPlan.self, ...)`

Это подтверждает практическую пользу явной версионированной миграции для долгоживущих схем.

### Текущее продуктовое решение

На этот релиз:

- не внедряем `VersionedSchema/SchemaMigrationPlan` в `SwiftUI-SotkaApp`;
- делаем реальную проверку upgrade-path на устройстве: App Store build -> TestFlight build из ветки;
- при отсутствии крэшей/потери данных идём в релиз.

### Отложенная задача (техдолг)

Перед следующим non-lightweight изменением модели данных вернуть отдельную задачу и внедрить:

- `VersionedSchema`
- `SchemaMigrationPlan`

с отдельным набором миграционных тестов.
