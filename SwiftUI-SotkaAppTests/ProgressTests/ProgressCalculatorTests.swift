import Foundation
@testable import SwiftUI_SotkaApp
import Testing

@Suite("Тесты для калькулятора прогресса")
struct ProgressCalculatorTests {
    private func makeUser(readDays: [Int]) -> User {
        let user = User.preview
        user.setReadInfopostDays(readDays)
        return user
    }

    private func makeUserWithActivities(
        readDays: [Int],
        activityDays: [Int],
        activityType: DayActivityType = .workout
    ) -> User {
        let user = makeUser(readDays: readDays)
        let now = Date()
        for day in activityDays {
            let activity = DayActivity(
                day: day,
                activityTypeRaw: activityType.rawValue,
                createDate: now,
                modifyDate: now,
                user: user
            )
            user.dayActivities.append(activity)
        }
        return user
    }

    @Test("Должен правильно рассчитывать процент прочитанных инфопостов")
    func testInfoPostsPercent() {
        let user = makeUser(readDays: Array(1 ... 25))
        let calculator = ProgressCalculator(user: user, currentDay: 100)

        #expect(calculator.infoPostsPercent == 25)
    }

    @Test("Должен правильно рассчитывать процент активности")
    func testActivityPercent() {
        let user = makeUserWithActivities(
            readDays: [],
            activityDays: Array(1 ... 50)
        )
        let calculator = ProgressCalculator(user: user, currentDay: 100)

        #expect(calculator.activityPercent == 50)
    }

    @Test("Должен использовать текущий день как знаменатель для полного прогресса")
    func fullProgressPercentRespectsCurrentDay() {
        let user = makeUserWithActivities(
            readDays: Array(1 ... 5),
            activityDays: Array(1 ... 5)
        )
        let calculator = ProgressCalculator(user: user, currentDay: 10)

        #expect(calculator.fullProgressPercent == 50)
    }

    @Test("Должен правильно определять статусы дней для прошлого, текущего и будущего")
    func testDayStatuses() {
        let user = makeUserWithActivities(
            readDays: [1, 3, 5],
            activityDays: [1, 2, 3, 4, 5, 6],
            activityType: .workout
        )
        // Обновляем типы активностей для дней 3 и 4 на rest
        if let activity3 = user.activitiesByDay[3] {
            activity3.activityType = .rest
        }
        if let activity4 = user.activitiesByDay[4] {
            activity4.activityType = .rest
        }

        let calculator = ProgressCalculator(user: user, currentDay: 6)
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
        let calculator = ProgressCalculator(user: user, currentDay: 2)
        let statuses = calculator.dayStatuses

        #expect(statuses[0] == .skipped)
    }
}
