# Анализ и план реализации вьюхи статистики прогресса

## Обзор

В старом iOS приложении (SOTKA-OBJc) и Android приложении сверху экрана прогресса отображается горизонтальная вьюха с визуализацией статистики пользователя. Это кастомный прогресс-бар с несколькими цветами, отображающий активность, инфопосты и полный прогресс в процентах.

## Анализ существующих реализаций

### Старое iOS приложение (SOTKA-OBJc)

#### Структура файлов:
- **ProgressController.m** - основной контроллер, отображает ProgressBarCell в секции 0
- **ProgressBarCell.h/m/xib** - ячейка таблицы с вьюхой статистики
- **ProgressBarView.h/m/xib** - кастомный вью с горизонтальными полосками

#### Визуальное отображение:
- ProgressBarView - горизонтальный контейнер с 100 полосками (по одной на каждый день)
- Высота 25pt, скругленные углы
- 3 лейбла снизу: "Инфопосты:", "Активность:", "Полный прогресс:" с соответствующими процентами

#### Логика и цвета:
```objective-c
// Цвета из ProgressBarView.m
UIColor* currentDayColor = [UIColor colorWithRed:45/255.0 green:123/255.0 blue:245/255.0 alpha:1.0];      // Синий
UIColor* notFilledDayColor = [UIColor colorWithRed:255/255.0 green:50/255.0 blue:50/255.0 alpha:1.0];     // Красный
UIColor* halfPassedDayColor = [UIColor colorWithRed:255/255.0 green:223/255.0 blue:0/255.0 alpha:1.0];    // Желтый
UIColor* passedDayColor = [UIColor colorWithRed:40/255.0 green:190/255.0 blue:150/255.0 alpha:1.0];       // Зеленый
```

#### Логика расчета прогресса:
1. **Полный прогресс**: дни, где есть тренировка И прочитан инфопост
2. **Инфопосты**: дни, где прочитан инфопост (независимо от тренировки)
3. **Активность**: дни, где есть любая активность (тренировка, отдых, растяжка, болезнь)

### Android приложение

#### Структура файлов:
- **ProgressFragment.kt** - основной фрагмент с логикой
- **fragment_progress.xml** - layout с horizontalProgress LinearLayout
- **colors.xml** - цвета для прогресс-бара

#### Визуальное отображение:
- horizontalProgress - LinearLayout с 100 TextView (по одному на день)
- Высота 36dp, в CardView с скругленными углами
- 3 лейбла снизу: "Полный прогресс:", "Инфопосты:", "Активность:"

#### Логика и цвета:
```kotlin
// Цвета из colors.xml
progress_color_default = #CCCCCC      // Серый (по умолчанию)
progress_color_full_activity = #00C308 // Зеленый (тренировка + инфопост)
progress_color_one_activity = #FFE225  // Желтый (только тренировка или инфопост)
progress_color_no_activity = #d94d4d   // Красный (не пройден)
progress_color_current_day = #0a5fb8   // Синий (текущий день)
```

#### Логика расчета прогресса:
Аналогична старому iOS приложению:
1. **Full progress**: дни с активностью И прочитанным инфопостом
2. **Infoposts**: дни с прочитанным инфопостом
3. **Activities**: дни с любой активностью (training, rest, stretching, sick)

## Сравнение реализаций

| Аспект | Старое iOS | Android | Примечание |
|--------|------------|---------|-------------|
| Контейнер | ProgressBarView (custom) | LinearLayout | |
| Элементы дня | UIView в UIStackView | TextView | |
| Количество элементов | 100 фиксировано | 100 динамически | |
| Высота | 25pt | 36dp | |
| Цвета | RGB значения | Color resources | |
| Позиция | В таблице (секция 0) | В ScrollView | |
| Лейблы | 3 строки с процентами | 3 строки с процентами | |

## План реализации для нового приложения

### 1. Создание компонентов

#### ProgressStatsView
- Основная вьюха для отображения статистики
- Свойства: currentDay, progressItems, readInfoPosts
- Вычисляемые свойства для процентов

#### ProgressBarView
- Горизонтальный прогресс-бар с 100 сегментами
- Цвета согласно логике (синий, зеленый, желтый, красный, серый)
- Анимации переходов

#### ProgressStatsLabelsView
- 3 лейбла с процентами
- Локализованные строки
- Форматирование текста

### 2. Логика расчета прогресса

#### ProgressCalculator
- `calculateFullProgress()` - дни с тренировкой + инфопост
- `calculateInfoPostsProgress()` - дни с прочитанным инфопостом
- `calculateActivityProgress()` - дни с любой активностью
- `getDayColor(day: Int)` - определение цвета для каждого дня

### 3. Интеграция с данными

#### Источники данных:
- `UserProgress` - информация о тренировках
- `StatusManager` - текущий день программы
- `InfoPostManager` - прочитанные инфопосты

#### SwiftData модели:
```swift
@Model
final class UserProgress {
    var day: Int
    var activityType: ActivityType?
    var isSynced: Bool
    // ... другие поля
}

@Model
final class ReadInfoPost {
    var day: Int
    var readDate: Date
    var isSynced: Bool
}
```

### 4. Цвета и дизайн

#### Color extension:
```swift
extension Color {
    static let progressCurrentDay = Color.blue
    static let progressFullActivity = Color.green
    static let progressPartialActivity = Color.yellow
    static let progressNoActivity = Color.red
    static let progressDefault = Color.gray
}
```

### 5. Интеграция в ProgressScreen

#### Структура экрана:
```
ProgressScreen
├── ProgressStatsView (новая)
│   ├── ProgressBarView
│   └── ProgressStatsLabelsView
└── ProgressGridView (существующая)
```

### 6. ViewModel для статистики

#### ProgressStatsViewModel:
```swift
@Observable
final class ProgressStatsViewModel {
    private let progressService: ProgressService
    private let infoPostService: InfoPostService

    var fullProgressPercent: Int = 0
    var infoPostsPercent: Int = 0
    var activityPercent: Int = 0
    var dayColors: [Color] = []

    func updateStats() {
        // Логика расчета
    }
}
```

### 7. Локализация

#### Ключи для строк:
- `progressFullProgressTitle`
- `progressInfoPostsTitle`
- `progressActivityTitle`

### 8. Анимации и UX

#### Анимации:
- Появление статистики при загрузке экрана
- Плавные переходы цветов при изменении данных
- Пульсация текущего дня

#### Accessibility:
- VoiceOver описание прогресса
- Семантические цвета
- Доступные размеры текста

## Технические требования

### Производительность:
- Ленивая загрузка цветов
- Эффективные вычисления процентов
- Кэширование результатов

### Тестирование:
- Unit тесты для ProgressCalculator
- UI тесты для корректного отображения
- Тесты для всех комбинаций статусов дней

### Офлайн-приоритет:
- Все расчеты на основе локальных данных SwiftData
- Синхронизация не влияет на отображение статистики
- Флаги синхронизации для инфопостов и прогресса

## Следующие шаги

1. **Создать ProgressStatsView** - основную вьюху
2. **Реализовать ProgressCalculator** - логику расчета
3. **Добавить модели SwiftData** - ReadInfoPost
4. **Интегрировать в ProgressScreen** - подключить к существующему экрану
5. **Добавить анимации** - улучшить UX
6. **Протестировать** - покрыть тестами

## Примечания

- Логика полностью идентична в обоих приложениях
- Android использует более современный подход с ConstraintLayout
- Цвета и логика расчета должны быть сохранены для консистентности
- Необходима интеграция с существующими сервисами приложения
