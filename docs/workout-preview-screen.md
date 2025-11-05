# Экран превью тренировки (Workout Preview Screen)

## Обзор

Этот документ описывает анализ экрана "Тренировка" из Android-SOTKA и SOTKA-OBJc, а также план реализации аналогичного экрана для нового приложения SwiftUI-SotkaApp.

**Важно**: Данный документ описывает только функционал экрана превью тренировки с кнопкой "Сохранить как пройденную". Другие экраны тренировок (выполнение, таймер, редактор) будут описаны в отдельных документах.

## Анализ существующих реализаций

### Android-SOTKA: TrainingsPreviewFragment

#### Расположение
- **Файл**: `app/src/main/java/com/fgu/workout100days/screens/activity_edit_training/fragment_trainings_preview/TrainingsPreviewFragment.kt`
- **Presenter**: `TrainingsPreviewPresenterImpl.kt`
- **Layout**: `fragment_trainings_preview.xml`

#### Основные компоненты

1. **Заголовок экрана**
   - Заголовок: "Тренировка" (строка `common_workout`)
   - Toolbar с кнопкой "Назад" и меню (иконка настроек)

2. **Сегментированный контрол выбора типа выполнения** (в верхней части экрана)
   - Показывается только для дней > 49 и не пройденных
   - Для дней 50-91: показываются только "Круги" и "Подходы" (без "Турбо")
   - Для дней 92-98: показываются все три опции - "Круги", "Подходы" и "Турбо"
   - Для дней 1-49: не показывается
   - Для дней 99-100: не показывается

3. **Список упражнений**
   - RecyclerView с упражнениями дня
   - Отображение кругов/подходов
   - Возможность изменения количества повторений (увеличение/уменьшение)
   - Набор упражнений зависит от:
     - Номера дня
     - Блока программы (Базовый 1-49, Продвинутый 50-91, Турбо 92-98, Заключение 99-100)
     - Типа выполнения (Круги/Подходы/Турбо)

4. **Кнопки управления (внизу экрана)**

   **Режим 1: День не пройден** (`layoutButtonsTrainingNotPassed`)
   - Кнопка "Начать тренировку" (`buttonStartTraining`) - синяя
   - Кнопка "Сохранить как пройденную" (`buttonJustSaveTraining`) - зеленая

   **Режим 2: День пройден** (`layoutButtonsTrainingPassed`)
   - Кнопка "Комментарий" (`buttonCommentTrainingPassed`) - зеленая
   - Кнопка "Сохранить" (`buttonSaveTrainingPassed`) - синяя
   - Кнопка "Продолжить" (`buttonContinueTraining`) - зеленая (показывается только если тренировка была начата, но не завершена)

4. **Реклама другого приложения**
   - Блок с рекламой "Продвинутый дневник тренировок" (`trexerButtonCardView`)
   - **Примечание**: В новом приложении реализовывать не нужно

#### Логика сохранения тренировки

**Метод**: `saveTraining(dayNumber: Int)` в `TrainingsPreviewPresenterImpl.kt`

```kotlin
override fun saveTraining(dayNumber: Int) {
    interactor.getDayByNumber(dayNumber)
        .subscribeOn(Schedulers.io())
        .observeOn(AndroidSchedulers.mainThread())
        .subscribeBy(
            onNext = { day ->
                // Устанавливаем actualCircles
                day.actualCircles = if (!day.passed) getPlannedCircles(day) else {
                    if (day.actualCircles > 0) day.actualCircles else day.provideCircles()
                }
                // Помечаем день как пройденный
                day.passed = true
                // Сохраняем в базу данных с синхронизацией
                interactor.updateDayInDatabase(day, true)
                    .subscribeOn(Schedulers.io())
                    .observeOn(AndroidSchedulers.mainThread())
                    .subscribeBy(onComplete = {
                        router.back() // Возвращаемся назад
                    }, onError = { ... })
            },
            onError = { ... }
        )
}
```

**Логика**:
1. Получает день по номеру из базы данных
2. Устанавливает `actualCircles`:
   - Если день не пройден: берет `plannedCircles` (или вычисляет через `getPlannedCircles()`)
   - Если день пройден: сохраняет существующий `actualCircles` или вычисляет через `provideCircles()`
3. Устанавливает `day.passed = true`
4. Сохраняет в базу данных с флагом синхронизации (`true`)
5. Возвращается назад (закрывает экран)

