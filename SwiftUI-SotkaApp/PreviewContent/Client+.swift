import Foundation
import SWUtils

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

struct MockProgressClient: ProgressClient {
    let result: MockResult

    func getProgress() async throws -> [ProgressResponse] {
        print("Имитируем запрос getProgress")
        try await Task.sleep(for: .seconds(1))
        switch result {
        case .success:
            print("Успешно получили список прогресса")
            return [
                .init(
                    id: 1,
                    pullups: 10,
                    pushups: 20,
                    squats: 30,
                    weight: 70.0,
                    createDate: "2025-01-01 12:00:00",
                    modifyDate: "2025-01-01 12:00:00"
                ),
                .init(
                    id: 50,
                    pullups: 15,
                    pushups: 25,
                    squats: 35,
                    weight: 72.0,
                    createDate: "2025-01-02 12:00:00",
                    modifyDate: "2025-01-02 12:00:00"
                )
            ]
        case let .failure(error):
            throw error
        }
    }

    func createProgress(progress: ProgressRequest) async throws -> ProgressResponse {
        print("Имитируем запрос createProgress (day=\(progress.id))")
        try await Task.sleep(for: .seconds(1))
        switch result {
        case .success:
            print("Успешно создали прогресс")
            return .init(
                id: progress.id,
                pullups: progress.pullups,
                pushups: progress.pushups,
                squats: progress.squats,
                weight: progress.weight,
                createDate: DateFormatterService.stringFromFullDate(Date(), format: .serverDateTimeSec),
                modifyDate: progress.modifyDate
            )
        case let .failure(error):
            throw error
        }
    }

    func updateProgress(day: Int, progress: ProgressRequest) async throws -> ProgressResponse {
        print("Имитируем запрос updateProgress (day=\(day))")
        try await Task.sleep(for: .seconds(1))
        switch result {
        case .success:
            print("Успешно обновили прогресс")
            return .init(
                id: progress.id,
                pullups: progress.pullups,
                pushups: progress.pushups,
                squats: progress.squats,
                weight: progress.weight,
                createDate: DateFormatterService.stringFromFullDate(Date(), format: .serverDateTimeSec),
                modifyDate: progress.modifyDate
            )
        case let .failure(error):
            throw error
        }
    }

    func deleteProgress(day: Int) async throws {
        print("Имитируем запрос deleteProgress (day=\(day))")
        try await Task.sleep(for: .seconds(1))
        switch result {
        case .success:
            print("Успешно удалили прогресс")
        case let .failure(error):
            throw error
        }
    }
}

struct MockInfopostsClient: InfopostsClient {
    let result: MockResult

    func getReadPosts() async throws -> [Int] {
        print("Имитируем запрос getReadPosts")
        try await Task.sleep(for: .seconds(1))
        switch result {
        case .success:
            print("Успешно получили список прочитанных инфопостов")
            return [1, 3, 5, 7, 10]
        case let .failure(error):
            throw error
        }
    }

    func setPostRead(day: Int) async throws {
        print("Имитируем запрос setPostRead (day=\(day))")
        try await Task.sleep(for: .seconds(1))
        switch result {
        case .success:
            print("Успешно отметили инфопост \(day) как прочитанный")
        case let .failure(error):
            throw error
        }
    }

    func deleteAllReadPosts() async throws {
        print("Имитируем запрос deleteAllReadPosts")
        try await Task.sleep(for: .seconds(1))
        switch result {
        case .success:
            print("Успешно удалили все прочитанные инфопосты")
        case let .failure(error):
            throw error
        }
    }
}
