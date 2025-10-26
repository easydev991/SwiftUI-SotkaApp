import Foundation
@testable import SwiftUI_SotkaApp
import Testing

@Suite("Тесты для калькулятора прогресса")
struct ProgressCalculatorTests {
    private func makeUser(readDays: [Int]) -> User {
        let user = User.preview
        user.readInfopostDays = readDays
        return user
    }

    private func makeActivities(upto day: Int, activity: DayActivityType = .workout) -> [DayActivityType] {
        guard day > 0 else { return [] }
        return Array(repeating: activity, count: day)
    }

    @Test("Должен правильно рассчитывать процент прочитанных инфопостов")
    func testInfoPostsPercent() {
        let user = makeUser(readDays: Array(1 ... 25))
        let calculator = ProgressCalculator(user: user, activities: [], currentDay: 100)

        #expect(calculator.infoPostsPercent == 25)
    }

    @Test("Должен правильно рассчитывать процент активности")
    func testActivityPercent() {
        let user = makeUser(readDays: [])
        let activities = makeActivities(upto: 50, activity: .workout)
        let calculator = ProgressCalculator(user: user, activities: activities, currentDay: 100)

        #expect(calculator.activityPercent == 50)
    }

    @Test("Должен использовать текущий день как знаменатель для полного прогресса")
    func fullProgressPercentRespectsCurrentDay() {
        let user = makeUser(readDays: Array(1 ... 5))
        let activities = makeActivities(upto: 5, activity: .workout)
        let calculator = ProgressCalculator(user: user, activities: activities, currentDay: 10)

        #expect(calculator.fullProgressPercent == 50)
    }

    @Test("Должен правильно определять статусы дней для прошлого, текущего и будущего")
    func testDayStatuses() {
        let user = makeUser(readDays: [1, 3, 5])
        let activities: [DayActivityType] = [.workout, .workout, .rest, .rest, .workout, .rest]
        let calculator = ProgressCalculator(user: user, activities: activities, currentDay: 6)
        let statuses = calculator.dayStatuses

        #expect(statuses[0] == .completed)
        #expect(statuses[1] == .partial)
        #expect(statuses[2] == .completed)
        #expect(statuses[3] == .partial)
        #expect(statuses[4] == .completed)
        #expect(statuses[5] == .currentDay)
        #expect(statuses[6] == .notStarted)
    }

    @Test("Должен помечать день как пропущенный при отсутствии активности и инфопоста")
    func dayStatusSkipped() {
        let user = makeUser(readDays: [])
        let activities: [DayActivityType] = []
        let calculator = ProgressCalculator(user: user, activities: activities, currentDay: 2)
        let statuses = calculator.dayStatuses

        #expect(statuses[0] == .skipped)
    }
}