**Примечания**:
- Обе кнопки ("Сохранить как пройденную" и "Сохранить") вызывают один и тот же метод `saveTraining()`
- Метод работает одинаково для пройденных и не пройденных дней

### SOTKA-OBJc: TrainingController

#### Расположение
- **Файл**: `WorkOut100Days/Controllers/Training/TrainingController.m`
- **Storyboard**: `Training.storyboard`

#### Основные компоненты

1. **Заголовок экрана**
   - Навигационный заголовок: "Тренировка"
   - Кнопка редактирования (правый верхний угол)

2. **Список упражнений**
   - UITableView с упражнениями дня
   - Отображение кругов/подходов
   - Возможность редактирования (в режиме редактирования)

3. **Кнопки управления (внизу экрана)**

   **Режим создания новой тренировки** (`createMode == YES`):
   - Кнопка "Начать тренировку" (`buttonView`)
   - StackView с текстом "Уже прошёл тренировку?" (`alreadyStackView`) - обычно скрыт
   - Кнопка "Сохранить" (внутри `buttonView`)

   **Режим просмотра существующей тренировки** (`createMode == NO`):
   - Метод `hideAllButtonsExceptSaveButton` скрывает `alreadyStackView`
   - Кнопка "Сохранить" доступна для пересохранения

#### Логика сохранения тренировки

**Метод**: `save:(id)sender` в `TrainingController.m`

**Примечание**: Реализация метода в коде закомментирована, но логика видна из комментариев:

1. Создает или обновляет `DbDay` объект
2. Устанавливает:
   - `day.day = self.currentDay`
   - `day.cycleCount = self.numberOfCycles`
   - `day.trainType = self.cycleSegment.selectedSegmentIndex`
   - `day.executeType = executeType`
   - `day.comment = commentString`
   - `day.synched = NO`
   - `day.modifyDate = [NSDate date]`
3. Удаляет существующие тренировки и добавляет новые из массива `exercises`
4. Сохраняет в Core Data
5. Обновляет данные на Apple Watch (если применимо)

**Особенности**:
- В методе `hideAllButtonsExceptSaveButton` скрывается `alreadyStackView` (текст "Уже прошёл тренировку?")
- В старом приложении этот экран используется как для создания, так и для просмотра/редактирования тренировки

## План реализации для SwiftUI-SotkaApp

### Текущий статус реализации

**Основной функционал**: ✅ Реализован
- ✅ Модели данных, сервис `WorkoutProgramCreator`, ViewModel, UI компоненты
- ✅ Интеграция с `JournalScreen` и `HomeActivitySectionView`
- ✅ Базовые тесты для всех компонентов
- ✅ Степперы для изменения количества повторений и кругов/подходов
- ✅ Сохранение пользовательских изменений при смене типа выполнения

### Архитектура экрана ✅

**Компоненты**: `WorkoutPreviewScreen`, `WorkoutPreviewViewModel`, `WorkoutPreviewExecutionTypePicker`, `WorkoutPreviewButtonsView`, `TrainingRowView`

**Структура файлов**:
- `WorkoutPreviewScreen.swift` - основной экран с навигацией и композицией компонентов
- `WorkoutPreviewViewModel.swift` - бизнес-логика и состояние
- `Views/WorkoutPreviewExecutionTypePicker.swift` - сегментированный контрол выбора типа выполнения
- `Views/WorkoutPreviewButtonsView.swift` - кнопки управления (сохранить, комментарий и т.д.)
- `Views/TrainingRowView.swift` - строка упражнения в списке

**Точки входа**: `JournalScreen`, `HomeActivitySectionView` (через меню "Изменить" → "Тренировка")

### Логика работы с типами выполнения ✅

**Блоки программы**: Базовый (1-49), Продвинутый (50-91), Турбо (92-98), Заключение (99-100)

**Сегментированный контрол**: Показывается только для не пройденных дней > 49. Логика инкапсулирована в `WorkoutProgramCreator`.

**Модели**: ✅ `DayActivity.isPassed`, `WorkoutPreviewTraining`, маппинги между моделями

### WorkoutProgramCreator ✅

**Структура**: Инкапсулирует данные тренировки, генерацию упражнений и расчет кругов. Реализован по TDD.

**Локализация**: ✅ Основные строки добавлены в `Localizable.xcstrings`

## Примечания

1. **Реклама**: Блок с рекламой "Продвинутый дневник тренировок" из Android-версии реализовывать не нужно.

