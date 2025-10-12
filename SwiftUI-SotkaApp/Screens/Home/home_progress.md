# Анализ функционала заполнения результатов прогресса на главном экране

## Обзор

Функционал заполнения результатов прогресса позволяет пользователям вносить свои показатели (подтягивания, отжимания, приседания, вес) в ключевые моменты программы тренировок. Анализ показывает различия в реализации между Android и старым iOS приложениями.

### Структура программы тренировок

Программа "100 дней" состоит из следующих блоков:
- **БАЗОВЫЙ блок**: дни 1-49
- **ПРОДВИНУТЫЙ блок**: дни 50-91  
- **ТУРБО-блок**: дни 92-98
- **Заключение**: дни 99-100

Контрольные точки для заполнения результатов:
- День 1 (начало БАЗОВОГО блока)
- День 50 (начало ПРОДВИНУТОГО блока) 
- День 92 (начало ТУРБО-блока)
- День 100 (завершение программы)

## Android приложение (Android-SOTKA)

### Структура элемента

```xml
<!-- "Fill results" button if current day is 49 or 100 -->
<RelativeLayout
    android:id="@+id/fillTrainingResults"
    android:layout_width="match_parent"
    android:layout_height="wrap_content"
    android:background="?android:attr/selectableItemBackground"
    android:clickable="true"
    android:focusable="true"
    android:minHeight="@dimen/recycler_item_min_height"
    android:paddingLeft="8dp"
    android:paddingRight="8dp"
    android:visibility="gone"
    tools:visibility="visible">

    <ImageView
        android:id="@+id/iconGoToFillTrainingResults"
        android:layout_width="wrap_content"
        android:layout_height="wrap_content"
        android:layout_alignParentEnd="true"
        android:layout_centerVertical="true"
        android:scaleType="center"
        android:src="@drawable/ic_keyboard_arrow_right_grey_400_18dp" />

    <TextView
        android:id="@+id/fillTrainingResultsText"
        style="@style/RobotoLight"
        android:layout_width="match_parent"
        android:layout_height="wrap_content"
        android:layout_centerVertical="true"
        android:layout_marginTop="4dp"
        android:layout_marginBottom="4dp"
        android:layout_toStartOf="@+id/iconGoToFillTrainingResults"
        android:text="@string/fragmentHomeFillResultsBase"
        android:textColor="?attr/softTextColor"
        android:textSize="14sp" />
</RelativeLayout>
```

### Логика отображения

#### Условия показа
```kotlin
// HomePresenterImpl.kt - setupTrainingDay()
view.setFillResultsContainerVisible(
    (dayNumber == DAY_PROGRESS_NUMBER_2 && !preferences.isResultEnteredFor49Day) ||
    (dayNumber == DAY_PROGRESS_NUMBER_3 && !preferences.isResultEnteredFor100Day), 
    dayNumber
)
```

#### Константы
```kotlin
const val DAY_PROGRESS_NUMBER_2 = 49  // 49-й день - базовый блок
const val DAY_PROGRESS_NUMBER_3 = 100 // 100-й день - полное прохождение
```

#### Установка текста
```kotlin
// HomeFragment.kt - setFillResultsContainerVisible()
override fun setFillResultsContainerVisible(visible: Boolean, dayNumber: Int) {
    if (dayNumber == DAY_PROGRESS_NUMBER_2) {
        fillTrainingResultsText.text = resources.getString(R.string.fragmentHomeFillResultsBase)
    } else if (dayNumber == DAY_PROGRESS_NUMBER_3) {
        fillTrainingResultsText.text = resources.getString(R.string.fragmentHomeFillResultsFull)
    }
    
    fillTrainingResults?.visibility = if (visible) View.VISIBLE else View.GONE
}
```

### Строковые ресурсы

```xml
<!-- values/strings.xml -->
<string name="fragmentHomeFillResultsBase">Enter results for BASIC block</string>
<string name="fragmentHomeFillResultsFull">Enter results for your walkthrough</string>

<!-- values-ru/strings.xml -->
<string name="fragmentHomeFillResultsBase">Внести результаты БАЗОВОГО блока</string>
<string name="fragmentHomeFillResultsFull">Внести результаты прохождения программы</string>
```

### Логика клика

```kotlin
// HomePresenterImpl.kt
override fun fillResultsClicked() {
    val dayNumber = view.getDayNumber()
    dayNumber ?: return; if (dayNumber == 0) return

    val progressNumber = when (dayNumber) {
        49 -> 2
        100 -> 3
        else -> 1
    }

    router.openFillProgress(progressNumber)
    updateResultEntering(dayNumber)
}
```

### Навигация

```kotlin
// HomeRouterImpl.kt
override fun openFillProgress(progressNumber: Int) {
    startView(
        viewClass = LastStepPreparingActivity::class,
        params = LastStepPreparingActivity.getBundle(
            screenType = LastStepPreparingActivityScreensType.CHANGE_PARAMETERS,
            progressNumber = progressNumber
        )
    )
}
```

