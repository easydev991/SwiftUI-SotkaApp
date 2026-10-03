# Примеры unit-тестов

Все сниппеты — из реальных тестов проекта. Образцы-файлы: `ReviewManagerTests.swift`, `ReviewStorageTests.swift`, `JournalPagePersistenceTests.swift`, `MockUserDefaults.swift`.

## Базовый синтаксис

```swift
// ReviewStorageTests.swift
@Suite("Тесты ReviewStorage — persistence attempts через UserDefaults")
@MainActor
struct ReviewStorageTests {
    @Test("markAttempted обновляет lastReviewRequestAttemptDate")
    func markAttemptedUpdatesDate() throws {
        let storage = ReviewStorage(userDefaults: try MockUserDefaults.create())
        let before = Date()
        storage.markAttempted(.first)
        let after = Date()
        let date = try #require(storage.lastReviewRequestAttemptDate())
        #expect(date >= before && date <= after)
    }
}
```

## Изоляция SwiftData — in-memory ModelContainer

```swift
// ReviewManagerTests.swift
@MainActor
@Suite("Тесты ReviewManager eligibility и координации")
struct ReviewManagerTests {
    private func makeContainer() throws -> ModelContainer {
        try ModelContainer(
            for: User.self,
            DayActivity.self,
            DayActivityTraining.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
    }
}
```

## Изоляция UserDefaults

```swift
// JournalPagePersistenceTests.swift
@Test("Clamp в 0, если сохранённая страница выходит за pageCount")
func restoresAndClampsOutOfRangePageToZero() throws {
    let defaults = try MockUserDefaults.create()
    defaults.set(99, forKey: JournalPagePersistence.storageKey)
    #expect(JournalPagePersistence.restoreSelectedPage(defaults: defaults, totalDays: 100) == 0)
}
```

## SUT-фабрика с моками (makeSUT)

```swift
// ReviewManagerTests.swift — конструктор SUT одной строкой в каждом тесте
private func makeSUT(
    attemptedMilestones: [ReviewMilestone] = [],
    completedWorkoutCount: Int = 0
) throws -> (ReviewManager, ReviewStorage, WorkoutCompletionsCounter, ModelContainer) {
    let userDefaults = try MockUserDefaults.create()
    userDefaults.set(attemptedMilestones.map(\.rawValue), forKey: ReviewStorage.attemptedMilestones)
    let store = ReviewStorage(userDefaults: userDefaults)
    let container = try makeContainer()
    try seedActivities(count: completedWorkoutCount, in: container)
    let counter = WorkoutCompletionsCounter(modelContainer: container)
    let manager = ReviewManager(
        attemptStore: store,
        completionsCounter: counter,
        currentUserIdProvider: { 1 }
    )
    return (manager, store, counter, container)
}

@Test("Выставляет pendingRequest при достижении milestone 1")
func setsPendingOnFirstMilestone() async throws {
    let (manager, _, _, _) = try makeSUT(completedWorkoutCount: 1)
    await manager.workoutCompletedSuccessfully(hadRecentError: false)
    let pending = try #require(manager.pendingRequest)
    #expect(pending == .first)
}
```

## Параметризованный тест

```swift
// AddCustomExerciseModelTests.swift
@Test("Нельзя сохранить с пустым именем", arguments: ["", "   ", "  \n  "])
func cannotSaveWithBlankName(name: String) { ... }

// InfopostSectionTests.swift
@Test("Должен возвращать preparation для специальных файлов", arguments: ["aims", "organiz", "d0-women"])
func returnsPreparationForSpecialFiles(fileName: String) { ... }
```

В `arguments:` — только вводные данные, ожидаемый результат внутри тела теста.

## Проверка конкретной ошибки

```swift
@Test("Должен выбрасывать ошибку для несуществующего пользователя")
func testUserNotFound() {
    #expect(throws: MyServiceError.userNotFound) {
        try service.someMethod()
    }
}
```

## Комментарии: плохо vs хорошо

```swift
// ПЛОХО — комментарий дублирует #expect
@Test
func testUserValidation() {
    let result = service.validateUser(email: "test@example.com", age: 17)
    // Ожидаем false из-за возраста
    #expect(!result)
}

// ХОРОШО — русское описание в @Test, тело самодокументируемо
@Test("Должен отклонять пользователей младше 18 лет")
func testUserValidation() {
    let result = service.validateUser(email: "test@example.com", age: 17)
    #expect(!result)
}
```

## Async + throws

```swift
// ReviewManagerTests.swift — await есть → async; #require есть → throws
@Test("Не выставляет pendingRequest для count=0")
func noPendingForZeroCount() async throws {
    let (manager, _, _, _) = try makeSUT(completedWorkoutCount: 0)
    await manager.workoutCompletedSuccessfully(hadRecentError: false)
    #expect(manager.pendingRequest == nil)
}
```
