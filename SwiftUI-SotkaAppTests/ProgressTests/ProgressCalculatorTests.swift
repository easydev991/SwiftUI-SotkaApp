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

    @Test("При currentDay 101 прогресс совпадает с 100-дневным расчетом")
    func progressDoesNotGrowOnDay101() {
        let readDays = Array(1 ... 50)
        let activityDays = Array(1 ... 75)
        let user = makeUserWithActivities(
            readDays: readDays,
            activityDays: activityDays
        )

        let calculatorDay100 = ProgressCalculator(user: user, currentDay: 100)
        let calculatorDay101 = ProgressCalculator(user: user, currentDay: 101)

        let fullProgressDay100 = calculatorDay100.fullProgressPercent
        let fullProgressDay101 = calculatorDay101.fullProgressPercent
        let infoPercentDay100 = calculatorDay100.infoPostsPercent
        let infoPercentDay101 = calculatorDay101.infoPostsPercent
        let activityPercentDay100 = calculatorDay100.activityPercent
        let activityPercentDay101 = calculatorDay101.activityPercent
        let dayStatusesDay101 = calculatorDay101.dayStatuses
        let currentDayMarkersCount = dayStatusesDay101.count(where: { $0 == .currentDay })
        let notStartedMarkersCount = dayStatusesDay101.count(where: { $0 == .notStarted })
        let statusesCount = dayStatusesDay101.count
        let lastDayStatus = dayStatusesDay101[99]

        #expect(fullProgressDay100 == fullProgressDay101)
        #expect(infoPercentDay100 == infoPercentDay101)
        #expect(activityPercentDay100 == activityPercentDay101)
        #expect(statusesCount == 100)
        #expect(currentDayMarkersCount == 0)
        #expect(notStartedMarkersCount == 0)
        #expect(lastDayStatus == .skipped)
    }

    @Test("При currentDay 200 прогресс совпадает с 100-дневным расчетом")
    func progressDoesNotGrowOnDay200() {
        let readDays = Array(1 ... 80)
        let activityDays = Array(1 ... 90)
        let user = makeUserWithActivities(
            readDays: readDays,
            activityDays: activityDays
        )

        let calculatorDay100 = ProgressCalculator(user: user, currentDay: 100)
        let calculatorDay200 = ProgressCalculator(user: user, currentDay: 200)

        let fullProgressDay100 = calculatorDay100.fullProgressPercent
        let fullProgressDay200 = calculatorDay200.fullProgressPercent
        let infoPercentDay100 = calculatorDay100.infoPostsPercent
        let infoPercentDay200 = calculatorDay200.infoPostsPercent
        let activityPercentDay100 = calculatorDay100.activityPercent
        let activityPercentDay200 = calculatorDay200.activityPercent
        let dayStatusesDay200 = calculatorDay200.dayStatuses
        let currentDayMarkersCount = dayStatusesDay200.count(where: { $0 == .currentDay })
        let notStartedMarkersCount = dayStatusesDay200.count(where: { $0 == .notStarted })
        let statusesCount = dayStatusesDay200.count
        let lastDayStatus = dayStatusesDay200[99]

        #expect(fullProgressDay100 == fullProgressDay200)
        #expect(infoPercentDay100 == infoPercentDay200)
        #expect(activityPercentDay100 == activityPercentDay200)
        #expect(statusesCount == 100)
        #expect(currentDayMarkersCount == 0)
        #expect(notStartedMarkersCount == 0)
        #expect(lastDayStatus == .skipped)
    }

    @Test("После полного сброса прогресс начинается заново")
    func progressResetsAfterFullReset() {
        let user = makeUserWithActivities(
            readDays: Array(1 ... 20),
            activityDays: Array(1 ... 30)
        )
        let calculatorBeforeReset = ProgressCalculator(user: user, currentDay: 100)

        let fullProgressBeforeReset = calculatorBeforeReset.fullProgressPercent
        let infoPercentBeforeReset = calculatorBeforeReset.infoPostsPercent
        let activityPercentBeforeReset = calculatorBeforeReset.activityPercent

        user.setReadInfopostDays([])
        user.dayActivities.removeAll()

        let calculatorAfterReset = ProgressCalculator(user: user, currentDay: 1)
        let fullProgressAfterReset = calculatorAfterReset.fullProgressPercent
        let infoPercentAfterReset = calculatorAfterReset.infoPostsPercent
        let activityPercentAfterReset = calculatorAfterReset.activityPercent
        let dayStatusesAfterReset = calculatorAfterReset.dayStatuses

        #expect(fullProgressBeforeReset > 0)
        #expect(infoPercentBeforeReset > 0)
        #expect(activityPercentBeforeReset > 0)

        #expect(fullProgressAfterReset == 0)
        #expect(infoPercentAfterReset == 0)
        #expect(activityPercentAfterReset == 0)
        #expect(dayStatusesAfterReset[0] == .currentDay)
        #expect(dayStatusesAfterReset[1] == .notStarted)
    }
}
