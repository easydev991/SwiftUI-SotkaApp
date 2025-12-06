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
        // Заглушка для превью
    }

    func requestCurrentActivity(day _: Int) async throws -> DayActivityType? {
        // Заглушка для превью
        nil
    }

    func requestWorkoutData(day: Int) async throws -> WorkoutData {
        // Заглушка для превью
        WorkoutData(
            day: day,
            executionType: 0,
            trainings: [],
            plannedCount: 4
        )
    }

    func sendWorkoutResult(day _: Int, result _: WorkoutResult, executionType _: ExerciseExecutionType) async throws {
        // Заглушка для превью
    }

    func deleteActivity(day _: Int) async throws {
        // Заглушка для превью
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
