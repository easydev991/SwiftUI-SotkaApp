# План реализации: Продление календаря (Calendar Extension)

## Концепция

Функционал позволяет пользователям **продолжить программу 100-дневки** после её завершения, получая дополнительные 100-дневные блоки. В отличие от старого приложения (SOTKA-OBJc), где это была платная функция (IAP), в нашем SwiftUI-приложении все функции бесплатные — пользователь просто нажимает кнопку и получает +100 дней.

---

## Сводка функционала (из старого приложения)

| Аспект | Детали (SOTKA-OBJc) | Адаптация для SwiftUI |
|--------|---------------------|----------------------|
| **Тип** | Покупка в приложении (IAP) | Бесплатная кнопка |
| **Название продукта** | `com.FGU.WorkOut100Days.100DaysSubscription` | Не требуется |
| **Что даёт** | +100 дней к программе | +100 дней к программе |
| **Когда показывается** | На 100-й день (и каждые последующие 100 дней) | Аналогично |
| **Условие показа кнопки** | `currentDay % 100 == 0` | Аналогично |
| **Где хранятся данные** | UserDefaults + синхронизация с сервером | UserDefaults + SwiftData |
| **UI** | `HomeProlongationCell` на главном экране | Новая секция/кнопка на HomeScreen |

---

## Этап 1: Модель данных (Domain Layer)

### 1.1 Расширение DayCalculator

**Цель**: Модифицировать `DayCalculator` для поддержки расширений календаря.

- [ ] Написать тесты для `DayCalculator` с расширениями
  - Тест: день 50 без расширений → currentDay=50, daysLeft=50
  - Тест: день 100 без расширений → currentDay=100, isOver=true
  - Тест: день 150 с 1 расширением → currentDay=150, daysLeft=50
  - Тест: день 200 с 1 расширением → currentDay=200, isOver=true
  - Тест: день 250 с 2 расширениями → currentDay=250, daysLeft=50

- [ ] Добавить свойство `extensionCount: Int` в `DayCalculator`
  - Количество купленных/доступных расширений (по 100 дней каждое)
  - По умолчанию 0

- [ ] Изменить логику расчёта `currentDay`:
  ```
  currentDay = min(daysBetween + 1 + extensionCount * 100, 100 + extensionCount * 100)
  daysLeft = (100 + extensionCount * 100) - currentDay
  isOver = false (теперь программа может быть бесконечной)
  ```

- [ ] Добавить computed property `totalAvailableDays: Int`
  - `totalAvailableDays = 100 + extensionCount * 100`

- [ ] Добавить computed property `shouldShowExtensionButton: Bool`
  - `true` когда `currentDay % 100 == 0` и `currentDay > 0`
  - Условие: показывать кнопку на 100, 200, 300... дні

### 1.2 Хранение extension dates

**Цель**: Сохранять даты расширений локально.

- [ ] Добавить ключ в `UserDefaults` через `Constants`:
  - `calendarExtensionDatesKey = "CalendarExtensionDates"`

- [ ] Добавить свойства в `StatusManager`:
  - `extensionDates: [Date]` — массив дат расширений
  - `extensionDatesCount: Int` — вычисляемое свойство (count extensionDates)

- [ ] Реализовать методы в `StatusManager`:
  - `addExtensionDate(_ date: Date)` — добавить дату расширения
  - `clearExtensionDates()` — очистить все расширения (при reset/ logout)

- [ ] Написать тесты для `StatusManager`:
  - Тест добавления extension date
  - Тест очистки при logout
  - Тест очистки при resetProgram

---

## Этап 2: Бизнес-логика (Domain Layer)

### 2.1 Логика добавления расширения

- [ ] Написать тесты для `CalendarExtensionService` (создать новый сервис)
  - Тест: успешное добавление расширения
  - Тест: расширение добавляет +100 дней
  - Тест: multiple extensions (200, 300 дней и т.д.)
  - Тест: валидация — нельзя добавить если currentDay < 100

- [ ] Создать `CalendarExtensionService`:
  - Метод `extendCalendar()` → добавляет текущую дату как extension date
  - Метод `canExtendCalendar(currentDay: Int) → Bool`:
    - Возвращает `true` если `currentDay % 100 == 0` и `currentDay > 0`

- [ ] Обновить `StatusManager`:
  - Интегрировать `CalendarExtensionService`
  - После добавления расширения — пересоздать `currentDayCalculator`

### 2.2 Синхронизация с Apple Watch

- [ ] Обновить `WatchStatusMessage` для отправки `extensionCount` на часы
- [ ] Обновить логику отправки статуса в `StatusManager`

---

## Этап 3: UI Layer (HomeScreen)

### 3.1 Кнопка "Продлить календарь"

