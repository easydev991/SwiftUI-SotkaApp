import Foundation
@testable import SotkaWatch_Watch_App
import Testing

@MainActor
struct WorkoutViewModelNavigationTitleTests {
    @Test("Должен возвращать пустой заголовок для разминки")
    func navigationTitleForWarmUp() throws {
        let connectivityService = MockWatchConnectivityService()
        let viewModel = WorkoutViewModel(
            connectivityService: connectivityService
        )

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

        let title = viewModel.getNavigationTitle()
        #expect(title == "")
    }

    @Test("Должен возвращать заголовок для круга")
    func navigationTitleForCycle() throws {
        let connectivityService = MockWatchConnectivityService()
        let viewModel = WorkoutViewModel(
            connectivityService: connectivityService
        )

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

        // Переходим к первому кругу
        viewModel.completeCurrentStep()

        let title = viewModel.getNavigationTitle()
        let expectedTitle = String(localized: .workoutViewCycle(1, 4))
        #expect(title == expectedTitle)
    }

    @Test("Должен возвращать заголовок для второго круга")
    func navigationTitleForSecondCycle() throws {
        let connectivityService = MockWatchConnectivityService()
        let viewModel = WorkoutViewModel(
            connectivityService: connectivityService
        )

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

        // Переходим к первому кругу
        viewModel.completeCurrentStep()
        // Завершаем таймер отдыха
        viewModel.handleRestTimerFinish(force: false)
        // Переходим ко второму кругу
        viewModel.completeCurrentStep()

        let title = viewModel.getNavigationTitle()
        let expectedTitle = String(localized: .workoutViewCycle(2, 4))
        #expect(title == expectedTitle)
    }

    @Test("Должен возвращать заголовок для подхода")
    func navigationTitleForSet() throws {
        let connectivityService = MockWatchConnectivityService()
        let viewModel = WorkoutViewModel(
            connectivityService: connectivityService
        )

        let trainings = [
            WorkoutPreviewTraining(count: 5, typeId: 0)
        ]

        viewModel.setupWorkoutData(
            dayNumber: 1,
            executionType: .sets,
            trainings: trainings,
            plannedCount: 6,
            restTime: 60
        )

        // Переходим к первому подходу
        viewModel.completeCurrentStep()

        let title = viewModel.getNavigationTitle()
        let expectedTitle = String(localized: .workoutViewSet(1, 6))
        #expect(title == expectedTitle)
    }

    @Test("Должен возвращать заголовок для второго подхода")
    func navigationTitleForSecondSet() throws {
        let connectivityService = MockWatchConnectivityService()
        let viewModel = WorkoutViewModel(
            connectivityService: connectivityService
        )

        let trainings = [
            WorkoutPreviewTraining(count: 5, typeId: 0)
        ]

        viewModel.setupWorkoutData(
            dayNumber: 1,
            executionType: .sets,
            trainings: trainings,
            plannedCount: 6,
            restTime: 60
        )

        // Переходим к первому подходу
        viewModel.completeCurrentStep()
        // Завершаем таймер отдыха
        viewModel.handleRestTimerFinish(force: false)
        // Переходим ко второму подходу
        viewModel.completeCurrentStep()

        let title = viewModel.getNavigationTitle()
        let expectedTitle = String(localized: .workoutViewSet(2, 6))
        #expect(title == expectedTitle)
    }

    @Test("Должен возвращать пустой заголовок для заминки")
    func navigationTitleForCoolDown() throws {
        let connectivityService = MockWatchConnectivityService()
        let viewModel = WorkoutViewModel(
            connectivityService: connectivityService
        )

        let trainings = [
            WorkoutPreviewTraining(count: 5, typeId: 0)
        ]

        viewModel.setupWorkoutData(
            dayNumber: 1,
            executionType: .cycles,
            trainings: trainings,
            plannedCount: 2,
            restTime: 60
        )

        // Завершаем разминку
        viewModel.completeCurrentStep()
        // Завершаем первый круг
        viewModel.completeCurrentStep()
        viewModel.handleRestTimerFinish(force: false)
        // Завершаем второй круг
        viewModel.completeCurrentStep()
        viewModel.handleRestTimerFinish(force: false)
        // После завершения последнего круга мы автоматически переходим к заминке

        let title = viewModel.getNavigationTitle()
        #expect(title == "")
    }

    @Test("Должен возвращать заголовок по умолчанию когда текущий этап отсутствует")
    func navigationTitleWhenCurrentStepIsNil() {
        let connectivityService = MockWatchConnectivityService()
        let viewModel = WorkoutViewModel(
            connectivityService: connectivityService
        )

        let title = viewModel.getNavigationTitle()
        let expectedTitle = String(localized: .workoutScreenTitle)
        #expect(title == expectedTitle)
    }

    @Test("Должен возвращать пустой заголовок для заминки когда plannedCount = nil")
    func navigationTitleForCoolDownWithNilPlannedCount() throws {
        let connectivityService = MockWatchConnectivityService()
        let viewModel = WorkoutViewModel(
            connectivityService: connectivityService
        )

        let trainings = [
            WorkoutPreviewTraining(count: 5, typeId: 0)
        ]

        viewModel.setupWorkoutData(
            dayNumber: 1,
            executionType: .cycles,
            trainings: trainings,
            plannedCount: nil,
            restTime: 60
        )

        // Когда plannedCount = nil, круги не создаются, поэтому после разминки сразу заминка
        // Завершаем разминку
        viewModel.completeCurrentStep()

        let title = viewModel.getNavigationTitle()
        #expect(title == "")
    }

