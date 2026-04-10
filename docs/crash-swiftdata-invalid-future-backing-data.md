# Краш `SwiftData: _InvalidFutureBackingData.getValue`

## Кратко

Это единичный production-crash после релиза `4.3.0 (1)`, произошедший на `iPhone14,3` с `iOS 26.0.1` через ~13 секунд после запуска приложения.

Падение происходит во время рендера `DayActivityTrainingView`, когда UI читает `activity.trainings.sorted`, а один из объектов `DayActivityTraining` уже находится в невалидном состоянии внутри SwiftData. По стеку это не похоже на ошибку бизнес-логики в расчётах или синке дат. Это похоже на сочетание:

- известной нестабильности SwiftData вокруг `FutureBackingData` / relationship-объектов;
- нашего текущего паттерна, где UI напрямую читает live SwiftData relationship в момент, когда sync или локальное обновление может удалить или заменить связанные сущности.

## Что видно из crash report

### Факты

- Версия приложения: `4.3.0 (1)`
- Дата падения: `2026-02-10 19:17:42 +0200`
- OS: `iPhone OS 26.0.1`
- Устройство: `iPhone14,3`
- Количество инцидентов: 1 устройство / 1 crash с момента релиза
- Crash point в Xcode Analytics: `SwiftData: _InvalidFutureBackingData.getValue<A>(forKey:) + 208`

### Ключевой стек

- `SwiftData._InvalidFutureBackingData.getValue<A>(forKey:)`
- `PersistentModel.getValue<A>(forKey:)`
- `DayActivityTraining.sortOrder.getter`
- `closure #1 in Array.sorted.getter`
- `DayActivityTrainingView.body.getter`

### Что это означает

В момент построения UI приложение пытается прочитать `sortOrder` у одной из тренировок дня, но backing data этой SwiftData-сущности уже недоступен. Для SwiftData это фатальная ситуация, и framework падает через internal assertion.

## Где в коде находится проблемная зона

### Чтение relationship прямо из UI

- `Screens/Profile/Journal/Views/DayActivityTrainingView.swift`
  - `ForEach(activity.trainings.sorted, id: \.persistentModelID) { ... }`
- `Models/Workout/DayActivityTraining.swift`
  - `sorted` читает `sortOrder` у каждого `DayActivityTraining`

### Места, где relationship активно мутируется

- `Models/Workout/DayActivity.swift`
  - `setNonWorkoutType(_:, user:)` делает `trainings.removeAll()`
- `Services/DailyActivitiesService.swift`
  - `updateExistingActivity(_:with:user:)` делает `existing.trainings.removeAll()` и затем добавляет новые
  - `updateLocalFromServer(_:_:)` делает `local.trainings.removeAll()` и затем заменяет массив новыми объектами
  - `downloadServerActivities(context:excludeDeletedDays:)` местами физически удаляет `DayActivity`

### Почему это особенно важно

`DayActivityTrainingView` используется не только в дневнике, но и на главном экране через `DayActivityContentView`. При этом синхронизация активностей запускается автоматически при переходе приложения в `active`:

- `SwiftUI_SotkaAppApp.swift` -> `statusManager.getStatus()`
- `StatusManager.getStatus()` -> `syncJournalAndProgress()`
- `syncJournalAndProgress()` -> `dailyActivitiesService.syncDailyActivities(context:)`

То есть пользователь вполне может открыть приложение, увидеть тренировку на экране, а параллельно sync обновит или удалит связанные `trainings`.

## Как, вероятнее всего, воспроизводится

Точного пошагового воспроизведения из одного crash report получить нельзя, потому что в отчёте нет пользовательских действий и наших дополнительных логов. Но наиболее вероятный сценарий такой:

1. У пользователя есть `DayActivity` типа `workout` с заполненными `trainings`.
2. Он открывает экран, где строится `DayActivityTrainingView`:
   - главный экран с текущей активностью, или
   - дневник тренировок.
