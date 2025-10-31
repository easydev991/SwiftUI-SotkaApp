import Foundation
import SWNetwork

/// Сервис для обращений к серверу
struct SWClient: Sendable {
    /// Сервис, предоставляющий токен и выполняющий логаут
    let authHelper: AuthHelper
    /// Сервис для отправки запросов/получения ответов от сервера
    private let service: SWNetworkProtocol

    /// Инициализатор
    /// - Parameter authHelper: Сервис, предоставляющий токен и выполняющий логаут
    init(with authHelper: AuthHelper) {
        self.authHelper = authHelper
        self.service = SWNetworkService()
    }
}

extension SWClient: LoginClient {
    func logIn(with token: String?) async throws -> Int {
        struct Response: Decodable { let userId: Int }
        let endpoint = Endpoint.login
        let finalComponents = try await makeComponents(for: endpoint, with: token)
        let result: Response = try await service.requestData(components: finalComponents)
        return result.userId
    }

    func getUserByID(_ userID: Int) async throws -> UserResponse {
        let endpoint = Endpoint.getUser(id: userID)
        return try await makeResult(for: endpoint)
    }

    func resetPassword(for login: String) async throws {
        let endpoint = Endpoint.resetPassword(login: login)
        try await makeStatus(for: endpoint)
    }
}

extension SWClient: ProfileClient {
    func editUser(_ id: Int, model: MainUserForm) async throws -> UserResponse {
        let endpoint = Endpoint.editUser(id: id, form: model)
        return try await makeResult(for: endpoint)
    }

    func changePassword(current: String, new: String) async throws {
        let endpoint = Endpoint.changePassword(currentPass: current, newPass: new)
        try await makeStatus(for: endpoint)
    }
}

extension SWClient: CountryClient {
    func getCountries() async throws -> [CountryResponse] {
        let endpoint = Endpoint.getCountries
        return try await makeResult(for: endpoint)
    }
}

extension SWClient: StatusClient {
    func start(date: String) async throws -> CurrentRun {
        let endpoint = Endpoint.start(date)
        return try await makeResult(for: endpoint)
    }

    func current() async throws -> CurrentRun {
        let endpoint = Endpoint.current
        return try await makeResult(for: endpoint)
    }
}

extension SWClient: ExerciseClient {
    func getCustomExercises() async throws -> [CustomExerciseResponse] {
        let endpoint = Endpoint.getCustomExercises
        return try await makeResult(for: endpoint)
    }

    func saveCustomExercise(id: String, exercise: CustomExerciseRequest) async throws -> CustomExerciseResponse {
        let endpoint = Endpoint.saveCustomExercise(id: id, exercise: exercise)
        return try await makeResult(for: endpoint)
    }

    func deleteCustomExercise(id: String) async throws {
        let endpoint = Endpoint.deleteCustomExercise(id: id)
        try await makeStatus(for: endpoint)
    }
}

extension SWClient: InfopostsClient {
    func getReadPosts() async throws -> [Int] {
        let endpoint = Endpoint.getReadPosts
        return try await makeResult(for: endpoint)
    }

    func setPostRead(day: Int) async throws {
        let endpoint = Endpoint.setPostRead(day: day)
        try await makeStatus(for: endpoint)
    }

    func deleteAllReadPosts() async throws {
        let endpoint = Endpoint.deleteAllReadPosts
        try await makeStatus(for: endpoint)
    }
}

extension SWClient: ProgressClient {
    func getProgress() async throws -> [ProgressResponse] {
        let endpoint = Endpoint.getProgress
        return try await makeResult(for: endpoint)
    }

    func getProgress(day: Int) async throws -> ProgressResponse {
        let endpoint = Endpoint.getProgressDay(day: day)
        do {
            return try await makeResult(for: endpoint)
        } catch APIError.notFound {
            throw ClientError.progressNotFound(day: day)
        } catch {
            throw error
        }
    }

