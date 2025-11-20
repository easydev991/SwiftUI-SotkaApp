#if DEBUG
import Foundation
import SWUtils

struct MockLoginClient: LoginClient {
    let result: MockResult
    let instantResponse: Bool

    init(result: MockResult, instantResponse: Bool = false) {
        self.result = result
        self.instantResponse = instantResponse
    }

    func logIn(with _: String?) async throws -> Int {
        print("Имитируем запрос logIn")
        if !instantResponse {
            try await Task.sleep(for: .seconds(1))
        }
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
        if !instantResponse {
            try await Task.sleep(for: .seconds(1))
        }
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
        if !instantResponse {
            try await Task.sleep(for: .seconds(1))
        }
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
        if !instantResponse {
            try await Task.sleep(for: .seconds(1))
        }
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
        if !instantResponse {
            try await Task.sleep(for: .seconds(1))
        }
        switch result {
        case .success:
            print("Успешно получили статус прохождения сотки")
            // Для дня 12 возвращаем дату старта 11 дней назад
            let calendar = Calendar.current
            let startDate = calendar.date(byAdding: .day, value: -11, to: .now) ?? .now
            return .init(date: startDate, maxForAllRunsDay: 100)
        case let .failure(error):
            throw error
        }
    }
}

struct MockExerciseClient: ExerciseClient {
    let result: MockResult
    let instantResponse: Bool

    init(result: MockResult, instantResponse: Bool = false) {
        self.result = result
        self.instantResponse = instantResponse
    }

    func getCustomExercises() async throws -> [CustomExerciseResponse] {
        print("Имитируем запрос getCustomExercises")
        if !instantResponse {
            try await Task.sleep(for: .seconds(1))
        }
        switch result {
        case .success:
            print("Успешно получили список пользовательских упражнений")
            let calendar = Calendar.current
            let now = Date()
            let exercise1Date = calendar.date(byAdding: .day, value: -5, to: now) ?? now
            let exercise2Date = calendar.date(byAdding: .day, value: -3, to: now) ?? now
            let exercise3Date = calendar.date(byAdding: .day, value: -2, to: now) ?? now

            return [
                .init(
                    id: "demo-exercise-1",
                    name: String(localized: .demoExerciseClapPushUps),
                    imageId: 0,
                    createDate: DateFormatterService.stringFromFullDate(exercise1Date, format: .serverDateTimeSec),
                    modifyDate: DateFormatterService.stringFromFullDate(exercise1Date, format: .serverDateTimeSec),
                    isHidden: false
                ),
                .init(
                    id: "demo-exercise-2",
                    name: String(localized: .demoExerciseBoxJumps),
                    imageId: 2,
                    createDate: DateFormatterService.stringFromFullDate(exercise2Date, format: .serverDateTimeSec),
                    modifyDate: DateFormatterService.stringFromFullDate(exercise2Date, format: .serverDateTimeSec),
                    isHidden: false
                ),
                .init(
                    id: "demo-exercise-3",
                    name: String(localized: .demoExerciseBurpees),
                    imageId: 11,
                    createDate: DateFormatterService.stringFromFullDate(exercise3Date, format: .serverDateTimeSec),
                    modifyDate: DateFormatterService.stringFromFullDate(exercise3Date, format: .serverDateTimeSec),
                    isHidden: false
                )
            ]
        case let .failure(error):
            throw error
        }
    }