**Цель**: Добавить UI для продления на главном экране.

- [ ] Создать `HomeCalendarExtensionView`:
  - Текст: "Если хочешь продолжить использовать приложение в качестве дневника тренировок, нажми кнопку ниже"
  - Кнопка: "Продлить календарь на 100 дней"
  - Отображается только когда `shouldShowExtensionButton == true`

- [ ] Интегрировать `HomeCalendarExtensionView` в `HomeScreen`:
  - Добавить после `HomeDayCountView` в `makeVerticalView`
  - Добавить после `HomeDayCountView` в `makeHorizontalView`

- [ ] Добавить `@Environment` для `CalendarExtensionService` в `HomeScreen`

- [ ] Добавить `@State` для управления видимостью кнопки:
  - `showExtensionButton: Bool`

### 3.2 Обновление HomeDayCountView

- [ ] Модифицировать `HomeDayCountView`:
  - При `currentDay > 100` показывать "День X из Y" вместо "День 100 из 100"
  - Обновить `finishedView`: теперь это не конец программы, а просто 100 дней
  - Убрать кнопку оценки приложения (rate app) с экрана поздравления

### 3.3 Локализация

- [ ] Добавить строки в `.strings` файлы (ru, en):
  - `"calendarExtensionTitle"` = "Продление календаря"
  - `"calendarExtensionDescription"` = "Если хочешь продолжить использовать приложение в качестве дневника тренировок, нажми кнопку ниже"
  - `"calendarExtensionButton"` = "Продлить календарь на 100 дней"
  - `"calendarExtensionSuccess"` = "Календарь продлён на 100 дней!"

---

## Этап 4: UI Layer (MoreScreen)

### 4.1 Отображение количества расширений

- [ ] Добавить в `MoreScreen` секцию с информацией о расширениях:
  - Текст: "Продлений календаря: X"
  - Показывать только если `extensionCount > 0`

---

## Этап 5: Обработка событий сброса/выхода

### 5.1 Очистка данных при logout

- [ ] Обновить `StatusManager.didLogout()`:
  - Добавить вызов `clearExtensionDates()`

### 5.2 Очистка данных при resetProgram

- [ ] Обновить `StatusManager.resetProgram()`:
  - Добавить вызов `clearExtensionDates()`

---

## Этап 6: Тестирование

### 6.1 Unit-тесты

- [ ] Тесты `DayCalculator` с расширениями
- [ ] Тесты `CalendarExtensionService`
- [ ] Тесты `StatusManager` (extension dates)
- [ ] Тесты `HomeScreen` (show/hide button logic)

### 6.2 UI-тесты

- [ ] Тест: кнопка появляется на 100-й день
- [ ] Тест: нажатие кнопки продлевает календарь
- [ ] Тест: после продления показывается день 101 из 200

---

## Зависимости между этапами

```
Этап 1 (Модели) → Этап 2 (Бизнес-логика) → Этап 3 (HomeScreen UI)
                                                        ↓
Этап 5 (Сброс данных) ←─────────────────────────────── Этап 4 (MoreScreen UI)
                                                        ↓
                                              Этап 6 (Тестирование)
```

---

## Критерии завершения

1. ✅ Пользователь видит кнопку "Продлить календарь" на 100-й, 200-й, 300-й... день
2. ✅ Нажатие кнопки добавляет +100 дней к программе
3. ✅ После продления счётчик показывает "День 101 из 200" (пример)
4. ✅ Количество расширений сохраняется между сессиями
5. ✅ При logout/reset программы расширения очищаются
6. ✅ Все тесты проходят
7. ✅ Code formatting и linting проходят (`make format`)

---

## Файлы для изменения

| Файл | Изменения |
|------|-----------|
| `Models/DayCalculator.swift` | Добавить extensionCount, пересчитать currentDay |
| `Services/StatusManager.swift` | Добавить extensionDates, методы add/clear |
| `Services/CalendarExtensionService.swift` | **НОВЫЙ** — логика добавления расширений |
| `Screens/Home/HomeScreen.swift` | Интеграция кнопки продления |
| `Screens/Home/Views/HomeDayCountView.swift` | Поддержка дней > 100 |
| `Screens/Home/Views/HomeCalendarExtensionView.swift` | **НОВЫЙ** — UI кнопки |
| `Screens/More/MoreScreen.swift` | Показать количество расширений |
| `Services/WatchStatusMessage.swift` | Отправка extensionCount на часы |

---

## Файлы для создания

| Файл | Описание |
|------|---------|
| `Services/CalendarExtensionService.swift` | Сервис для работы с расширениями |
| `Screens/Home/Views/HomeCalendarExtensionView.swift` | UI компонент кнопки |
