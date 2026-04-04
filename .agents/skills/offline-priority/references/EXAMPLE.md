# Примеры офлайн-приоритета

## Модель с флагами синхронизации

```swift
@Model
final class SomeModel {
    // Основные данные
    var id: UUID
    var name: String
    
    // Флаги синхронизации (обязательно!)
    var isSynced: Bool = false
    var shouldDelete: Bool = false
    var lastModified: Date = Date()
}
```

## Сохранение данных

```swift
func saveWorkout(_ workout: Workout) {
    // 1. Сохраняем локально
    workout.isSynced = false
    workout.lastModified = Date()
    modelContext.insert(workout)
    
    // 2. Пытаемся синхронизировать (неблокирущще)
    Task {
        await syncService.syncWorkout(workout)
    }
}
```

## Синхронизация данных

```swift
func syncUnsyncedData() async {
    let unsyncedWorkouts = try? modelContext.fetch(
        FetchDescriptor<Workout>(
            predicate: #Predicate { !$0.isSynced }
        )
    )
    
    await withTaskGroup(of: Void.self) { group in
        for workout in unsyncedWorkouts ?? [] {
            group.addTask {
                do {
                    try await uploadWorkout(workout)
                    workout.isSynced = true
                } catch {
                    // Ошибка синхронизации - продолжаем работу локально
                    logger.error("Ошибка синхронизации: \(error)")
                }
            }
        }
    }
}
```
