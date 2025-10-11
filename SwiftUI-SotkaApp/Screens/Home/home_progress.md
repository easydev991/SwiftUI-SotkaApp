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

### Структура данных

```swift
// Progress.swift
@Model
final class Progress {
    /// Совпадает с номером дня
    var id: Int
    var pullUps: Int?
    var pushUps: Int?
    var squats: Int?
    var weight: Float?
    var isSynced: Bool = false
    var lastModified = Date.now
    
    var isFilled: Bool {
        let values = [pullUps, pushUps, squats, weight].compactMap { $0 }
        return values.count == 4 && values.allSatisfy { $0 > 0 }
    }
}

// User.swift - добавление связи с прогрессом
@Model
final class User {
    // ... существующие свойства ...
    
    /// Результаты прогресса пользователя
    @Relationship(deleteRule: .cascade) var progressResults: [Progress] = []
    
    // ... остальные свойства ...
}
```

### Логика отображения

```swift
// User.swift - добавление вычисляемых свойств для прогресса
extension User {
    /// Проверяет, заполнены ли результаты для текущего дня
    func isMaximumsFilled(for currentDay: Int) -> Bool {
        let progressDay: Int
        if currentDay >= 1 && currentDay <= 49 {
            progressDay = 1  // БАЗОВЫЙ блок
        } else if currentDay >= 50 && currentDay <= 99 {
            progressDay = 50 // ПРОДВИНУТЫЙ блок
        } else if currentDay >= 100 {
            progressDay = 100 // Заключение
        } else {
            return true
        }
        
        // Проверяем, есть ли заполненные результаты для соответствующего дня
        return progressResults.contains { $0.id == progressDay && $0.isFilled }
    }
}

// HomeScreen.swift - добавить получение текущего пользователя
import SwiftData

struct HomeScreen: View {
    @Environment(StatusManager.self) private var statusManager
    @Query private var users: [User]
    private var user: User? { users.first }
    
    var body: some View {
        NavigationStack {
            @Bindable var statusManager = statusManager
            ZStack {
                Color.swBackground.ignoresSafeArea()
                if let calculator = statusManager.currentDayCalculator, let user {
                    ScrollView {
                        VStack(spacing: 12) {
                            HomeDayCountView(calculator: calculator)
                            makeInfopostView(with: calculator)
                            HomeActivitySectionView()
                            makeFillProgressView(with: calculator, user: user)
                        }
                        .padding([.horizontal, .bottom])
                    }
                } else {
                    Text("Loading")
                }
            }
            // ... остальной код
        }
    }
}

private extension HomeScreen {
    func makeFillProgressView(with calculator: DayCalculator, user: User) -> some View {
        HomeFillProgressSectionView(
            currentDay: calculator.currentDay,
            user: user
        )
    }
}

// HomeFillProgressSectionView.swift - доработка существующего компонента
struct HomeFillProgressSectionView: View {
    let model: Model
    
    init(currentDay: Int, user: User) {
        self.model = .init(currentDay: currentDay, user: user)
    }
    
    var body: some View {
        if model.shouldShowFillProgress {
            HomeSectionView(title: NSLocalizedString("Home.Progress", comment: "Прогресс")) {
                NavigationLink {
                    // TODO: Экран заполнения результатов
                    EmptyView()
                } label: {
                    HStack {
                        Text(model.localizedTitle)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        ChevronView()
                    }
                    .padding([.horizontal, .bottom], 12)
                }
            }
        }
    }
}

extension HomeFillProgressSectionView {
    struct Model {
        let shouldShowFillProgress: Bool
        let localizedTitle = NSLocalizedString("Home.FillResults", comment: "Заполнить результаты")
        
        init(currentDay: Int, user: User) {
            self.shouldShowFillProgress = !user.isMaximumsFilled(for: currentDay)
        }
    }
}
```

Этот анализ показывает, что старое iOS приложение имеет более гибкую логику с диапазонами дней, которая помогает пользователю не забыть внести прогресс. Этот подход следует использовать в качестве основы для нового приложения.

## План тестирования

Для тестирования новой логики заполнения прогресса необходимо создать unit-тесты, следуя правилам из `@SwiftUI-SotkaApp/unit-testing-ios-app.mdc`.

