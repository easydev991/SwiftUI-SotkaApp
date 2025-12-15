import SwiftUI

/// Упрощенная версия экрана превью тренировки для Apple Watch
struct WorkoutPreviewView: View {
    // MARK: - Properties

    @Environment(\.currentDay) private var currentDay
    @State private var viewModel: WorkoutPreviewViewModel
    @State private var showEditView = false
    @State private var showWorkoutView = false

    /// Инициализатор
    /// - Parameters:
    ///   - connectivityService: Сервис связи с iPhone
    ///   - appGroupHelper: Хелпер для чтения данных из App Group UserDefaults (опционально)
    init(
        connectivityService: any WatchConnectivityServiceProtocol,
        appGroupHelper: (any WatchAppGroupHelperProtocol)? = nil
    ) {
        _viewModel = State(
            initialValue: .init(
                connectivityService: connectivityService,
                appGroupHelper: appGroupHelper ?? WatchAppGroupHelper()
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
            .sheet(isPresented: $showEditView) {
                WorkoutEditView(viewModel: viewModel)
            }
            .fullScreenCover(isPresented: $showWorkoutView) {
                if let executionType = viewModel.selectedExecutionType {
                    WorkoutView(
                        executionType: executionType,
                        trainings: viewModel.trainings,
                        plannedCount: viewModel.plannedCount,
                        restTime: viewModel.restTime,
                        connectivityService: viewModel.connectivityService,
                        appGroupHelper: viewModel.appGroupHelper,
                        onWorkoutCompleted: { result in
                            viewModel.handleWorkoutResult(result)
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
        Button {
            showEditView = true
        } label: {
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
