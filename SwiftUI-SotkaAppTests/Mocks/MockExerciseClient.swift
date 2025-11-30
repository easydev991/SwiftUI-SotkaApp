import Foundation
@testable import SwiftUI_SotkaApp
import SWUtils

/// Mock клиент для тестирования логики пользовательских упражнений
final class MockExerciseClient: ExerciseClient, @unchecked Sendable {
    // MARK: - Properties

    /// Список моковых упражнений
    var mockedCustomExercises: [CustomExerciseResponse] = []

    /// Флаг для имитации ошибок
    var shouldThrowError = false

    /// Кастомная ошибка для выброса
    var errorToThrow: Error = MockExerciseClient.MockError.demoError

    /// Счетчики вызовов методов
    var getCustomExercisesCallCount = 0
    var saveCustomExerciseCallCount = 0
    var deleteCustomExerciseCallCount = 0

    /// Массивы для отслеживания всех вызовов
    var saveCustomExerciseCalls: [(id: String, exercise: CustomExerciseRequest)] = []
    var deleteCustomExerciseCalls: [String] = []

    /// Словарь для хранения упражнений по ID (для имитации сервера)
    private var serverExercises: [String: CustomExerciseResponse] = [:]

    // MARK: - Initialization

    init(mockedCustomExercises: [CustomExerciseResponse] = []) {
        self.mockedCustomExercises = mockedCustomExercises
        for exercise in mockedCustomExercises {
            serverExercises[exercise.id] = exercise
        }
    }

    // MARK: - ExerciseClient Implementation

    func getCustomExercises() async throws -> [CustomExerciseResponse] {
        getCustomExercisesCallCount += 1
        if shouldThrowError {
            throw errorToThrow
        }
        return Array(serverExercises.values)
    }

    func saveCustomExercise(id: String, exercise: CustomExerciseRequest) async throws -> CustomExerciseResponse {
        saveCustomExerciseCallCount += 1
        saveCustomExerciseCalls.append((id: id, exercise: exercise))

        if shouldThrowError {
            throw errorToThrow
        }

        // Создаем ответ на основе запроса
        let createDate = DateFormatterService.dateFromString(exercise.createDate, format: .serverDateTimeSec)
        let modifyDate: Date? = exercise.modifyDate.map {
            DateFormatterService.dateFromString($0, format: .serverDateTimeSec)
        }
        let response = CustomExerciseResponse(
            id: exercise.id,
            name: exercise.name,
            imageId: exercise.imageId,
            createDate: createDate,
            modifyDate: modifyDate,
            isHidden: exercise.isHidden
        )

        // Сохраняем в словаре для последующих вызовов getCustomExercises()
        serverExercises[exercise.id] = response

        return response
    }

    func deleteCustomExercise(id: String) async throws {
        deleteCustomExerciseCallCount += 1
        deleteCustomExerciseCalls.append(id)

        if shouldThrowError {
            throw errorToThrow
        }

        // Удаляем из словаря
        serverExercises.removeValue(forKey: id)
    }

    // MARK: - Helper Methods

    /// Сброс всех счетчиков и состояний
    func reset() {
        getCustomExercisesCallCount = 0
        saveCustomExerciseCallCount = 0
        deleteCustomExerciseCallCount = 0
        shouldThrowError = false
        saveCustomExerciseCalls.removeAll()
        deleteCustomExerciseCalls.removeAll()
        serverExercises.removeAll()
        for exercise in mockedCustomExercises {
            serverExercises[exercise.id] = exercise
        }
    }
}

extension MockExerciseClient {
    /// Ошибка для тестирования
    enum MockError: Error {
        case demoError
    }
}
