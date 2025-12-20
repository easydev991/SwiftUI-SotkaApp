import SWDesignSystem
import SwiftData
import SwiftUI
import SWUtils

struct WorkoutPreviewScreen: View {
    @Environment(\.restTime) private var restTime
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(StatusManager.self) private var statusManager
    @Environment(\.currentDay) private var currentDay
    @State private var viewModel = WorkoutPreviewViewModel()
    @State private var showEditorScreen = false
    @State private var showWorkoutScreen = false
    @FocusState private var isCommentFocused: Bool
    let activitiesService: DailyActivitiesService
    let day: Int

    var body: some View {
        NavigationStack {
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
            .fullScreenCover(isPresented: $showWorkoutScreen) {
                if let executionType = viewModel.selectedExecutionType {
                    WorkoutScreen(
                        dayNumber: day,
                        executionType: executionType,
                        trainings: viewModel.trainings,
                        plannedCount: viewModel.plannedCount,
                        restTime: viewModel.restTime,
                        onWorkoutCompleted: { result in
                            viewModel.handleWorkoutResult(result)
                            showWorkoutScreen = false
                        }
                    )
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                viewModel.updateData(modelContext: modelContext, day: day, restTime: restTime)
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
}

private extension WorkoutPreviewScreen {
    var openEditorButton: some View {
        Button {
            showEditorScreen.toggle()
        } label: {
            Image(systemName: "pencil")
        }
        .accessibilityIdentifier("OpenWorkoutEditorButton")
        .sheet(isPresented: $showEditorScreen) {
            WorkoutExerciseEditorScreen(viewModel: viewModel)
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
                    if viewModel.canEditComment {
                        Divider()
                        commentEditor
                    }
                }
            }
            .padding()
        }
        .scrollBounceBehavior(.basedOnSize)
    }

    func makeTrainingRowView(for training: WorkoutPreviewTraining) -> some View {
        TrainingRowView(
            id: training.id,
            image: makeExerciseImage(for: training),
            title: makeExerciseTitle(for: training),
            count: training.count,
            onAction: { id, action in
                viewModel.updatePlannedCount(id: id, action: action)
            }
        )
    }

    func makePlannedCountView(for executionType: ExerciseExecutionType) -> some View {
        TrainingRowView(
            id: "plannedCount",
            image: viewModel.displayExecutionType(for: executionType).image,
            title: viewModel.displayExecutionType(for: executionType).localizedTitle,
            count: viewModel.displayedCount,
            onAction: { id, action in
                viewModel.updatePlannedCount(id: id, action: action)
            },
            isDisabled: viewModel.isPlannedCountDisabled
        )
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

    func makeExerciseImage(for training: WorkoutPreviewTraining) -> Image {
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

    func makeExerciseTitle(for training: WorkoutPreviewTraining) -> String {
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
            isWorkoutCompleted: viewModel.isWorkoutCompleted,
            onSave: {
                viewModel.saveTrainingAsPassed(
                    activitiesService: activitiesService,
                    modelContext: modelContext
                )
                // Отправляем данные на часы после сохранения
                if currentDay == day {
                    let currentActivity = activitiesService.getActivityType(day: day, context: modelContext)
                    statusManager.sendCurrentStatus(
                        isAuthorized: true,
                        currentDay: currentDay,
                        currentActivity: currentActivity
                    )
                }
                dismiss()
            },
            onStartTraining: {
                showWorkoutScreen = true
            }
        )
        .padding([.horizontal, .bottom])
    }
}

#if DEBUG
#Preview {
    NavigationStack {
        WorkoutPreviewScreen(
            activitiesService: DailyActivitiesService(client: MockDaysClient(result: .success)),
            day: 50
        )
        .modelContainer(PreviewModelContainer.make(with: .preview))
    }
}
#endif
