import Foundation
@testable import SwiftUI_SotkaApp
import Testing

struct TimerSoundTests {
    @Test("Должен возвращать правильное расширение файла")
    func fileExtension() {
        #expect(TimerSound.ringtone1.fileExtension == "mp3")
    }

    @Test("Должен возвращать правильное имя файла без расширения")
    func fileNameWithoutExtension() {
        #expect(TimerSound.ringtone1.fileName == "Ringtone 1")
    }

    @Test("Должен инициализироваться из rawValue")
    func initFromRawValue() throws {
        let sound = TimerSound(rawValue: "Ringtone 1.mp3")
        let ringtone1 = try #require(sound)
        #expect(ringtone1 == .ringtone1)
    }

    @Test("Должен возвращать nil для несуществующего rawValue")
    func initFromInvalidRawValue() {
        let sound = TimerSound(rawValue: "nonexistent.mp3")
        #expect(sound == nil)
    }

    @Test("Должен предоставлять все кейсы через allCases")
    func allCasesAvailable() {
        let allCases = TimerSound.allCases
        #expect(allCases.count == 7)
        #expect(allCases.contains(.ringtone1))
        #expect(allCases.contains(.ringtone2))
        #expect(allCases.contains(.ringtone3))
        #expect(allCases.contains(.ringtone4))
        #expect(allCases.contains(.ringtone5))
        #expect(allCases.contains(.ringtone6))
        #expect(allCases.contains(.ringtone7))
    }

    @Test("Должен правильно обрабатывать имена файлов с пробелами")
    func fileNameWithSpaces() {
        #expect(TimerSound.ringtone1.fileName == "Ringtone 1")
        #expect(TimerSound.ringtone1.fileExtension == "mp3")
    }

    @Test("Должен возвращать displayName равный fileName")
    func displayNameEqualsFileName() {
        #expect(TimerSound.ringtone1.displayName == TimerSound.ringtone1.fileName)
    }
}
