import Foundation
@testable import SotkaWatch_Watch_App

/// Мок сервиса записи в HealthKit: фиксирует вызовы разрешения и сохранения
@MainActor
final class HealthKitWorkoutWritingMock: HealthKitWorkoutWriting {
    private(set) var authorizationRequestCount = 0
    private(set) var savedWorkouts: [(startDate: Date, endDate: Date)] = []

    func requestWriteAuthorization() async {
        authorizationRequestCount += 1
    }

    func saveWorkout(startDate: Date, endDate: Date) async {
        savedWorkouts.append((startDate, endDate))
    }
}
