<!-- baa8bcdb-9a15-4a4f-b4ee-8e4f734e9931 e27158e3-a498-4a63-b5c4-9300c3318a2c -->
# План детализации главного экрана SotkaApp

## Общая структура

На основе скриншота и кода старого приложения (`HomeController.m`), главный экран должен содержать следующие секции (сверху вниз):

1. **Текущий день** (уже реализовано) - `DayCountView`
2. **Тема** (нужно реализовать) - изображение дня + переход к инфопосту
3. **Активность** (нужно реализовать на заглушках) - 4 кнопки выбора типа активности
4. **Прогресс** (нужно реализовать на заглушках) - кнопка перехода к заполнению результатов

## 1. Секция "Тема" (полная реализация)

### 1.1 Обновление модели DayActivityType

**Файл**: `SwiftUI-SotkaApp/Models/Workout/DayActivityType.swift`

Модель уже существует, нужно доработать:

- Добавить computed property `color: Color` - цвет для UI (синий для workout, зеленый для rest, фиолетовый для stretch, красный для sick)
- Добавить computed property `iconName: String` - имя SF Symbol для иконки
- Оставить существующий `localizedTitle: LocalizedStringKey`

Соответствие со старым приложением:

- `workout` = `ACTIVITY_TYPE_EXERCISE` (0)
- `rest` = `ACTIVITY_TYPE_REST` (1)
- `stretch` = `ACTIVITY_TYPE_STRETCH` (2)
- `sick` = `ACTIVITY_TYPE_ILL` (3)

### 1.2 HomeThemeSection view

**Файл**: `SwiftUI-SotkaApp/Screens/Home/HomeThemeSection.swift`

Компонент для отображения темы дня:

- Заголовок "Тема" (локализованный через `LocalizedStringKey`)
- `Image` для отображения изображения дня из Assets
  - Использовать статичные свойства Xcode: `Image(._\(day))` (например, `Image(._6)` для дня 6)
  - Изображения находятся в `Assets.xcassets/InfopostsImages/` в формате `{day}-1`
- При тапе по изображению - навигация к `InfopostDetailScreen` с инфопостом для текущего дня
- Использовать `.insideCardBackground()` для оформления карточки
- Скругленные углы для изображения через `.clipShape(RoundedRectangle(cornerRadius:))`
- Высота изображения ~200-250pt
- Aspect ratio: `.fill` или `.fit` в зависимости от дизайна

**Логика получения инфопоста**:

- Использовать `InfopostsService` для получения инфопоста по номеру дня
- Нужно добавить метод `func getInfopost(forDay: Int) -> Infopost?` в `InfopostsService`
- Метод должен искать в `availableInfoposts` инфопост с `dayNumber == forDay`

### 1.3 Обновление InfopostsService

**Файл**: `SwiftUI-SotkaApp/Services/Infoposts/InfopostsService.swift`

Добавить публичный метод:

```swift
func getInfopost(forDay day: Int) -> Infopost? {
    availableInfoposts.first { $0.dayNumber == day }
}
```

### 1.4 Локализация

**Файл**: `Localizable.xcstrings`

Добавить строки:

- "Theme" / "Тема" - заголовок секции
- Проверить наличие локализации для "WorkoutDay", "RestDay", "StretchDay", "SickDay" (должны быть уже в файле)

## 2. Секция "Активность" (заглушка)

### 2.1 HomeActivitySection view

**Файл**: `SwiftUI-SotkaApp/Screens/Home/HomeActivitySection.swift`

Компонент для выбора типа активности:

- Заголовок "Активность" (локализованный)
- Сетка из 4 круглых кнопок (использовать `LazyVGrid` с 2 колонками или `HStack` с 2 `VStack` для 2x2 расположения)
  - Тренировка (`DayActivityType.workout`)
  - Растяжка (`DayActivityType.stretch`)
  - Отдых (`DayActivityType.rest`)
  - Болезнь (`DayActivityType.sick`)
- Каждая кнопка:
  - Круглая форма через `.clipShape(Circle())`
  - Фон цвета из `DayActivityType.color`
  - SF Symbol иконка из `DayActivityType.iconName`
  - Название снизу через `DayActivityType.localizedTitle`
  - При нажатии - показывать alert "Функционал в разработке"
- Использовать `.insideCardBackground()` для оформления карточки
- Отключить кнопки в зависимости от дня (логика из `HomeTrainActionCell.m`):
  - День 1: отключить "Отдых" и "Болезнь" (opacity 0.5, disabled)
  - Дни 1-5: отключить "Растяжка" (opacity 0.5, disabled)

**Дизайн кнопок**:

- Круглые размером ~80x80pt
- Spacing между кнопками 16pt
- Label снизу с `.footnote` шрифтом
- Иконка в центре кнопки белого цвета

### 2.2 Локализация

Добавить строки:

- "Activity" / "Активность" - заголовок секции
- "Feature in development" / "Функционал в разработке" - текст alert

Локализация для типов активности уже есть через `LocalizedStringKey` в `DayActivityType`.

