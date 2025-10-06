import Foundation

struct MockLoginClient: LoginClient {
    let result: MockResult

    func logIn(with _: String?) async throws -> Int {
        print("Имитируем запрос logIn")
        try await Task.sleep(for: .seconds(1))
        switch result {
        case .success:
            print("Успешно авторизовались")
            return UserResponse.preview.id
        case let .failure(error):
            throw error
        }
    }

    func getUserByID(_: Int) async throws -> UserResponse {
        print("Имитируем запрос getUserByID")
        try await Task.sleep(for: .seconds(1))
        switch result {
        case .success:
            print("Успешно получили данные пользователя")
            return .preview
        case let .failure(error):
            throw error
        }
    }

    func resetPassword(for _: String) async throws {
        print("Имитируем запрос resetPassword")
        try await Task.sleep(for: .seconds(1))
        switch result {
        case .success:
            print("Успешно сбросили пароль")
        case let .failure(error):
            throw error
        }
    }
}

extension MockLoginClient: StatusClient {
    func start(date _: String) async throws -> CurrentRun {
        print("Имитируем запрос start")
        try await Task.sleep(for: .seconds(1))
        switch result {
        case .success:
            print("Успешно cтартовали сотку")
            return .init(date: .now, maxForAllRunsDay: 0)
        case let .failure(error):
            throw error
        }
    }

    func current() async throws -> CurrentRun {
        print("Имитируем запрос current")
        try await Task.sleep(for: .seconds(1))
        switch result {
        case .success:
            print("Успешно получили статус прохождения сотки")
            return .init(date: .now, maxForAllRunsDay: 0)
        case let .failure(error):
            throw error
        }
    }
}

struct MockExerciseClient: ExerciseClient {
    let result: MockResult

    func getCustomExercises() async throws -> [CustomExerciseResponse] {
        print("Имитируем запрос getCustomExercises")
        try await Task.sleep(for: .seconds(1))
        switch result {
        case .success:
            print("Успешно получили список пользовательских упражнений")
            return [
                .init(
                    id: "111",
                    name: "Отжимания с хлопком",
                    imageId: 1,
                    createDate: "2025-01-01 12:00:00",
                    modifyDate: "2025-01-01 12:00:00",
                    isHidden: false
                ),
                .init(
                    id: "222",
                    name: "Прыжки на тумбу",
                    imageId: 2,
                    createDate: "2025-01-02 12:00:00",
                    modifyDate: "2025-01-02 12:00:00",
                    isHidden: false
                )
            ]
        case let .failure(error):
            throw error
        }
    }

    func saveCustomExercise(id: String, exercise: CustomExerciseRequest) async throws -> CustomExerciseResponse {
        print("Имитируем запрос saveCustomExercise (id=\(id))")
        try await Task.sleep(for: .seconds(1))
        switch result {
        case .success:
            print("Успешно сохранили пользовательское упражнение")
            return .init(
                id: exercise.id,
                name: exercise.name,
                imageId: exercise.imageId,
                createDate: exercise.createDate,
                modifyDate: exercise.modifyDate ?? exercise.createDate,
                isHidden: exercise.isHidden
            )
        case let .failure(error):
            throw error
        }
    }

    func deleteCustomExercise(id: String) async throws {
        print("Имитируем запрос deleteCustomExercise (id=\(id))")
        try await Task.sleep(for: .seconds(1))
        switch result {
        case .success:
            print("Успешно удалили пользовательское упражнение")
        case let .failure(error):
            throw error
        }
    }
}
