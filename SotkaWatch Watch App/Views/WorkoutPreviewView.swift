import SwiftUI

/// Упрощенная версия экрана превью тренировки для Apple Watch
struct WorkoutPreviewView: View {
    // MARK: - Properties

    let dayNumber: Int
    let workoutData: WorkoutData?

    // MARK: - State (заглушки для верстки)

    @State private var selectedExecutionType: ExerciseExecutionType?
    @State private var availableExecutionTypes: [ExerciseExecutionType] = []
    @State private var trainings: [WorkoutPreviewTraining] = []
    @State private var plannedCount: Int?
    @State private var restTime: Int = Constants.defaultRestTime
    @State private var showEditView = false
    @State private var showWorkoutView = false

    // MARK: - Callbacks (заглушки для верстки)

    var onStartWorkout: (() -> Void)?
    var onSaveAsPassed: (() -> Void)?
    var onUpdateExecutionType: ((ExerciseExecutionType) -> Void)?
    var onUpdateTrainingCount: ((String, Int) -> Void)?
    var onUpdatePlannedCount: ((Int) -> Void)?
    var onUpdateRestTime: ((Int) -> Void)?
    var shouldShowExecutionTypePicker: Bool {
        guard !trainings.isEmpty else { return false }
        return availableExecutionTypes.count > 1
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 8) {
                    executionTypePicker
                    Divider()
                    workoutContentView
                    bottomButtonsView
                }
            }
            .navigationTitle(.day(number: dayNumber))
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    editButton
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
        }
        .onAppear {
            setupInitialData()
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
        if shouldShowExecutionTypePicker {
            Picker(.exerciseExecutionType, selection: .init(
                get: { selectedExecutionType },
                set: { newValue in
                    selectedExecutionType = newValue
                    if let newValue {
                        onUpdateExecutionType?(newValue)
                    }
                }
            )) {
                ForEach(availableExecutionTypes, id: \.self) { type in
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
            if let selectedExecutionType {
                Divider()
                makePlannedCountView(for: selectedExecutionType)
                // TODO: пикер времени показываем только если !wasOriginallyPassed по аналогии с WorkoutPreviewScreen
                makeRestTimePicker(
                    .init(
                        get: { restTime },
                        set: { newValue in
                            restTime = newValue
                            onUpdateRestTime?(newValue)
                        }
                    )
                )
                Divider()
            }
        }
    }

    func makeTrainingRowView(for training: WorkoutPreviewTraining) -> some View {
        let value = Binding(
            get: { training.count ?? 0 },
            set: { newValue in
                if newValue == 0 {
                    // Удаляем упражнение из списка (отличие для первой итерации часов)
                    if let index = trainings.firstIndex(where: { $0.id == training.id }) {
                        trainings.remove(at: index)
                    }
                } else {
                    // Обновляем count для упражнения
                    if let index = trainings.firstIndex(where: { $0.id == training.id }) {
                        trainings[index] = trainings[index].withCount(newValue)
                    }
                    onUpdateTrainingCount?(training.id, newValue)
                }
            }
        )
        let title = makeExerciseTitle(for: training)
        return NavigationLink(destination: WorkoutStepperView(value: value, from: 1, title: title)) {
            ActivityRowView(
                image: makeExerciseImage(for: training),
                title: title,
                count: training.count
            )
        }
    }

    func makePlannedCountView(for executionType: ExerciseExecutionType) -> some View {
        let value = Binding(
            get: { plannedCount ?? 1 },
            set: { newValue in
                plannedCount = newValue
                onUpdatePlannedCount?(newValue)
            }
        )
        let title = executionType.localizedTitle
        return NavigationLink(destination: WorkoutStepperView(value: value, from: 1, title: title)) {
            ActivityRowView(
                image: WorkoutProgramCreator.getEffectiveExecutionType(for: dayNumber, executionType: executionType).image,
                title: title,
                count: plannedCount
            )
        }
        .disabled(executionType == .turbo)
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
        VStack(spacing: 8) {
            Button(.workoutPreviewStartTraining) {
                showWorkoutView = true
                onStartWorkout?()
            }
            .buttonStyle(.borderedProminent)

            Button(.workoutPreviewSaveAsPassed) {
                onSaveAsPassed?()
            }
            .buttonStyle(.bordered)
        }
    }
}

// MARK: - Helper Methods

private extension WorkoutPreviewView {
    var visibleTrainings: [WorkoutPreviewTraining] {
        trainings.filter { ($0.count ?? 0) > 0 }
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
           let selectedExecutionType {
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

    func setupInitialData() {
        // Инициализация данных из workoutData
        if let workoutData {
            selectedExecutionType = workoutData.exerciseExecutionType
            trainings = workoutData.trainings
            plannedCount = workoutData.plannedCount

            // Заполняем availableExecutionTypes (заглушка)
            if workoutData.day > 49 {
                availableExecutionTypes = [.cycles, .sets]
                if workoutData.day >= 92 {
                    availableExecutionTypes.append(.turbo)
                }
            } else {
                availableExecutionTypes = [.cycles]
            }
        }
    }
}

// MARK: - Preview

#if DEBUG
#Preview {
    let workoutData = WorkoutData(
        day: 50,
        executionType: 0,
        trainings: [
            WorkoutPreviewTraining(
                id: "1",
                count: 10,
                typeId: 0,
                customTypeId: nil,
                sortOrder: 0
            ),
            WorkoutPreviewTraining(
                id: "2",
                count: 15,
                typeId: 3,
                customTypeId: nil,
                sortOrder: 1
            )
        ],
        plannedCount: 4
    )

    WorkoutPreviewView(
        dayNumber: 50,
        workoutData: workoutData
    )
}
#endif
