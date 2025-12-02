import Foundation
@testable import SotkaWatch_Watch_App
import Testing

struct WatchAppGroupHelperTests {
    @Test("Читает статус авторизации из UserDefaults")
    func readsAuthStatusFromUserDefaults() throws {
        let userDefaults = try MockUserDefaults.create()
        userDefaults.set(true, forKey: Constants.isAuthorizedKey)
        let helper = WatchAppGroupHelper(userDefaults: userDefaults)

        #expect(helper.isAuthorized)
    }

    @Test("Возвращает false если статус авторизации не установлен")
    func returnsFalseWhenAuthStatusNotSet() throws {
        let userDefaults = try MockUserDefaults.create()
        let helper = WatchAppGroupHelper(userDefaults: userDefaults)

        #expect(!helper.isAuthorized)
    }

    @Test("Возвращает false если UserDefaults недоступен")
    func returnsFalseWhenUserDefaultsUnavailable() {
        let helper = WatchAppGroupHelper(userDefaults: nil)

        #expect(!helper.isAuthorized)
    }

    @Test("Читает дату начала программы из UserDefaults")
    func readsStartDateFromUserDefaults() throws {
        let userDefaults = try MockUserDefaults.create()
        let testDate = Date(timeIntervalSince1970: 1704067200)
        let timeInterval = testDate.timeIntervalSinceReferenceDate
        userDefaults.set(timeInterval, forKey: Constants.startDateKey)
        let helper = WatchAppGroupHelper(userDefaults: userDefaults)

        let startDate = try #require(helper.startDate)
        #expect(startDate.timeIntervalSince1970 == testDate.timeIntervalSince1970)
    }

    @Test("Возвращает nil если дата начала программы не установлена")
    func returnsNilWhenStartDateNotSet() throws {
        let userDefaults = try MockUserDefaults.create()
        let helper = WatchAppGroupHelper(userDefaults: userDefaults)

        #expect(helper.startDate == nil)
    }

    @Test("Возвращает nil если дата начала программы равна нулю")
    func returnsNilWhenStartDateIsZero() throws {
        let userDefaults = try MockUserDefaults.create()
        userDefaults.set(0.0, forKey: Constants.startDateKey)
        let helper = WatchAppGroupHelper(userDefaults: userDefaults)

        #expect(helper.startDate == nil)
    }

    @Test("Возвращает nil если UserDefaults недоступен для startDate")
    func returnsNilWhenUserDefaultsUnavailableForStartDate() {
        let helper = WatchAppGroupHelper(userDefaults: nil)

        #expect(helper.startDate == nil)
    }

    @Test("Вычисляет текущий день программы из startDate")
    func calculatesCurrentDayFromStartDate() throws {
        let userDefaults = try MockUserDefaults.create()
        let startDate = Date(timeIntervalSince1970: 1704067200)
        let timeInterval = startDate.timeIntervalSinceReferenceDate
        userDefaults.set(timeInterval, forKey: Constants.startDateKey)
        let helper = WatchAppGroupHelper(userDefaults: userDefaults)

        let currentDay = try #require(helper.currentDay)
        let expectedCalculator = DayCalculator(startDate, Date.now)
        #expect(currentDay == expectedCalculator.currentDay)
    }

    @Test("Возвращает nil если startDate отсутствует для вычисления текущего дня")
    func returnsNilWhenStartDateMissingForCurrentDay() throws {
        let userDefaults = try MockUserDefaults.create()
        let helper = WatchAppGroupHelper(userDefaults: userDefaults)

        #expect(helper.currentDay == nil)
    }

    @Test("Читает время отдыха из UserDefaults")
    func readsRestTimeFromUserDefaults() throws {
        let userDefaults = try MockUserDefaults.create()
        userDefaults.set(45, forKey: Constants.restTimeKey)
        let helper = WatchAppGroupHelper(userDefaults: userDefaults)

        #expect(helper.restTime == 45)
    }

    @Test("Возвращает значение по умолчанию если время отдыха не установлено")
    func returnsDefaultValueWhenRestTimeNotSet() throws {
        let userDefaults = try MockUserDefaults.create()
        let helper = WatchAppGroupHelper(userDefaults: userDefaults)

        #expect(helper.restTime == Constants.defaultRestTime)
    }

    @Test("Возвращает значение по умолчанию если время отдыха равно нулю")
    func returnsDefaultValueWhenRestTimeIsZero() throws {
        let userDefaults = try MockUserDefaults.create()
        userDefaults.set(0, forKey: Constants.restTimeKey)
        let helper = WatchAppGroupHelper(userDefaults: userDefaults)

        #expect(helper.restTime == Constants.defaultRestTime)
    }

    @Test("Возвращает значение по умолчанию если UserDefaults недоступен для restTime")
    func returnsDefaultValueWhenUserDefaultsUnavailableForRestTime() {
        let helper = WatchAppGroupHelper(userDefaults: nil)

        let restTime = helper.restTime
        #expect(restTime == Constants.defaultRestTime)
    }
}
