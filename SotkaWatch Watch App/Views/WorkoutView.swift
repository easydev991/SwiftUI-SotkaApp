import SwiftUI

struct WorkoutView: View {
    @Environment(\.currentDay) private var currentDay
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase

    @State private var viewModel: WorkoutViewModel
    @State private var showStopWorkoutConfirmation = false

    private let executionType: ExerciseExecutionType
    private let trainings: [WorkoutPreviewTraining]
    private let plannedCount: Int?
    private let restTime: Int
    private let onWorkoutCompleted: (WorkoutResult) -> Void

    /// Инициализатор
    /// - Parameters:
    ///   - executionType: Тип выполнения тренировки
    ///   - trainings: Массив упражнений
    ///   - plannedCount: Плановое количество кругов/подходов
    ///   - restTime: Время отдыха между подходами/кругами (в секундах)
    ///   - connectivityService: Сервис связи с iPhone
    ///   - appGroupHelper: Хелпер для чтения данных из App Group UserDefaults (опционально)
    ///   - onWorkoutCompleted: Callback при завершении тренировки
    init(
        executionType: ExerciseExecutionType,
        trainings: [WorkoutPreviewTraining],
        plannedCount: Int?,
        restTime: Int,
        connectivityService: any WatchConnectivityServiceProtocol,
        appGroupHelper: (any WatchAppGroupHelperProtocol)? = nil,
        onWorkoutCompleted: @escaping (WorkoutResult) -> Void
    ) {
        self.executionType = executionType
        self.trainings = trainings
        self.plannedCount = plannedCount
        self.restTime = restTime
        self.onWorkoutCompleted = onWorkoutCompleted
        _viewModel = State(
            initialValue: .init(
                connectivityService: connectivityService,
                appGroupHelper: appGroupHelper
            )
        )
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                ZStack {
                    Spacer().containerRelativeFrame([.vertical])
                    if let currentStep = viewModel.currentStep {
                        switch currentStep {
                        case .warmUp:
                            warmUpView
                        case let .exercise(executionType, number):
                            makeExerciseView(executionType: executionType, number: number)
                        case .coolDown:
                            coolDownView
                        }
                    } else {
                        ProgressView()
                    }
                }
                .animation(.default, value: viewModel.currentStep)
            }
            .navigationTitle(viewModel.getNavigationTitle())
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    stopWorkoutButtonSection
                }
            }
            .onAppear {
                viewModel.setupWorkoutData(
                    dayNumber: currentDay,
                    executionType: executionType,
                    trainings: trainings,
                    plannedCount: plannedCount,
                    restTime: restTime
                )
            }
            .onChange(of: scenePhase) { _, newPhase in
                guard newPhase == .active else { return }
                viewModel.checkAndHandleExpiredRestTimer()
            }
            .onChange(of: viewModel.isWorkoutCompleted) { _, isCompleted in
                guard isCompleted else { return }
                Task {
                    if let result = await viewModel.finishWorkout() {
                        onWorkoutCompleted(result)
                        dismiss()
                    }
                }
            }
            .fullScreenCover(isPresented: $viewModel.showTimer) {
                WorkoutRestTimerView(duration: restTime) { force in
                    viewModel.handleRestTimerFinish(force: force)
                }
            }
            .alert(.error, isPresented: .init(
                get: { viewModel.error != nil },
                set: { if !$0 { viewModel.error = nil } }
            )) {
                Button(.ok, role: .cancel) {
                    viewModel.error = nil
                }
            } message: {
                if let error = viewModel.error {
                    Text(error.localizedDescription)
                }
            }
        }
    }
}

// MARK: - Private Views

private extension WorkoutView {
    var warmUpView: some View {
        VStack(spacing: 20) {
            Text(.workoutStepWarmUp).font(.headline)
            actionButton
        }
    }

    func makeExerciseView(executionType: ExerciseExecutionType, number: Int) -> some View {
        let effectiveType = viewModel.getEffectiveExecutionType()
        let currentTrainings: [WorkoutPreviewTraining]
        // TODO: вынести эту логику во вьюмодель и написать тесты, а тут просто обращаться к вьюмодели
        if effectiveType == .cycles {
            currentTrainings = viewModel.trainings
        } else {
            let exerciseIndex = (number - 1) / (viewModel.plannedCount ?? 1)
            if exerciseIndex < viewModel.trainings.count {
                currentTrainings = [viewModel.trainings[exerciseIndex]]
            } else {
                currentTrainings = []
            }
        }

        return VStack(spacing: 12) {
            if effectiveType == .cycles {
                ForEach(currentTrainings) { training in
                    ActivityRowView(
                        image: training.exerciseImage,
                        title: training.makeExerciseTitle(
                            dayNumber: currentDay,
                            selectedExecutionType: executionType
                        ),
                        count: training.count
                    )
                }
            } else {
                if let training = currentTrainings.first {
                    ActivityRowView(
                        image: training.exerciseImage,
                        title: training.makeExerciseTitle(
                            dayNumber: currentDay,
                            selectedExecutionType: executionType
                        ),
                        count: training.count
                    )
                }
            }
            actionButton
        }
        .padding(.vertical)
    }

    var coolDownView: some View {
        VStack(spacing: 20) {
            Text(.workoutStepCoolDown).font(.headline)
            actionButton
        }
    }

    var actionButton: some View {
        Button(.done, action: viewModel.completeCurrentStep)
    }

    var stopWorkoutButtonSection: some View {
        Button {
            showStopWorkoutConfirmation = true
        } label: {
            Image(systemName: "xmark")
        }
        .confirmationDialog(
            .workoutScreenStopWorkoutTitle,
            isPresented: $showStopWorkoutConfirmation,
            titleVisibility: .visible
        ) {
            Button(.workoutScreenStopWorkoutConfirmButton, role: .destructive) {
                if let result = viewModel.cancelWorkout() {
                    onWorkoutCompleted(result)
                }
                dismiss()
            }
        } message: {
            Text(.workoutScreenStopWorkoutMessage)
        }
    }
}

// MARK: - Preview

#Preview("Подход") {
    let connectivityService = PreviewWatchConnectivityService()
    WorkoutView(
        executionType: .sets,
        trainings: .previewSets,
        plannedCount: 2,
        restTime: 60,
        connectivityService: connectivityService,
        onWorkoutCompleted: { _ in }
    )
    .currentDay(2)
}

#Preview("Круг") {
    let connectivityService = PreviewWatchConnectivityService()
    WorkoutView(
        executionType: .cycles,
        trainings: .previewCycles,
        plannedCount: 4,
        restTime: 60,
        connectivityService: connectivityService,
        onWorkoutCompleted: { _ in }
    )
    .currentDay(2)
}
