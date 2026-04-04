# План реализации: Продление календаря (Calendar Extension)

## Концепция

Функционал позволяет пользователю продолжать программу после 100-го дня, добавляя блоки по 100 дней.
В SwiftUI-приложении это бесплатное действие: пользователь нажимает кнопку и получает +100 дней.

---

## Цели и ограничения

- Продление доступно только на граничных днях: 100, 200, 300...
- Продление не должно сдвигать `currentDay` вперёд в момент нажатия кнопки.
- Логика офлайн-first: источник истины локально (UserDefaults/SwiftData), sync не блокирует UI.
- После logout/reset данные продлений очищаются.
- Поддержка watchOS обязательна: часы продолжают отображать только текущий номер дня (`День X`).

### Продуктовые решения (зафиксировано)

- Семантика продления в этом приложении отличается от старого ObjC: мы не «перезапускаем» отсчёт от даты покупки продления.
- Если пользователь нажал продление не в день 100, а позже (например, на «застывшем» 100-м экране через 30 дней), после продления `currentDay` станет равен фактически прошедшему времени, ограниченному `totalDays`.
- V1: продления device-local only (без серверной синхронизации между устройствами). Это осознанное ограничение релиза.

---

## Базовая математика (единый контракт)

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

let isOver = shouldShowExtensionButton
let shouldShowInfopost = currentDay <= 100 && !isOver
```

Пояснение UX на 100-м дне после продления:

- до нажатия: `currentDay=100`, `totalDays=100`, `isOver=true`
- после нажатия: `currentDay=100`, `totalDays=200`, `isOver=false`, `daysLeft=100`

---

## Этап 1: DayCalculator

- [ ] Добавить `extensionCount: Int = 0` и `maxExtensionCount = 100`
- [ ] Добавить `normalizedExtensionCount`, `totalDays`, `shouldShowExtensionButton`, `isOver`, `shouldShowInfopost`
- [ ] Явно обновить ветку старта в будущем: `daysLeft = totalDays - 1`
- [ ] Обновить `id` (включить зависимость от `currentDay`, `daysLeft`, `totalDays`)

### Тесты DayCalculator

- [ ] День 1, `extensionCount=0` → `currentDay=1`, `daysLeft=99`, `isOver=false`
- [ ] День 100, `extensionCount=0` → `isOver=true`, `shouldShowExtensionButton=true`
- [ ] День 100, `extensionCount=1` → `isOver=false`, `totalDays=200`, `daysLeft=100`
- [ ] День 150, `extensionCount=1` → `currentDay=150`, `daysLeft=50`
- [ ] День 200, `extensionCount=1` → `isOver=true`
- [ ] Старт в будущем + `extensionCount=1` → `daysLeft=199`
- [ ] Лимит: `extensionCount=100`, `currentDay=10100` → `shouldShowExtensionButton=false`
- [ ] Лимит: `extensionCount=101` обрезается до 100, кнопка не показывается

Примечание: модель дня начинается с 1, сценарий `currentDay=0` не используется.

---

## Этап 2: Хранение и бизнес-логика в StatusManager

### 2.1 Хранение продлений

- [ ] Добавить хранение `extensionDates` в UserDefaults
- [ ] Ввести type-safe контейнер:

```swift
struct CalendarExtensionData: Codable {
    var dates: [Date] = []
    var count: Int { dates.count }
}
```

- [ ] При повреждении данных fallback на пустую модель
- [ ] `extensionCount` вычислять только как `extensionDates.count`
- [ ] Зафиксировать, что `dates` в V1 используются как audit trail + источник `count`

### 2.2 API StatusManager

- [ ] Реализовать API:
  - `func addExtensionDate(_ date: Date = .now)`
  - `func removeLastExtensionDate()`
  - `func clearExtensionDates()`
  - `func extendCalendar()`
- [ ] Добавить сигнатуру:
  - `private func rebuildCurrentDayCalculator(now: Date = .now)`
- [ ] В `rebuildCurrentDayCalculator` брать `extensionCount` из `extensionDates.count`

```swift
func extendCalendar() {
    guard let calculator = currentDayCalculator else { return }
    guard calculator.shouldShowExtensionButton else { return }
    addExtensionDate(.now)
    rebuildCurrentDayCalculator()
    sendCurrentStatusWithCurrentDay()
}
```

### 2.3 Тесты StatusManager

- [ ] Сохранение/чтение `extensionDates`
- [ ] `extendCalendar()` срабатывает только при `shouldShowExtensionButton == true`
- [ ] `extendCalendar()` увеличивает `totalDays` на 100
- [ ] `removeLastExtensionDate()` откатывает одно продление
- [ ] `didLogout()` и `resetProgram()` очищают продления

---

## Этап 3: HomeScreen

### 3.1 Кнопка продления

- [ ] Создать `HomeCalendarExtensionView`
- [ ] Показывать только при `calculator.shouldShowExtensionButton`
- [ ] Разместить сразу после `HomeDayCountView`

### 3.2 Активности на Home

- [ ] Исправить `HomeScreen.Model.showActivitySection` (сейчас `currentDay <= 100`)
- [ ] Новое правило: секция активностей видна для всех валидных дней программы, а не только до 100

### 3.3 DayCount / finished state

- [ ] Обновить `HomeDayCountView`: `finishedView` должен показываться только на границе `isOver=true`
- [ ] В `finishedView` убрать захардкоженное `100`; показывать текущую граничную сотню (`currentDay`)
- [ ] Обновить `makeNumberView`: корректная отрисовка 3+ цифр (101, 1000 и т.д.)
- [ ] Если текущие image-цифры недостаточны для 3-значного макета, добавить отдельный layout как аналог старого infinite-cell

### 3.4 Инфопост на Home

- [ ] Использовать `calculator.shouldShowInfopost`
- [ ] Для `currentDay > 100` инфопост скрыт

### 3.5 Тесты UI/Home

- [ ] На 100-м дне без продления кнопка видна
- [ ] После продления кнопка скрывается, `totalDays=200`, `currentDay=100`
- [ ] На 101+ секция активностей остаётся доступной
- [ ] На 101+ day counter корректно отображает 3-значное число

---

## Этап 4: Journal (iOS)

### 4.0 Архитектурная правка

Текущий Journal рендерит только 1...100 через `InfopostSection.days`.
Для `totalDays > 100` нужно отвязать источник дней Journal от `InfopostSection` как единственного источника.

### 4.1 List mode

- [ ] В list режиме формировать дни `1...totalDays`
- [ ] Секции:
  - для 1...100 сохранить `base/advanced/turbo/conclusion`
  - для 101+ добавить секции `101...200`, `201...300`, ...
- [ ] Сортировка работает для всех диапазонов

### 4.2 Grid mode (пагинация)

- [ ] `pageCount = max(1, ceil(Double(totalDays) / 100.0))`
- [ ] Page 0: 4 секции (49/42/7/2)
- [ ] Page 1+: одна секция по 100 дней
- [ ] Формула дня:
  - page 0: `day = cumulativeRows + rowIndex + 1`
  - page > 0: `day = page * 100 + rowIndex + 1`
- [ ] Реализовать page UI через `TabView` + `.tabViewStyle(.page)`

### 4.3 Тесты Journal

- [ ] list: при `totalDays=200` доступны дни 1...200
- [ ] grid: pageCount корректен для 100/200/250
- [ ] grid: day mapping корректен для page 0 и page > 0
- [ ] дни > `currentDay` disabled

---

## Этап 5: ProgressCalculator

- [ ] KPI прогресса зафиксированы как 100-дневные: `ProgressCalculator` не меняем
- [ ] После 100-го дня прогресс не должен изменяться
- [ ] Прогресс должен изменяться только после полного сброса программы (через MoreScreen), как уже реализовано

### Тесты ProgressCalculator

- [ ] Регрессионный тест: при днях > 100 проценты и day statuses остаются на уровне 100-дневной программы
- [ ] Регрессионный тест: после полного сброса прогресс начинается заново

---

## Этап 6: Уведомления (границы 100/200/...)

Ежедневные уведомления не зависят от продления календаря.

- [ ] Логику уведомлений не менять: они зависят только от:
  - флага включения уведомлений
  - выбранного времени уведомления
- [ ] Продление календаря не должно влиять на планирование/удаление ежедневных уведомлений

### Тесты уведомлений

- [ ] Регрессионный тест: после продления состояние ежедневных уведомлений не меняется
- [ ] Регрессионный тест: уведомления работают только по флагу и времени

---

## Этап 7: Watch (iOS + watchOS)

- [ ] Контракт с часами не расширять: передаём и отображаем только `currentDay`
- [ ] `totalDays` в watch payload не добавлять
- [ ] UI часов оставляем в формате `День X`

### Тесты watch

- [ ] Регрессионный тест: после продления часы продолжают получать только `currentDay`
- [ ] Регрессионный тест: UI часов отображает `День X` без `totalDays`

---

## Этап 8: Reset / Logout

- [ ] `StatusManager.didLogout()` вызывает `clearExtensionDates()`
- [ ] `StatusManager.resetProgram()` вызывает `clearExtensionDates()`
- [ ] Добавить регрессионные тесты

---

## Этап 9: Debug / Preview / совместимость

- [ ] `StatusManager.setCurrentDayForDebug` расширить диапазон (не `1...100`)
- [ ] Обновить `DayCalculator+.swift` preview для дней > 100
- [ ] Добавить/обновить тесты `StatusManagerSetCurrentDayForDebugTests` для диапазона > 100
- [ ] Проверить `WorkoutProgramCreator` для дней > 100 и зафиксировать поведение (reuse паттерна или отдельная логика)

---

## Этап 10: Финальное тестирование

- [ ] Целевые unit-тесты по этапам 1-9
- [ ] UI-тесты ключевых сценариев продления
- [ ] Регрессия watch connectivity
- [ ] `make format`

---

## Зависимости этапов

```text
Этап 1 -> Этап 2 -> Этапы 3,4,5,6,7,8,9 -> Этап 10
```

---

## Критерии завершения

1. Кнопка продления появляется только на 100/200/300... при неактивированном продлении.
2. Лимит продлений работает корректно, кнопка скрыта при достижении лимита.
3. После продления `totalDays += 100`, `currentDay` не прыгает на границе.
4. Секция активностей на Home работает и после 100-го дня.
5. Счётчик дней корректно отображает 3+ цифр.
6. Journal поддерживает `totalDays > 100` в list и grid.
7. KPI прогресса остаются 100-дневными; после 100-го дня прогресс не меняется до полного сброса.
8. Уведомления зависят только от флага включения и времени, продление на них не влияет.
9. Watch показывает только `День X`; `totalDays` не передаётся и не отображается.
10. Продления очищаются при logout/reset.
11. Все тесты проходят.

---

## Файлы для изменения

| Файл | Изменения |
|------|-----------|
| `SwiftUI-SotkaApp/Models/DayCalculator.swift` | `maxExtensionCount`, `normalizedExtensionCount`, `totalDays`, `shouldShowExtensionButton`, future-start branch |
| `SwiftUI-SotkaApp/Services/StatusManager.swift` | хранение/очистка продлений, `extendCalendar()`, `rebuildCurrentDayCalculator(now:)`, debug range, watch дедупликация |
| `SwiftUI-SotkaApp/Screens/Home/HomeScreen.swift` | `showActivitySection` для дней > 100, интеграция `HomeCalendarExtensionView`, infopost |
| `SwiftUI-SotkaApp/Screens/Home/Views/HomeDayCountView.swift` | `finishedView` без захардкоженного 100, 3-значный формат |
| `SwiftUI-SotkaApp/Screens/Home/Views/HomeCalendarExtensionView.swift` | новый компонент кнопки продления |
| `SwiftUI-SotkaApp/Screens/Profile/Journal/JournalScreen.swift` | прокидывание `totalDays` в list/grid |
| `SwiftUI-SotkaApp/Screens/Profile/Journal/JournalListView.swift` | дни до `totalDays`, секции 101+ |
| `SwiftUI-SotkaApp/Screens/Profile/Journal/JournalGridView.swift` | пагинация 100-дневными страницами |
| `SwiftUI-SotkaApp/Models/Infoposts/InfopostSection.swift` | разделение инфопост-секций и journal-секций |
| `SwiftUI-SotkaApp/Models/ProgressCalculator.swift` | зафиксировать и покрыть тестами 100-дневные KPI без изменений поведения |
| `SwiftUI-SotkaApp/PreviewContent/DayCalculator+.swift` | корректные preview для дней > 100 |
| `SwiftUI-SotkaApp/Services/WorkoutProgramCreator.swift` | проверка/адаптация поведения для дней > 100 |
| `SwiftUI-SotkaAppTests/StatusManagerTests/StatusManagerSetCurrentDayForDebugTests.swift` | расширение диапазона и новые кейсы |
| `SwiftUI-SotkaApp/Services/AppSettings.swift` | только регрессионная валидация: уведомления независимы от продления |
| `SwiftUI-SotkaApp/Services/WatchStatusMessage.swift` | только регрессионная валидация: payload без `totalDays` |
| `SotkaWatch Watch App/Services/WatchConnectivityService.swift` | только регрессионная валидация: принимается `currentDay` без `totalDays` |
| `SotkaWatch Watch App/ViewModels/HomeViewModel.swift` | только регрессионная валидация: UI использует только `currentDay` |
| `SotkaWatch Watch App/Views/DayActivityView.swift` | подтверждение формата `День X` без изменений |

---

## Что сознательно не делаем в этом плане

- Не возвращаем IAP-логику старого приложения.
- Не добавляем отдельный `CalendarExtensionService` (логика остаётся в `StatusManager`).
- Не добавляем UI «отменить продление» в V1 (только внутренний rollback-метод).
- Не добавляем серверную синхронизацию продлений между устройствами в V1 (device-local only).
- Не меняем 100-дневную модель KPI прогресса.
- Не меняем контракт watch на `totalDays` (часы показывают только текущий день).
- Не связываем ежедневные уведомления с продлением календаря.
