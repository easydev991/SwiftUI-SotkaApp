import Foundation

/// Протокол для WatchConnectivityService для тестирования
@MainActor
protocol WatchConnectivityServiceProtocol {
    var currentDay: Int? { get }
    var currentActivity: DayActivityType? { get }
    var restTime: Int? { get }
    var onCurrentActivityChanged: ((DayActivityType?) -> Void)? { get set }
    var onWorkoutDataReceived: ((WorkoutDataResponse) -> Void)? { get set }
    func sendActivityType(day: Int, activityType: DayActivityType) async throws
    func requestCurrentActivity(day: Int) async throws -> DayActivityType?
    func requestWorkoutData(day: Int) async throws -> WorkoutDataResponse
    func sendWorkoutResult(
        day: Int,
        result: WorkoutResult,
        executionType: ExerciseExecutionType,
        trainings: [WorkoutPreviewTraining],
        comment: String?
    ) async throws
    func deleteActivity(day: Int) async throws
}

/// WatchConnectivityService соответствует протоколу
extension WatchConnectivityService: WatchConnectivityServiceProtocol {}
