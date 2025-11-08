import SWDesignSystem
import SwiftData
import SwiftUI
import SWUtils

struct WorkoutPreviewScreen: View {
    // TODO: передавать activitiesService в инициализаторе, не через environment
    @Environment(DailyActivitiesService.self) private var activitiesService
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = WorkoutPreviewViewModel()
    @State private var showEditorScreen = false
    @FocusState private var isCommentFocused: Bool
    let day: Int

    var body: some View {
        VStack(spacing: 0) {
            executionTypePicker
            workoutContentView
            Spacer()
            bottomButtonsView
        }
        .animation(.default, value: viewModel.selectedExecutionType)
        .background(Color.swBackground)
        .navigationTitle(.workoutPreviewTitle(day))
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                CloseButton(mode: .xmark) { dismiss() }
            }
            if viewModel.shouldShowEditButton {
                ToolbarItem(placement: .topBarTrailing) {
                    openEditorButton
                }
            }
        }
        .sheet(isPresented: $showEditorScreen) {
            WorkoutExerciseEditorScreen()
                .environment(viewModel)
        }
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            viewModel.updateData(modelContext: modelContext, day: day)
        }
        .alert(
            isPresented: $viewModel.error.mappedToBool(),
            error: viewModel.error
        ) {
            Button(.ok, role: .cancel) {
                viewModel.error = nil
            }
        }
    }
}

private extension WorkoutPreviewScreen {
    var openEditorButton: some View {
        Button {
            showEditorScreen.toggle()
        } label: {
            Image(systemName: "pencil")
        }
    }

    @ViewBuilder
    var executionTypePicker: some View {
        if viewModel.shouldShowExecutionTypePicker(modelContext: modelContext, day: day) {
            WorkoutPreviewExecutionTypePicker(
                selection: .init(
                    get: { viewModel.selectedExecutionType },
                    set: { newValue in
                        if let newValue {
                            viewModel.updateExecutionType(newValue)
                        }
                    }
                ),
                availableTypes: viewModel.availableExecutionTypes
            )
            .padding(.horizontal)
        }
    }

    var workoutContentView: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(viewModel.trainings.sorted) { training in
                    TrainingRowView(
                        id: training.id,
                        image: exerciseImage(for: training),
                        title: exerciseTitle(for: training),
                        count: training.count,
                        onAction: { id, action in
                            viewModel.updatePlannedCount(id: id, action: action)
                        }
                    )
                }
                if let selectedExecutionType = viewModel.selectedExecutionType {
                    Divider()
                    TrainingRowView(
                        id: "plannedCount",
                        image: viewModel.displayExecutionType(for: selectedExecutionType).image,
                        title: viewModel.displayExecutionType(for: selectedExecutionType).localizedTitle,
                        count: viewModel.plannedCount,
                        onAction: { id, action in
                            viewModel.updatePlannedCount(id: id, action: action)
                        },
                        isDisabled: viewModel.isPlannedCountDisabled
                    )
                    if viewModel.wasOriginallyPassed {
                        Divider()
                        commentEditor
                    }
                }
            }
            .padding()
        }
        .scrollBounceBehavior(.basedOnSize)
    }

    var commentEditor: some View {
        SWTextEditor(
            text: .init(
                get: { viewModel.comment ?? "" },
                set: { newValue in
                    viewModel.updateComment(newValue.isEmpty ? nil : newValue)
                }
            ),
            placeholder: String(localized: .dayActivityCommentPlaceholder),
            isFocused: isCommentFocused,
            height: 200
        )
        .focused($isCommentFocused)
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
            return exerciseType.makeLocalizedTitle(day, executionType: selectedExecutionType, sortOrder: training.sortOrder)
        } else if let typeId = training.typeId,
                  let exerciseType = ExerciseType(rawValue: typeId) {
            return exerciseType.localizedTitle
        }
        return String(localized: .exerciseTypeUnknown)
    }

    var bottomButtonsView: some View {
        WorkoutPreviewButtonsView(
            isPassed: viewModel.wasOriginallyPassed,
            hasChanges: viewModel.hasChanges,
            onSave: {
                viewModel.saveTrainingAsPassed(
                    activitiesService: activitiesService,
                    modelContext: modelContext
                )
                dismiss()
            },
            onStartTraining: viewModel.startTraining
        )
        .padding(.horizontal)
    }
}

#if DEBUG
#Preview {
    NavigationStack {
        WorkoutPreviewScreen(day: 50)
            .environment(DailyActivitiesService(client: MockDaysClient(result: .success)))
            .modelContainer(PreviewModelContainer.make(with: .preview))
    }
}
#endif
