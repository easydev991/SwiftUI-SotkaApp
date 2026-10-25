import Foundation
import SwiftData
@testable import SwiftUI_SotkaApp
import Testing

@Suite("User Model Tests")
struct UserTests {
    // MARK: - Private Helper Methods

    /// Создает CustomExercise для тестов
    private func createCustomExercise(id: String, name: String, imageId: Int, user: User) -> CustomExercise {
        CustomExercise(
            id: id,
            name: name,
            imageId: imageId,
            createDate: Date(),
            modifyDate: Date(),
            user: user
        )
    }

    // MARK: - gender Tests

    @Test("gender с неопределенным кодом")
    func genderWithUnspecifiedCode() throws {
        let user = User(id: 1, genderCode: -1)
        let gender = try #require(user.gender)
        #expect(gender == .unspecified)
    }

    @Test("gender с мужским кодом")
    func genderWithMaleCode() throws {
        let user = User(id: 1, genderCode: 0)
        let gender = try #require(user.gender)
        #expect(gender == .male)
    }

    @Test("gender с женским кодом")
    func genderWithFemaleCode() throws {
        let user = User(id: 1, genderCode: 1)
        let gender = try #require(user.gender)
        #expect(gender == .female)
    }

    @Test("gender с nil кодом")
    func genderWithNilCode() {
        let user = User(id: 1, genderCode: nil)
        #expect(user.gender == nil)
    }

    @Test("gender с невалидным кодом")
    func genderWithInvalidCode() {
        let user = User(id: 1, genderCode: 999)
        #expect(user.gender == nil)
    }

    // MARK: - customExerciseCountText Tests

    @Test("customExerciseCountText с пустыми упражнениями")
    func customExerciseCountTextWithEmptyExercises() {
        let user = User(id: 1)
        // По умолчанию customExercises пустой массив
        let countText = user.customExerciseCountText
        #expect(countText == "")
    }

    @Test("customExerciseCountText с одним упражнением")
    func customExerciseCountTextWithOneExercise() {
        let user = User(id: 1)
        let exercise = createCustomExercise(id: "test-1", name: "Test Exercise", imageId: 1, user: user)
        user.customExercises.append(exercise)

        let countText = user.customExerciseCountText
        #expect(countText == "1")
    }

    @Test("customExerciseCountText с несколькими упражнениями")
    func customExerciseCountTextWithMultipleExercises() {
        let user = User(id: 1)
        // Создаем несколько упражнений и добавляем в массив
        let exercise1 = createCustomExercise(id: "test-1", name: "Exercise 1", imageId: 1, user: user)
        let exercise2 = createCustomExercise(id: "test-2", name: "Exercise 2", imageId: 2, user: user)
        let exercise3 = createCustomExercise(id: "test-3", name: "Exercise 3", imageId: 3, user: user)

        user.customExercises.append(exercise1)
        user.customExercises.append(exercise2)
        user.customExercises.append(exercise3)

        let countText = user.customExerciseCountText
        #expect(countText == "3")
    }

    // MARK: - isMaximumsFilled Tests

    @Test("isMaximumsFilled для дня 1-48 с заполненными результатами")
    func isMaximumsFilledForDay1To48WithFilledResults() {
        let user = User(id: 1)
        let progress = UserProgress(id: 1)
        progress.pullUps = 10
        progress.pushUps = 20
        progress.squats = 30
        progress.weight = 70.0
        user.progressResults.append(progress)

        #expect(user.isMaximumsFilled(for: 25))
    }

    @Test("isMaximumsFilled для дня 49 с заполненными результатами")
    func isMaximumsFilledForDay49WithFilledResults() {
        let user = User(id: 1)
        let progress = UserProgress(id: 49)
        progress.pullUps = 10
        progress.pushUps = 20
        progress.squats = 30
        progress.weight = 70.0
        user.progressResults.append(progress)

        #expect(user.isMaximumsFilled(for: 49))
    }

