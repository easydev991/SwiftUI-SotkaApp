import Foundation
@testable import SwiftUI_SotkaApp
import Testing

@MainActor
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

    @Test("Должен возвращать .ringtone1 при отсутствии сохраненного значения")
    func defaultTimerSound() throws {
        let userDefaults = try MockUserDefaults.create()
        let settings = AppSettings(userDefaults: userDefaults)
        #expect(settings.timerSound == .ringtone1)
    }

    @Test("Должен сохранять и читать выбранную мелодию")
    func saveAndReadTimerSound() throws {
        let userDefaults = try MockUserDefaults.create()
        let settings = AppSettings(userDefaults: userDefaults)
        settings.timerSound = .ringtone2
        #expect(settings.timerSound == .ringtone2)

        let storedValue = try #require(userDefaults.string(forKey: "WorkoutTimerSound"))
        let storedSound = try #require(TimerSound(rawValue: storedValue))
        #expect(storedSound == .ringtone2)
    }

    @Test("Должен использовать правильный ключ UserDefaults")
    func correctTimerSoundUserDefaultsKey() throws {
        let userDefaults = try MockUserDefaults.create()
        let settings = AppSettings(userDefaults: userDefaults)
        settings.timerSound = .ringtone3

        let storedValue = userDefaults.string(forKey: "WorkoutTimerSound")
        #expect(storedValue == "Ringtone 3.mp3")
    }

    @Test("Должен возвращать сохраненное значение после пересоздания экземпляра")
    func timerSoundPersistenceAfterRecreation() throws {
        let userDefaults = try MockUserDefaults.create()
        let settings1 = AppSettings(userDefaults: userDefaults)
        settings1.timerSound = .ringtone4

        let storedValueBefore = userDefaults.string(forKey: "WorkoutTimerSound")
        #expect(storedValueBefore == "Ringtone 4.mp3")

        let settings2 = AppSettings(userDefaults: userDefaults)
        let storedValueAfter = userDefaults.string(forKey: "WorkoutTimerSound")
        #expect(storedValueAfter == "Ringtone 4.mp3")
        #expect(settings2.timerSound == .ringtone4)
    }
}