    func createProgress(progress: ProgressRequest) async throws -> ProgressResponse {
        let endpoint = Endpoint.createProgress(progress)
        return try await makeResult(for: endpoint)
    }

    func updateProgress(day: Int, progress: ProgressRequest) async throws -> ProgressResponse {
        let endpoint = Endpoint.updateProgress(day: day, progress: progress)
        return try await makeResult(for: endpoint)
    }

    func deleteProgress(day: Int) async throws {
        let endpoint = Endpoint.deleteProgress(day: day)
        try await makeStatus(for: endpoint)
    }

    func deletePhoto(day: Int, type: String) async throws {
        let endpoint = Endpoint.deleteProgressPhoto(day: day, type: type)
        try await makeStatus(for: endpoint)
    }
}

extension SWClient: DaysClient {
    func getDays() async throws -> [DayResponse] {
        let endpoint = Endpoint.getDays
        return try await makeResult(for: endpoint)
    }

    func createDay(_ day: DayRequest) async throws -> DayResponse {
        let endpoint = Endpoint.createDay(day)
        return try await makeResult(for: endpoint)
    }

    func updateDay(model: DayRequest) async throws -> DayResponse {
        let endpoint = Endpoint.updateDay(dayModel: model)
        return try await makeResult(for: endpoint)
    }

    func deleteDay(day: Int) async throws {
        let endpoint = Endpoint.deleteDay(day: day)
        try await makeStatus(for: endpoint)
    }
}

enum ClientError: Error, LocalizedError {
    case forceLogout
    case noConnection
    case progressNotFound(day: Int)

    var errorDescription: String? {
        switch self {
        case .forceLogout: String(localized: .errorForceLogout)
        case .noConnection: String(localized: .errorNoConnection)
        case let .progressNotFound(day): String(localized: "Progress.Error.NotFound \(day)")
        }
    }
}

enum Endpoint {
    // MARK: Получить список стран/городов
    /// **GET** ${API}/countries
    case getCountries

    // MARK: Авторизация
    /// **POST** ${API}/auth/login
    case login

    // MARK: Получить профиль пользователя
    /// **GET** ${API}/users/<user_id>
    /// `id` - идентификатор пользователя, чей профиль нужно получить
    case getUser(id: Int)

    // MARK: Восстановление пароля
    /// **POST** ${API}/auth/reset
    case resetPassword(login: String)

    // MARK: Изменить данные пользователя
    /// **POST** ${API}/users/<user_id>
    case editUser(id: Int, form: MainUserForm)

    // MARK: Изменить пароль
    /// **POST** ${API}/auth/changepass
    case changePassword(currentPass: String, newPass: String)

    // MARK: Стартовать сотку
    /// **POST** ${API}/100/start
    case start(_ date: String)

    // MARK: Статус сотки пользователя
    /// **GET** ${API}/100/current_run
    case current

    // MARK: Получить список пользовательских упражнений
    /// **GET** ${API}/100/custom_exercises
    case getCustomExercises

    // MARK: Сохранить пользовательское упражнение
    /// **POST** ${API}/100/custom_exercises
    case saveCustomExercise(id: String, exercise: CustomExerciseRequest)

    // MARK: Удалить пользовательское упражнение
    /// **DELETE** ${API}/100/custom_exercises/<id>
    case deleteCustomExercise(id: String)

    // MARK: Получить прочитанные инфопосты
    /// **GET** ${API}/100/posts/read
    case getReadPosts

    // MARK: Отметить инфопост как прочитанный
    /// **POST** ${API}/100/posts/read/<day>
    case setPostRead(day: Int)

    // MARK: Удалить все прочитанные инфопосты
    /// **DELETE** ${API}/100/posts/read
    case deleteAllReadPosts

    // MARK: Получить список прогресса пользователя
    /// **GET** ${API}/100/progress
    case getProgress

    // MARK: Получить прогресс для конкретного дня
    /// **GET** ${API}/100/progress/<day>
    case getProgressDay(day: Int)

