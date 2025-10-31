import Foundation
@testable import SwiftUI_SotkaApp
import SWUtils

final class MockDaysClient: DaysClient, @unchecked Sendable {
    // MARK: - Properties

    /// Список моковых ответов сервера для getDays()
    var mockedDayResponses: [DayResponse] = []

    /// Флаг для имитации ошибок
    var shouldThrowError = false

    /// Кастомная ошибка для выброса
    var errorToThrow: Error = NSError(domain: "TestError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Test error"])

    /// Счетчики вызовов методов
    var getDaysCallCount = 0
    var createDayCallCount = 0
    var updateDayCallCount = 0
    var deleteDayCallCount = 0

    /// Массивы для отслеживания всех вызовов
    var createDayCalls: [DayRequest] = []
    var updateDayCalls: [DayRequest] = []
    var deleteDayCalls: [Int] = []

    /// Словарь для хранения активностей по дням (для имитации сервера)
    private var serverActivities: [Int: DayResponse] = [:]

    /// Множество дней, которые были установлены через setServerActivity и должны сохраняться даже после deleteDay
    private var preservedDays: Set<Int> = []

    // MARK: - Initialization

    init(mockedDayResponses: [DayResponse] = []) {
        self.mockedDayResponses = mockedDayResponses
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

    func createDay(_ day: DayRequest) async throws -> DayResponse {
        createDayCallCount += 1
        createDayCalls.append(day)

        if shouldThrowError {
            throw errorToThrow
        }

        // Создаем ответ на основе запроса
        let response = DayResponse(
            id: day.id,
            activityType: day.activityType,
            count: day.count,
            plannedCount: day.plannedCount,
            executeType: day.executeType,
            trainType: day.trainingType,
            trainings: day.trainings?.map { training in
                DayResponse.Training(
                    typeId: training.typeId,
                    customTypeId: training.customTypeId,
                    count: training.count,
                    sortOrder: nil
                )
            },
            createDate: day.createDate ?? DateFormatterService.stringFromFullDate(Date(), format: .serverDateTimeSec),
            modifyDate: day.modifyDate ?? DateFormatterService.stringFromFullDate(Date(), format: .serverDateTimeSec),
            duration: day.duration,
            comment: day.comment
        )

        // Сохраняем в словаре для последующих вызовов getDays()
        serverActivities[day.id] = response

        return response
    }

    func updateDay(model: DayRequest) async throws -> DayResponse {
        updateDayCallCount += 1
        updateDayCalls.append(model)

        if shouldThrowError {
            throw errorToThrow
        }

        // Создаем ответ на основе запроса
        let response = DayResponse(
            id: model.id,
            activityType: model.activityType,
            count: model.count,
            plannedCount: model.plannedCount,
            executeType: model.executeType,
            trainType: model.trainingType,
            trainings: model.trainings?.map { training in
                DayResponse.Training(
                    typeId: training.typeId,
                    customTypeId: training.customTypeId,
                    count: training.count,
                    sortOrder: nil
                )
            },
            createDate: model.createDate ?? DateFormatterService.stringFromFullDate(Date(), format: .serverDateTimeSec),
            modifyDate: model.modifyDate ?? DateFormatterService.stringFromFullDate(Date(), format: .serverDateTimeSec),
            duration: model.duration,
            comment: model.comment
        )

        // Обновляем в словаре
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

    /// Удаляет активность с сервера напрямую (для тестирования)
    func removeServerActivity(day: Int) {
        serverActivities.removeValue(forKey: day)
    }

    /// Сброс всех счетчиков и состояний
    func reset() {
        getDaysCallCount = 0
        createDayCallCount = 0
        updateDayCallCount = 0
        deleteDayCallCount = 0
        shouldThrowError = false
        createDayCalls.removeAll()
        updateDayCalls.removeAll()
        deleteDayCalls.removeAll()
        serverActivities.removeAll()
        for response in mockedDayResponses {
            serverActivities[response.id] = response
        }
    }
}
