import Foundation
import SwiftData
@testable import SwiftUI_SotkaApp
import Testing

extension WorkoutScreenViewModelTests {
    @Suite("Тесты для вспомогательных методов")
    struct HelperMethodsTests {
        @Test("Должен возвращать состояние для конкретного этапа")
        @MainActor
        func getStepState() throws {
            let viewModel = WorkoutScreenViewModel()
            let trainings = [
                WorkoutPreviewTraining(count: 5, typeId: 0)
            ]
            let appSettings = AppSettings(userDefaults: UserDefaults(suiteName: "test")!)

            viewModel.setupWorkoutData(
                dayNumber: 1,
                executionType: .cycles,
                trainings: trainings,
                plannedCount: 4,
                restTime: 60
            )

            let warmUpState = viewModel.getStepState(for: .warmUp)
            #expect(warmUpState == .active)

            let coolDownState = viewModel.getStepState(for: .coolDown)
            #expect(coolDownState == .inactive)

            viewModel.completeCurrentStep(appSettings: appSettings)

            let firstCycleState = viewModel.getStepState(for: .exercise(.cycles, number: 1))
            #expect(firstCycleState == .active)
        }

        @Test("Должен возвращать текущий активный этап")
        @MainActor
        func currentStep() throws {
            let viewModel = WorkoutScreenViewModel()
            let trainings = [
                WorkoutPreviewTraining(count: 5, typeId: 0)
            ]
            let appSettings = AppSettings(userDefaults: UserDefaults(suiteName: "test")!)

            viewModel.setupWorkoutData(
                dayNumber: 1,
                executionType: .cycles,
                trainings: trainings,
                plannedCount: 4,
                restTime: 60
            )

            let currentStep = try #require(viewModel.currentStep)
            #expect(currentStep.id == WorkoutStep.warmUp.id)

            viewModel.completeCurrentStep(appSettings: appSettings)

            let nextStep = try #require(viewModel.currentStep)
            if case let .exercise(.cycles, number) = nextStep {
                #expect(number == 1)
            } else {
                Issue.record("Ожидался этап с типом .exercise(.cycles, number: 1)")
            }

            let firstCycleState = viewModel.getStepState(for: .exercise(.cycles, number: 1))
            #expect(firstCycleState == .active)
        }

        @Test("Должен возвращать только этапы с типом .cycles")
        @MainActor
        func getCycleSteps() throws {
            let viewModel = WorkoutScreenViewModel()
            let trainings = [
                WorkoutPreviewTraining(count: 5, typeId: 0)
            ]

            viewModel.setupWorkoutData(
                dayNumber: 1,
                executionType: .cycles,
                trainings: trainings,
                plannedCount: 4,
                restTime: 60
            )

            let cycleSteps = viewModel.getCycleSteps()
            #expect(cycleSteps.count == 4)

            for stepState in cycleSteps {
                if case let .exercise(executionType, number) = stepState.step {
                    #expect(executionType == .cycles)
                    #expect(number >= 1)
                    #expect(number <= 4)
                } else {
                    Issue.record("Ожидался этап с типом .exercise(.cycles, number: ...)")
                }
            }

            let creator = WorkoutProgramCreator(day: 92, executionType: .turbo)
            viewModel.setupWorkoutData(
                dayNumber: 92,
                executionType: .turbo,
                trainings: creator.trainings,
                plannedCount: creator.plannedCount,
                restTime: 60
            )

            let turboDaySteps = viewModel.getCycleSteps()
            #expect(turboDaySteps.count == 40)

            for stepState in turboDaySteps {
                if case let .exercise(executionType, number) = stepState.step {
                    #expect(executionType == .cycles)
                    #expect(number >= 1)
                    #expect(number <= 40)
                } else {
                    Issue.record("Ожидался этап с типом .exercise(.cycles, number: ...)")
                }
            }
        }

        @Test("Должен возвращать этапы подходов для конкретного упражнения")
        @MainActor
        func getExerciseSteps() throws {
            let viewModel = WorkoutScreenViewModel()
            let trainings = [
                WorkoutPreviewTraining(count: 5, typeId: 0),
                WorkoutPreviewTraining(count: 10, typeId: 2),
                WorkoutPreviewTraining(count: 15, typeId: 3),
                WorkoutPreviewTraining(count: 20, typeId: 4)
            ]

            viewModel.setupWorkoutData(
                dayNumber: 1,
                executionType: .sets,
                trainings: trainings,
                plannedCount: 6,
                restTime: 60
            )

            let firstTrainingId = trainings[0].id
            let firstExerciseSteps = viewModel.getExerciseSteps(for: firstTrainingId)
            #expect(firstExerciseSteps.count == 6)

            for stepState in firstExerciseSteps {
                if case let .exercise(executionType, number) = stepState.step {
                    #expect(executionType == .sets)
                    #expect(number >= 1)
                    #expect(number <= 6)
                } else {
                    Issue.record("Ожидался этап с типом .exercise(.sets, number: ...)")
                }
            }

            let secondTrainingId = trainings[1].id
            let secondExerciseSteps = viewModel.getExerciseSteps(for: secondTrainingId)
            #expect(secondExerciseSteps.count == 6)

            for stepState in secondExerciseSteps {
                if case let .exercise(executionType, number) = stepState.step {
                    #expect(executionType == .sets)
                    #expect(number >= 1)
                    #expect(number <= 6)
                } else {
                    Issue.record("Ожидался этап с типом .exercise(.sets, number: ...)")
                }
            }

            #expect(firstExerciseSteps.count == secondExerciseSteps.count)
            let firstTrainingIndex = trainings.firstIndex { $0.id == firstTrainingId }
            let secondTrainingIndex = trainings.firstIndex { $0.id == secondTrainingId }
            let firstIndex = try #require(firstTrainingIndex)
            let secondIndex = try #require(secondTrainingIndex)
            #expect(firstIndex < secondIndex)

            let plannedCount = try #require(viewModel.plannedCount)
            let firstStartIndex = 1 + firstIndex * plannedCount
            let secondStartIndex = 1 + secondIndex * plannedCount
            #expect(secondStartIndex - firstStartIndex >= plannedCount)

            viewModel.setupWorkoutData(
                dayNumber: 1,
                executionType: .cycles,
                trainings: trainings,
                plannedCount: 4,
                restTime: 60
            )

            let emptySteps = viewModel.getExerciseSteps(for: firstTrainingId)
            #expect(emptySteps.isEmpty)

            let nonExistentId = "non-existent-id"
            let nonExistentSteps = viewModel.getExerciseSteps(for: nonExistentId)
            #expect(nonExistentSteps.isEmpty)
        }

