import Foundation
import SwiftData
@testable import SwiftUI_SotkaApp
import Testing

struct ProgressTests {
    private typealias Section = UserProgress.Section

    // MARK: - Section Computed Property Tests

    @Test("section вычисляется правильно для первого блока")
    func sectionComputedForFirstBlock() {
        let progress = UserProgress(id: 1)
        #expect(progress.section == .one)
    }

    @Test("section вычисляется правильно для второго блока")
    func sectionComputedForSecondBlock() {
        let progress = UserProgress(id: 50)
        #expect(progress.section == .two)
    }

    @Test("section вычисляется правильно для третьего блока")
    func sectionComputedForThirdBlock() {
        let progress = UserProgress(id: 100)
        #expect(progress.section == .three)
    }

    @Test(arguments: [
        (1, Section.one),
        (25, Section.one),
        (48, Section.one),
        (49, Section.two),
        (50, Section.two),
        (75, Section.two),
        (99, Section.two),
        (100, Section.three),
        (150, Section.three),
        (200, Section.three)
    ])
    private func sectionComputedParameterized(day: Int, expectedSection: Section) {
        let progress = UserProgress(id: day)
        #expect(progress.section == expectedSection)
    }

    @Test("section вычисляется как первый блок для недопустимых значений")
    func sectionComputedForInvalidValues() {
        let progress = UserProgress(id: 0)
        #expect(progress.section == .one)
    }

    // MARK: - isMetricsFilled Tests

    @Test("isMetricsFilled с полными данными")
    func isFilledWithCompleteData() {
        let progress = UserProgress(id: 1)
        progress.pullUps = 10
        progress.pushUps = 20
        progress.squats = 30
        progress.weight = 70.0
        #expect(progress.isMetricsFilled)
    }

    @Test("isMetricsFilled с неполными данными")
    func isFilledWithIncompleteData() {
        let progress = UserProgress(id: 1)
        progress.pullUps = 10
        progress.pushUps = nil
        progress.squats = 30
        progress.weight = 70.0
        #expect(!progress.isMetricsFilled)
    }

    @Test("isMetricsFilled с нулевыми значениями")
    func isFilledWithZeroValues() {
        let progress = UserProgress(id: 1)
        progress.pullUps = 0
        progress.pushUps = 20
        progress.squats = 30
        progress.weight = 70.0
        #expect(!progress.isMetricsFilled)
    }

    @Test("isMetricsFilled с отрицательными значениями")
    func isFilledWithNegativeValues() {
        let progress = UserProgress(id: 1)
        progress.pullUps = -5
        progress.pushUps = 20
        progress.squats = 30
        progress.weight = 70.0
        #expect(!progress.isMetricsFilled)
    }

    @Test(arguments: [
        (nil, nil, nil, nil),
        (10, nil, nil, nil),
        (10, 20, nil, nil),
        (10, 20, 30, nil),
        (0, 20, 30, 70.0),
        (10, 0, 30, 70.0),
        (10, 20, 0, 70.0),
        (10, 20, 30, 0.0),
        (-1, 20, 30, 70.0),
        (10, -1, 30, 70.0),
        (10, 20, -1, 70.0),
        (10, 20, 30, -1.0)
    ])
    func isFilledParameterized(
        pullUps: Int?,
        pushUps: Int?,
        squats: Int?,
        weight: Float?
    ) {
        let progress = UserProgress(id: 1)
        progress.pullUps = pullUps
        progress.pushUps = pushUps
        progress.squats = squats
        progress.weight = weight

        #expect(!progress.isMetricsFilled)
    }

    // MARK: - hasAnyMetricsData Tests

    @Test("hasAnyMetricsData с пустыми данными")
    func hasAnyDataWithEmptyData() {
        let progress = UserProgress(id: 1)
        #expect(!progress.hasAnyMetricsData)
    }

    @Test("hasAnyMetricsData с одним полем pullUps")
    func hasAnyDataWithPullUpsOnly() {
        let progress = UserProgress(id: 1, pullUps: 10)
        #expect(progress.hasAnyMetricsData)
    }

