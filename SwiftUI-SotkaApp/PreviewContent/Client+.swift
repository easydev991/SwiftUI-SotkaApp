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
            return .init(date: .now)
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
            return .init(date: .now)
        case let .failure(error):
            throw error
        }
    }
}
