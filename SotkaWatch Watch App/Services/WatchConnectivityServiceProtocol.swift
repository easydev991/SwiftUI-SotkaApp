import Foundation

/// Протокол для WatchConnectivityService для тестирования
@MainActor
protocol WatchConnectivityServiceProtocol {
    func sendActivityType(day: Int, activityType: DayActivityType) async throws
    func requestCurrentActivity(day: Int) async throws -> DayActivityType?
    func requestWorkoutData(day: Int) async throws -> WorkoutData
    func sendWorkoutResult(day: Int, result: WorkoutResult, executionType: ExerciseExecutionType) async throws
}

/// WatchConnectivityService соответствует протоколу
extension WatchConnectivityService: WatchConnectivityServiceProtocol {}
