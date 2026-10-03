# Примеры офлайн-хранения

## Модель без sync-флагов

```swift
@Model
final class SomeModel {
    var id: UUID
    var name: String
    // Только данные. Флаги isSynced/shouldDelete/lastModified — deprecated,
    // на новые модели не переносим.
}
```

## Сохранение данных

```swift
func saveWorkout(_ workout: Workout, context: ModelContext) {
    context.insert(workout)
    try? context.save() // единственный «бэкенд» — локальный SwiftData
}
```

## Очистка при логауте (single-user)

```swift
func logout(context: ModelContext) {
    try? context.delete(model: Workout.self) // вся сущность, а не «текущего пользователя»
    try? context.save()
    AuthHelper.logout() // сброс isAuthorized в UserDefaults
}
```
