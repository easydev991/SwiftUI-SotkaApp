# Документация: Продление календаря (Calendar Extension)

## Назначение

Функционал позволяет продолжать программу после 100-го дня блоками по 100 дней.
В текущей реализации продление бесплатное и доступно из Home.

- Все пользователи работают офлайн (сервер закрыт): продления хранятся только локально.

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

Используется SwiftData-сущность `CalendarExtensionRecord`:

- `date` — дата продления (нормализуется до секунды);
- `shouldDelete` — резервный флаг (всегда `false`: записи удаляются физически через `clearExtensionDates()`/`removeLastExtensionDate()`, фильтрации по флагу нет; при повторном добавлении той же даты выполняется сброс флага);
- связь с `User` — plain optional без `@Relationship`/`deleteRule`.

### Очистка данных

Локальные продления очищаются при:

- `didLogout()`
- `resetProgram()`

---

## Серверная синхронизация покупок (удалена)

Серверная синхронизация покупок календаря удалена вместе со sync-слоем: сервер `100.workout.su` закрыт (2026-08-01), приложение в read-only режиме.

Ранее использовался серверный контракт:

- `GET /100/purchases`
- `POST /100/purchases/calendars`

Поле `calendars` содержало массив ISO-дат; при merge применялись union `serverDates`/`localDates`, дедуп по нормализованной UTC-дате и пометка локальных записей синхронизированными. Контракт утратил актуальность.

> **Историческая справка (sync-слой удалён в `ed82f6e9`):** ранее здесь также была секция «Retry» — `getStatus()` детерминированно вызывал `syncJournalAndProgress()`, что инициировало retry unsynced. Раздел утратил актуальность и удалён.

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
- один и тот же persisted-ключ используется во всех режимах;
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

Для `make test_ui` и `make screenshots` внедрён единый preflight симулятора (boot/check, grant permissions, понятные ошибки). Запуск и troubleshooting — `docs/ui-tests-and-screenshots.md`. В `Makefile` добавлены команды preflight и отдельный target `test_ui_preflight_script` для unit-тестов preflight-скрипта.

---

## Проверка и покрытие

Реализация покрыта unit/integration/regression тестами, включая:

- математику DayCalculator;
- StatusManager (offline-only, локальные продления, cleanup);
- Home/Journal/Analytics;
- cleanup при logout/reset;
- SwiftData migration-тесты для legacy-store.

---

## Миграция SwiftData

Для `CalendarExtensionRecord` применяется lightweight-подход: явная текущая `Schema([...])`, safe-open legacy-store подтверждён миграционными тестами (включая апгрейд с релизных схем 4.0/4.1). Политика миграций, правила добавления моделей/полей и отложенный переход на `VersionedSchema`/`SchemaMigrationPlan` описаны в `docs/data-migration.md` (единый владелец темы миграций).