    @Test("isMaximumsFilled для дня 50-99 с заполненными результатами")
    func isMaximumsFilledForDay50To99WithFilledResults() {
        let user = User(id: 1)
        let progress = UserProgress(id: 49)
        progress.pullUps = 15
        progress.pushUps = 25
        progress.squats = 35
        progress.weight = 75.0
        user.progressResults.append(progress)

        #expect(user.isMaximumsFilled(for: 75))
    }

    @Test("isMaximumsFilled для дня 100+ с заполненными результатами")
    func isMaximumsFilledForDay100PlusWithFilledResults() {
        let user = User(id: 1)
        let progress = UserProgress(id: 100)
        progress.pullUps = 20
        progress.pushUps = 30
        progress.squats = 40
        progress.weight = 80.0
        user.progressResults.append(progress)

        #expect(user.isMaximumsFilled(for: 105))
    }

    @Test("isMaximumsFilled без данных")
    func isMaximumsFilledWithoutData() {
        let user = User(id: 1)

        #expect(!user.isMaximumsFilled(for: 25))
    }

    @Test("isMaximumsFilled с незаполненными результатами")
    func isMaximumsFilledWithUnfilledResults() {
        let user = User(id: 1)
        let progress = UserProgress(id: 1)
        progress.pullUps = 10
        progress.pushUps = nil
        progress.squats = 30
        progress.weight = 70.0
        user.progressResults.append(progress)

        #expect(!user.isMaximumsFilled(for: 25))
    }

    @Test(arguments: [
        (1, 1, true),
        (25, 1, true),
        (48, 1, true),
        (49, 49, true),
        (50, 49, true),
        (75, 49, true),
        (99, 49, true),
        (100, 100, true),
        (105, 100, true),
        (1, 49, false),
        (25, 49, false),
        (49, 1, false),
        (50, 1, false),
        (75, 1, false),
        (100, 1, false),
        (100, 49, false)
    ])
    func isMaximumsFilledParameterized(
        currentDay: Int,
        progressDay: Int,
        expected: Bool
    ) {
        let user = User(id: 1)
        let progress = UserProgress(id: progressDay)
        progress.pullUps = 10
        progress.pushUps = 20
        progress.squats = 30
        progress.weight = 70.0
        user.progressResults.append(progress)

        #expect(user.isMaximumsFilled(for: currentDay) == expected)
    }

    // MARK: - isOfflineOnly Tests

    @Test("isOfflineOnly true для offline-user")
    func isOfflineOnlyTrueForOfflineUser() {
        let user = User(id: -1, userName: "offline-user")
        #expect(user.isOfflineOnly)
    }

    @Test("isOfflineOnly false для обычного userName")
    func isOfflineOnlyFalseForRegularUser() {
        let user = User(id: 1, userName: "john")
        #expect(!user.isOfflineOnly)
    }

    @Test("isOfflineOnly false для nil userName")
    func isOfflineOnlyFalseForNilUserName() {
        let user = User(id: 1, userName: nil)
        #expect(!user.isOfflineOnly)
    }

    // MARK: - init(offlineWithGenderCode:) Tests

    @Test("Офлайн-инициализатор устанавливает id -1 и userName offline-user")
    func offlineInitSetsIdAndUserName() {
        let user = User(offlineWithGenderCode: Gender.male.code)
        #expect(user.id == -1)
        #expect(user.userName == "offline-user")
        #expect(user.isOfflineOnly)
    }

    @Test("Офлайн-инициализатор устанавливает genderCode для каждого пола")
    func offlineInitSetsGenderCodeForEachGender() {
        for gender in Gender.allCases {
            let user = User(offlineWithGenderCode: gender.code)
            #expect(user.genderCode == gender.code)
            #expect(user.gender == gender)
        }
    }

    // MARK: - activitiesByDay Tests