    @Test("Должен возвращать правильный заголовок для первого подхода первого упражнения")
    func navigationTitleForFirstSetOfFirstExercise() throws {
        let connectivityService = MockWatchConnectivityService()
        let viewModel = WorkoutViewModel(
            connectivityService: connectivityService
        )

        let trainings = [
            WorkoutPreviewTraining(count: 5, typeId: 0),
            WorkoutPreviewTraining(count: 10, typeId: 2)
        ]

        viewModel.setupWorkoutData(
            dayNumber: 1,
            executionType: .sets,
            trainings: trainings,
            plannedCount: 2,
            restTime: 60
        )

        // Завершаем разминку
        viewModel.completeCurrentStep()

        // Должен быть первый подход первого упражнения (глобальный номер 1, но для упражнения это 1/2)
        let title = viewModel.getNavigationTitle()
        let expectedTitle = String(localized: .workoutViewSet(1, 2))
        #expect(title == expectedTitle)
    }

    @Test("Должен возвращать правильный заголовок для второго подхода первого упражнения")
    func navigationTitleForSecondSetOfFirstExercise() throws {
        let connectivityService = MockWatchConnectivityService()
        let viewModel = WorkoutViewModel(
            connectivityService: connectivityService
        )

        let trainings = [
            WorkoutPreviewTraining(count: 5, typeId: 0),
            WorkoutPreviewTraining(count: 10, typeId: 2)
        ]

        viewModel.setupWorkoutData(
            dayNumber: 1,
            executionType: .sets,
            trainings: trainings,
            plannedCount: 2,
            restTime: 60
        )

        // Завершаем разминку
        viewModel.completeCurrentStep()
        // Завершаем первый подход первого упражнения (глобальный номер 1)
        viewModel.completeCurrentStep()
        if viewModel.showTimer {
            viewModel.handleRestTimerFinish(force: false)
        }

        // Должен быть второй подход первого упражнения (глобальный номер 2, но для упражнения это 2/2)
        let title = viewModel.getNavigationTitle()
        let expectedTitle = String(localized: .workoutViewSet(2, 2))
        #expect(title == expectedTitle)
    }

    @Test("Должен возвращать правильный заголовок для первого подхода второго упражнения")
    func navigationTitleForFirstSetOfSecondExercise() throws {
        let connectivityService = MockWatchConnectivityService()
        let viewModel = WorkoutViewModel(
            connectivityService: connectivityService
        )

        let trainings = [
            WorkoutPreviewTraining(count: 5, typeId: 0),
            WorkoutPreviewTraining(count: 10, typeId: 2)
        ]

        viewModel.setupWorkoutData(
            dayNumber: 1,
            executionType: .sets,
            trainings: trainings,
            plannedCount: 2,
            restTime: 60
        )

        // Завершаем разминку
        viewModel.completeCurrentStep()
        // Завершаем первый подход первого упражнения (глобальный номер 1)
        viewModel.completeCurrentStep()
        if viewModel.showTimer {
            viewModel.handleRestTimerFinish(force: false)
        }
        // Завершаем второй подход первого упражнения (глобальный номер 2)
        viewModel.completeCurrentStep()
        if viewModel.showTimer {
            viewModel.handleRestTimerFinish(force: false)
        }

        // Должен быть первый подход второго упражнения (глобальный номер 3, но для упражнения это 1/2)
        let title = viewModel.getNavigationTitle()
        let expectedTitle = String(localized: .workoutViewSet(1, 2))
        #expect(title == expectedTitle)
    }

    @Test("Должен возвращать правильный заголовок для второго подхода второго упражнения")
    func navigationTitleForSecondSetOfSecondExercise() throws {
        let connectivityService = MockWatchConnectivityService()
        let viewModel = WorkoutViewModel(
            connectivityService: connectivityService
        )

        let trainings = [
            WorkoutPreviewTraining(count: 5, typeId: 0),
            WorkoutPreviewTraining(count: 10, typeId: 2)
        ]

        viewModel.setupWorkoutData(
            dayNumber: 1,
            executionType: .sets,
            trainings: trainings,
            plannedCount: 2,
            restTime: 60
        )

        // Завершаем разминку
        viewModel.completeCurrentStep()
        // Завершаем первый подход первого упражнения (глобальный номер 1)
        viewModel.completeCurrentStep()
        if viewModel.showTimer {
            viewModel.handleRestTimerFinish(force: false)
        }
        // Завершаем второй подход первого упражнения (глобальный номер 2)
        viewModel.completeCurrentStep()
        if viewModel.showTimer {
            viewModel.handleRestTimerFinish(force: false)
        }
        // Завершаем первый подход второго упражнения (глобальный номер 3)
        viewModel.completeCurrentStep()
        if viewModel.showTimer {
            viewModel.handleRestTimerFinish(force: false)
        }

        // Должен быть второй подход второго упражнения (глобальный номер 4, но для упражнения это 2/2)
        let title = viewModel.getNavigationTitle()
        let expectedTitle = String(localized: .workoutViewSet(2, 2))
        #expect(title == expectedTitle)
    }
}
