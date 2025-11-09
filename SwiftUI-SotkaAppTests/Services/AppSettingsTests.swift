import Foundation
@testable import SwiftUI_SotkaApp
import Testing

struct AppSettingsTests {
    @Test("Должен возвращать значение по умолчанию 60 секунд при отсутствии сохраненного значения")
    func defaultRestTime() throws {
        let userDefaults = try MockUserDefaults.create()
        let settings = AppSettings(userDefaults: userDefaults)
        #expect(settings.restTime == 60)
    }

    @Test("Должен сохранять и читать значение времени отдыха")
    func saveAndReadRestTime() throws {
        let userDefaults = try MockUserDefaults.create()
        let settings = AppSettings(userDefaults: userDefaults)
        settings.restTime = 45
        #expect(settings.restTime == 45)

        let storedValue = userDefaults.integer(forKey: "WorkoutTimer")
        #expect(storedValue == 45)
    }

    @Test("Должен использовать правильный ключ UserDefaults")
    func correctUserDefaultsKey() throws {
        let userDefaults = try MockUserDefaults.create()
        let settings = AppSettings(userDefaults: userDefaults)
        settings.restTime = 75

        let storedValue = userDefaults.integer(forKey: "WorkoutTimer")
        #expect(storedValue == 75)
    }

    @Test("Должен возвращать сохраненное значение после пересоздания экземпляра")
    func persistenceAfterRecreation() throws {
        let userDefaults = try MockUserDefaults.create()
        let settings1 = AppSettings(userDefaults: userDefaults)
        settings1.restTime = 50

        let storedValueBefore = userDefaults.integer(forKey: "WorkoutTimer")
        #expect(storedValueBefore == 50)

        let settings2 = AppSettings(userDefaults: userDefaults)
        let storedValueAfter = userDefaults.integer(forKey: "WorkoutTimer")
        #expect(storedValueAfter == 50)
        #expect(settings2.restTime == 50)
    }
}
