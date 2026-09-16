# Функция "Восстановить рекомендуемые упражнения"

## Обзор

В старом приложении (SOTKA-OBJc) реализована функция восстановления рекомендуемого набора упражнений, когда пользователь изменил их вручную.

## Реализация в старом приложении (ObjC)

### Расположение файлов

- **View:** `WorkOut100Days/Views/RestoreView/` - UI компонент с кнопкой "Восстановить"
- **Controller:** `WorkOut100Days/Controllers/Training/TrainingController.m` - логика отображения и обработки
- **Logic:** Методы `exercisesRecommended` и `restoreClicked`

### Условия отображения

Кнопка "Восстановить" отображается в футере секции упражнений, когда:

1. Текущий режим НЕ "турбо" (cycleSegment.selectedSegmentIndex != 2)
2. Набор упражнений отличается от рекомендуемых
3. Таблица НЕ находится в режиме редактирования

```objc
-(CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    if (section == SECION_EXERCISES) {
        if (![self exercisesRecommended] && (!tableView.editing)) {
            return 50;  // Высота для RestoreView
        }
    }
    // ...
}

-(UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    if (section == SECION_EXERCISES) {
        if (![self exercisesRecommended] && (!tableView.editing)) {
            RestoreView *view = [[[NSBundle mainBundle] loadNibNamed:@"RestoreView"
                                                               owner:self
                                                             options:nil] firstObject];
            [view.restoreButton addTarget:self action:@selector(restoreClicked:)
                         forControlEvents:UIControlEventTouchUpInside];
            return view;
        }
    }
    // ...
}
```

### Логика проверки (exercisesRecommended)

```objc
- (BOOL) exercisesRecommended {
    // Турбо-режим всегда считается "рекомендованным"
    if (self.cycleSegment.selectedSegmentIndex == 2) {
        return true;
    }

    TrainProgramCreator *creator = [TrainProgramCreator instance];

    // Собираем типы текущих упражнений
    NSMutableArray<NSString*> *exTypes = [NSMutableArray new];
    for (PlanTrainObject* ex in exercises) {
        [exTypes addObject:[NSString stringWithFormat:@"%ld", (long)ex.typeId]];
    }

    // Получаем рекомендуемые упражнения для текущего дня и типа тренировки
    NSArray *recExercises = [creator recommendExercisesForDay:self.currentDay
                                                        type:(int)self.cycleSegment.selectedSegmentIndex];

    // Проверяем, что все рекомендуемые типы присутствуют
    for (PlanTrainObject* recEx in recExercises) {
        NSString *type = [NSString stringWithFormat:@"%ld", (long)recEx.typeId];
        if ([exTypes indexOfObject:type] == NSNotFound) {
            return NO;  // Отсутствует рекомендуемое упражнение
        }
    }

    return YES;
}
```

### Логика восстановления (restoreClicked)

```objc
- (IBAction)restoreClicked:(id)sender {
    TrainProgramCreator *creator = [TrainProgramCreator instance];

    // Восстанавливаем рекомендуемые упражнения
    exercises = [NSMutableArray arrayWithArray:
        [creator recommendExercisesForDay:self.currentDay
                                    type:(int)self.cycleSegment.selectedSegmentIndex]];

    // Восстанавливаем рекомендуемое количество кругов
    NSInteger gender = [WorkOutBrain instance].userGender;
    self.numberOfCycles = [creator recommendNumberOfCyclesForDay:(int)self.currentDay
                                                            type:(int)self.cycleSegment.selectedSegmentIndex
                                                          gender:gender];

    // Обновляем отображение
    [self fillExerciseNames];

    NSRange range = NSMakeRange(0, [self numberOfSectionsInTableView:self.tableView]);
    NSIndexSet *sections = [NSIndexSet indexSetWithIndexesInRange:range];
    [self.tableView reloadSections:sections withRowAnimation:UITableViewRowAnimationAutomatic];
}
```

### Текстовые метки

**Русский:**

- Label: "Набор упражнений отличается от рекомендуемых"
- Button: "Восстановить"

**Английский (базовый):**

- Label: "Exercise set is different than planned"
- Button: "Restore"

## Рекомендации для SwiftUI-SotkaApp

