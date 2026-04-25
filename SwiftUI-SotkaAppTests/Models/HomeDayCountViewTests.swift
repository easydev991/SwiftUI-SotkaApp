import Foundation
@testable import SwiftUI_SotkaApp
import Testing

@MainActor
struct HomeDayCountModelTests {
    @Test("Для чисел меньше 10 счётчик форматируется с ведущим нулем")
    func formatSingleDigitDay() {
        #expect(HomeDayCountModel.formattedDayString(for: 7) == "07")
    }

    @Test("Для чисел 100+ счётчик возвращает полное значение без обрезания")
    func formatThreeDigitDay() {
        #expect(HomeDayCountModel.formattedDayString(for: 101) == "101")
        #expect(HomeDayCountModel.formattedDayString(for: 1000) == "1000")
    }

    @Test("Поздравляющий блок показывается только на 100-м дне")
    func firstCompletionDayCheck() {
        let day100 = HomeDayCountModel(currentDay: 100).isFirstProgramCompletionDay
        let day200 = HomeDayCountModel(currentDay: 200).isFirstProgramCompletionDay
        let day300 = HomeDayCountModel(currentDay: 300).isFirstProgramCompletionDay

        #expect(day100)
        #expect(!day200)
        #expect(!day300)
    }
}