    @Test("hasAnyMetricsData с одним полем pushUps")
    func hasAnyDataWithPushUpsOnly() {
        let progress = UserProgress(id: 1, pushUps: 20)
        #expect(progress.hasAnyMetricsData)
    }

    @Test("hasAnyMetricsData с одним полем squats")
    func hasAnyDataWithSquatsOnly() {
        let progress = UserProgress(id: 1, squats: 30)
        #expect(progress.hasAnyMetricsData)
    }

    @Test("hasAnyMetricsData с одним полем weight")
    func hasAnyDataWithWeightOnly() {
        let progress = UserProgress(id: 1, weight: 70.0)
        #expect(progress.hasAnyMetricsData)
    }

    @Test("hasAnyMetricsData с полными данными")
    func hasAnyDataWithCompleteData() {
        let progress = UserProgress(id: 1, pullUps: 10, pushUps: 20, squats: 30, weight: 70.0)
        #expect(progress.hasAnyMetricsData)
    }

    @Test("hasAnyMetricsData с частичными данными")
    func hasAnyDataWithPartialData() {
        let progress = UserProgress(id: 1, pullUps: 10, weight: 70.0)
        #expect(progress.hasAnyMetricsData)
    }

    @Test("hasAnyMetricsData с нулевыми значениями")
    func hasAnyDataWithZeroValues() {
        let progress = UserProgress(id: 1, pullUps: 0, pushUps: 0, squats: 0, weight: 0.0)
        #expect(!progress.hasAnyMetricsData)
    }

    @Test("hasAnyMetricsData с отрицательными значениями")
    func hasAnyDataWithNegativeValues() {
        let progress = UserProgress(id: 1, pullUps: -5, pushUps: -10, squats: -15, weight: -1.0)
        #expect(!progress.hasAnyMetricsData)
    }

    @Test("hasAnyMetricsData с смешанными значениями (положительные и нулевые)")
    func hasAnyDataWithMixedValues() {
        let progress = UserProgress(id: 1, pullUps: 10, pushUps: 0, squats: 0, weight: 0.0)
        #expect(progress.hasAnyMetricsData)
    }

    @Test("hasAnyMetricsData с одним нулевым значением")
    func hasAnyDataWithOneZeroValue() {
        let progress = UserProgress(id: 1, pullUps: 0)
        #expect(!progress.hasAnyMetricsData)
    }

    @Test("hasAnyMetricsData с одним отрицательным значением")
    func hasAnyDataWithOneNegativeValue() {
        let progress = UserProgress(id: 1, pushUps: -5)
        #expect(!progress.hasAnyMetricsData)
    }

    @Test(arguments: [
        (nil, nil, nil, nil, false),
        (0, nil, nil, nil, false),
        (nil, 0, nil, nil, false),
        (nil, nil, 0, nil, false),
        (nil, nil, nil, 0.0, false),
        (-1, nil, nil, nil, false),
        (nil, -1, nil, nil, false),
        (nil, nil, -1, nil, false),
        (nil, nil, nil, -1.0, false),
        (1, nil, nil, nil, true),
        (nil, 1, nil, nil, true),
        (nil, nil, 1, nil, true),
        (nil, nil, nil, 1.0, true),
        (0, 0, 0, 0.0, false),
        (-1, -1, -1, -1.0, false),
        (1, 0, 0, 0.0, true),
        (0, 1, 0, 0.0, true),
        (0, 0, 1, 0.0, true),
        (0, 0, 0, 1.0, true)
    ])
    func hasAnyDataParameterized(
        pullUps: Int?,
        pushUps: Int?,
        squats: Int?,
        weight: Float?,
        expected: Bool
    ) {
        let progress = UserProgress(id: 1)
        progress.pullUps = pullUps
        progress.pushUps = pushUps
        progress.squats = squats
        progress.weight = weight

        #expect(progress.hasAnyMetricsData == expected)
    }

    // MARK: - canBeDeleted Tests

