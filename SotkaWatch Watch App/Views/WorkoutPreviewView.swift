import SwiftUI

/// Упрощенная версия экрана превью тренировки для Apple Watch
struct WorkoutPreviewView: View {
    // MARK: - Properties

    @Environment(\.currentDay) private var currentDay
    @State private var viewModel: WorkoutPreviewViewModel
    @State private var showWorkoutView = false

    /// Инициализатор
    /// - Parameter connectivityService: Сервис связи с iPhone
    init(
        connectivityService: any WatchConnectivityServiceProtocol
    ) {
        _viewModel = State(
            initialValue: .init(
                connectivityService: connectivityService
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
                    set: { if !$0 { viewModel.error = nil } }
                ),
                error: viewModel.error
            ) {
                Button(.ok, role: .cancel) {
                    viewModel.error = nil
                }
            }
        }
        .opacity(viewModel.isLoading ? 0.5 : 1)
        .disabled(viewModel.isLoading)
        .overlay {
            if viewModel.isLoading {
                ProgressView()
            }
        }
        .task {
            await viewModel.loadData(day: currentDay)
        }
    }
}

// MARK: - Private Views

private extension WorkoutPreviewView {
    var editButton: some View {
        NavigationLink(destination: WorkoutEditView(viewModel: viewModel)) {
            Image(systemName: "pencil")
        }
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
        }
    }

    var workoutContentView: some View {
        LazyVStack(spacing: 8) {
            ForEach(viewModel.visibleTrainings) { training in
                makeTrainingRowView(for: training)
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
            WatchActivityRowView(
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
            WatchActivityRowView(
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
                Text(.sec(seconds)).tag(seconds)
            }
        } label: {
            Label(.workoutPreviewRestTimePicker, systemImage: "timer")
        }
        .pickerStyle(.navigationLink)
    }

    var commentEditor: some View {
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
                showWorkoutView = true
            }
        )
    }
}

#if DEBUG
#Preview {
    WorkoutPreviewView(
        connectivityService: PreviewWatchConnectivityService()
    )
    .currentDay(50)
}
#endif