2. **TDD подход**: При реализации следовать правилам TDD - сначала тесты, затем реализация. После каждого этапа запускать `make format`.

3. **Синхронизация**: Сохранение должно работать офлайн, синхронизация с сервером происходит через `DailyActivitiesService` при следующей синхронизации.

4. **Архитектура ViewModel**: ViewModel не должна хранить ссылки на `ModelContext` или `DailyActivitiesService` - они передаются в методы как параметры. Это упрощает тестирование и делает зависимости явными.

## План реализации оставшихся задач

### Приоритет 1: Критические проблемы ✅

**Статус**: Все задачи реализованы. Фильтрация активности по типу в `updateData`, логика отображения кнопок через флаг `wasOriginallyPassed`, рефактор `shouldShowExecutionTypePicker` в ViewModel. Все реализовано по TDD.

### Приоритет 2: Степпер для изменения количества повторений ✅

**Статус**: Реализовано. Добавлен степпер для изменения количества повторений через `TrainingRowView` с enum `TrainingRowAction`, методом `withCount(_:)` в `WorkoutPreviewTraining`, методом `updatePlannedCount(id:action:)` в ViewModel. Реализовано по TDD.

### Приоритет 2.5: Степпер для изменения количества кругов/подходов ✅

**Статус**: Реализовано. Рефакторинг `TrainingRowView` для работы с отдельными параметрами, переименование в `updatePlannedCount(id:action:)`, добавление `isPlannedCountDisabled` для отключения степпера при типе "Турбо". Реализовано по TDD.

### Приоритет 2.6: Сохранение пользовательских изменений при смене типа выполнения ✅

**Статус**: Реализовано. Метод `WorkoutProgramCreator.withExecutionType(_:)` сохраняет пользовательские изменения `plannedCount` и `count` упражнений. Если `plannedCount` равен дефолтному для текущего типа - пересчитывается для нового. При переходе на `.turbo` используются дефолтные значения. Реализовано по TDD.

### Приоритет 2.7: Исправление багов при загрузке существующей активности ✅

**Статус**: Реализовано. Исправлены баги с активностью кнопки "Сохранить" и отображением количества кругов/подходов при загрузке существующей пройденной активности.
Добавлен механизм отслеживания изменений в `WorkoutPreviewViewModel` через snapshot исходных данных и computed property `hasChanges`, исправлен `WorkoutProgramCreator.init(from:)` для вычисления `plannedCount` при `nil`.
Реализовано по TDD.

### Приоритет 2.8: Исправление логики "турбо" executionType для дней в "Турбо-блоке"

**Статус**: Частично выполнено ✅

**Выполнено**:
- ✅ День 92 в режиме turbo: объединены два выпада в одно упражнение (3 упражнения: pushUps=4, lunges=2, pullUps=1)
- ✅ Отображение счетчика для turbo: показывается "Круги" с иконкой кругов вместо "Турбо"
- ✅ Скрытие комментария: комментарий показывается только для пройденных тренировок (wasOriginallyPassed == true)
- ✅ Тесты для дня 92 в режимах turbo и cycles/sets
- ✅ Дефолтный executionType для продвинутого блока (дни 50-91): установлен `.cycles` вместо `.sets`
- ✅ Название турбо-упражнения для дня 92 - выпады: добавлена локализация `lunges92` и логика в `ExerciseType.makeLocalizedTitle`
- ✅ Количество отжиманий для дня 92 в режиме не-турбо: исправлено на pushUps=2 для cycles/sets
- ✅ Метод displayExecutionType: перемещен в `WorkoutPreviewViewModel` с тестами
- ✅ Названия и количества упражнений для дня 98 в режиме турбо: установлены правильные количества (10, 20, 30)
- ✅ Проверка соответствия типов упражнений между Android и новым приложением: основные типы добавлены
- ✅ Тесты для турбо-дней: добавлены в `WorkoutProgramCreatorTests`

**Оставшиеся проблемы**:

1. **Дублирование названий турбо-упражнений для дня 95**:
   - Проблема: название упражнения "1 минута стульчик - 10 прыжков" дублируется несколько раз
   - Текущее состояние: используется `turbo95_3` (rawValue = 953) для третьего упражнения (sortOrder=2)
   - **Нужно**: проверить локализацию для `turbo95_3` и исправить маппинг в `ExerciseType.localizedTitle`, чтобы убрать дублирование названий