### Управление состоянием

#### Preferences
```kotlin
// PreferencesProvider.kt
var isResultEnteredFor49Day: Boolean
var isResultEnteredFor100Day: Boolean
```

#### Установка флагов после сохранения
```kotlin
// ChangeParametersPresenterImpl.kt и ProgressPresenterImpl.kt
if (progress.hasProgress()) {
    when (progressNumber) {
        2 -> preferences.isResultEnteredFor49Day = true
        3 -> preferences.isResultEnteredFor100Day = true
    }
}
```

#### Сброс флагов при сбросе программы
```kotlin
// PreferencesProviderImpl.kt
isResultEnteredFor49Day = false
isResultEnteredFor100Day = false
```

### Модель Progress

```kotlin
// Progress.kt
data class Progress(
    val number: Int,
    var pullUps: Int? = null,
    var pushUps: Int? = null,
    var squats: Int? = null,
    var weight: Float? = null,
    var synced: Boolean = true
) {
    fun hasProgress(): Boolean = 
        pullUps != null && pullUps != -1 && 
        pushUps != null && pushUps != -1 && 
        squats != null && squats != -1 && 
        weight != null && weight != -1f
}
```

## Старое iOS приложение (SOTKA-OBJc)

### Структура секции

```objc
// HomeController.m
typedef enum {
    SECTION_LOGIN_TRAIN,
    SECTION_CURRENT_PROGRESS,
    SECTION_SUBJECT,
    SECTION_WARNING,
    SECTION_EXERCISES,
    SECTION_FILL_PROGRESS,  // Секция для заполнения результатов
    SECTION_FILL_CITY,
    SECTION_COUNT
} HomeSection;
```

### Логика отображения

#### Условия показа секции
```objc
// HomeController.m - numberOfRowsInSection
if (section == SECTION_FILL_PROGRESS) {
    if ([self isProgressFillHidden]) {
        return 0;
    }
    return 2; // Заголовок + ячейка с кнопкой
}
```

#### Проверка скрытия
```objc
// HomeController.m - isProgressFillHidden
- (BOOL) isProgressFillHidden {
    if ([[WorkOutBrain instance] isMaximumsFilled]) {
        return YES;
    }
    return NO;
}
```

#### Логика заполнения результатов
```objc
// WorkOutBrain.m - isMaximumsFilled
- (BOOL) isMaximumsFilled {
    NSInteger currentDay = self.currentDay;
    if ((currentDay >= 1) && (currentDay <= 49)) {
        DbUser* user = [DbUser fetchForDay:1];
        if ((user == nil) || [user isEmpty]) {
            return NO;
        }
    }
    else if ((currentDay >= 50) && (currentDay <= 99)) {
        DbUser* user = [DbUser fetchForDay:50];
        if ((user == nil) || [user isEmpty]) {
            return NO;
        }
    }
    else if (currentDay >= 100 && ([WorkOutBrain instance].additionalDatesCount == 0)) {
        DbUser* user = [DbUser fetchForDay:100];
        if ((user == nil) || [user isEmpty]) {
            return NO;
        }
    }
    return YES;
}
```

### Ячейка HomeFillResultsCell

```objc
// HomeFillResultsCell.m - configureForDay
- (void) configureForDay:(NSInteger)day {
    DbUser* user = [DbUser fetchForDay:day];
    if ((user == nil) || [user isEmpty]) {
        self.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        self.userInteractionEnabled = YES;
    }
    else {
        self.accessoryType = UITableViewCellAccessoryCheckmark;
        self.userInteractionEnabled = NO;
        self.tintColor = [UIColor colorWithRed:0 green:190/255.0 blue:0 alpha:1.0];
    }
}
```

### Логика клика

```objc
// HomeController.m - didSelectRowAtIndexPath
if ((indexPath.section == SECTION_FILL_PROGRESS) && (indexPath.row == 1)) {
    [self fillResults];
}
```

```objc
// HomeController.m - fillResults
- (void) fillResults {
    // Показать вкладку прогресса
    self.tabBarController.selectedIndex = 3;
}
```

### Модель DbUser

```objc
// DbUser+Extension.m - isEmpty
- (BOOL) isEmpty {
    if ((self.pullups == nil) || (self.pushups == nil) || (self.squats == nil) ||
        (self.weight == nil)) {
        return YES;
    }
    return NO;
}
```

## Сравнительный анализ

### Сходства

1. **Концепция**: Оба приложения показывают кнопку для заполнения результатов в ключевые моменты программы
2. **Данные**: Оба сохраняют одинаковые показатели (подтягивания, отжимания, приседания, вес)
3. **Состояние**: Оба отслеживают, заполнены ли результаты, чтобы скрыть кнопку после заполнения

### Различия

#### Android приложение
- **Точные дни**: Показывает кнопку только на 49-й и 100-й день
- **Отдельные флаги**: Использует `isResultEnteredFor49Day` и `isResultEnteredFor100Day`
- **Навигация**: Открывает отдельный экран `ChangeParametersFragment`
- **Тексты**: Разные тексты для 49-го и 100-го дня
- **Ограниченность**: Пользователь может забыть внести прогресс, если пропустит точные дни

