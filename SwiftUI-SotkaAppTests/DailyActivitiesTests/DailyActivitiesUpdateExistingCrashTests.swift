import Foundation
import SwiftData
@testable import SwiftUI_SotkaApp
import SWUtils
import Testing

extension DailyActivitiesServiceTests {
    @Test("updateExistingActivity не падает при замене trainings (краш-регрессия)")
    func updateExistingActivityDoesNotCrashWhenReplacingTrainings() throws {
        let mockClient = MockDaysClient()
        let service = DailyActivitiesService(client: mockClient)
        let container = try ModelContainer(
            for: DayActivity.self,
            DayActivityTraining.self,
            User.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = container.mainContext

        let user = User(id: 1, userName: "testuser", fullName: "Test User", email: "test@example.com")
        context.insert(user)
        try context.save()

        let existing = DayActivity(
            day: 5,
            activityTypeRaw: DayActivityType.workout.rawValue,
            count: 10,
            plannedCount: 8,
            executeTypeRaw: ExerciseExecutionType.cycles.rawValue,
            trainingTypeRaw: nil,
            duration: nil,
            comment: nil,
            createDate: .now,
            modifyDate: .now,
            user: user
        )
        let oldTraining1 = DayActivityTraining(count: 5, typeId: ExerciseType.pullups.rawValue, sortOrder: 0, dayActivity: existing)
        let oldTraining2 = DayActivityTraining(count: 8, typeId: ExerciseType.pushups.rawValue, sortOrder: 1, dayActivity: existing)
        existing.trainings = [oldTraining1, oldTraining2]
        context.insert(existing)
        try context.save()

        let new = DayActivity(
            day: 5,
            activityTypeRaw: DayActivityType.workout.rawValue,
            count: 12,
            plannedCount: 8,
            executeTypeRaw: ExerciseExecutionType.cycles.rawValue,
            trainingTypeRaw: nil,
            duration: nil,
            comment: "updated",
            createDate: .now,
            modifyDate: .now
        )
        let newTraining1 = DayActivityTraining(count: 6, typeId: ExerciseType.pullups.rawValue, sortOrder: 0, dayActivity: new)
        let newTraining2 = DayActivityTraining(count: 10, typeId: ExerciseType.pushups.rawValue, sortOrder: 1, dayActivity: new)
        let newTraining3 = DayActivityTraining(count: 15, typeId: ExerciseType.squats.rawValue, sortOrder: 2, dayActivity: new)
        new.trainings = [newTraining1, newTraining2, newTraining3]

        service.createDailyActivity(new, context: context)

        let saved = try #require(context.fetch(FetchDescriptor<DayActivity>()).first)
        #expect(saved.day == 5)
        let count = try #require(saved.count)
        #expect(count == 12)
        let comment = try #require(saved.comment)
        #expect(comment == "updated")
        #expect(saved.trainings.count == 3)

        let sorted = saved.trainings.sorted
        let sortOrder0 = try #require(sorted.first?.sortOrder)
        #expect(sortOrder0 == 0)
    }

    @Test("Два последовательных saveTrainingAsPassed через ViewModel не падают (краш-регрессия)")
    @MainActor
    func twoSequentialSavesViaViewModelDoNotCrash() throws {
        let container = try ModelContainer(
            for: DayActivity.self,
            DayActivityTraining.self,
            User.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = container.mainContext
        let user = User(id: 1)
        context.insert(user)
        try context.save()

        let mockClient = MockDaysClient()
        let activitiesService = DailyActivitiesService(client: mockClient)

        let viewModel = WorkoutPreviewViewModel()
        viewModel.dayNumber = 5
        viewModel.selectedExecutionType = .cycles
        viewModel.count = 10
        viewModel.plannedCount = 8
        viewModel.trainings = [
            WorkoutPreviewTraining(count: 5, typeId: ExerciseType.pullups.rawValue, sortOrder: 0)
        ]

        viewModel.saveTrainingAsPassed(activitiesService: activitiesService, modelContext: context)

        let firstSave = try #require(context.fetch(FetchDescriptor<DayActivity>()).first)
        #expect(firstSave.day == 5)

        let viewModel2 = WorkoutPreviewViewModel()
        viewModel2.dayNumber = 5
        viewModel2.selectedExecutionType = .cycles
        viewModel2.count = 12
        viewModel2.plannedCount = 8
        viewModel2.trainings = [
            WorkoutPreviewTraining(count: 6, typeId: ExerciseType.pullups.rawValue, sortOrder: 0),
            WorkoutPreviewTraining(count: 10, typeId: ExerciseType.pushups.rawValue, sortOrder: 1)
        ]

        viewModel2.saveTrainingAsPassed(activitiesService: activitiesService, modelContext: context)

        let secondSave = try #require(context.fetch(FetchDescriptor<DayActivity>()).first)
        #expect(secondSave.day == 5)
        let count = try #require(secondSave.count)
        #expect(count == 12)
        #expect(secondSave.trainings.count == 2)
    }

    @Test("После обновления старые trainings заменены, новые имеют корректный sortOrder")
    func trainingsReplacedWithCorrectSortOrderAfterUpdate() throws {
        let mockClient = MockDaysClient()
        let service = DailyActivitiesService(client: mockClient)
        let container = try ModelContainer(
            for: DayActivity.self,
            DayActivityTraining.self,
            User.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = container.mainContext

        let user = User(id: 1, userName: "testuser", fullName: "Test User", email: "test@example.com")
        context.insert(user)
        try context.save()

        let existing = DayActivity(
            day: 10,
            activityTypeRaw: DayActivityType.workout.rawValue,
            count: 5,
            plannedCount: 8,
            executeTypeRaw: ExerciseExecutionType.cycles.rawValue,
            trainingTypeRaw: nil,
            duration: nil,
            comment: nil,
            createDate: .now,
            modifyDate: .now,
            user: user
        )
        let oldTraining1 = DayActivityTraining(count: 3, typeId: ExerciseType.pullups.rawValue, sortOrder: 0, dayActivity: existing)
        let oldTraining2 = DayActivityTraining(count: 5, typeId: ExerciseType.pushups.rawValue, sortOrder: 1, dayActivity: existing)
        existing.trainings = [oldTraining1, oldTraining2]
        context.insert(existing)
        try context.save()

        let new = DayActivity(
            day: 10,
            activityTypeRaw: DayActivityType.workout.rawValue,
            count: 7,
            plannedCount: 8,
            executeTypeRaw: ExerciseExecutionType.cycles.rawValue,
            trainingTypeRaw: nil,
            duration: nil,
            comment: nil,
            createDate: .now,
            modifyDate: .now
        )
        let newTraining1 = DayActivityTraining(count: 10, typeId: ExerciseType.squats.rawValue, sortOrder: 0, dayActivity: new)
        let newTraining2 = DayActivityTraining(count: 12, typeId: ExerciseType.pullups.rawValue, sortOrder: 1, dayActivity: new)
        let newTraining3 = DayActivityTraining(count: 8, typeId: ExerciseType.pushups.rawValue, sortOrder: 2, dayActivity: new)
        new.trainings = [newTraining1, newTraining2, newTraining3]

        service.createDailyActivity(new, context: context)

        let updated = try #require(context.fetch(FetchDescriptor<DayActivity>()).first)
        #expect(updated.trainings.count == 3)

        let sorted = updated.trainings.sorted
        #expect(sorted.count == 3)

        let squatsTraining = try #require(sorted.first { $0.typeId == ExerciseType.squats.rawValue })
        #expect(squatsTraining.count == 10)
        let sortOrder0 = try #require(squatsTraining.sortOrder)
        #expect(sortOrder0 == 0)

        let pullupsTraining = try #require(sorted.first { $0.typeId == ExerciseType.pullups.rawValue })
        #expect(pullupsTraining.count == 12)
        let sortOrder1 = try #require(pullupsTraining.sortOrder)
        #expect(sortOrder1 == 1)

        let pushupsTraining = try #require(sorted.first { $0.typeId == ExerciseType.pushups.rawValue })
        #expect(pushupsTraining.count == 8)
        let sortOrder2 = try #require(pushupsTraining.sortOrder)
        #expect(sortOrder2 == 2)

        let allTypeIds = Set(updated.trainings.map(\.typeId))
        #expect(!allTypeIds.contains(nil))
    }

    @Test("После обновления старые trainings удалены из контекста, не orphan'ены")
    func oldTrainingsRemovedFromContextAfterUpdate() throws {
        let mockClient = MockDaysClient()
        let service = DailyActivitiesService(client: mockClient)
        let container = try ModelContainer(
            for: DayActivity.self,
            DayActivityTraining.self,
            User.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = container.mainContext

        let user = User(id: 1, userName: "testuser", fullName: "Test User", email: "test@example.com")
        context.insert(user)
        try context.save()

        let existing = DayActivity(
            day: 7,
            activityTypeRaw: DayActivityType.workout.rawValue,
            count: 5,
            plannedCount: 8,
            executeTypeRaw: ExerciseExecutionType.cycles.rawValue,
            trainingTypeRaw: nil,
            duration: nil,
            comment: nil,
            createDate: .now,
            modifyDate: .now,
            user: user
        )
        let oldTraining1 = DayActivityTraining(count: 3, typeId: ExerciseType.pullups.rawValue, sortOrder: 0, dayActivity: existing)
        let oldTraining2 = DayActivityTraining(count: 5, typeId: ExerciseType.pushups.rawValue, sortOrder: 1, dayActivity: existing)
        existing.trainings = [oldTraining1, oldTraining2]
        context.insert(existing)
        try context.save()

        let allTrainingsBefore = try context.fetch(FetchDescriptor<DayActivityTraining>())
        #expect(allTrainingsBefore.count == 2)

        let new = DayActivity(
            day: 7,
            activityTypeRaw: DayActivityType.workout.rawValue,
            count: 10,
            plannedCount: 8,
            executeTypeRaw: ExerciseExecutionType.cycles.rawValue,
            trainingTypeRaw: nil,
            duration: nil,
            comment: nil,
            createDate: .now,
            modifyDate: .now
        )
        let newTraining = DayActivityTraining(count: 10, typeId: ExerciseType.squats.rawValue, sortOrder: 0, dayActivity: new)
        new.trainings = [newTraining]

        service.createDailyActivity(new, context: context)

        let updated = try #require(context.fetch(FetchDescriptor<DayActivity>()).first)
        #expect(updated.trainings.count == 1)
        #expect(updated.trainings.first?.typeId == ExerciseType.squats.rawValue)

        let allTrainingsAfter = try context.fetch(FetchDescriptor<DayActivityTraining>())
        #expect(
            allTrainingsAfter.count == 1,
            "Старые trainings должны быть удалены из контекста, а не orphan'ены. Фактически: \(allTrainingsAfter.count)"
        )

        let orphaned = allTrainingsAfter.filter { $0.dayActivity == nil }
        #expect(orphaned.isEmpty, "Не должно быть orphaned trainings (dayActivity == nil). Найдено: \(orphaned.count)")
    }

    @Test("Идемпотентность: 3+ последовательных сохранения одного дня без краша и дублирования")
    func threeSequentialSavesAreIdempotent() throws {
        let mockClient = MockDaysClient()
        let service = DailyActivitiesService(client: mockClient)
        let container = try ModelContainer(
            for: DayActivity.self,
            DayActivityTraining.self,
            User.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = container.mainContext

        let user = User(id: 1, userName: "testuser", fullName: "Test User", email: "test@example.com")
        context.insert(user)
        try context.save()

        let saves: [(count: Int, trainings: [(count: Int, typeId: Int?, sortOrder: Int?)])] = [
            (count: 5, trainings: [
                (count: 3, typeId: ExerciseType.pullups.rawValue, sortOrder: 0)
            ]),
            (count: 8, trainings: [
                (count: 6, typeId: ExerciseType.pullups.rawValue, sortOrder: 0),
                (count: 10, typeId: ExerciseType.pushups.rawValue, sortOrder: 1)
            ]),
            (count: 12, trainings: [
                (count: 7, typeId: ExerciseType.pullups.rawValue, sortOrder: 0),
                (count: 11, typeId: ExerciseType.pushups.rawValue, sortOrder: 1),
                (count: 15, typeId: ExerciseType.squats.rawValue, sortOrder: 2)
            ])
        ]

        for save in saves {
            let new = DayActivity(
                day: 5,
                activityTypeRaw: DayActivityType.workout.rawValue,
                count: save.count,
                plannedCount: 8,
                executeTypeRaw: ExerciseExecutionType.cycles.rawValue,
                trainingTypeRaw: nil,
                duration: nil,
                comment: nil,
                createDate: .now,
                modifyDate: .now
            )
            new.trainings = save.trainings.map { t in
                DayActivityTraining(count: t.count, typeId: t.typeId, sortOrder: t.sortOrder, dayActivity: new)
            }
            service.createDailyActivity(new, context: context)
        }

        let allActivities = try context.fetch(FetchDescriptor<DayActivity>())
        #expect(allActivities.count == 1, "Должна быть ровно 1 DayActivity, фактически: \(allActivities.count)")

        let saved = try #require(allActivities.first)
        let count = try #require(saved.count)
        #expect(count == 12)
        #expect(saved.trainings.count == 3, "Должно быть 3 training, фактически: \(saved.trainings.count)")

        let allTrainings = try context.fetch(FetchDescriptor<DayActivityTraining>())
        #expect(allTrainings.count == 3, "В контексте должно быть ровно 3 DayActivityTraining, фактически: \(allTrainings.count)")

        let orphaned = allTrainings.filter { $0.dayActivity == nil }
        #expect(orphaned.isEmpty, "Не должно быть orphaned trainings. Найдено: \(orphaned.count)")
    }

    @Test("Стабильная повторная выборка: после context.save() повторный fetch безопасен")
    func stableReFetchAfterContextSave() throws {
        let mockClient = MockDaysClient()
        let service = DailyActivitiesService(client: mockClient)
        let container = try ModelContainer(
            for: DayActivity.self,
            DayActivityTraining.self,
            User.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = container.mainContext

        let user = User(id: 1, userName: "testuser", fullName: "Test User", email: "test@example.com")
        context.insert(user)
        try context.save()

        let existing = DayActivity(
            day: 3,
            activityTypeRaw: DayActivityType.workout.rawValue,
            count: 5,
            plannedCount: 8,
            executeTypeRaw: ExerciseExecutionType.cycles.rawValue,
            trainingTypeRaw: nil,
            duration: nil,
            comment: nil,
            createDate: .now,
            modifyDate: .now,
            user: user
        )
        let oldTraining = DayActivityTraining(count: 3, typeId: ExerciseType.pullups.rawValue, sortOrder: 0, dayActivity: existing)
        existing.trainings = [oldTraining]
        context.insert(existing)
        try context.save()

        let new = DayActivity(
            day: 3,
            activityTypeRaw: DayActivityType.workout.rawValue,
            count: 10,
            plannedCount: 8,
            executeTypeRaw: ExerciseExecutionType.cycles.rawValue,
            trainingTypeRaw: nil,
            duration: nil,
            comment: "refreshed",
            createDate: .now,
            modifyDate: .now
        )
        let newTraining = DayActivityTraining(count: 10, typeId: ExerciseType.squats.rawValue, sortOrder: 0, dayActivity: new)
        new.trainings = [newTraining]

        service.createDailyActivity(new, context: context)

        try context.save()

        let firstFetch = try context.fetch(FetchDescriptor<DayActivity>())
        let first = try #require(firstFetch.first)
        #expect(first.trainings.count == 1)
        let comment1 = try #require(first.comment)
        #expect(comment1 == "refreshed")

        let secondFetch = try context.fetch(FetchDescriptor<DayActivity>())
        let second = try #require(secondFetch.first)
        #expect(second.trainings.count == 1)
        let comment2 = try #require(second.comment)
        #expect(comment2 == "refreshed")

        let sorted1 = first.trainings.sorted
        let sorted2 = second.trainings.sorted
        #expect(sorted1.count == sorted2.count)
        let sortOrder1 = try #require(sorted1.first?.sortOrder)
        let sortOrder2 = try #require(sorted2.first?.sortOrder)
        #expect(sortOrder1 == sortOrder2)
        let typeId1 = try #require(sorted1.first?.typeId)
        let typeId2 = try #require(sorted2.first?.typeId)
        #expect(typeId1 == typeId2)

        let allTrainings = try context.fetch(FetchDescriptor<DayActivityTraining>())
        #expect(allTrainings.count == 1, "После save в контексте должна быть ровно 1 training. Фактически: \(allTrainings.count)")
    }
}