2. **Названия и количества упражнений для дня 97 в режиме турбо**:
   - В Android: 5 упражнений, все pushUps=5, но с разными названиями по sortOrder (pushUps970, pushUps971, pushUps972)
   - В новом приложении: используются `turbo97PushupsHigh` (97), обычные `pushups` (3), `turbo97PushupsHighArms` (973), обычные `pushups` (3), `turbo97PushupsHigh` (97)
   - **Проблемы**:
     - В новом приложении нет типов 970, 971, 972 в enum `ExerciseType`
     - Для sortOrder 1 и 3 используются обычные `pushups` (3) вместо специального типа
   - **Нужно**: 
     - Проверить на сервере (StreetWorkoutSU) наличие типов упражнений 970, 971, 972
     - Если типы есть на сервере: добавить их в enum `ExerciseType` и использовать правильные типы в `WorkoutProgramCreator.generateFreeStyleTurboExercises`
     - Если типов нет на сервере: добавить логику для использования правильных названий в зависимости от sortOrder и executionType (как в Android)

### Приоритет 3: Дополнительные кнопки

#### 4. Поле для комментария ✅

**Статус**: Реализовано. Добавлено поле `SWTextEditor` для ввода комментария тренировки на экране `WorkoutPreviewScreen` с синхронизацией через ViewModel.

#### 5. Кнопка "Начать тренировку" ✅

**Статус**: Реализовано. Добавлена кнопка "Начать тренировку", которая отображается только для еще не пройденных тренировок вместе с кнопкой "Сохранить как пройденную". При нажатии выводит в консоль `print("TODO: переход к началу тренировки")`. Полная реализация перехода к экрану выполнения тренировки будет добавлена в отдельном документе.

## Будущие доработки

### Кнопка "Продолжить"

**Задача**: Показывать кнопку только если тренировка была начата, но не завершена.

**Статус**: Отложено до реализации логики отслеживания состояния выполнения тренировки.

**Описание**:
- В Android приложении кнопка "Продолжить" (`buttonContinueTraining`) отображается для пройденных дней, если есть активная (не завершенная) тренировка для текущего дня
- Логика показа: `interactor.getActiveTrainingDay() != -1 && interactor.getActiveTrainingDay() == view.getDayNumber()`
- При нажатии вызывает тот же метод, что и кнопка "Начать тренировку" - переход к экрану выполнения тренировки
- Активная тренировка отслеживается через `activeTrainingDay` и `activeTrainingCircle` в Preferences
- В старом iOS приложении (SOTKA-OBJc) такого функционала нет

**Что нужно реализовать**:
- Механизм отслеживания активной тренировки (начата, но не завершена)
- Логику показа кнопки только для пройденных дней с активной тренировкой
- Интеграцию с экраном выполнения тренировки (будет реализован в отдельном документе)

### Редактор упражнений

**Статус**: План реализации готов. Ожидает реализации.

**Задача**: Реализовать экран редактора упражнений для изменения набора упражнений в тренировочном дне. В новом приложении весь функционал бесплатный (не требуется проверка покупок).

#### Анализ существующих реализаций

**Android-SOTKA: EditTrainingSetFragment**
- **Расположение**: `fragment_edit_training_set/EditTrainingSetFragment.kt`
- **ViewModel**: `EditTrainingViewModel.kt`
- **Структура данных**: Использует мапперы `DayToEditTrainingSetMapper` и `ExercisesToEditTrainingSetMapper` для преобразования данных в элементы списка
- **Три типа элементов списка**:
  1. `EditTrainingDayRemovableItem` - упражнения текущего дня (с кнопкой удаления и drag handle)
  2. `EditTrainingDayTypeItem` - стандартные упражнения (с кнопкой добавления)
  3. `EditTrainingDayUserItem` - пользовательские упражнения (с кнопкой добавления)
- **Drag and Drop**: Использует `ItemTouchHelper` с `TrainingItemTouchCallback` для перестановки упражнений
- **Условия показа**: Кнопка редактирования показывается только для типов выполнения `.cycles` и `.sets` (не для `.turbo`)

**SOTKA-OBJc: TrainingCustomEditorController**
- **Расположение**: `TrainingCustomEditorController.m`
- **Функционал**: Отображает список пользовательских упражнений для выбора и добавления в тренировку
- **Особенности**: Использует `NSFetchedResultsController` для работы с Core Data