### Тесты для модели Progress

**Файл**: `HomeFillProgressTests.swift`

1. **Тест `isFilled` с полными данными**
   - Создать Progress с pullUps=10, pushUps=20, squats=30, weight=70.0
   - Проверить `#expect(progress.isFilled)`

2. **Тест `isFilled` с неполными данными**
   - Создать Progress с pullUps=10, pushUps=nil, squats=30, weight=70.0
   - Проверить `#expect(!progress.isFilled)`

3. **Тест `isFilled` с нулевыми значениями**
   - Создать Progress с pullUps=0, pushUps=20, squats=30, weight=70.0
   - Проверить `#expect(!progress.isFilled)`

4. **Параметризированный тест для разных комбинаций**
   - Тестировать различные комбинации nil/0/положительных значений
   - Использовать `@Test(arguments:)` для массива тестовых данных

### Тесты для User extension

**Файл**: `UserTests.swift` (добавить через extension)

1. **Тест `isMaximumsFilled` для дня 1-49**
   - Создать User с progressResults для дня 1 (заполненными)
   - Проверить `#expect(user.isMaximumsFilled(for: 25))`

2. **Тест `isMaximumsFilled` для дня 50-99**
   - Создать User с progressResults для дня 50 (заполненными)
   - Проверить `#expect(user.isMaximumsFilled(for: 75))`

3. **Тест `isMaximumsFilled` для дня 100+**
   - Создать User с progressResults для дня 100 (заполненными)
   - Проверить `#expect(user.isMaximumsFilled(for: 105))`

4. **Тест `isMaximumsFilled` без данных**
   - Создать User без progressResults
   - Проверить `#expect(!user.isMaximumsFilled(for: 25))`

5. **Параметризированный тест для граничных дней**
   - Тестировать дни 1, 49, 50, 99, 100 с разными состояниями данных

### Тесты для HomeFillProgressSectionView.Model

**Файл**: `HomeFillProgressSectionViewModelTests.swift`

**Структура тестов**:
```swift
private typealias Model = HomeFillProgressSectionView.Model
```

1. **Тест `shouldShowFillProgress` когда нужно показать**
   - Создать User без заполненных результатов для текущего дня
   - Проверить `#expect(model.shouldShowFillProgress)`

2. **Тест `shouldShowFillProgress` когда не нужно показывать**
   - Создать User с заполненными результатами для текущего дня
   - Проверить `#expect(!model.shouldShowFillProgress)`

3. **Тест `localizedTitle`**
   - Проверить что `model.localizedTitle` возвращает правильную локализованную строку

4. **Параметризированный тест для разных дней**
   - Тестировать создание модели для дней 1, 25, 49, 50, 75, 99, 100, 105
   - Проверять корректность `shouldShowFillProgress` для каждого случая

### Принципы тестирования

- **Использовать Swift Testing** (`import Testing`)
- **Разворачивать опционалы** с `try #require()`
- **Проверять Bool условия** напрямую: `#expect(condition)` вместо `#expect(condition == true)`
- **Использовать параметризированные тесты** для множественных сценариев
- **Добавлять комментарии в `#expect`** только для сложной логики
- **Тестировать бизнес-логику**, не UI компоненты

## Регистрация модели в SwiftData

Новую модель `Progress` нужно зарегистрировать в SwiftData в файле `SwiftUI_SotkaAppApp.swift`:

### 1. Добавить в Schema
```swift
let schema = Schema([User.self, Country.self, CustomExercise.self, Progress.self])
```

### 2. Добавить очистку при логауте
```swift
.onChange(of: authHelper.isAuthorized) { _, isAuthorized in
    appSettings.setWorkoutNotificationsEnabled(isAuthorized)
    if !isAuthorized {
        appSettings.didLogout()
        statusManager.didLogout()
        do {
            try modelContainer.mainContext.delete(model: User.self)
            try modelContainer.mainContext.delete(model: CustomExercise.self)
            try modelContainer.mainContext.delete(model: Progress.self)  // Добавить эту строку
        } catch {
            fatalError("Не удалось удалить данные пользователя: \(error.localizedDescription)")
        }
    }
}
```

Это обеспечит корректную работу с данными прогресса в SwiftData и их очистку при выходе пользователя из системы.