    @Test("canBeDeleted с пустыми данными и без фото")
    func canBeDeletedWithEmptyDataAndNoPhotos() {
        let progress = UserProgress(id: 1)
        #expect(!progress.canBeDeleted)
    }

    @Test("canBeDeleted с данными упражнений и без фото")
    func canBeDeletedWithExerciseDataAndNoPhotos() {
        let progress = UserProgress(id: 1, pullUps: 10, pushUps: 20, squats: 30, weight: 70.0)
        #expect(progress.canBeDeleted)
    }

    @Test("canBeDeleted без данных упражнений и с фото")
    func canBeDeletedWithNoExerciseDataAndWithPhotos() {
        let progress = UserProgress(id: 1)
        progress.dataPhotoFront = "test".data(using: .utf8)
        #expect(progress.canBeDeleted)
    }

    @Test("canBeDeleted с данными упражнений и фото")
    func canBeDeletedWithExerciseDataAndPhotos() {
        let progress = UserProgress(id: 1, pullUps: 10, weight: 70.0)
        progress.dataPhotoFront = "test".data(using: .utf8)
        progress.dataPhotoBack = "test2".data(using: .utf8)
        #expect(progress.canBeDeleted)
    }

    @Test("canBeDeleted с нулевыми данными упражнений и фото")
    func canBeDeletedWithZeroExerciseDataAndPhotos() {
        let progress = UserProgress(id: 1, pullUps: 0, pushUps: 0, squats: 0, weight: 0.0)
        progress.dataPhotoFront = "test".data(using: .utf8)
        #expect(progress.canBeDeleted)
    }

    @Test("canBeDeleted с отрицательными данными упражнений и фото")
    func canBeDeletedWithNegativeExerciseDataAndPhotos() {
        let progress = UserProgress(id: 1, pullUps: -5, pushUps: -10)
        progress.dataPhotoSide = "test".data(using: .utf8)
        #expect(progress.canBeDeleted)
    }

    @Test("canBeDeleted с одним типом фото")
    func canBeDeletedWithOnePhotoType() {
        let progress = UserProgress(id: 1)
        progress.dataPhotoFront = "test".data(using: .utf8)
        #expect(progress.canBeDeleted)
    }

    @Test("canBeDeleted с URL фото и без локальных данных")
    func canBeDeletedWithPhotoURLsAndNoLocalData() {
        let progress = UserProgress(id: 1)
        progress.urlPhotoFront = "https://example.com/photo1.jpg"
        #expect(progress.canBeDeleted)
    }

    @Test("canBeDeleted с комбинацией локальных и URL фото")
    func canBeDeletedWithMixedPhotoTypes() {
        let progress = UserProgress(id: 1)
        progress.dataPhotoFront = "test".data(using: .utf8)
        progress.urlPhotoBack = "https://example.com/photo2.jpg"
        #expect(progress.canBeDeleted)
    }

    @Test(arguments: [
        // (pullUps, pushUps, squats, weight, hasPhotoData, expected)
        (nil, nil, nil, nil, false, false),
        (10, nil, nil, nil, false, true),
        (nil, 20, nil, nil, false, true),
        (nil, nil, 30, nil, false, true),
        (nil, nil, nil, 70.0, false, true),
        (0, 0, 0, 0.0, false, false),
        (-5, -10, -15, -1.0, false, false),
        (nil, nil, nil, nil, true, true),
        (10, 20, 30, 70.0, true, true),
        (0, 0, 0, 0.0, true, true),
        (-5, -10, -15, -1.0, true, true),
        (5, 10, nil, 75.5, true, true),
        (nil, 10, 20, nil, true, true)
    ])
    func canBeDeletedParameterized(
        pullUps: Int?,
        pushUps: Int?,
        squats: Int?,
        weight: Float?,
        hasPhotoData: Bool,
        expected: Bool
    ) {
        let progress = UserProgress(id: 1)
        progress.pullUps = pullUps
        progress.pushUps = pushUps
        progress.squats = squats
        progress.weight = weight

        if hasPhotoData {
            progress.dataPhotoFront = Data("test".utf8)
        }

        #expect(progress.canBeDeleted == expected)
    }

