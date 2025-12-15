import Foundation
import Observation

@MainActor
@Observable
final class PreviewWatchAuthService: WatchAuthServiceProtocol {
    var isAuthorized: Bool

    init(isAuthorized: Bool = false) {
        self.isAuthorized = isAuthorized
    }

    func checkAuthStatus() -> Bool {
        isAuthorized
    }

    func updateAuthStatus(_ isAuthorized: Bool) {
        self.isAuthorized = isAuthorized
    }
}

@MainActor
final class PreviewWatchConnectivityService: WatchConnectivityServiceProtocol {
    func sendActivityType(day _: Int, activityType _: DayActivityType) async throws {
        print("Заглушка sendActivityType")
    }

    func requestCurrentActivity(day _: Int) async throws -> DayActivityType? {
        .workout
    }

    func requestWorkoutData(day: Int) async throws -> WorkoutDataResponse {
        WorkoutDataResponse(
            workoutData: .init(
                day: day,
                executionType: 0,
                trainings: .previewSets,
                plannedCount: 4
            ),
            executionCount: nil,
            comment: nil
        )
    }

    func sendWorkoutResult(day _: Int, result _: WorkoutResult, executionType _: ExerciseExecutionType, comment _: String?) async throws {
        print("Заглушка sendWorkoutResult")
    }

    func deleteActivity(day _: Int) async throws {
        print("Заглушка deleteActivity")
    }
}

/// Мок для WatchAppGroupHelper для превью
struct PreviewWatchAppGroupHelper: WatchAppGroupHelperProtocol {
    var isAuthorized: Bool
    var startDate: Date?
    var restTime: Int

    var currentDay: Int? {
        guard let startDate else {
            return nil
        }
        let calculator = DayCalculator(startDate, Date.now)
        return calculator.currentDay
    }

    init(
        isAuthorized: Bool = false,
        startDate: Date? = nil,
        restTime: Int = 60
    ) {
        self.isAuthorized = isAuthorized
        self.startDate = startDate
        self.restTime = restTime
    }
}
