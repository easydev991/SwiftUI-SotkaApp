import SWDesignSystem
import SwiftData
import SwiftUI
import SWUtils

struct WorkoutScreen: View {
    @State private var viewModel = WorkoutScreenViewModel()
    @State private var showStopWorkoutConfirmation = false
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase
    @Environment(AppSettings.self) private var appSettings
    let dayNumber: Int
    let executionType: ExerciseExecutionType
    let trainings: [WorkoutPreviewTraining]
    let plannedCount: Int?
    let restTime: Int
    let onWorkoutCompleted: (WorkoutResult) -> Void

    var body: some View {
        NavigationStack {
            @Bindable var vm = viewModel
            List {
                if vm.shouldShowExercisesReminder {
                    exercisesReminderSection
                }
                warmUpSection
                workoutStepsSection
                coolDownSection
                stopWorkoutButtonSection
            }
            .navigationTitle(.workoutScreenTitle)
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                vm.setupWorkoutData(
                    dayNumber: dayNumber,
                    executionType: executionType,
                    trainings: trainings,
                    plannedCount: plannedCount,
                    restTime: restTime
                )
            }
            .onChange(of: scenePhase) { _, newPhase in
                guard newPhase == .active else { return }
                vm.checkAndHandleExpiredRestTimer(appSettings: appSettings)
            }
            .fullScreenCover(isPresented: $vm.showTimer) {
                vm.onTimerCompleted(appSettings: appSettings)
            } content: {
                WorkoutTimerScreen(duration: restTime)
            }
        }
    }
}

private extension WorkoutScreen {
    var exercisesReminderSection: some View {
        Section(.workoutScreenExercisesReminder) {
            ForEach(viewModel.trainings) { training in
                ActivityRowView(
                    image: getExerciseImage(for: training),
                    title: viewModel.getExerciseTitle(for: training, modelContext: modelContext),
                    count: training.count
                )
            }
        }
    }

    var warmUpSection: some View {
        WorkoutRowView(
            title: WorkoutStep.warmUp.localizedTitle,
            state: viewModel.getStepState(for: .warmUp),
            action: {
                viewModel.completeCurrentStep(appSettings: appSettings)
            }
        )
    }

    @ViewBuilder
    var workoutStepsSection: some View {
        switch viewModel.getEffectiveExecutionType() {
        case .cycles:
            ForEach(viewModel.getCycleSteps()) { stepState in
                WorkoutRowView(
                    title: stepState.step.localizedTitle,
                    state: stepState.state,
                    action: {
                        viewModel.completeCurrentStep(appSettings: appSettings)
                    }
                )
            }
        case .sets:
            ForEach(viewModel.trainings) { training in
                Section {
                    ForEach(viewModel.getExerciseSteps(for: training.id)) { stepState in
                        WorkoutRowView(
                            title: stepState.step.localizedTitle,
                            state: stepState.state,
                            action: {
                                viewModel.completeCurrentStep(appSettings: appSettings)
                            }
                        )
                    }
                } header: {
                    Text(viewModel.getExerciseTitleWithCount(for: training, modelContext: modelContext))
                }
            }
        case .turbo:
            EmptyView()
        }
    }

    var coolDownSection: some View {
        WorkoutRowView(
            title: WorkoutStep.coolDown.localizedTitle,
            state: viewModel.getStepState(for: .coolDown),
            action: {
                viewModel.completeCurrentStep(appSettings: appSettings)
                if let result = viewModel.getWorkoutResult() {
                    onWorkoutCompleted(result)
                }
                dismiss()
            }
        )
    }

    var stopWorkoutButtonSection: some View {
        Section {
            Button(.workoutScreenStopWorkoutButton, role: .destructive) {
                showStopWorkoutConfirmation = true
            }
            .confirmationDialog(
                .workoutScreenStopWorkoutTitle,
                isPresented: $showStopWorkoutConfirmation,
                titleVisibility: .visible
            ) {
                Button(.workoutScreenStopWorkoutConfirmButton, role: .destructive) {
                    if let result = viewModel.getWorkoutResult(interrupt: true) {
                        onWorkoutCompleted(result)
                    }
                    dismiss()
                }
            } message: {
                Text(.workoutScreenStopWorkoutMessage)
            }
        }
    }

    func getExerciseImage(for training: WorkoutPreviewTraining) -> Image {
        if let customTypeId = training.customTypeId,
           let customExercise = CustomExercise.fetch(by: customTypeId, in: modelContext) {
            customExercise.image
        } else if let typeId = training.typeId,
                  let exerciseType = ExerciseType(rawValue: typeId) {
            exerciseType.image
        } else {
            .init(systemName: "questionmark.circle")
        }
    }
}

#if DEBUG
#Preview("Круги") {
    NavigationStack {
        WorkoutScreen(
            dayNumber: 1,
            executionType: .cycles,
            trainings: .previewCycles,
            plannedCount: 4,
            restTime: 60,
            onWorkoutCompleted: { _ in }
        )
        .environment(AppSettings())
    }
}

#Preview("Подходы") {
    NavigationStack {
        WorkoutScreen(
            dayNumber: 50,
            executionType: .sets,
            trainings: .previewSets,
            plannedCount: 6,
            restTime: 90,
            onWorkoutCompleted: { _ in }
        )
        .environment(AppSettings())
    }
}

#Preview("Турбо") {
    NavigationStack {
        WorkoutScreen(
            dayNumber: 92,
            executionType: .turbo,
            trainings: .previewTurbo,
            plannedCount: 5,
            restTime: 45,
            onWorkoutCompleted: { _ in }
        )
        .environment(AppSettings())
    }
}
#endif
