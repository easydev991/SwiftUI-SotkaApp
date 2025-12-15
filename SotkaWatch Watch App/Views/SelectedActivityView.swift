import SwiftUI

struct SelectedActivityView: View {
    @Environment(\.currentDay) private var currentDay
    @State private var shouldShowDeleteConfirmation = false
    private let mode: Mode
    private let comment: String?
    private let onSelect: (DayActivityType) -> Void
    private let onDelete: (Int) -> Void

    init(
        activity: DayActivityType,
        onSelect: @escaping (DayActivityType) -> Void,
        onDelete: @escaping (Int) -> Void,
        workoutData: WorkoutData?,
        workoutExecutionCount: Int?,
        comment: String?
    ) {
        self.mode = .init(
            activity: activity,
            data: workoutData,
            executionCount: workoutExecutionCount
        )
        self.comment = comment
        self.onSelect = onSelect
        self.onDelete = onDelete
    }

    var body: some View {
        ZStack {
            switch mode {
            case let .workout(data, executionCount):
                ScrollView {
                    VStack(spacing: 8) {
                        makeHeaderView(for: .workout)
                        WatchDayActivityTrainingView(
                            workoutData: data,
                            executionCount: executionCount
                        )
                        WatchDayActivityCommentView(comment: comment)
                    }
                }
            case let .nonWorkout(activity):
                if let comment, !comment.isEmpty {
                    ScrollView {
                        VStack(spacing: 8) {
                            makeHeaderView(for: activity)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            WatchDayActivityCommentView(comment: comment)
                        }
                    }
                } else {
                    makeHeaderView(for: activity)
                }
            }
        }
        .animation(.default, value: mode)
        .padding(.horizontal)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                deleteButton
            }
            ToolbarItem(placement: .topBarTrailing) {
                editButton
            }
        }
    }
}

extension SelectedActivityView {
    enum Mode: Equatable {
        case workout(data: WorkoutData, executionCount: Int?)
        case nonWorkout(DayActivityType)

        var isWorkout: Bool {
            if case .workout = self { true } else { false }
        }

        var activity: DayActivityType {
            switch self {
            case .workout: .workout
            case let .nonWorkout(activity): activity
            }
        }

        init(activity: DayActivityType, data: WorkoutData?, executionCount: Int?) {
            if activity == .workout, let data {
                self = .workout(data: data, executionCount: executionCount)
            } else {
                self = .nonWorkout(activity)
            }
        }
    }
}

private extension SelectedActivityView {
    @ViewBuilder
    func makeHeaderView(for activity: DayActivityType) -> some View {
        if activity == .workout {
            Text(activity.localizedTitle)
                .frame(maxWidth: .infinity, alignment: .leading)
                .bold()
        } else {
            HStack(spacing: 12) {
                activity.image
                    .padding()
                    .background {
                        Circle().fill(activity.color)
                    }
                Text(activity.localizedTitle).bold()
            }
        }
    }

    var deleteButton: some View {
        Button(role: .destructive) {
            shouldShowDeleteConfirmation = true
        } label: {
            Image(systemName: "trash")
        }
        .confirmationDialog(
            .journalDeleteEntry,
            isPresented: $shouldShowDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button(.journalDelete, role: .destructive) {
                onDelete(currentDay)
            }
        } message: {
            Text(.journalDeleteEntryMessage(currentDay))
        }
    }

    @ViewBuilder
    var editButton: some View {
        if mode.isWorkout {
            Button {
                onSelect(.workout)
            } label: {
                Image(systemName: "pencil")
            }
        } else {
            NavigationLink {
                DayActivitySelectionView(
                    onSelect: onSelect,
                    selectedActivity: mode.activity
                )
            } label: {
                Image(systemName: "pencil")
            }
        }
    }
}

#Preview("Отдых без коммента") {
    NavigationStack {
        SelectedActivityView(
            activity: .rest,
            onSelect: { _ in },
            onDelete: { _ in },
            workoutData: nil,
            workoutExecutionCount: nil,
            comment: nil
        )
        .currentDay(10)
    }
}

#Preview("Отдых с комментом") {
    NavigationStack {
        SelectedActivityView(
            activity: .rest,
            onSelect: { _ in },
            onDelete: { _ in },
            workoutData: nil,
            workoutExecutionCount: nil,
            comment: "Отлично отдыхается сегодня, как же классно отдохнуть!"
        )
        .currentDay(10)
    }
}

#Preview("Тренировка") {
    NavigationStack {
        SelectedActivityView(
            activity: .workout,
            onSelect: { _ in },
            onDelete: { _ in },
            workoutData: .init(
                day: 10,
                executionType: ExerciseExecutionType.cycles.rawValue,
                trainings: [
                    .init(
                        count: 10,
                        typeId: ExerciseType.pullups.rawValue,
                        sortOrder: 0
                    ),
                    .init(
                        count: 20,
                        typeId: ExerciseType.pushups.rawValue,
                        sortOrder: 1
                    )
                ],
                plannedCount: 4
            ),
            workoutExecutionCount: 4,
            comment: "Отличная тренировка!"
        )
        .navigationTitle(.day(number: 2))
        .currentDay(2)
    }
}
