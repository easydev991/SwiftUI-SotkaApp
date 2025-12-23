import Foundation
@testable import SwiftUI_SotkaApp
import Testing

@Suite("Тесты для форматирования времени отдыха")
struct RestTimeFormattingTests {
    @Test("Должен правильно разбивать секунды на минуты и секунды для значений меньше 60")
    func splitsSecondsCorrectlyForValuesBelow60() {
        let components5 = RestTimeComponents(totalSeconds: 5)
        #expect(components5.minutes == 0)
        #expect(components5.seconds == 5)

        let components30 = RestTimeComponents(totalSeconds: 30)
        #expect(components30.minutes == 0)
        #expect(components30.seconds == 30)

        let components59 = RestTimeComponents(totalSeconds: 59)
        #expect(components59.minutes == 0)
        #expect(components59.seconds == 59)
    }

    @Test("Должен правильно разбивать секунды на минуты и секунды для значений равных 60")
    func splitsSecondsCorrectlyForValue60() {
        let components = RestTimeComponents(totalSeconds: 60)
        #expect(components.minutes == 1)
        #expect(components.seconds == 0)
    }

    @Test("Должен правильно разбивать секунды на минуты и секунды для значений больше 60")
    func splitsSecondsCorrectlyForValuesAbove60() {
        let components65 = RestTimeComponents(totalSeconds: 65)
        #expect(components65.minutes == 1)
        #expect(components65.seconds == 5)

        let components120 = RestTimeComponents(totalSeconds: 120)
        #expect(components120.minutes == 2)
        #expect(components120.seconds == 0)

        let components300 = RestTimeComponents(totalSeconds: 300)
        #expect(components300.minutes == 5)
        #expect(components300.seconds == 0)

        let components600 = RestTimeComponents(totalSeconds: 600)
        #expect(components600.minutes == 10)
        #expect(components600.seconds == 0)
    }

    @Test("Должен правильно обрабатывать граничные значения из restPickerOptions")
    func handlesBoundaryValuesFromRestPickerOptions() {
        let components5 = RestTimeComponents(totalSeconds: 5)
        #expect(components5.minutes == 0)
        #expect(components5.seconds == 5)

        let components600 = RestTimeComponents(totalSeconds: 600)
        #expect(components600.minutes == 10)
        #expect(components600.seconds == 0)
    }

    @Test("Должен возвращать формат секунд для 0 минут и N секунд (N > 0)")
    func returnsSecondsFormatForZeroMinutesAndPositiveSeconds() {
        let components5 = RestTimeComponents(totalSeconds: 5)
        let expected5 = String(localized: .sec(5))
        #expect(components5.localizedString == expected5)

        let components30 = RestTimeComponents(totalSeconds: 30)
        let expected30 = String(localized: .sec(30))
        #expect(components30.localizedString == expected30)

        let components59 = RestTimeComponents(totalSeconds: 59)
        let expected59 = String(localized: .sec(59))
        #expect(components59.localizedString == expected59)
    }

    @Test("Должен возвращать формат минут и секунд для M минут и N секунд (M > 0, N > 0)")
    func returnsMinutesAndSecondsFormatForPositiveMinutesAndSeconds() {
        let components65 = RestTimeComponents(totalSeconds: 65)
        let expected65 = String(localized: .minSec(1, 5))
        #expect(components65.localizedString == expected65)

        let components125 = RestTimeComponents(totalSeconds: 125)
        let expected125 = String(localized: .minSec(2, 5))
        #expect(components125.localizedString == expected125)

        let components305 = RestTimeComponents(totalSeconds: 305)
        let expected305 = String(localized: .minSec(5, 5))
        #expect(components305.localizedString == expected305)
    }

    @Test("Должен возвращать формат минут для M минут и 0 секунд (M > 0)")
    func returnsMinutesFormatForPositiveMinutesAndZeroSeconds() {
        let components60 = RestTimeComponents(totalSeconds: 60)
        let expected60 = String(localized: .min(1))
        #expect(components60.localizedString == expected60)

        let components120 = RestTimeComponents(totalSeconds: 120)
        let expected120 = String(localized: .min(2))
        #expect(components120.localizedString == expected120)

        let components300 = RestTimeComponents(totalSeconds: 300)
        let expected300 = String(localized: .min(5))
        #expect(components300.localizedString == expected300)

        let components600 = RestTimeComponents(totalSeconds: 600)
        let expected600 = String(localized: .min(10))
        #expect(components600.localizedString == expected600)
    }

    @Test("Должен правильно форматировать все значения из restPickerOptions")
    func formatsAllValuesFromRestPickerOptions() {
        for seconds in Constants.restPickerOptions {
            let components = RestTimeComponents(totalSeconds: seconds)
            let formatted = components.localizedString

            if components.minutes == 0, components.seconds > 0 {
                let expected = String(localized: .sec(components.seconds))
                #expect(formatted == expected)
            } else if components.minutes > 0, components.seconds > 0 {
                let expected = String(localized: .minSec(components.minutes, components.seconds))
                #expect(formatted == expected)
            } else if components.minutes > 0, components.seconds == 0 {
                let expected = String(localized: .min(components.minutes))
                #expect(formatted == expected)
            }
        }
    }
}
