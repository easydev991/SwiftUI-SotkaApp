import Foundation
import SwiftData
@testable import SwiftUI_SotkaApp
import SWUtils
import Testing

@Suite("User Model Tests")
struct UserTests {
    // MARK: - Private Helper Methods

    /// Вычисляет возраст на основе даты рождения
    private func calculateAge(from birthDateString: String) -> Int {
        let birthDate = DateFormatterService.dateFromString(birthDateString, format: .isoShortDate)
        return Calendar.current.dateComponents([.year], from: birthDate, to: .now).year ?? 0
    }

    /// Возвращает строку возраста для проверки в genderWithAge
    private func ageString(from birthDateString: String) -> String {
        "\(calculateAge(from: birthDateString))"
    }

    /// Создает CustomExercise для тестов
    private func createCustomExercise(id: String, name: String, imageId: Int, user: User) -> CustomExercise {
        CustomExercise(
            id: id,
            name: name,
            imageId: imageId,
            createDate: Date(),
            modifyDate: Date(),
            user: user
        )
    }

    // MARK: - avatarUrl Tests

    @Test("avatarUrl with valid URL")
    func avatarUrlWithValidUrl() throws {
        let user = User(id: 1, imageStringURL: "https://example.com/avatar.jpg")
        let avatarUrl = try #require(user.avatarUrl)
        #expect(avatarUrl.absoluteString == "https://example.com/avatar.jpg")
    }

    @Test("avatarUrl with cyrillic characters")
    func avatarUrlWithCyrillic() throws {
        let user = User(id: 1, imageStringURL: "https://example.com/аватар.jpg")
        let avatarUrl = try #require(user.avatarUrl)
        // URL кодирует кириллические символы, поэтому проверяем закодированную версию
        #expect(avatarUrl.absoluteString.contains("%D0%B0%D0%B2%D0%B0%D1%82%D0%B0%D1%80"))
    }

    @Test("avatarUrl with empty string")
    func avatarUrlWithEmptyString() {
        let user = User(id: 1, imageStringURL: "")
        #expect(user.avatarUrl == nil)
    }

    @Test("avatarUrl with nil value")
    func avatarUrlWithNil() {
        let user = User(id: 1, imageStringURL: nil)
        #expect(user.avatarUrl == nil)
    }

    // MARK: - gender Tests

    @Test("gender with unspecified code")
    func genderWithUnspecifiedCode() throws {
        let user = User(id: 1, genderCode: -1)
        let gender = try #require(user.gender)
        #expect(gender == .unspecified)
    }

    @Test("gender with male code")
    func genderWithMaleCode() throws {
        let user = User(id: 1, genderCode: 0)
        let gender = try #require(user.gender)
        #expect(gender == .male)
    }

    @Test("gender with female code")
    func genderWithFemaleCode() throws {
        let user = User(id: 1, genderCode: 1)
        let gender = try #require(user.gender)
        #expect(gender == .female)
    }

    @Test("gender with nil code")
    func genderWithNilCode() {
        let user = User(id: 1, genderCode: nil)
        #expect(user.gender == nil)
    }

    @Test("gender with invalid code")
    func genderWithInvalidCode() {
        let user = User(id: 1, genderCode: 999)
        #expect(user.gender == nil)
    }

    // MARK: - birthDate Tests