    // MARK: - displayedValue Tests

    @Test("displayedValue для weight с значением")
    func displayedValueForWeightWithValue() {
        let progress = UserProgress(id: 1, weight: 75.5)
        let displayed = progress.displayedValue(for: .weight)
        #expect(displayed.contains("75.5"))
        #expect(displayed.contains("кг") || displayed.contains("kg"))
    }

    @Test("displayedValue для weight без значения")
    func displayedValueForWeightWithoutValue() {
        let progress = UserProgress(id: 1, weight: nil)
        #expect(progress.displayedValue(for: .weight) == "—")
    }

    @Test("displayedValue для pullUps с значением")
    func displayedValueForPullUpsWithValue() {
        let progress = UserProgress(id: 1, pullUps: 15)
        #expect(progress.displayedValue(for: .pullUps) == "15")
    }

    @Test("displayedValue для pullUps без значения")
    func displayedValueForPullUpsWithoutValue() {
        let progress = UserProgress(id: 1, pullUps: nil)
        #expect(progress.displayedValue(for: .pullUps) == "—")
    }

    @Test("displayedValue для pushUps с значением")
    func displayedValueForPushUpsWithValue() {
        let progress = UserProgress(id: 1, pushUps: 25)
        #expect(progress.displayedValue(for: .pushUps) == "25")
    }

    @Test("displayedValue для pushUps без значения")
    func displayedValueForPushUpsWithoutValue() {
        let progress = UserProgress(id: 1, pushUps: nil)
        #expect(progress.displayedValue(for: .pushUps) == "—")
    }

    @Test("displayedValue для squats с значением")
    func displayedValueForSquatsWithValue() {
        let progress = UserProgress(id: 1, squats: 35)
        #expect(progress.displayedValue(for: .squats) == "35")
    }

    @Test("displayedValue для squats без значения")
    func displayedValueForSquatsWithoutValue() {
        let progress = UserProgress(id: 1, squats: nil)
        #expect(progress.displayedValue(for: .squats) == "—")
    }

    @Test("displayedValue для всех типов с nil значениями")
    func displayedValueForAllTypesWithNilValues() {
        let progress = UserProgress(id: 1)

        #expect(progress.displayedValue(for: .weight) == "—")
        #expect(progress.displayedValue(for: .pullUps) == "—")
        #expect(progress.displayedValue(for: .pushUps) == "—")
        #expect(progress.displayedValue(for: .squats) == "—")
    }

    @Test("displayedValue для всех типов с конкретными значениями")
    func displayedValueForAllTypesWithSpecificValues() {
        let progress = UserProgress(id: 1, pullUps: 15, pushUps: 25, squats: 35, weight: 75.5)

        let weightResult = progress.displayedValue(for: .weight)
        #expect(weightResult.contains("75.5"))
        #expect(weightResult.contains("кг") || weightResult.contains("kg"))

        #expect(progress.displayedValue(for: .pullUps) == "15")
        #expect(progress.displayedValue(for: .pushUps) == "25")
        #expect(progress.displayedValue(for: .squats) == "35")
    }

    @Test("displayedValue с полными данными для всех типов")
    func displayedValueWithCompleteDataForAllTypes() {
        let progress = UserProgress(id: 1, pullUps: 10, pushUps: 20, squats: 30, weight: 70.0)

        let weightDisplayed = progress.displayedValue(for: .weight)
        let pullUpsDisplayed = progress.displayedValue(for: .pullUps)
        let pushUpsDisplayed = progress.displayedValue(for: .pushUps)
        let squatsDisplayed = progress.displayedValue(for: .squats)

        #expect(weightDisplayed.contains("70.0"))
        #expect(weightDisplayed.contains("кг") || weightDisplayed.contains("kg"))
        #expect(pullUpsDisplayed == "10")
        #expect(pushUpsDisplayed == "20")
        #expect(squatsDisplayed == "30")
    }

