import OSLog
import SWDesignSystem
import SwiftUI

/// Упрощенная версия экрана превью тренировки для Apple Watch
struct WorkoutPreviewView: View {
    // MARK: - Properties

    @Environment(\.currentDay) private var currentDay
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: WorkoutPreviewViewModel
    @State private var showWorkoutView = false

    @ObservationIgnored private let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "SotkaWatch",
        category: String(describing: WorkoutPreviewView.self)
    )

    /// Инициализатор
    /// - Parameters:
    ///   - connectivityService: Сервис связи с iPhone
    ///   - healthKitWriting: Сервис записи в HealthKit (в проде — `HealthKitWorkoutWriter`)
    init(
        connectivityService: any WatchConnectivityServiceProtocol,
        healthKitWriting: (any HealthKitWorkoutWriting)? = nil
    ) {
        _viewModel = State(
            initialValue: .init(
                connectivityService: connectivityService,
                healthKitWriting: healthKitWriting
            )
        )
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 8) {
                    executionTypePicker
                    workoutContentView
                    bottomButtonsView
                }
            }
            .navigationTitle(.day(number: currentDay))
            .toolbar {
                if viewModel.shouldShowEditButton {
                    ToolbarItem(placement: .topBarTrailing) {
                        editButton
                    }
                }
            }
            .fullScreenCover(isPresented: $showWorkoutView) {
                if let executionType = viewModel.selectedExecutionType {
                    WorkoutView(
                        executionType: executionType,
                        trainings: viewModel.trainings,
                        plannedCount: viewModel.plannedCount,
                        restTime: viewModel.restTime,
                        connectivityService: viewModel.connectivityService,
                        onWorkoutCompleted: { result in
                            viewModel.handleWorkoutResult(result)
                            showWorkoutView = false
                        }
                    )
                }
            }
            .alert(
                isPresented: .init(
                    get: { viewModel.error != nil },
                    set: {
                        if !$0 {
                            viewModel.error = nil
                        }
                    }
                ),
                error: viewModel.error
            ) {
                Button(.ok, role: .cancel) {
                    viewModel.error = nil
                }
            }
        }
        .loadingOverlay(if: viewModel.isLoading)
        .task {
            await viewModel.loadData(day: currentDay)
            // Запрос разрешения HealthKit — идемпотентный, best-effort после загрузки данных.
            // Отменяется автоматически при уходе вью (SwiftUI .task cancellation).
            await viewModel.requestHealthKitAuthorizationIfNeeded()
        }
        .onAppear {
            viewModel.onSaveCompleted = {
                dismiss()
            }
        }
    }
}

// MARK: - Private Views

private extension WorkoutPreviewView {
    var editButton: some View {
        NavigationLink(destination: WorkoutEditView(viewModel: viewModel)) {
            Image(systemName: "pencil")
        }
        .accessibilityIdentifier("WorkoutPreviewView.editButton")
    }

    @ViewBuilder
    var executionTypePicker: some View {
        if viewModel.shouldShowExecutionTypePicker(day: currentDay, isPassed: viewModel.wasOriginallyPassed) {
            Picker(.exerciseExecutionType, selection: Binding(
                get: { viewModel.selectedExecutionTypeForPicker },
                set: { newValue in
                    viewModel.updateExecutionType(with: newValue)
                }
            )) {
                ForEach(viewModel.availableExecutionTypes, id: \.self) { type in
                    Text(type.localizedTitle).tag(type)
                }
            }
            .pickerStyle(.navigationLink)
            .accessibilityIdentifier("WorkoutPreview.executionTypePicker")
        }
    }

    var workoutContentView: some View {
        LazyVStack(spacing: 8) {
            ForEach(viewModel.visibleTrainings) { training in
                makeTrainingRowView(for: training)
                    .accessibilityIdentifier("WorkoutPreview.trainingRowView")
            }
            if let selectedExecutionType = viewModel.selectedExecutionType {
                Divider()
                makePlannedCountView(for: selectedExecutionType)
                if !viewModel.wasOriginallyPassed {
                    makeRestTimePicker(
                        .init(
                            get: { viewModel.restTime },
                            set: { viewModel.updateRestTime($0) }
                        )
                    )
                    Divider()
                }
                if viewModel.canEditComment {
                    commentEditor
                    Divider()
                }
            }
        }
    }

    func makeTrainingRowView(for training: WorkoutPreviewTraining) -> some View {
        let value = Binding(
            get: { training.count ?? 0 },
            set: { newValue in
                viewModel.updateTrainingCount(for: training.id, newValue: newValue)
            }
        )
        let title = training.makeExerciseTitle(
            dayNumber: currentDay,
            selectedExecutionType: viewModel.selectedExecutionType
        )
        return NavigationLink(destination: WorkoutStepperView(value: value, from: 1, title: title)) {
            ActivityRowView(
                image: training.exerciseImage,
                title: title,
                count: training.count
            )
        }
    }

    func makePlannedCountView(for executionType: ExerciseExecutionType) -> some View {
        let value = Binding(
            get: { viewModel.displayedCount ?? 1 },
            set: viewModel.updatePlannedCount
        )
        let title = viewModel.displayExecutionType(for: executionType).localizedTitle
        return NavigationLink(destination: WorkoutStepperView(value: value, from: 1, title: title)) {
            ActivityRowView(
                image: viewModel.displayExecutionType(for: executionType).image,
                title: title,
                count: viewModel.displayedCount
            )
        }
        .disabled(viewModel.isPlannedCountDisabled)
    }

    func makeRestTimePicker(_ value: Binding<Int>) -> some View {
        Picker(selection: value) {
            ForEach(Constants.restPickerOptions, id: \.self) { seconds in
                Text(RestTimeComponents(totalSeconds: seconds).localizedString).tag(seconds)
            }
        } label: {
            Label(.workoutPreviewRestTimePicker, systemImage: "timer")
        }
        .pickerStyle(.navigationLink)
    }

    var commentEditor: some View {
        #if os(watchOS)
        TextFieldLink(prompt: Text(.dayActivityCommentPlaceholder)) {
            HStack {
                Image(systemName: "text.bubble")
                if let comment = viewModel.comment, !comment.isEmpty {
                    Text(comment)
                        .lineLimit(2)
                        .foregroundStyle(.secondary)
                } else {
                    Text(.dayActivityCommentPlaceholder)
                        .foregroundStyle(.secondary)
                }
            }
            .multilineTextAlignment(.leading)
        } onSubmit: { text in
            viewModel.updateComment(text.isEmpty ? nil : text)
        }
        #else
        EmptyView()
        #endif
    }

    var bottomButtonsView: some View {
        WorkoutPreviewButtonsView(
            isPassed: viewModel.wasOriginallyPassed,
            hasChanges: viewModel.hasChanges,
            isWorkoutCompleted: viewModel.isWorkoutCompleted,
            onSave: {
                Task {
                    await viewModel.saveTrainingAsPassed()
                }
            },
            onStartTraining: {
                logger
                    .info(
                        "Нажата кнопка «Начать тренировку»: day=\(currentDay), canStartTraining=\(viewModel.canStartTraining), trainings.count=\(viewModel.trainings.count)"
                    )
                showWorkoutView = true
            },
            canStartTraining: viewModel.canStartTraining
        )
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("WorkoutPreview.bottomButtonsView")
    }
}

#if DEBUG
#Preview {
    WorkoutPreviewView(
        connectivityService: PreviewWatchConnectivityService(currentDay: 92)
    )
    .currentDay(92)
}
#endif