> **Статус (2026-09-16):** в SwiftUI-SotkaApp функция **не реализована** — ни футера с кнопкой восстановления, ни проверки совпадения с рекомендуемым набором в коде нет. Предусловие выполнено: набор упражнений можно менять через `WorkoutExerciseEditorScreen` (`.sheet`, только для типов `.cycles` и `.sets`).

Соответствие понятий:

- `TrainProgramCreator` → `WorkoutProgramCreator` (структура, функциональный стиль: `withExecutionType(_:)`, `withCustomExercises(_:)`, `withData(from:)`)
- `recommendExercisesForDay:type:` → рекомендуемый набор получают через `WorkoutProgramCreator(day:executionType:)` (генерация — приватный `generateExercises(for:executionType:)`)
- `recommendNumberOfCyclesForDay:type:gender:` → `calculatePlannedCircles(for:executionType:)` — параметр `gender` удалён вместе с гендерной логикой
- `cycleSegment.selectedSegmentIndex != 2` → `selectedExecutionType != .turbo` (`ExerciseExecutionType`)
- `tableView.editing` → редактор упражнений `WorkoutExerciseEditorScreen` в `.sheet`
- `TrainingController` → `WorkoutPreviewScreen` / `WorkoutPreviewViewModel`

### 1. Структура

```swift
// Футер с кнопкой восстановления для списка упражнений на WorkoutPreviewScreen
struct RestoreExercisesFooter: View {
    let onRestore: () -> Void

    var body: some View {
        HStack {
            Text(.exercisesDifferFromRecommended)  // ключ добавить в String Catalog
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer()
            Button(.restore, action: onRestore)  // ключ добавить в String Catalog
                .buttonStyle(.bordered)
        }
        .padding()
    }
}
```

### 2. Условия отображения

```swift
var shouldShowRestoreButton: Bool {
    // Не показывать в турбо-режиме
    guard selectedExecutionType != .turbo else { return false }

    // Не показывать если упражнения совпадают с рекомендуемыми
    return !exercisesMatchRecommended
}

var exercisesMatchRecommended: Bool {
    let recommended = WorkoutProgramCreator(
        day: dayNumber,
        executionType: selectedExecutionType
    ).trainings

    // Сравнение должно учитывать и typeId, и customTypeId (пользовательские упражнения).
    // В WorkoutProgramCreator уже есть приватная утилита makeTrainingMatchKey(for:) —
    // при реализации открыть к ней доступ или использовать ту же логику.
    func matchKey(for training: WorkoutPreviewTraining) -> String {
        training.customTypeId.map { "custom:\($0)" }
            ?? training.typeId.map { "type:\($0)" }
            ?? "id:\(training.id)"
    }

    let currentKeys = Set(trainings.map(matchKey))
    return recommended.allSatisfy { currentKeys.contains(matchKey(for: $0)) }
}
```

Дополнительные условия:

- Скрывать футер, пока открыт редактор упражнений (`WorkoutExerciseEditorScreen` в `.sheet`).
- Ограничение то же, что у кнопки редактирования (`shouldShowEditButton`): только `.cycles` и `.sets`.

### 3. Действие восстановления

```swift
func restoreRecommendedExercises() {
    let recommended = WorkoutProgramCreator(
        day: dayNumber,
        executionType: selectedExecutionType
    )

    // Восстанавливаем рекомендуемые упражнения и количество кругов/подходов
    trainings = recommended.trainings
    plannedCount = recommended.plannedCount
}
```

- Восстановление меняет только состояние `WorkoutPreviewViewModel`; запись в SwiftData — через существующий поток сохранения (`buildDayActivity()` → `DailyActivitiesService.createDailyActivity`). Механизм snapshot автоматически активирует кнопку «Сохранить» через `hasChanges`.

## Связанные компоненты

- `WorkoutProgramCreator` (`SwiftUI-SotkaApp/Services/WorkoutProgramCreator.swift`, `WorkoutProgramCreator+DayActivity.swift`) - генератор рекомендуемых программ тренировок
- Методы `generateExercises(for:executionType:)` (приватный) и `calculatePlannedCircles(for:executionType:)`
- `WorkoutPreviewScreen` / `WorkoutPreviewViewModel` - экран превью тренировки (аналог `TrainingController`)
- `WorkoutExerciseEditorScreen` - редактор набора упражнений (только `.cycles` и `.sets`)