    @Test("displayedValue с нулевыми значениями для всех типов")
    func displayedValueWithZeroValuesForAllTypes() {
        let progress = UserProgress(id: 1, pullUps: 0, pushUps: 0, squats: 0, weight: 0.0)

        #expect(progress.displayedValue(for: .weight) == "—")
        #expect(progress.displayedValue(for: .pullUps) == "—")
        #expect(progress.displayedValue(for: .pushUps) == "—")
        #expect(progress.displayedValue(for: .squats) == "—")
    }

    // MARK: - Parameterized Tests for displayedValue

    @Test(arguments: [Float.zero, nil])
    func displayedValueForWeightWithNilOrZero(weight: Float?) {
        let progress = UserProgress(id: 1, weight: weight)
        #expect(progress.displayedValue(for: .weight) == "—")
    }

    @Test(arguments: [
        (1.0, "1.0"),
        (10.5, "10.5"),
        (99.9, "99.9"),
        (100.0, "100.0")
    ])
    func displayedValueForWeightParameterized(weight: Float, expected: String) {
        let progress = UserProgress(id: 1, weight: weight)
        let displayed = progress.displayedValue(for: .weight)

        #expect(displayed.contains(expected))
        #expect(displayed.contains("кг") || displayed.contains("kg"))
    }

    @Test(arguments: [Int.zero, nil])
    func displayedValueForPullUpsWithNilOrZero(pullUps: Int?) {
        let progress = UserProgress(id: 1, pullUps: pullUps)
        #expect(progress.displayedValue(for: .pullUps) == "—")
    }

    @Test(arguments: [
        (1, "1"),
        (10, "10"),
        (99, "99"),
        (100, "100")
    ])
    func displayedValueForPullUpsParameterized(pullUps: Int, expected: String) {
        let progress = UserProgress(id: 1, pullUps: pullUps)
        #expect(progress.displayedValue(for: .pullUps) == expected)
    }

    @Test(arguments: [Int.zero, nil])
    func displayedValueForPushUpsWithNilOrZero(pushUps: Int?) {
        let progress = UserProgress(id: 1, pushUps: pushUps)
        #expect(progress.displayedValue(for: .pushUps) == "—")
    }

    @Test(arguments: [
        (1, "1"),
        (10, "10"),
        (99, "99"),
        (100, "100")
    ])
    func displayedValueForPushUpsParameterized(pushUps: Int, expected: String) {
        let progress = UserProgress(id: 1, pushUps: pushUps)
        #expect(progress.displayedValue(for: .pushUps) == expected)
    }

    @Test(arguments: [Int.zero, nil])
    func displayedValueForSquatsWithNilOrZero(squats: Int?) {
        let progress = UserProgress(id: 1, squats: squats)
        #expect(progress.displayedValue(for: .squats) == "—")
    }

    @Test(arguments: [
        (1, "1"),
        (10, "10"),
        (99, "99"),
        (100, "100")
    ])
    func displayedValueForSquatsParameterized(squats: Int, expected: String) {
        let progress = UserProgress(id: 1, squats: squats)
        #expect(progress.displayedValue(for: .squats) == expected)
    }

    // MARK: - Day Mapping Tests

    @Test("getExternalDayFromProgressId для дня 1")
    func getExternalDayFromProgressIdForDayOne() {
        #expect(UserProgress.getExternalDayFromProgressId(1) == 1)
    }

    @Test("getExternalDayFromProgressId для дня 50")
    func getExternalDayFromProgressIdForDayFifty() {
        #expect(UserProgress.getExternalDayFromProgressId(50) == 50)
    }

    @Test("getExternalDayFromProgressId для дня 100")
    func getExternalDayFromProgressIdForDayHundred() {
        #expect(UserProgress.getExternalDayFromProgressId(100) == 99)
    }

    @Test("getExternalDayFromProgressId для обычных дней")
    func getExternalDayFromProgressIdForRegularDays() {
        #expect(UserProgress.getExternalDayFromProgressId(25) == 25)
        #expect(UserProgress.getExternalDayFromProgressId(75) == 75)
        #expect(UserProgress.getExternalDayFromProgressId(150) == 150)
    }

