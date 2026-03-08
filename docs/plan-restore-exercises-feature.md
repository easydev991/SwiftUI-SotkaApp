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

### 1. Структура

```swift
// Модификатор для отображения футера с кнопкой восстановления
struct RestoreExercisesFooter: View {
    let onRestore: () -> Void

    var body: some View {
        HStack {
            Text("Набор упражнений отличается от рекомендуемых")
                .font(.caption)
                .foregroundColor(.secondary)
            Spacer()
            Button("Восстановить", action: onRestore)
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
    guard trainType != .turbo else { return false }

    // Не показывать если упражнения совпадают с рекомендуемыми
    return !exercisesMatchRecommended
}

var exercisesMatchRecommended: Bool {
    let recommended = TrainProgramCreator.recommendedExercises(for: day, type: trainType)
    let currentTypeIds = Set(trainings.compactMap { $0.typeId })
    let recommendedTypeIds = Set(recommended.compactMap { $0.typeId })

    return recommendedTypeIds.isSubset(of: currentTypeIds)
}
```

### 3. Действие восстановления

```swift
func restoreRecommendedExercises() {
    let recommended = TrainProgramCreator.recommendedExercises(for: day, type: trainType)
    trainings = recommended.map { training in
        DayActivityTraining(from: training, dayActivity: self)
    }

    // Восстановить рекомендуемое количество кругов
    cycleCount = TrainProgramCreator.recommendedCycles(
        for: day,
        type: trainType,
        gender: userGender
    )
}
```

## Связанные компоненты

- `TrainProgramCreator` - генератор рекомендуемых программ тренировок
- Методы `recommendExercisesForDay:type:` и `recommendNumberOfCyclesForDay:type:gender:`