#### План реализации

##### 1. Условия показа кнопки редактирования

**Местоположение**: Кнопка в навбаре справа (`toolbar`) на экране `WorkoutPreviewScreen`

**Логика показа**:
- Показывается только для типов выполнения `.cycles` и `.sets`
- Скрывается для типа `.turbo`
- Метод в `WorkoutPreviewViewModel`: `shouldShowEditButton() -> Bool`

**Реализация**:
```swift
// В WorkoutPreviewScreen.swift
@State private var showEditorScreen = false

// В body:
.toolbar {
    if viewModel.shouldShowEditButton() {
        ToolbarItem(placement: .topBarTrailing) {
            Button {
                showEditorScreen.toggle()
            } label: {
                Image(systemName: "pencil")
            }
        }
    }
}
.navigationDestination(isPresented: $showEditorScreen) {
    WorkoutExerciseEditorScreen()
        .environment(viewModel)
}
```

##### 2. Структура экрана редактора

**Новый экран**: `WorkoutExerciseEditorScreen`

**Три секции списка**:

1. **Секция 1: Упражнения текущего дня** (не турбо-упражнения)
   - Отображаются в том же порядке, что и на экране превью
   - Каждая строка содержит:
     - Кнопка удаления слева (иконка "minus.circle.fill")
     - Иконка упражнения
     - Название упражнения
     - Иконка drag handle справа (иконка "line.3.horizontal")
   - Поддержка drag and drop для изменения порядка (только в рамках этой секции)
   - При удалении упражнение удаляется из списка

2. **Секция 2: Стандартные упражнения**
   - Список стандартных упражнений из `ExerciseType` (не турбо-упражнения):
     - `pullups` (0)
     - `austrPullups` (1)
     - `squats` (2)
     - `pushups` (3)
     - `pushupsKnees` (4)
     - `lunges` (5)
   - Каждая строка содержит:
     - Кнопка добавления слева (иконка "plus.circle.fill")
     - Иконка упражнения
     - Название упражнения
   - При нажатии на кнопку добавления упражнение копируется в первую секцию с `count = 5` (по умолчанию)

3. **Секция 3: Пользовательские упражнения** (если есть)
   - Список пользовательских упражнений из `CustomExercise` (загружается из `ModelContext`)
   - Каждая строка содержит:
     - Кнопка добавления слева (иконка "plus.circle.fill")
     - Иконка упражнения
     - Название упражнения
   - При нажатии на кнопку добавления упражнение копируется в первую секцию с `count = 5` (по умолчанию)
   - Если пользовательских упражнений нет, секция не показывается

**Навигация**:
- Кнопка "Готово" в навбаре справа для сохранения изменений и возврата на экран превью (использует `@Environment(\.dismiss)`)
- Стандартная кнопка "Назад" в навбаре слева для отмены изменений (изменения не сохраняются, локальный state-массив отбрасывается)

##### 3. Состояние и логика экрана редактора

**ViewModel**: Используется `WorkoutPreviewViewModel` через Environment (отдельный ViewModel не требуется)

**Локальное состояние в экране редактора**:
- `@State private var editableExercises: [WorkoutPreviewTraining]` - локальный массив упражнений для редактирования
- `@Environment(WorkoutPreviewViewModel.self) private var previewViewModel` - ViewModel превью экрана через Environment
- `@Query(FetchDescriptor<CustomExercise>(predicate: #Predicate { !$0.shouldDelete })) private var customExercises: [CustomExercise]` - загрузка пользовательских упражнений через SwiftData Query
- `@Environment(\.dismiss) private var dismiss` - для возврата на экран превью

**Методы в экране редактора**:
- `onAppear` - инициализация `editableExercises` из `previewViewModel.trainings` (только не турбо-упражнения)
- `removeExercise(at index: Int)` - удаление упражнения из локального массива `editableExercises`
- `addStandardExercise(_ exerciseType: ExerciseType)` - добавление стандартного упражнения в локальный массив `editableExercises` с `count = 5`
- `addCustomExercise(_ customExercise: CustomExercise)` - добавление пользовательского упражнения в локальный массив `editableExercises` с `count = 5`
- `moveExercise(from source: IndexSet, to destination: Int)` - перемещение упражнения в локальном массиве (используется в `.onMove` для List)
- `saveChanges()` - вызов `previewViewModel.updateTrainings(editableExercises)` и `dismiss()`

