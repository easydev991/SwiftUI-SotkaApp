import SwiftUI

/// Упрощенная версия экрана превью тренировки для Apple Watch
struct WorkoutPreviewView: View {
    // MARK: - Properties

    let dayNumber: Int
    @State private var viewModel: WorkoutPreviewViewModel
    @State private var showEditView = false
    @State private var showWorkoutView = false

    /// Инициализатор
    /// - Parameters:
    ///   - dayNumber: Номер дня программы
    ///   - connectivityService: Сервис связи с iPhone
    ///   - appGroupHelper: Хелпер для чтения данных из App Group UserDefaults (опционально)
    init(
        dayNumber: Int,
        connectivityService: any WatchConnectivityServiceProtocol,
        appGroupHelper: (any WatchAppGroupHelperProtocol)? = nil
    ) {
        self.dayNumber = dayNumber
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
                VStack(spacing: 8) {
                    executionTypePicker
                    workoutContentView
                    bottomButtonsView
                }
            }
            .navigationTitle(.day(number: dayNumber))
            .toolbar {
                if viewModel.shouldShowEditButton {
                    ToolbarItem(placement: .topBarTrailing) {
                        editButton
                    }
                }
            }
            .sheet(isPresented: $showEditView) {
                // TODO: WorkoutEditView (без customExercisesSection для первой итерации)
                ProgressView()
            }
            .fullScreenCover(isPresented: $showWorkoutView) {
                // TODO: WorkoutView
                ProgressView()
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
            await viewModel.loadData(day: dayNumber)
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
        if viewModel.shouldShowExecutionTypePicker(day: dayNumber, isPassed: viewModel.wasOriginallyPassed) {
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
            ForEach(visibleTrainings) { training in
                makeTrainingRowView(for: training)
            }
            if let selectedExecutionType = viewModel.selectedExecutionType {
                Divider()
                makePlannedCountView(for: selectedExecutionType)
                if !viewModel.wasOriginallyPassed {
                    Divider()
                    makeRestTimePicker(
                        .init(
                            get: { viewModel.restTime },
                            set: { viewModel.updateRestTime($0) }
                        )
                    )
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
        let title = makeExerciseTitle(for: training)
        return NavigationLink(destination: WorkoutStepperView(value: value, from: 1, title: title)) {
            WatchActivityRowView(
                image: makeExerciseImage(for: training),
                title: title,
                count: training.count
            )
        }
    }

    func makePlannedCountView(for executionType: ExerciseExecutionType) -> some View {
        let value = Binding(
            get: { viewModel.displayedCount ?? 1 },
            set: { newValue in
                viewModel.updatePlannedCount(for: newValue)
            }
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

// MARK: - Helper Methods

private extension WorkoutPreviewView {
    var visibleTrainings: [WorkoutPreviewTraining] {
        viewModel.trainings.filter { ($0.count ?? 0) > 0 }
    }

    func makeExerciseImage(for training: WorkoutPreviewTraining) -> Image {
        if let typeId = training.typeId,
           let exerciseType = ExerciseType(rawValue: typeId) {
            return exerciseType.image
        }
        return Image(systemName: "questionmark.circle")
    }

    func makeExerciseTitle(for training: WorkoutPreviewTraining) -> String {
        if let typeId = training.typeId,
           let exerciseType = ExerciseType(rawValue: typeId),
           let selectedExecutionType = viewModel.selectedExecutionType {
            return exerciseType.makeLocalizedTitle(
                dayNumber,
                executionType: selectedExecutionType,
                sortOrder: training.sortOrder
            )
        } else if let typeId = training.typeId,
                  let exerciseType = ExerciseType(rawValue: typeId) {
            return exerciseType.localizedTitle
        }
        return String(localized: .exerciseTypeUnknown)
    }
}

// MARK: - Preview

#if DEBUG
#Preview {
    let connectivityService = PreviewWatchConnectivityService()
    WorkoutPreviewView(
        dayNumber: 50,
        connectivityService: connectivityService
    )
}
#endif