    func saveCustomExercise(id: String, exercise: CustomExerciseRequest) async throws -> CustomExerciseResponse {
        print("Имитируем запрос saveCustomExercise (id=\(id))")
        if !instantResponse {
            try await Task.sleep(for: .seconds(1))
        }
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
        if !instantResponse {
            try await Task.sleep(for: .seconds(1))
        }
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
    let instantResponse: Bool

    init(result: MockResult, instantResponse: Bool = false) {
        self.result = result
        self.instantResponse = instantResponse
    }

    func getProgress() async throws -> [ProgressResponse] {
        print("Имитируем запрос getProgress")
        if !instantResponse {
            try await Task.sleep(for: .seconds(1))
        }
        switch result {
        case .success:
            print("Успешно получили список прогресса")
            // Возвращаем прогресс для дня 1 (контрольная точка) с данными из ScreenshotDemoData
            let calendar = Calendar.current
            let now = Date()
            let progressDate = calendar.date(byAdding: .day, value: -11, to: now) ?? now
            let dateString = DateFormatterService.stringFromFullDate(progressDate, format: .serverDateTimeSec)
            return [
                .init(
                    id: 1,
                    pullups: 7,
                    pushups: 15,
                    squats: 30,
                    weight: 70.0,
                    createDate: dateString,
                    modifyDate: dateString
                )
            ]
        case let .failure(error):
            print("Ошибка получения списка прогресса")
            throw error
        }
    }

    func getProgress(day: Int) async throws -> ProgressResponse {
        print("Имитируем запрос getProgress для дня \(day)")
        if !instantResponse {
            try await Task.sleep(for: .seconds(0.5))
        }
        switch result {
        case .success:
            print("Успешно получили прогресс для дня \(day)")
            // Имитируем случай, когда день найден
            if day == 1 || day == 49 || day == 100 {
                let calendar = Calendar.current
                let now = Date()
                let progressDate = calendar.date(byAdding: .day, value: -11, to: now) ?? now
                let dateString = DateFormatterService.stringFromFullDate(progressDate, format: .serverDateTimeSec)
                return .init(
                    id: day,
                    pullups: day == 1 ? 7 : 10,
                    pushups: day == 1 ? 15 : 20,
                    squats: day == 1 ? 30 : 30,
                    weight: 70.0,
                    createDate: dateString,
                    modifyDate: dateString
                )
            } else {
                // День не найден - имитируем ошибку прогресса не найден
                throw MockProgressClient.MockError.progressNotFound(day: day)
            }
        case let .failure(error):
            throw error
        }
    }

    func createProgress(progress: ProgressRequest) async throws -> ProgressResponse {
        print("Имитируем запрос createProgress (day=\(progress.id))")
        if !instantResponse {
            try await Task.sleep(for: .seconds(1))
        }
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
        if !instantResponse {
            try await Task.sleep(for: .seconds(1))
        }
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
        if !instantResponse {
            try await Task.sleep(for: .seconds(1))
        }
        switch result {
        case .success:
            print("Успешно удалили прогресс")
        case let .failure(error):
            throw error
        }
    }

    func deletePhoto(day: Int, type: String) async throws {
        print("Имитируем запрос deletePhoto (day=\(day), type=\(type))")
        if !instantResponse {
            try await Task.sleep(for: .seconds(1))
        }
        switch result {
        case .success:
            print("Успешно удалили фотографию")
        case let .failure(error):
            throw error
        }
    }
}

extension MockProgressClient {
    /// Ошибка для тестирования
    enum MockError: Error {
        case progressNotFound(day: Int)
    }
}

struct MockInfopostsClient: InfopostsClient {
    let result: MockResult
    let instantResponse: Bool

    init(result: MockResult, instantResponse: Bool = false) {
        self.result = result
        self.instantResponse = instantResponse
    }

    func getReadPosts() async throws -> [Int] {
        print("Имитируем запрос getReadPosts")
        if !instantResponse {
            try await Task.sleep(for: .seconds(1))
        }
        switch result {
        case .success:
            print("Успешно получили список прочитанных инфопостов")
            return ScreenshotDemoData.readInfopostDays
        case let .failure(error):
            throw error
        }
    }

    func setPostRead(day: Int) async throws {
        print("Имитируем запрос setPostRead (day=\(day))")
        if !instantResponse {
            try await Task.sleep(for: .seconds(1))
        }
        switch result {
        case .success:
            print("Успешно отметили инфопост \(day) как прочитанный")
        case let .failure(error):
            throw error
        }
    }

