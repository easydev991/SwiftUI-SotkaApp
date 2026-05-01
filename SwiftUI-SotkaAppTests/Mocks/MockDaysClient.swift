import Foundation
@testable import SwiftUI_SotkaApp
import SWUtils

final class MockDaysClient: DaysClient, @unchecked Sendable {
    // MARK: - Properties

    /// Флаг для имитации ошибок
    var shouldThrowError = false

    /// Кастомная ошибка для выброса
    var errorToThrow: Error = MockDaysClient.MockError.demoError

    /// Счетчики вызовов методов
    var getDaysCallCount = 0
    var updateDayCallCount = 0
    var deleteDayCallCount = 0

    /// Массивы для отслеживания всех вызовов
    var updateDayCalls: [DayRequest] = []
    var deleteDayCalls: [Int] = []

    /// Словарь для хранения активностей по дням (для имитации сервера)
    private var serverActivities: [Int: DayResponse] = [:]

    /// Множество дней, которые были установлены через setServerActivity и должны сохраняться даже после deleteDay
    private var preservedDays: Set<Int> = []

    // MARK: - Initialization

    init(mockedDayResponses: [DayResponse] = []) {
        for response in mockedDayResponses {
            serverActivities[response.id] = response
        }
    }

    // MARK: - DaysClient Implementation

    func getDays() async throws -> [DayResponse] {
        getDaysCallCount += 1
        if shouldThrowError {
            throw errorToThrow
        }
        return Array(serverActivities.values)
    }

    func updateDay(model: DayRequest) async throws -> DayResponse {
        updateDayCallCount += 1
        updateDayCalls.append(model)
        if shouldThrowError { throw errorToThrow }
        let response = DayResponse(
            id: model.id, activityType: model.activityType, count: model.count,
            plannedCount: model.plannedCount, executeType: model.executeType,
            trainType: model.trainingType,
            trainings: model.trainings?.map { DayResponse.Training(
                typeId: $0.typeId,
                customTypeId: $0.customTypeId,
                count: $0.count,
                sortOrder: nil
            ) },
            createDate: Date(), modifyDate: nil, duration: model.duration, comment: model.comment
        )
        serverActivities[model.id] = response
        return response
    }

    func deleteDay(day: Int) async throws {
        deleteDayCallCount += 1
        deleteDayCalls.append(day)

        if shouldThrowError {
            throw errorToThrow
        }

        // Удаляем из словаря, если день не в preservedDays
        if !preservedDays.contains(day) {
            serverActivities.removeValue(forKey: day)
        }
    }

    // MARK: - Helper Methods

    /// Устанавливает активность на сервере напрямую (для тестирования)
    /// Активность будет сохранена даже после вызова deleteDay
    func setServerActivity(_ response: DayResponse) {
        serverActivities[response.id] = response
        preservedDays.insert(response.id)
    }
}

extension MockDaysClient {
    /// Ошибка для тестирования
    enum MockError: Error {
        case demoError
    }
}