3. Почти сразу после запуска приложения стартует синхронизация активностей.
4. Во время sync тот же `DayActivity` обновляется с сервера, переводится в другой тип активности, либо удаляется. В коде это приводит к `trainings.removeAll()`, замене массива тренировок или удалению самой активности.
5. SwiftUI в этот же момент продолжает строить `ForEach(activity.trainings.sorted, ...)`.
6. Одна из `DayActivityTraining` уже инвалидирована внутри SwiftData, и чтение `sortOrder` падает на `_InvalidFutureBackingData.getValue`.

## Что вызывает краш

### Непосредственная причина

Чтение свойства `sortOrder` у уже невалидного `DayActivityTraining` во время сортировки массива для UI.

### Более глубокая причина

Сейчас UI работает с "живыми" SwiftData-relationship объектами напрямую, а слой sync/редактирования в это же время активно:

- очищает дочерние relationship-массивы;
- заменяет дочерние объекты новыми экземплярами;
- иногда физически удаляет родительскую запись.

Для SwiftData на iOS 18+/26 подобные сценарии с relationship/deletion/update уже известны как нестабильные. По публичным обсуждениям Apple Developer Forums это похоже на framework-level баг или как минимум на очень хрупкое место SwiftData, особенно при удалении и обновлении one-to-many relationships.

Итог: это не "чисто баг Apple" и не "чисто баг нашего кода". Скорее это app-level рискованный паттерн, который попадает в известную слабую зону SwiftData.

## Минимальный безопасный технический план фикса

### Цель

Убрать самый рискованный паттерн без расширения области изменений на весь sync-слой.

### План

1. Перестать рендерить `activity.trainings.sorted` напрямую в `DayActivityTrainingView`.
2. Загружать дочерние `DayActivityTraining` отдельным `@Query`, чтобы view не держал прямую зависимость от parent relationship-коллекции.
3. Сразу преобразовывать полученные `DayActivityTraining` в value-модель для UI перед `ForEach`.
4. Добавить узкий regression-тест на преобразование в value snapshot и порядок сортировки.
5. Не менять `DailyActivitiesService`, пока не появятся повторные краши или надёжный сценарий воспроизведения, требующий deeper fix.

## Можно ли поправить

Да, смягчить и практически убрать этот crash можно.

### Наиболее реалистичные меры

1. Не рендерить `activity.trainings` напрямую из relationship в `View`.
2. Передавать в UI не live `DayActivityTraining`, а value-snapshot, например массив `WorkoutPreviewTraining` или отдельный DTO для отображения.
3. В `sheet`/`Menu`/списках по возможности передавать `day` или `persistentModelID`, а сам объект перечитывать ближе к месту использования, чтобы уменьшить время жизни stale reference.
4. В sync-обновлениях осторожнее обращаться с заменой relationship:
   - по возможности избегать паттерна `removeAll()` + немедленная замена в том же жизненном цикле UI;
   - при необходимости делать более явную двухшаговую схему обновления children.

### Что реализовано сейчас

- В `DayActivityTrainingView` убрано прямое чтение `activity.trainings.sorted`.
- Дочерние тренировки теперь загружаются отдельным `@Query` по дню активности.
- Для рендера используется value snapshot (`WorkoutPreviewTraining`), а не live `DayActivityTraining` в `ForEach`.
- Добавлен тест на преобразование в отсортированный UI snapshot.

### Что не стоит считать достаточным фиксом

- Просто обернуть чтение в `if let` не поможет: падение происходит внутри SwiftData до того, как мы успеем безопасно обработать значение.
- Просто убрать сортировку тоже вряд ли полностью решит проблему: crash проявился на `sortOrder`, но корень в чтении инвалидированной модели, а не в самом алгоритме сортировки.

## Нужно ли исправлять

### Короткий ответ

Да, исправить стоит, но это не выглядит как срочный emergency hotfix.

### Почему стоит исправить

- Это fatal crash.
- Он происходит в базовом пользовательском сценарии: открытие приложения и показ тренировки.
- Проблемное место находится в UI и sync-слое, то есть теоретически может повториться у других пользователей при похожем timing.

### Почему не похоже на блокер релиза

- С момента релиза зафиксирован только 1 crash.
- Пока затронуто только 1 устройство.
- Crash произошёл на `iOS 26.0.1`, где SwiftData и сам по себе выглядит более хрупким.

