import SwiftUI

/// Экран редактирования тренировки для Apple Watch
///
/// Позволяет редактировать состав упражнений в тренировке и их количество
/// Без пользовательских упражнений (customExercisesSection) для первой итерации
struct WorkoutEditView: View {
    // MARK: - Properties

    @Environment(\.dismiss) private var dismiss
    let viewModel: WorkoutPreviewViewModel
    @State private var editableExercises: [WorkoutPreviewTraining] = []

    var body: some View {
        List {
            dayExercisesSection
            standardExercisesSection
        }
        .navigationTitle(.workoutExerciseEditorTitle)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: saveChanges) {
                    Image(systemName: "checkmark")
                }
            }
        }
        .onAppear(perform: initializeEditableExercises)
    }

    // MARK: - Private Views

    private var canRemoveExercise: Bool {
        editableExercises.count > 1
    }

    private var dayExercisesSection: some View {
        Section(.workoutExerciseEditorDayExercises) {
            ForEach(editableExercises) { exercise in
                WorkoutExerciseEditorRowView(
                    image: exercise.exerciseImage,
                    title: exercise.makeExerciseTitle(
                        dayNumber: viewModel.dayNumber,
                        selectedExecutionType: viewModel.selectedExecutionType
                    ),
                    mode: .removable,
                    onAction: {
                        removeExercise(exercise)
                    }
                )
                .disabled(!canRemoveExercise)
            }
            .onMove { source, destination in
                moveExercise(from: source, to: destination)
            }
        }
    }

    private var standardExercisesSection: some View {
        Section(.workoutExerciseEditorStandardExercises) {
            ForEach(ExerciseType.standardExercises, id: \.rawValue) { exerciseType in
                WorkoutExerciseEditorRowView(
                    image: exerciseType.image,
                    title: exerciseType.localizedTitle,
                    mode: .addable,
                    onAction: {
                        addStandardExercise(exerciseType)
                    }
                )
            }
        }
    }

    // MARK: - Methods

    private func initializeEditableExercises() {
        editableExercises = viewModel.initializeEditableExercises()
    }

    private func removeExercise(_ exercise: WorkoutPreviewTraining) {
        guard editableExercises.count > 1 else { return }
        editableExercises.removeAll { $0.id == exercise.id }
    }

    private func addStandardExercise(_ exerciseType: ExerciseType) {
        let newExercise = WorkoutPreviewTraining(
            count: 5,
            typeId: exerciseType.rawValue,
            customTypeId: nil,
            sortOrder: nil
        )
        editableExercises.append(newExercise)
    }

    private func moveExercise(from source: IndexSet, to destination: Int) {
        editableExercises.move(fromOffsets: source, toOffset: destination)
    }

    private func saveChanges() {
        viewModel.updateTrainings(editableExercises)
        dismiss()
    }
}

#if DEBUG
#Preview {
    @Previewable @State var viewModel = WorkoutPreviewViewModel(
        connectivityService: PreviewWatchConnectivityService(),
        appGroupHelper: PreviewWatchAppGroupHelper()
    )
    NavigationStack {
        WorkoutEditView(viewModel: viewModel)
    }
}
#endif