    // MARK: Создать новый прогресс
    /// **POST** ${API}/100/progress
    case createProgress(_ progress: ProgressRequest)

    // MARK: Обновить существующий прогресс для конкретного дня
    /// **POST** ${API}/100/progress/<day>
    case updateProgress(day: Int, progress: ProgressRequest)

    // MARK: Удалить прогресс для конкретного дня
    /// **DELETE** ${API}/100/progress/<day>
    case deleteProgress(day: Int)

    // MARK: Удалить фотографию прогресса для конкретного дня
    /// **DELETE** ${API}/100/progress/<day>/photos/<type>
    case deleteProgressPhoto(day: Int, type: String)

    // MARK: Дни тренировок (дневник)
    /// **GET** ${API}/100/days
    case getDays
    /// **POST** ${API}/100/days
    case createDay(_ day: DayRequest)
    /// **POST** ${API}/100/days/<day>
    case updateDay(dayModel: DayRequest)
    /// **DELETE** ${API}/100/days/<day>
    case deleteDay(day: Int)

    var urlPath: String {
        switch self {
        case .getCountries: "/countries"
        case .login: "/auth/login"
        case let .getUser(id): "/users/\(id)"
        case .resetPassword: "/auth/reset"
        case let .editUser(userID, _): "/users/\(userID)"
        case .changePassword: "/auth/changepass"
        case .start: "/100/start"
        case .current: "/100/current_run"
        case .getCustomExercises: "/100/custom_exercises"
        case let .saveCustomExercise(id, _): "/100/custom_exercises/\(id)"
        case let .deleteCustomExercise(id): "/100/custom_exercises/\(id)"
        case .getReadPosts: "/100/posts/read"
        case let .setPostRead(day): "/100/posts/read/\(day)"
        case .deleteAllReadPosts: "/100/posts/read"
        case .getProgress: "/100/progress"
        case let .getProgressDay(day): "/100/progress/\(day)"
        case .createProgress: "/100/progress"
        case let .updateProgress(day, _): "/100/progress/\(day)"
        case let .deleteProgress(day): "/100/progress/\(day)"
        case let .deleteProgressPhoto(day, type): "/100/progress/\(day)/photos/\(type)"
        case .getDays, .createDay: "/100/days"
        case let .updateDay(dayModel): "/100/days/\(dayModel.id)"
        case let .deleteDay(day): "/100/days/\(day)"
        }
    }

    var method: HTTPMethod {
        switch self {
        case .login, .resetPassword, .editUser, .changePassword, .start, .saveCustomExercise, .setPostRead, .createProgress,
             .updateProgress, .createDay, .updateDay: .post
        case .getProgressDay: .get
        case .getUser, .getCountries, .current, .getCustomExercises, .getReadPosts, .getProgress, .getDays: .get
        case .deleteCustomExercise, .deleteAllReadPosts, .deleteProgress, .deleteProgressPhoto, .deleteDay: .delete
        }
    }

    var hasMultipartFormData: Bool {
        switch self {
        case .editUser, .createProgress, .updateProgress: true
        case .getProgressDay: false
        case .login, .getUser, .resetPassword, .getCountries, .changePassword, .start, .current, .getCustomExercises, .saveCustomExercise,
             .deleteCustomExercise, .getReadPosts, .setPostRead, .deleteAllReadPosts, .getProgress, .deleteProgress,
             .deleteProgressPhoto, .getDays, .createDay, .updateDay, .deleteDay: false
        }
    }

    var queryItems: [URLQueryItem] {
        switch self {
        case .login, .getUser, .resetPassword, .getCountries, .editUser, .changePassword, .start, .current, .getCustomExercises,
             .saveCustomExercise, .deleteCustomExercise, .getReadPosts, .setPostRead, .deleteAllReadPosts, .getProgress, .getProgressDay,
             .createProgress,
             .updateProgress, .deleteProgress, .deleteProgressPhoto, .getDays, .createDay, .updateDay, .deleteDay: []
        }
    }