##### 4. Интеграция с WorkoutPreviewScreen

**Передача данных через Environment**:
- `WorkoutPreviewViewModel` передается в экран редактора через `.environment(viewModel)`
- Экран редактора получает доступ к ViewModel через `@Environment(WorkoutPreviewViewModel.self)`
- При появлении экрана (`onAppear`) создается локальный `@State` массив `editableExercises` из `previewViewModel.trainings` (только не турбо-упражнения)
- Все изменения происходят в локальном массиве до нажатия "Сохранить"
- При нажатии "Назад" локальный массив отбрасывается, изменения не сохраняются

**Обновление WorkoutPreviewViewModel**:
- Метод `updateTrainings(_ newTrainings: [WorkoutPreviewTraining])` для обновления списка упражнений
- При обновлении пересчитывается `sortOrder` на основе порядка в массиве (0, 1, 2, ...)
- Новые упражнения получают `count = 5` по умолчанию (если не указано иное)
- После обновления пересоздается `WorkoutProgramCreator` с новыми упражнениями через метод `withCustomExercises`

**Обновление WorkoutProgramCreator**:
- Метод `withCustomExercises(_ exercises: [WorkoutPreviewTraining]) -> WorkoutProgramCreator` для создания нового экземпляра с пользовательскими упражнениями
- Сохраняет остальные данные (executionType, plannedCount, count, comment)

##### 5. UI компоненты

**Переиспользование ActivityRowView**:
- Использовать существующий компонент `ActivityRowView` для отображения упражнения (иконка, название, счетчик)
- Обернуть `ActivityRowView` в `HStack` с кнопками по бокам:
  - Слева: кнопка удаления (иконка "minus.circle.fill") для первой секции или кнопка добавления (иконка "plus.circle.fill") для второй и третьей секций
  - Справа: иконка drag handle (иконка "line.3.horizontal") только для первой секции

**Новый компонент**: `WorkoutExerciseEditorRowView`
- Обертка над `ActivityRowView` с кнопками по бокам
- Параметры: `exercise`, `mode` (`.removable` или `.addable`), `onAction` (для удаления/добавления)
- Для первой секции: кнопка удаления слева + `ActivityRowView` + drag handle справа
- Для второй и третьей секций: кнопка добавления слева + `ActivityRowView`

**Drag and Drop**:
- Использование нативного `.onMove(perform:)` модификатора для `List` в SwiftUI
- Применяется только к первой секции (упражнения дня)
- Метод `moveExercise(from source: IndexSet, to destination: Int)` обновляет локальный массив `editableExercises`

**Секции списка**:
- Использование `List` с `Section` в SwiftUI для разделения на три секции
- Первая секция: `ForEach(editableExercises)` с `.onMove` для drag and drop
- Вторая секция: `ForEach(standardExercises)` - стандартные упражнения
- Третья секция: `ForEach(customExercises)` - пользовательские упражнения (если есть)
- Заголовки секций: "Упражнения дня", "Стандартные упражнения", "Пользовательские упражнения"

##### 6. Тестирование (TDD подход)

**Unit тесты для WorkoutExerciseEditorScreen**:
- Тест инициализации локального массива из ViewModel при `onAppear`
- Тест загрузки пользовательских упражнений через `@Query`
- Тест удаления упражнения из локального массива
- Тест добавления стандартного упражнения в локальный массив с `count = 5`
- Тест добавления пользовательского упражнения в локальный массив с `count = 5`
- Тест перемещения упражнений в локальном массиве через `.onMove` (drag and drop)
- Тест вызова `previewViewModel.updateTrainings` при сохранении
- Тест фильтрации турбо-упражнений при инициализации

**UI тесты для WorkoutExerciseEditorRowView**:
- Тест отображения `ActivityRowView` с кнопками по бокам
- Тест кнопки удаления для режима `.removable`
- Тест кнопки добавления для режима `.addable`
- Тест отображения drag handle для первой секции

**Unit тесты для WorkoutPreviewTraining**:
- Тест метода `isTurboExercise` для различных типов упражнений

**Unit тесты для WorkoutProgramCreator**:
- Тест метода `withCustomExercises` для сохранения пользовательских изменений
- Тест сохранения остальных данных при обновлении упражнений

**UI тесты**:
- Тест отображения трех секций
- Тест drag and drop в первой секции
- Тест добавления/удаления упражнений
- Тест сохранения изменений

##### 7. Локализация

