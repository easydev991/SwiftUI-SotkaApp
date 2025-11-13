import SWDesignSystem
import SwiftData
import SwiftUI

struct WorkoutExerciseEditorScreen: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(FetchDescriptor<CustomExercise>(predicate: #Predicate { !$0.shouldDelete }))
    private var customExercises: [CustomExercise]
    @State private var editableExercises: [WorkoutPreviewTraining] = []
    @State private var showCreateExerciseScreen = false
    let viewModel: WorkoutPreviewViewModel

    var body: some View {
        NavigationStack {
            List {
                dayExercisesSection
                standardExercisesSection
                customExercisesSection
            }
            .sheet(isPresented: $showCreateExerciseScreen) {
                NavigationStack {
                    ScrollView {
                        EditCustomExerciseScreen { showCreateExerciseScreen = false }
                    }
                    .scrollBounceBehavior(.basedOnSize)
                }
            }
            .navigationTitle(.workoutExerciseEditorTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    CloseButton(mode: .xmark) { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(.workoutExerciseEditorDone, action: saveChanges)
                }
            }
            .onAppear {
                initializeEditableExercises()
            }
        }
    }
}

private extension WorkoutExerciseEditorScreen {
    var canRemoveExercise: Bool {
        editableExercises.count > 1
    }

    var dayExercisesSection: some View {
        Section(.workoutExerciseEditorDayExercises) {
            ForEach(editableExercises) { exercise in
                WorkoutExerciseEditorRowView(
                    image: exerciseImage(for: exercise),
                    title: exerciseTitle(for: exercise),
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

    var standardExercisesSection: some View {
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

    var customExercisesSection: some View {
        Section(.workoutExerciseEditorCustomExercises) {
            ForEach(customExercises) { customExercise in
                WorkoutExerciseEditorRowView(
                    image: customExercise.image,
                    title: customExercise.name,
                    mode: .addable,
                    onAction: {
                        addCustomExercise(customExercise)
                    }
                )
            }
            Button(.workoutExerciseEditorCreateExercise) {
                showCreateExerciseScreen = true
            }
        }
    }

    func exerciseImage(for training: WorkoutPreviewTraining) -> Image {
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

    func exerciseTitle(for training: WorkoutPreviewTraining) -> String {
        if let customTypeId = training.customTypeId,
           let customExercise = CustomExercise.fetch(by: customTypeId, in: modelContext) {
            return customExercise.name
        } else if let typeId = training.typeId,
                  let exerciseType = ExerciseType(rawValue: typeId),
                  let selectedExecutionType = viewModel.selectedExecutionType {
            return exerciseType.makeLocalizedTitle(
                viewModel.dayNumber,
                executionType: selectedExecutionType,
                sortOrder: training.sortOrder
            )
        } else if let typeId = training.typeId,
                  let exerciseType = ExerciseType(rawValue: typeId) {
            return exerciseType.localizedTitle
        }
        return String(localized: .exerciseTypeUnknown)
    }

    func initializeEditableExercises() {
        withAnimation {
            editableExercises = viewModel.trainings.filter { !$0.isTurboExercise }
        }
    }

    func removeExercise(_ exercise: WorkoutPreviewTraining) {
        guard editableExercises.count > 1 else { return }
        withAnimation {
            editableExercises.removeAll { $0.id == exercise.id }
        }
    }

    func addStandardExercise(_ exerciseType: ExerciseType) {
        let newExercise = WorkoutPreviewTraining(
            count: 5,
            typeId: exerciseType.rawValue,
            customTypeId: nil,
            sortOrder: nil
        )
        withAnimation {
            editableExercises.append(newExercise)
        }
    }

    func addCustomExercise(_ customExercise: CustomExercise) {
        let newExercise = WorkoutPreviewTraining(
            count: 5,
            typeId: nil,
            customTypeId: customExercise.id,
            sortOrder: nil
        )
        withAnimation {
            editableExercises.append(newExercise)
        }
    }

    func moveExercise(from source: IndexSet, to destination: Int) {
        editableExercises.move(fromOffsets: source, toOffset: destination)
    }

    func saveChanges() {
        viewModel.updateTrainings(editableExercises)
        dismiss()
    }
}

#if DEBUG
#Preview {
    NavigationStack {
        WorkoutExerciseEditorScreen(viewModel: .init())
            .modelContainer(PreviewModelContainer.make(with: .preview))
    }
}
#endif