## 3. Секция "Прогресс" (заглушка)

### 3.1 HomeProgressSection view

**Файл**: `SwiftUI-SotkaApp/Screens/Home/HomeProgressSection.swift`

Компонент для перехода к прогрессу:

- Заголовок "Прогресс" (локализованный)
- Строка с текстом "Заполнить результаты" и chevron справа (ближе к старому приложению)
  - Использовать `HStack` с `Text` и `Image(systemName: "chevron.right")`
  - При тапе на строку - alert "Функционал в разработке"
- Использовать `.insideCardBackground()` для оформления карточки
- Padding внутри карточки для удобства тапа

**Альтернативный вариант** (если нужна кнопка):

- Кнопка "Заполнить результаты" (полная ширина)
- Стиль: основная кнопка из дизайн-системы

### 3.2 Локализация

Добавить строки:

- "Progress" / "Прогресс" - заголовок секции
- "Fill in results" / "Заполнить результаты" - текст строки/кнопки

## 4. Обновление HomeScreen

### 4.1 Файл: `SwiftUI-SotkaApp/Screens/Home/HomeScreen.swift`

Обновить структуру ScrollView в `body`:

```swift
ScrollView {
    VStack(spacing: 16) {
        // 1. Текущий день (уже есть)
        DayCountView(calculator: calculator)
        
        // 2. Тема дня (новое)
        HomeThemeSection(
            currentDay: calculator.currentDay,
            infopostsService: statusManager.infopostsService
        )
        
        // 3. Активность (новое)
        HomeActivitySection(currentDay: calculator.currentDay)
        
        // 4. Прогресс (новое)
        HomeProgressSection()
    }
    .padding()
}
```

### 4.2 Toolbar

**Оставить** существующую кнопку "Infoposts" в toolbar - она нужна для доступа к полному списку инфопостов.

## 5. Технические детали

### 5.1 Навигация к инфопосту

Использовать `NavigationLink` внутри `HomeThemeSection`:

```swift
if let infopost = infopostsService.getInfopost(forDay: currentDay) {
    NavigationLink {
        InfopostDetailScreen(infopost: infopost)
    } label: {
        Image(._\(currentDay))
            .resizable()
            .aspectRatio(contentMode: .fill)
            // ...
    }
}
```

### 5.2 Проверка доступности изображения

- Изображения есть для дней с инфопостами (1-100)
- Если для текущего дня нет инфопоста или изображения - не показывать секцию "Тема"
- Проверять через `infopostsService.getInfopost(forDay:) != nil`

### 5.3 Цвета для типов активности

В `DayActivityType` добавить:

```swift
var color: Color {
    switch self {
    case .workout: .blue
    case .rest: .green
    case .stretch: .purple
    case .sick: .red
    }
}
```

Использовать стандартные SwiftUI цвета, без создания градиентов.

### 5.4 SF Symbols для типов активности

В `DayActivityType` добавить:

```swift
var iconName: String {
    switch self {
    case .workout: "figure.strengthtraining.traditional"
    case .rest: "bed.double.fill"
    case .stretch: "figure.yoga"
    case .sick: "cross.case.fill"
    }
}
```

## 6. Порядок реализации

1. Обновить `DayActivityType` (добавить `color` и `iconName`)
2. Добавить метод `getInfopost(forDay:)` в `InfopostsService`
3. Создать `HomeThemeSection` view с изображением и навигацией
4. Создать `HomeActivitySection` view с заглушками
5. Создать `HomeProgressSection` view с заглушками
6. Обновить `HomeScreen` для использования всех секций
7. Добавить недостающие локализованные строки в `Localizable.xcstrings`
8. Протестировать навигацию к инфопостам
9. Запустить `make format` для форматирования кода

## 7. Замечания

- Использовать существующую модель `DayActivityType` вместо создания новой
- Использовать `Image` вместо `AsyncImage` для загрузки из Assets
- Использовать статичные свойства Xcode для доступа к изображениям (например, `Image(._6)`)
- Не создавать градиенты - использовать стандартные цвета SwiftUI
- Оставить кнопку "Infoposts" в toolbar
- Все новые view следуют правилам именования: computed properties с суффиксом `View`, функции с префиксом `make`
- Использовать модификатор `.insideCardBackground()` из дизайн-системы
- Все логи на русском языке через `OSLog`
- После реализации запустить `make format`

### To-dos

- [ ] Создать enum ActivityType с типами активности и свойствами (цвет, иконка, описание)
- [ ] Добавить метод getInfopost(forDay:) в InfopostsService
- [ ] Создать HomeThemeSection с изображением дня и навигацией к инфопосту
- [ ] Создать HomeActivitySection с 4 кнопками выбора активности (заглушки)
- [ ] Создать HomeProgressSection с кнопкой перехода к прогрессу (заглушка)
- [ ] Обновить HomeScreen для использования всех новых секций
- [ ] Добавить все необходимые локализованные строки в Localizable.xcstrings
- [ ] Протестировать навигацию и запустить make format для форматирования кода