    @Test("activitiesByDay возвращает пустой словарь для пользователя без активностей")
    func activitiesByDayWithEmptyActivities() {
        let user = User(id: 1)
        let activitiesByDay = user.activitiesByDay
        #expect(activitiesByDay.isEmpty)
    }

    @Test("activitiesByDay возвращает словарь с одной активностью")
    @MainActor
    func activitiesByDayWithSingleActivity() throws {
        let container = try ModelContainer(
            for: User.self,
            DayActivity.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = container.mainContext

        let user = User(id: 1)
        context.insert(user)

        let dayActivity = DayActivity(day: 5, createDate: Date(), modifyDate: Date(), user: user)
        context.insert(dayActivity)
        try context.save()

        let activitiesByDay = user.activitiesByDay
        #expect(activitiesByDay.count == 1)
        let activity = try #require(activitiesByDay[5])
        #expect(activity.day == 5)
    }

    @Test("activitiesByDay возвращает словарь с несколькими активностями")
    @MainActor
    func activitiesByDayWithMultipleActivities() throws {
        let container = try ModelContainer(
            for: User.self,
            DayActivity.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = container.mainContext

        let user = User(id: 1)
        context.insert(user)

        let dayActivity1 = DayActivity(day: 1, createDate: Date(), modifyDate: Date(), user: user)
        let dayActivity2 = DayActivity(day: 10, createDate: Date(), modifyDate: Date(), user: user)
        let dayActivity3 = DayActivity(day: 50, createDate: Date(), modifyDate: Date(), user: user)
        context.insert(dayActivity1)
        context.insert(dayActivity2)
        context.insert(dayActivity3)
        try context.save()

        let activitiesByDay = user.activitiesByDay
        #expect(activitiesByDay.count == 3)
        let activity1 = try #require(activitiesByDay[1])
        let activity2 = try #require(activitiesByDay[10])
        let activity3 = try #require(activitiesByDay[50])
        #expect(activity1.day == 1)
        #expect(activity2.day == 10)
        #expect(activity3.day == 50)
    }

    @Test("activitiesByDay оставляет одну активность при дубликатах дней")
    @MainActor
    func activitiesByDayWithDuplicateDays() throws {
        let container = try ModelContainer(
            for: User.self,
            DayActivity.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = container.mainContext

        let user = User(id: 1)
        context.insert(user)

        let dayActivity1 = DayActivity(day: 5, count: 10, createDate: Date(), modifyDate: Date(), user: user)
        let dayActivity2 = DayActivity(day: 5, count: 20, createDate: Date(), modifyDate: Date(), user: user)
        context.insert(dayActivity1)
        context.insert(dayActivity2)
        try context.save()

        let activitiesByDay = user.activitiesByDay
        #expect(activitiesByDay.count == 1)
        let activity = try #require(activitiesByDay[5])
        #expect(activity.day == 5)
        let count = try #require(activity.count)
        #expect(count == 10 || count == 20)
    }

    @Test("activitiesByDay исключает активности с shouldDelete = true")
    @MainActor
    func activitiesByDayExcludesDeletedActivities() throws {
        let container = try ModelContainer(
            for: User.self,
            DayActivity.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = container.mainContext

        let user = User(id: 1)
        context.insert(user)

        let activeActivity = DayActivity(day: 1, createDate: Date(), modifyDate: Date(), user: user)
        activeActivity.shouldDelete = false

        let deletedActivity = DayActivity(day: 2, createDate: Date(), modifyDate: Date(), user: user)
        deletedActivity.shouldDelete = true

        context.insert(activeActivity)
        context.insert(deletedActivity)
        try context.save()

        let activitiesByDay = user.activitiesByDay
        #expect(activitiesByDay.count == 1)
        let activity = try #require(activitiesByDay[1])
        #expect(activity.day == 1)
        #expect(!activity.shouldDelete)
        #expect(activitiesByDay[2] == nil)
    }
}