## Рекомендация по приоритету

### Рекомендуемый статус

`Средний приоритет`, не hotfix, но взять в ближайший рабочий релиз.

### Практическая рекомендация

- Не выпускать отдельный срочный билд только ради этого одного инцидента.
- Запланировать точечный app-level mitigation:
  - убрать прямое чтение `activity.trainings.sorted` в UI;
  - перевести отображение тренировок на snapshot/value-модель;
  - отдельно проверить сценарии sync во время открытого `Home` и `Journal`.

## Что бы я считал хорошим исправлением

Минимально рискованное исправление выглядело бы так:

1. Вынести данные для отображения тренировки из live SwiftData relationship в snapshot-модель для UI.
2. Использовать эту snapshot-модель в `DayActivityTrainingView` вместо прямого `ForEach(activity.trainings.sorted, ...)`.
3. Добавить regression-тест или хотя бы ручной сценарий:
   - открыть экран с workout activity;
   - параллельно синком заменить `trainings` или удалить activity;
   - убедиться, что UI не падает.

## Инцидент v4.4.0: `EXC_BREAKPOINT` в `DayActivity.trainings.getter`

### Дата и обстоятельства

- Версия приложения: `4.4.0 (1)`
- Дата: `2 апреля 2026`
- Тип: `EXC_BREAKPOINT (SIGTRAP)`, `Triggered by Thread: 0`
- Стек: `DayActivity.trainings.getter` → `DailyActivitiesService.updateExistingActivity` → `createDailyActivity` → `WorkoutPreviewViewModel.saveTrainingAsPassed`

### Причина

В `updateExistingActivity` выполнялся цикл:

```swift
existing.trainings.removeAll()
for training in new.trainings {
    training.dayActivity = existing
    existing.trainings.append(training)
}
```

Присвоение `training.dayActivity = existing` через inverse relationship мутировало `new.trainings` во время итерации по нему, что приводило к `EXC_BREAKPOINT`.

### Фикс

Реализован через `TrainingReplacementSnapshot` (value-type snapshot):

1. В `createDailyActivity` до вызова `updateExistingActivity` создаётся `trainingsSnapshot = activity.trainings.map(\.trainingReplacementSnapshot)`.
2. `updateExistingActivity` принимает `trainingsSnapshot: [TrainingReplacementSnapshot]` вместо `new.trainings`.
3. Создаются новые `DayActivityTraining` из snapshot через `context.insert()`.
4. `existing.trainings` заменяется единым присвоением.
5. Старые trainings удаляются через `context.delete()` с проверкой по `ObjectIdentifier`.

### Тесты

Добавлены regression-тесты в `DailyActivitiesUpdateExistingCrashTests.swift`:

- Повторное сохранение trainings для одного дня не падает
- Старые trainings удаляются из контекста (нет orphan-объектов)
- Порядок `sortOrder` сохраняется после replace
- Идемпотентность: 3+ последовательных сохранения не создают дубликатов
- Стабильная повторная выборка после `context.save()`

### Верификация

- iOS: 1460 тестов пройдено (5 pre-existing падений в `WorkoutScreenViewModelStepCompletionTests`, не связанных с фиксом)
- watchOS: 189 тестов пройдено без деградации
- Новых пользовательских строк не добавлено, локализация не затронута

### Файлы

- `SwiftUI-SotkaApp/Services/DailyActivitiesService.swift` — `updateExistingActivity`, `createDailyActivity`, `TrainingReplacementSnapshot`
- `SwiftUI-SotkaAppTests/DailyActivitiesTests/DailyActivitiesUpdateExistingCrashTests.swift`

## Вывод

Краш реален, но редкий. По стеку он связан с тем, что SwiftUI рендерит `DayActivityTrainingView` в момент, когда SwiftData relationship уже инвалидирован после sync/update/delete. Минимальный app-level mitigation уже реализован: прямое чтение parent relationship убрано из рендера, а UI переведён на отдельный query + value snapshot. В v4.4.0 дополнительно устранён краш в mutation-слое: замена trainings теперь работает через value-type snapshot без мутации итерируемой коллекции.