    @Test("birthDate with valid ISO date")
    func birthDateWithValidIsoDate() {
        let user = User(id: 1, birthDateIsoString: "1990-01-15")
        let birthDate = user.birthDate

        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day], from: birthDate)

        #expect(components.year == 1990)
        #expect(components.month == 1)
        #expect(components.day == 15)
    }

    @Test("birthDate with empty string")
    func birthDateWithEmptyString() {
        let user = User(id: 1, birthDateIsoString: "")
        let birthDate = user.birthDate

        // Должна вернуть текущую дату по умолчанию
        let now = Date()
        let timeInterval = abs(birthDate.timeIntervalSince(now))
        #expect(timeInterval < 1.0) // Разница должна быть меньше секунды
    }

    @Test("birthDate with nil value")
    func birthDateWithNil() {
        let user = User(id: 1, birthDateIsoString: nil)
        let birthDate = user.birthDate

        // Должна вернуть текущую дату по умолчанию
        let now = Date()
        let timeInterval = abs(birthDate.timeIntervalSince(now))
        #expect(timeInterval < 1.0) // Разница должна быть меньше секунды
    }

    // MARK: - genderWithAge Tests

    @Test("genderWithAge with male gender")
    func genderWithAgeWithMale() {
        let user = User(id: 1, genderCode: 0, birthDateIsoString: "1990-01-01")
        let genderWithAge = user.genderWithAge

        // Проверяем, что строка содержит описание пола и возраст
        #expect(genderWithAge.contains("Мужчина") || genderWithAge.contains("Male"))
        #expect(genderWithAge.contains(ageString(from: "1990-01-01")))
    }

    @Test("genderWithAge with female gender")
    func genderWithAgeWithFemale() {
        let user = User(id: 1, genderCode: 1, birthDateIsoString: "1990-01-01")
        let genderWithAge = user.genderWithAge

        // Проверяем, что строка содержит описание пола и возраст
        #expect(genderWithAge.contains("Женщина") || genderWithAge.contains("Female"))
        #expect(genderWithAge.contains(ageString(from: "1990-01-01")))
    }

    @Test("genderWithAge with unspecified gender")
    func genderWithAgeWithUnspecified() {
        let user = User(id: 1, genderCode: -1, birthDateIsoString: "1990-01-01")
        let genderWithAge = user.genderWithAge

        // Должна содержать только возраст без пола
        #expect(!genderWithAge.contains("Мужчина"))
        #expect(!genderWithAge.contains("Женщина"))
        #expect(!genderWithAge.contains("Male"))
        #expect(!genderWithAge.contains("Female"))
        #expect(genderWithAge.contains(ageString(from: "1990-01-01")))
    }

    @Test("genderWithAge with nil gender")
    func genderWithAgeWithNilGender() {
        let user = User(id: 1, genderCode: nil, birthDateIsoString: "1990-01-01")
        let genderWithAge = user.genderWithAge

        // Должна содержать только возраст без пола
        #expect(!genderWithAge.contains("Мужчина"))
        #expect(!genderWithAge.contains("Женщина"))
        #expect(!genderWithAge.contains("Male"))
        #expect(!genderWithAge.contains("Female"))
        #expect(genderWithAge.contains(ageString(from: "1990-01-01")))
    }

    // MARK: - customExerciseCountText Tests

    @Test("customExerciseCountText with empty exercises")
    func customExerciseCountTextWithEmptyExercises() {
        let user = User(id: 1)
        // По умолчанию customExercises пустой массив
        let countText = user.customExerciseCountText
        #expect(countText == "")
    }

    @Test("customExerciseCountText with one exercise")
    func customExerciseCountTextWithOneExercise() {
        let user = User(id: 1)
        let exercise = createCustomExercise(id: "test-1", name: "Test Exercise", imageId: 1, user: user)
        user.customExercises.append(exercise)

        let countText = user.customExerciseCountText
        #expect(countText == "1")
    }

    @Test("customExerciseCountText with multiple exercises")
    func customExerciseCountTextWithMultipleExercises() {
        let user = User(id: 1)
        // Создаем несколько упражнений и добавляем в массив
        let exercise1 = createCustomExercise(id: "test-1", name: "Exercise 1", imageId: 1, user: user)
        let exercise2 = createCustomExercise(id: "test-2", name: "Exercise 2", imageId: 2, user: user)
        let exercise3 = createCustomExercise(id: "test-3", name: "Exercise 3", imageId: 3, user: user)

        user.customExercises.append(exercise1)
        user.customExercises.append(exercise2)
        user.customExercises.append(exercise3)

        let countText = user.customExerciseCountText
        #expect(countText == "3")
    }

    // MARK: - isMaximumsFilled Tests

    @Test("isMaximumsFilled для дня 1-49 с заполненными результатами")
    func isMaximumsFilledForDay1To49WithFilledResults() {
        let user = User(id: 1)
        let progress = Progress(id: 1)
        progress.pullUps = 10
        progress.pushUps = 20
        progress.squats = 30
        progress.weight = 70.0
        user.progressResults.append(progress)

        #expect(user.isMaximumsFilled(for: 25))
    }

    @Test("isMaximumsFilled для дня 50-99 с заполненными результатами")
    func isMaximumsFilledForDay50To99WithFilledResults() {
        let user = User(id: 1)
        let progress = Progress(id: 50)
        progress.pullUps = 15
        progress.pushUps = 25
        progress.squats = 35
        progress.weight = 75.0
        user.progressResults.append(progress)

        #expect(user.isMaximumsFilled(for: 75))
    }

    @Test("isMaximumsFilled для дня 100+ с заполненными результатами")
    func isMaximumsFilledForDay100PlusWithFilledResults() {
        let user = User(id: 1)
        let progress = Progress(id: 100)
        progress.pullUps = 20
        progress.pushUps = 30
        progress.squats = 40
        progress.weight = 80.0
        user.progressResults.append(progress)

        #expect(user.isMaximumsFilled(for: 105))
    }

    @Test("isMaximumsFilled без данных")
    func isMaximumsFilledWithoutData() {
        let user = User(id: 1)

        #expect(!user.isMaximumsFilled(for: 25))
    }

    @Test("isMaximumsFilled с незаполненными результатами")
    func isMaximumsFilledWithUnfilledResults() {
        let user = User(id: 1)
        let progress = Progress(id: 1)
        progress.pullUps = 10
        progress.pushUps = nil
        progress.squats = 30
        progress.weight = 70.0
        user.progressResults.append(progress)

        #expect(!user.isMaximumsFilled(for: 25))
    }

    @Test(arguments: [
        (1, 1, true),
        (25, 1, true),
        (49, 1, true),
        (50, 50, true),
        (75, 50, true),
        (99, 50, true),
        (100, 100, true),
        (105, 100, true),
        (1, 50, false),
        (25, 50, false),
        (50, 1, false),
        (75, 1, false),
        (100, 1, false),
        (100, 50, false)
    ])
    func isMaximumsFilledParameterized(
        currentDay: Int,
        progressDay: Int,
        expected: Bool
    ) {
        let user = User(id: 1)
        let progress = Progress(id: progressDay)
        progress.pullUps = 10
        progress.pushUps = 20
        progress.squats = 30
        progress.weight = 70.0
        user.progressResults.append(progress)

        #expect(user.isMaximumsFilled(for: currentDay) == expected)
    }
}