        @Test("Должен возвращать название упражнения с количеством в правильном формате")
        @MainActor
        func getExerciseTitleWithCount() throws {
            let viewModel = WorkoutScreenViewModel()
            let modelConfiguration = ModelConfiguration(isStoredInMemoryOnly: true)
            let modelContainer = try ModelContainer(
                for: User.self,
                CustomExercise.self,
                configurations: modelConfiguration
            )
            let context = modelContainer.mainContext

            let training1 = WorkoutPreviewTraining(count: 5, typeId: ExerciseType.pullups.rawValue)
            let title1 = viewModel.getExerciseTitleWithCount(for: training1, modelContext: context)
            #expect(title1 == "Подтягивания x 5")

            let training2 = WorkoutPreviewTraining(count: 20, typeId: ExerciseType.squats.rawValue)
            let title2 = viewModel.getExerciseTitleWithCount(for: training2, modelContext: context)
            #expect(title2 == "Приседания x 20")

            let training3 = WorkoutPreviewTraining(count: nil, typeId: ExerciseType.pullups.rawValue)
            let title3 = viewModel.getExerciseTitleWithCount(for: training3, modelContext: context)
            #expect(title3 == "Подтягивания")

            let user = User(id: 1, userName: "testuser", fullName: "Test User", email: "test@example.com")
            context.insert(user)

            let customExercise = CustomExercise(
                id: "custom-1",
                name: "Кастомное упражнение",
                imageId: 1,
                createDate: .now,
                modifyDate: .now,
                user: user
            )
            context.insert(customExercise)
            try context.save()

            let training4 = WorkoutPreviewTraining(count: 10, customTypeId: "custom-1")
            let title4 = viewModel.getExerciseTitleWithCount(for: training4, modelContext: context)
            #expect(title4 == "Кастомное упражнение x 10")

            let training5 = WorkoutPreviewTraining(count: nil, customTypeId: "custom-1")
            let title5 = viewModel.getExerciseTitleWithCount(for: training5, modelContext: context)
            #expect(title5 == "Кастомное упражнение")
        }

        @Test("Должен возвращать только название упражнения без количества")
        @MainActor
        func getExerciseTitle() throws {
            let viewModel = WorkoutScreenViewModel()
            let modelConfiguration = ModelConfiguration(isStoredInMemoryOnly: true)
            let modelContainer = try ModelContainer(
                for: User.self,
                CustomExercise.self,
                configurations: modelConfiguration
            )
            let context = modelContainer.mainContext

            let training1 = WorkoutPreviewTraining(count: 5, typeId: ExerciseType.pullups.rawValue)
            let title1 = viewModel.getExerciseTitle(for: training1, modelContext: context)
            #expect(title1 == "Подтягивания")

            let training2 = WorkoutPreviewTraining(count: 20, typeId: ExerciseType.squats.rawValue)
            let title2 = viewModel.getExerciseTitle(for: training2, modelContext: context)
            #expect(title2 == "Приседания")

            let training3 = WorkoutPreviewTraining(count: nil, typeId: ExerciseType.pushups.rawValue)
            let title3 = viewModel.getExerciseTitle(for: training3, modelContext: context)
            #expect(title3 == "Отжимания")

            let user = User(id: 1, userName: "testuser", fullName: "Test User", email: "test@example.com")
            context.insert(user)

            let customExercise = CustomExercise(
                id: "custom-1",
                name: "Кастомное упражнение",
                imageId: 1,
                createDate: .now,
                modifyDate: .now,
                user: user
            )
            context.insert(customExercise)
            try context.save()

            let training4 = WorkoutPreviewTraining(count: 10, customTypeId: "custom-1")
            let title4 = viewModel.getExerciseTitle(for: training4, modelContext: context)
            #expect(title4 == "Кастомное упражнение")

            let training5 = WorkoutPreviewTraining(count: nil, customTypeId: "custom-1")
            let title5 = viewModel.getExerciseTitle(for: training5, modelContext: context)
            #expect(title5 == "Кастомное упражнение")
        }
    }
}