**Новые строки для Localizable.xcstrings**:
- "WorkoutExerciseEditor.Title" - "Редактирование упражнений"
- "WorkoutExerciseEditor.Done" - "Готово"
- "WorkoutExerciseEditor.Cancel" - "Отмена"
- "WorkoutExerciseEditor.DayExercises" - "Упражнения дня"
- "WorkoutExerciseEditor.StandardExercises" - "Стандартные упражнения"
- "WorkoutExerciseEditor.CustomExercises" - "Пользовательские упражнения"

##### 8. Особенности реализации

**Фильтрация турбо-упражнений**:
- При загрузке текущих упражнений фильтруются только не турбо-упражнения
- Турбо-упражнения определяются по `ExerciseType` (значения >= 93 или специальные типы)
- Добавить extension для `WorkoutPreviewTraining` с методом `var isTurboExercise: Bool` для проверки, является ли упражнение турбо-упражнением

**Дефолтное количество повторений**:
- Новые упражнения получают `count = 5` по умолчанию
- Пользователь может изменить количество на экране превью после сохранения

**Сохранение порядка**:
- При сохранении `sortOrder` устанавливается на основе индекса в массиве (0, 1, 2, ...)
- Порядок сохраняется в `DayActivityTraining.sortOrder`

**Офлайн-приоритет**:
- Все изменения сохраняются локально в SwiftData
- Флаг `isSynced = false` устанавливается для `DayActivity` при изменении упражнений
- Синхронизация с сервером происходит при следующей синхронизации через `DailyActivitiesService`

**Переиспользование компонентов**:
- Использование `ActivityRowView` для единообразного отображения упражнений
- Использование `@Query` для автоматической загрузки пользовательских упражнений из SwiftData (аналогично `CustomExercisesScreen`)
- Использование нативных инструментов SwiftUI (`List` с `.onMove`) для drag and drop без дополнительных библиотек

##### 9. Порядок реализации (TDD)

1. **Этап 1: Подготовка и тесты**
   - Добавить extension для `WorkoutPreviewTraining` с методом `isTurboExercise` и тестами
   - Добавить метод `updateTrainings(_ newTrainings: [WorkoutPreviewTraining])` в `WorkoutPreviewViewModel` с тестами
   - Добавить метод `withCustomExercises` в `WorkoutProgramCreator` с тестами
   - Запустить `make format`

2. **Этап 2: UI компоненты**
   - Создать `WorkoutExerciseEditorRowView` с переиспользованием `ActivityRowView` и кнопками по бокам
   - Создать `WorkoutExerciseEditorScreen` с локальным `@State` массивом `editableExercises`
   - Добавить `@Query` для загрузки пользовательских упражнений
   - Реализовать `List` с тремя `Section` (упражнения дня, стандартные, пользовательские)
   - Реализовать нативный `.onMove` для drag and drop в первой секции
   - Реализовать методы добавления/удаления/перемещения упражнений в локальном массиве
   - Реализовать `onAppear` для инициализации локального массива из ViewModel
   - Реализовать кнопку "Готово" с вызовом `previewViewModel.updateTrainings` и `dismiss`
   - Запустить `make format`

3. **Этап 3: Интеграция**
   - Добавить `@State private var showEditorScreen = false` в `WorkoutPreviewScreen`
   - Добавить кнопку редактирования в toolbar с `showEditorScreen.toggle()`
   - Добавить `.navigationDestination(isPresented: $showEditorScreen)` для перехода на экран редактора
   - Передать `viewModel` через `.environment(viewModel)` в экран редактора
   - Реализовать метод `updateTrainings` в `WorkoutPreviewViewModel` для обработки изменений
   - Запустить `make format`

5. **Этап 5: Локализация и финальные тесты**
   - Добавить локализованные строки
   - Запустить все тесты
   - Проверить работу в симуляторе
   - Запустить `make format`

##### 10. Примечания

- **Бесплатный функционал**: В новом приложении весь функционал редактора доступен бесплатно (не требуется проверка покупок)
- **Только не турбо-упражнения**: Редактор работает только с обычными упражнениями (не турбо)
- **Интеграция с CustomExercisesScreen**: Пользовательские упражнения управляются в профиле через `CustomExercisesScreen`, а в редакторе только добавляются в тренировку
- **Совместимость с сервером**: Изменения сохраняются локально и синхронизируются с сервером через существующий механизм синхронизации