#### Старое iOS приложение
- **Диапазоны дней**: Показывает кнопку в зависимости от текущего дня:
  - Дни 1-49: проверяет результаты дня 1
  - Дни 50-99: проверяет результаты дня 50
  - День 100+: проверяет результаты дня 100
- **Единая логика**: Использует одну функцию `isMaximumsFilled()`
- **Единый текст**: Использует один текст "Заполни результаты" для всех этапов
- **Навигация**: Переключается на вкладку прогресса (tabBarController.selectedIndex = 3)
- **Визуальная обратная связь**: Показывает галочку после заполнения
- **Гибкость**: Пользователь может внести прогресс в любое время в рамках соответствующего диапазона

### Рекомендации для нового приложения

1. **Использовать подход старого iOS приложения**: Более гибкая логика с диапазонами дней для лучшего UX
2. **Добавить визуальную обратную связь**: Показывать галочку после заполнения
3. **Единый текст**: Использовать единый локализованный текст "Home.FillResults" для всех этапов
4. **Отдельный экран**: Создать отдельный экран для заполнения результатов
5. **Единая логика проверки**: Использовать одну функцию для проверки заполненности результатов

## Реализация в новом приложении

### ✅ Реализованные компоненты

1. **Модель Progress** - создана в `Models/Progress.swift` с полями для хранения результатов прогресса и методом `isFilled`
2. **Связь с User** - добавлена в `Models/User.swift` через `@Relationship(deleteRule: .cascade) var progressResults: [Progress]`
3. **Логика проверки** - реализована в `User.isMaximumsFilled(for:)` для определения необходимости показа кнопки
4. **UI компонент** - создан `HomeFillProgressSectionView` с логикой отображения
5. **Интеграция в HomeScreen** - добавлен вызов `makeFillProgressView` в главном экране
6. **Регистрация в SwiftData** - модель `Progress` добавлена в Schema и настроена очистка при логауте

### ❌ Не реализовано

1. **Экран заполнения результатов** - в `HomeFillProgressSectionView` показывается `EmptyView()` вместо реального экрана
2. **Навигация к экрану** - NavigationLink ведет к заглушке

Этот анализ показывает, что старое iOS приложение имеет более гибкую логику с диапазонами дней, которая помогает пользователю не забыть внести прогресс. Этот подход следует использовать в качестве основы для нового приложения.

## План тестирования

### ✅ Реализованные тесты

1. **Тесты для модели Progress** - созданы в `ProgressTests.swift`:
   - Тест `isFilled` с полными данными
   - Тест `isFilled` с неполными данными  
   - Тест `isFilled` с нулевыми значениями
   - Тест `isFilled` с отрицательными значениями
   - Параметризированный тест для разных комбинаций

2. **Тесты для User.isMaximumsFilled** - добавлены в `UserTests.swift`:
   - Тесты для дней 1-49, 50-99, 100+ с заполненными результатами
   - Тест без данных
   - Тест с незаполненными результатами
   - Параметризированный тест для граничных дней

3. **Тесты для HomeFillProgressSectionView.Model** - созданы в `HomeFillProgressSectionViewModelTests.swift`:
   - Тест `shouldShowFillProgress` когда нужно показать
   - Тест `shouldShowFillProgress` когда не нужно показывать
   - Параметризированные тесты для разных дней и блоков программы

### ✅ Принципы тестирования соблюдены

- Используется Swift Testing (`import Testing`)
- Bool условия проверяются напрямую: `#expect(condition)`
- Применяются параметризированные тесты для множественных сценариев
- Тестируется бизнес-логика, не UI компоненты

## Регистрация модели в SwiftData

### ✅ Реализовано

1. **Добавлена в Schema** - модель `Progress` зарегистрирована в `SwiftUI_SotkaAppApp.swift`
2. **Настроена очистка при логауте** - благодаря `@Relationship(deleteRule: .cascade)` модель `Progress` автоматически удаляется при удалении `User`

Это обеспечивает корректную работу с данными прогресса в SwiftData и их очистку при выходе пользователя из системы.

## Оставшиеся задачи

### 1. Создать экран заполнения результатов

Необходимо создать полноценный экран для ввода результатов прогресса, который будет открываться при нажатии на кнопку в `HomeFillProgressSectionView`. Экран должен:

- Позволять вводить подтягивания, отжимания, приседания и вес
- Валидировать введенные данные
- Сохранять результаты в SwiftData
- Показывать соответствующий день прогресса (1, 50 или 100) в зависимости от текущего дня

### 2. Обновить навигацию

Заменить `EmptyView()` в `HomeFillProgressSectionView` на реальный экран заполнения результатов.

### 3. Добавить визуальную обратную связь

После заполнения результатов показывать галочку или другой индикатор в `HomeFillProgressSectionView`, чтобы пользователь видел, что прогресс внесен.