    func deleteAllReadPosts() async throws {
        print("Имитируем запрос deleteAllReadPosts")
        if !instantResponse {
            try await Task.sleep(for: .seconds(1))
        }
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
    let instantResponse: Bool

    init(result: MockResult, instantResponse: Bool = false) {
        self.result = result
        self.instantResponse = instantResponse
    }

    func getDays() async throws -> [DayResponse] {
        print("Имитируем запрос getDays")
        if !instantResponse {
            try await Task.sleep(for: .seconds(1))
        }
        switch result {
        case .success:
            print("Успешно получили список дней тренировок")
            let calendar = Calendar.current
            let now = Date()
            var days: [DayResponse] = []

            // День 1: тренировка
            let day1Date = calendar.date(byAdding: .day, value: -11, to: now) ?? now
            days.append(.init(
                id: 1,
                activityType: 0,
                count: 4,
                plannedCount: 4,
                executeType: 1,
                trainType: 1,
                trainings: [
                    .init(typeId: 0, customTypeId: nil, count: 5, sortOrder: 0),
                    .init(typeId: 3, customTypeId: nil, count: 10, sortOrder: 1),
                    .init(typeId: 2, customTypeId: nil, count: 15, sortOrder: 2)
                ],
                createDate: DateFormatterService.stringFromFullDate(day1Date, format: .serverDateTimeSec),
                modifyDate: DateFormatterService.stringFromFullDate(day1Date, format: .serverDateTimeSec),
                duration: 1800,
                comment: nil
            ))

            // День 2: тренировка
            let day2Date = calendar.date(byAdding: .day, value: -10, to: now) ?? now
            days.append(.init(
                id: 2,
                activityType: 0,
                count: 4,
                plannedCount: 4,
                executeType: 1,
                trainType: 1,
                trainings: [
                    .init(typeId: 0, customTypeId: nil, count: 6, sortOrder: 0),
                    .init(typeId: 3, customTypeId: nil, count: 12, sortOrder: 1),
                    .init(typeId: 2, customTypeId: nil, count: 18, sortOrder: 2)
                ],
                createDate: DateFormatterService.stringFromFullDate(day2Date, format: .serverDateTimeSec),
                modifyDate: DateFormatterService.stringFromFullDate(day2Date, format: .serverDateTimeSec),
                duration: 2000,
                comment: nil
            ))

            // День 3: растяжка
            let day3Date = calendar.date(byAdding: .day, value: -9, to: now) ?? now
            days.append(.init(
                id: 3,
                activityType: 2,
                count: nil,
                plannedCount: nil,
                executeType: nil,
                trainType: nil,
                trainings: nil,
                createDate: DateFormatterService.stringFromFullDate(day3Date, format: .serverDateTimeSec),
                modifyDate: DateFormatterService.stringFromFullDate(day3Date, format: .serverDateTimeSec),
                duration: 900,
                comment: nil
            ))

            // День 4: тренировка
            let day4Date = calendar.date(byAdding: .day, value: -8, to: now) ?? now
            days.append(.init(
                id: 4,
                activityType: 0,
                count: 4,
                plannedCount: 4,
                executeType: 1,
                trainType: 1,
                trainings: [
                    .init(typeId: 0, customTypeId: nil, count: 7, sortOrder: 0),
                    .init(typeId: 3, customTypeId: nil, count: 14, sortOrder: 1),
                    .init(typeId: 2, customTypeId: nil, count: 21, sortOrder: 2)
                ],
                createDate: DateFormatterService.stringFromFullDate(day4Date, format: .serverDateTimeSec),
                modifyDate: DateFormatterService.stringFromFullDate(day4Date, format: .serverDateTimeSec),
                duration: 2200,
                comment: nil
            ))

            // День 5: тренировка
            let day5Date = calendar.date(byAdding: .day, value: -7, to: now) ?? now
            days.append(.init(
                id: 5,
                activityType: 0,
                count: 4,
                plannedCount: 4,
                executeType: 1,
                trainType: 1,
                trainings: [
                    .init(typeId: 0, customTypeId: nil, count: 8, sortOrder: 0),
                    .init(typeId: 3, customTypeId: nil, count: 16, sortOrder: 1),
                    .init(typeId: 2, customTypeId: nil, count: 24, sortOrder: 2)
                ],
                createDate: DateFormatterService.stringFromFullDate(day5Date, format: .serverDateTimeSec),
                modifyDate: DateFormatterService.stringFromFullDate(day5Date, format: .serverDateTimeSec),
                duration: 2400,
                comment: nil
            ))

            // День 6: тренировка
            let day6Date = calendar.date(byAdding: .day, value: -6, to: now) ?? now
            days.append(.init(
                id: 6,
                activityType: 0,
                count: 4,
                plannedCount: 4,
                executeType: 1,
                trainType: 1,
                trainings: [
                    .init(typeId: 0, customTypeId: nil, count: 9, sortOrder: 0),
                    .init(typeId: 3, customTypeId: nil, count: 18, sortOrder: 1),
                    .init(typeId: 2, customTypeId: nil, count: 27, sortOrder: 2)
                ],
                createDate: DateFormatterService.stringFromFullDate(day6Date, format: .serverDateTimeSec),
                modifyDate: DateFormatterService.stringFromFullDate(day6Date, format: .serverDateTimeSec),
                duration: 2600,
                comment: nil
            ))

            // День 7: отдых
            let day7Date = calendar.date(byAdding: .day, value: -5, to: now) ?? now
            days.append(.init(
                id: 7,
                activityType: 1,
                count: nil,
                plannedCount: nil,
                executeType: nil,
                trainType: nil,
                trainings: nil,
                createDate: DateFormatterService.stringFromFullDate(day7Date, format: .serverDateTimeSec),
                modifyDate: DateFormatterService.stringFromFullDate(day7Date, format: .serverDateTimeSec),
                duration: nil,
                comment: nil
            ))

            // День 8: тренировка
            let day8Date = calendar.date(byAdding: .day, value: -4, to: now) ?? now
            days.append(.init(
                id: 8,
                activityType: 0,
                count: 4,
                plannedCount: 4,
                executeType: 1,
                trainType: 1,
                trainings: [
                    .init(typeId: 0, customTypeId: nil, count: 10, sortOrder: 0),
                    .init(typeId: 3, customTypeId: nil, count: 20, sortOrder: 1),
                    .init(typeId: 2, customTypeId: nil, count: 30, sortOrder: 2)
                ],
                createDate: DateFormatterService.stringFromFullDate(day8Date, format: .serverDateTimeSec),
                modifyDate: DateFormatterService.stringFromFullDate(day8Date, format: .serverDateTimeSec),
                duration: 2800,
                comment: nil
            ))

            // День 9: тренировка
            let day9Date = calendar.date(byAdding: .day, value: -3, to: now) ?? now
            days.append(.init(
                id: 9,
                activityType: 0,
                count: 4,
                plannedCount: 4,
                executeType: 1,
                trainType: 1,
                trainings: [
                    .init(typeId: 0, customTypeId: nil, count: 11, sortOrder: 0),
                    .init(typeId: 3, customTypeId: nil, count: 22, sortOrder: 1),
                    .init(typeId: 2, customTypeId: nil, count: 33, sortOrder: 2)
                ],
                createDate: DateFormatterService.stringFromFullDate(day9Date, format: .serverDateTimeSec),
                modifyDate: DateFormatterService.stringFromFullDate(day9Date, format: .serverDateTimeSec),
                duration: 3000,
                comment: nil
            ))

            // День 10: растяжка
            let day10Date = calendar.date(byAdding: .day, value: -2, to: now) ?? now
            days.append(.init(
                id: 10,
                activityType: 2,
                count: nil,
                plannedCount: nil,
                executeType: nil,
                trainType: nil,
                trainings: nil,
                createDate: DateFormatterService.stringFromFullDate(day10Date, format: .serverDateTimeSec),
                modifyDate: DateFormatterService.stringFromFullDate(day10Date, format: .serverDateTimeSec),
                duration: 900,
                comment: nil
            ))

            // День 11: тренировка
            let day11Date = calendar.date(byAdding: .day, value: -1, to: now) ?? now
            days.append(.init(
                id: 11,
                activityType: 0,
                count: 4,
                plannedCount: 4,
                executeType: 1,
                trainType: 1,
                trainings: [
                    .init(typeId: 0, customTypeId: nil, count: 12, sortOrder: 0),
                    .init(typeId: 3, customTypeId: nil, count: 24, sortOrder: 1),
                    .init(typeId: 2, customTypeId: nil, count: 36, sortOrder: 2)
                ],
                createDate: DateFormatterService.stringFromFullDate(day11Date, format: .serverDateTimeSec),
                modifyDate: DateFormatterService.stringFromFullDate(day11Date, format: .serverDateTimeSec),
                duration: 3200,
                comment: nil
            ))

            return days
        case let .failure(error):
            throw error
        }
    }

    func createDay(_ day: DayRequest) async throws -> DayResponse {
        print("Имитируем запрос createDay (day=\(day.id))")
        if !instantResponse {
            try await Task.sleep(for: .seconds(1))
        }
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
        if !instantResponse {
            try await Task.sleep(for: .seconds(1))
        }
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
        if !instantResponse {
            try await Task.sleep(for: .seconds(1))
        }
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
    let instantResponse: Bool

    init(result: MockResult, instantResponse: Bool = false) {
        self.result = result
        self.instantResponse = instantResponse
    }

    func getUserByID(_: Int) async throws -> UserResponse {
        print("Имитируем запрос getUserByID")
        if !instantResponse {
            try await Task.sleep(for: .seconds(1))
        }
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
        if !instantResponse {
            try await Task.sleep(for: .seconds(1))
        }
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
        if !instantResponse {
            try await Task.sleep(for: .seconds(1))
        }
        switch result {
        case .success:
            print("Успешно изменили пароль")
        case let .failure(error):
            throw error
        }
    }
}

struct MockCountriesClient: CountriesClient {
    let result: MockResult
    let instantResponse: Bool

    init(result: MockResult, instantResponse: Bool = false) {
        self.result = result
        self.instantResponse = instantResponse
    }

    func getCountries() async throws -> [CountryResponse] {
        print("Имитируем запрос getCountries")
        if !instantResponse {
            try await Task.sleep(for: .seconds(1))
        }
        switch result {
        case .success:
            print("Успешно получили список стран")
            return []
        case let .failure(error):
            throw error
        }
    }
}
#endif