    var bodyParts: BodyMaker.Parts? {
        switch self {
        case .login, .getUser, .getCountries, .current, .getCustomExercises, .deleteCustomExercise, .getReadPosts, .setPostRead,
             .deleteAllReadPosts, .getProgress, .getProgressDay, .deleteProgress, .deleteProgressPhoto, .getDays, .deleteDay:
            return nil
        case let .editUser(_, form):
            let parameters = form.requestParameters
            let mediaFiles: [BodyMaker.MediaFile]? = if let image = form.image {
                [
                    BodyMaker.MediaFile(
                        key: "image",
                        filename: "\(UUID().uuidString).jpg",
                        data: image.data,
                        mimeType: image.mimeType
                    )
                ]
            } else {
                nil
            }
            return .init(parameters, mediaFiles)
        case let .changePassword(current, new):
            return .init(["password": current, "new_password": new], nil)
        case let .resetPassword(login):
            return .init(["username_or_email": login], nil)
        case let .start(date):
            return .init(["date": date], nil)
        case let .saveCustomExercise(_, exercise):
            return .init(exercise.formParameters, nil)
        case let .createProgress(progress), let .updateProgress(_, progress):
            let parameters = progress.requestParameters

            // Пустые медиа-файлы для удаления фото добавляются ниже
            // Создаем медиа-файлы для отправки фото
            var mediaFiles: [BodyMaker.MediaFile] = []

            if let photos = progress.photos, !photos.isEmpty {
                for (key, data) in photos {
                    guard !data.isEmpty else { continue }
                    mediaFiles.append(BodyMaker.MediaFile(
                        key: key,
                        filename: "\(UUID().uuidString).jpg",
                        data: data,
                        mimeType: "image/jpeg"
                    ))
                }
            }

            // Добавляем пустые медиа-файлы для фото, помеченных для удаления
            if let photosToDelete = progress.photosToDelete {
                for photoKey in photosToDelete {
                    mediaFiles.append(BodyMaker.MediaFile(
                        key: photoKey,
                        filename: "\(UUID().uuidString).jpg",
                        data: Data(), // Пустые данные для удаления
                        mimeType: "image/jpeg"
                    ))
                }
            }

            return .init(parameters, mediaFiles)
        case let .createDay(dayModel), let .updateDay(dayModel):
            return .init(dayModel.formParameters, nil)
        }
    }
}

private extension SWClient {
    @discardableResult
    func makeStatus(for endpoint: Endpoint) async throws -> Bool {
        do {
            let finalComponents = try await makeComponents(for: endpoint)
            return try await service.requestStatus(components: finalComponents)
        } catch APIError.invalidCredentials {
            await authHelper.triggerLogout()
            throw ClientError.forceLogout
        } catch APIError.notConnectedToInternet {
            throw ClientError.noConnection
        } catch {
            throw error
        }
    }

    func makeResult<T: Decodable>(
        for endpoint: Endpoint,
        with token: String? = nil
    ) async throws -> T {
        do {
            let finalComponents = try await makeComponents(for: endpoint, with: token)
            return try await service.requestData(components: finalComponents)
        } catch APIError.invalidCredentials {
            await authHelper.triggerLogout()
            throw ClientError.forceLogout
        } catch APIError.notConnectedToInternet {
            throw ClientError.noConnection
        } catch {
            throw error
        }
    }

    func makeComponents(
        for endpoint: Endpoint,
        with token: String? = nil
    ) async throws -> RequestComponents {
        let savedToken = await authHelper.authToken
        return .init(
            path: endpoint.urlPath,
            queryItems: endpoint.queryItems,
            httpMethod: endpoint.method,
            hasMultipartFormData: endpoint.hasMultipartFormData,
            bodyParts: endpoint.bodyParts,
            token: token ?? savedToken
        )
    }
}