    @Test("getInternalDayFromExternalDay для сервера дня 1")
    func getInternalDayFromExternalDayForServerDayOne() {
        #expect(UserProgress.getInternalDayFromExternalDay(1) == 1)
    }

    @Test("getInternalDayFromExternalDay для сервера дня 49")
    func getInternalDayFromExternalDayForServerDayFortyNine() {
        #expect(UserProgress.getInternalDayFromExternalDay(49) == 49)
    }

    @Test("getInternalDayFromExternalDay для сервера дня 99")
    func getInternalDayFromExternalDayForServerDayNinetyNine() {
        #expect(UserProgress.getInternalDayFromExternalDay(99) == 100)
    }

    @Test("getInternalDayFromExternalDay для обычных серверных дней")
    func getInternalDayFromExternalDayForRegularServerDays() {
        #expect(UserProgress.getInternalDayFromExternalDay(25) == 25)
        #expect(UserProgress.getInternalDayFromExternalDay(75) == 75)
        #expect(UserProgress.getInternalDayFromExternalDay(150) == 150)
    }

    @Test(arguments: [
        (1, 1),
        (49, 49),
        (50, 50),
        (100, 99),
        (25, 25),
        (75, 75),
        (150, 150)
    ])
    func getExternalDayFromProgressIdParameterized(internalDay: Int, expectedExternalDay: Int) {
        #expect(UserProgress.getExternalDayFromProgressId(internalDay) == expectedExternalDay)
    }

    @Test(arguments: [
        (1, 1),
        (49, 49),
        (99, 100),
        (25, 25),
        (75, 75),
        (150, 150)
    ])
    func getInternalDayFromExternalDayParameterized(externalDay: Int, expectedInternalDay: Int) {
        #expect(UserProgress.getInternalDayFromExternalDay(externalDay) == expectedInternalDay)
    }

    @Test("маппинг дней работает корректно для контрольных точек")
    func dayMappingWorksCorrectlyForCheckpoints() {
        // Тестируем контрольные точки (дни 1, 49, 99 сервера)
        let checkpointMappings = [
            (internalDay: 1, externalDay: 1),
            (internalDay: 49, externalDay: 49),
            (internalDay: 100, externalDay: 99)
        ]

        for (internalDay, expectedExternalDay) in checkpointMappings {
            let actualExternalDay = UserProgress.getExternalDayFromProgressId(internalDay)
            #expect(
                actualExternalDay == expectedExternalDay,
                "Неверный маппинг внутреннего дня \(internalDay) во внешний день. Ожидалось: \(expectedExternalDay), получено: \(actualExternalDay)"
            )

            // Проверяем обратный маппинг для внешних дней сервера
            let actualInternalDay = UserProgress.getInternalDayFromExternalDay(expectedExternalDay)
            #expect(
                actualInternalDay == internalDay,
                "Неверный обратный маппинг внешнего дня \(expectedExternalDay) во внутренний день. Ожидалось: \(internalDay), получено: \(actualInternalDay)"
            )
        }

        // Тестируем обычные дни (не контрольные точки)
        let regularDayMappings = [
            (internalDay: 25, externalDay: 25),
            (internalDay: 75, externalDay: 75),
            (internalDay: 150, externalDay: 150)
        ]

        for (internalDay, expectedExternalDay) in regularDayMappings {
            let actualExternalDay = UserProgress.getExternalDayFromProgressId(internalDay)
            #expect(
                actualExternalDay == expectedExternalDay,
                "Неверный маппинг обычного дня \(internalDay). Ожидалось: \(expectedExternalDay), получено: \(actualExternalDay)"
            )

            // Для обычных дней маппинг симметричный
            let actualInternalDay = UserProgress.getInternalDayFromExternalDay(expectedExternalDay)
            #expect(
                actualInternalDay == internalDay,
                "Неверный обратный маппинг обычного дня \(expectedExternalDay). Ожидалось: \(internalDay), получено: \(actualInternalDay)"
            )
        }
    }
}
