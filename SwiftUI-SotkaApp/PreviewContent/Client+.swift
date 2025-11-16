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
    func start(date _: String) async throws -> CurrentRunResponse {
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

    func current() async throws -> CurrentRunResponse {
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
                )
            ]
        case .failure:
            print("Ошибка получения списка прогресса")
            throw NSError(domain: "MockProgressClient", code: 1, userInfo: [NSLocalizedDescriptionKey: "Имитированная ошибка"])
        }
    }

    func getProgress(day: Int) async throws -> ProgressResponse {
        print("Имитируем запрос getProgress для дня \(day)")
        try await Task.sleep(for: .seconds(0.5))
        switch result {
        case .success:
            print("Успешно получили прогресс для дня \(day)")
            // Имитируем случай, когда день найден
            if day == 1 || day == 49 || day == 100 {
                return .init(
                    id: day,
                    pullups: 10,
                    pushups: 20,
                    squats: 30,
                    weight: 70.0,
                    createDate: "2025-01-01 12:00:00",
                    modifyDate: "2025-01-01 12:00:00"
                )
            } else {
                // День не найден - имитируем ошибку прогресса не найден
                throw NSError(
                    domain: "MockProgressClient",
                    code: 404,
                    userInfo: [NSLocalizedDescriptionKey: "Progress not found for day \(day)"]
                )
            }
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

    func deletePhoto(day: Int, type: String) async throws {
        print("Имитируем запрос deletePhoto (day=\(day), type=\(type))")
        try await Task.sleep(for: .seconds(1))
        switch result {
        case .success:
            print("Успешно удалили фотографию")
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

struct MockDaysClient: DaysClient {
    let result: MockResult

    func getDays() async throws -> [DayResponse] {
        print("Имитируем запрос getDays")
        try await Task.sleep(for: .seconds(1))
        switch result {
        case .success:
            print("Успешно получили список дней тренировок")
            return [
                .init(
                    id: 1,
                    activityType: 1,
                    count: 3,
                    plannedCount: 3,
                    executeType: 1,
                    trainType: 1,
                    trainings: [
                        .init(typeId: 1, customTypeId: nil, count: 10, sortOrder: 0),
                        .init(typeId: 2, customTypeId: nil, count: 20, sortOrder: 1)
                    ],
                    createDate: DateFormatterService.stringFromFullDate(Date(), format: .serverDateTimeSec),
                    modifyDate: DateFormatterService.stringFromFullDate(Date(), format: .serverDateTimeSec),
                    duration: 1800,
                    comment: "Тренировка дня 1"
                ),
                .init(
                    id: 2,
                    activityType: 2,
                    count: 1,
                    plannedCount: 1,
                    executeType: 1,
                    trainType: 2,
                    trainings: [
                        .init(typeId: 3, customTypeId: nil, count: 30, sortOrder: 0)
                    ],
                    createDate: DateFormatterService.stringFromFullDate(Date(), format: .serverDateTimeSec),
                    modifyDate: DateFormatterService.stringFromFullDate(Date(), format: .serverDateTimeSec),
                    duration: 900,
                    comment: "Растяжка"
                )
            ]
        case let .failure(error):
            throw error
        }
    }

    func createDay(_ day: DayRequest) async throws -> DayResponse {
        print("Имитируем запрос createDay (day=\(day.id))")
        try await Task.sleep(for: .seconds(1))
        switch result {
        case .success:
            print("Успешно создали день тренировки")
            return makeResponse(from: day, isUpdate: false)
        case let .failure(error):
            throw error
        }
    }

    func updateDay(model: DayRequest) async throws -> DayResponse {
        print("Имитируем запрос updateDay (day=\(model.id))")
        try await Task.sleep(for: .seconds(1))
        switch result {
        case .success:
            print("Успешно обновили день тренировки")
            return makeResponse(from: model, isUpdate: true)
        case let .failure(error):
            throw error
        }
    }

    func deleteDay(day: Int) async throws {
        print("Имитируем запрос deleteDay (day=\(day))")
        try await Task.sleep(for: .seconds(1))
        switch result {
        case .success:
            print("Успешно удалили день тренировки")
        case let .failure(error):
            throw error
        }
    }

    private func makeResponse(from request: DayRequest, isUpdate: Bool) -> DayResponse {
        let now = DateFormatterService.stringFromFullDate(Date(), format: .serverDateTimeSec)
        let trainings: [DayResponse.Training]? = {
            guard let reqTrainings = request.trainings, !reqTrainings.isEmpty else { return nil }
            return reqTrainings.enumerated().map { index, t in
                DayResponse.Training(
                    typeId: t.typeId,
                    customTypeId: t.customTypeId,
                    count: t.count,
                    sortOrder: index
                )
            }
        }()

        return DayResponse(
            id: request.id,
            activityType: request.activityType,
            count: request.count,
            plannedCount: request.plannedCount,
            executeType: request.executeType,
            trainType: request.trainingType,
            trainings: trainings,
            createDate: request.createDate ?? now,
            modifyDate: isUpdate ? (request.modifyDate ?? now) : request.modifyDate,
            duration: request.duration,
            comment: request.comment
        )
    }
}

struct MockProfileClient: ProfileClient {
    let result: MockResult

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

    func editUser(_ id: Int, model: MainUserForm) async throws -> UserResponse {
        print("Имитируем запрос editUser (id=\(id))")
        try await Task.sleep(for: .seconds(1))
        switch result {
        case .success:
            print("Успешно обновили данные пользователя")
            let birthDateString = DateFormatterService.stringFromFullDate(model.birthDate, format: .isoShortDate)
            return .init(
                id: id,
                name: model.userName,
                fullname: model.fullName,
                email: model.email,
                image: nil,
                cityId: Int(model.city.id),
                countryId: Int(model.country.id),
                gender: model.genderCode,
                birthDate: birthDateString
            )
        case let .failure(error):
            throw error
        }
    }

    func changePassword(current _: String, new _: String) async throws {
        print("Имитируем запрос changePassword")
        try await Task.sleep(for: .seconds(1))
        switch result {
        case .success:
            print("Успешно изменили пароль")
        case let .failure(error):
            throw error
        }
    }
}
