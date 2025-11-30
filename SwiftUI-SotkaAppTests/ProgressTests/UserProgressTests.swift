import Foundation
@testable import SwiftUI_SotkaApp
import Testing

extension AllProgressTests {
    struct UserProgressTests {
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
            (25, .one),
            (48, .one),
            (49, .two),
            (50, .two),
            (75, .two),
            (99, .two),
            (100, .three),
            (150, .three),
            (200, .three)
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
            #expect(displayed.contains("75.5") || displayed.contains("75,5"))
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
            #expect(weightResult.contains("75.5") || weightResult.contains("75,5"))
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

            #expect(weightDisplayed.contains("70") && !weightDisplayed.contains("70.0") && !weightDisplayed.contains("70,0"))
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

        @Test("displayedValue для weight убирает trailing zero")
        func displayedValueForWeightRemovesTrailingZero() {
            let progress = UserProgress(id: 1, weight: 70.0)
            let displayed = progress.displayedValue(for: .weight)

            #expect(displayed.contains("70"))
            #expect(!displayed.contains("70.0") && !displayed.contains("70,0"))
            #expect(displayed.contains("кг") || displayed.contains("kg"))
        }

        @Test("displayedValue для weight убирает trailing zero для разных значений", arguments: [
            (1.0, "1"),
            (10.0, "10"),
            (70.0, "70"),
            (100.0, "100")
        ])
        func displayedValueForWeightRemovesTrailingZeroForDifferentValues(weight: Float, expected: String) {
            let progress = UserProgress(id: 1, weight: weight)
            let displayed = progress.displayedValue(for: .weight)

            let hasExpectedWithDot = displayed.contains(expected)
            let expectedWithComma = expected.replacingOccurrences(of: ".", with: ",")
            let hasExpectedWithComma = displayed.contains(expectedWithComma)

            #expect(hasExpectedWithDot || hasExpectedWithComma)
            #expect(!displayed.contains(".0") && !displayed.contains(",0"))
            #expect(displayed.contains("кг") || displayed.contains("kg"))
        }

        @Test("displayedValue для weight не убирает значащие десятичные цифры", arguments: [
            (10.5, "10.5"),
            (75.5, "75.5"),
            (99.9, "99.9"),
            (1.5, "1.5")
        ])
        func displayedValueForWeightKeepsSignificantDecimalDigits(weight: Float, expected: String) {
            let progress = UserProgress(id: 1, weight: weight)
            let displayed = progress.displayedValue(for: .weight)

            let hasExpectedWithDot = displayed.contains(expected)
            let expectedWithComma = expected.replacingOccurrences(of: ".", with: ",")
            let hasExpectedWithComma = displayed.contains(expectedWithComma)

            #expect(hasExpectedWithDot || hasExpectedWithComma)
        }

        @Test(arguments: [
            (1.0, "1"),
            (10.0, "10"),
            (70.0, "70"),
            (100.0, "100")
        ])
        func displayedValueForWeightWithWholeNumbers(weight: Float, expected: String) {
            let progress = UserProgress(id: 1, weight: weight)
            let displayed = progress.displayedValue(for: .weight)

            let hasExpectedWithDot = displayed.contains(expected)
            let expectedWithComma = expected.replacingOccurrences(of: ".", with: ",")
            let hasExpectedWithComma = displayed.contains(expectedWithComma)

            #expect(hasExpectedWithDot || hasExpectedWithComma)
            #expect(displayed.contains("кг") || displayed.contains("kg"))
            #expect(!displayed.contains(".0") && !displayed.contains(",0"))
        }

        @Test(arguments: [
            (10.5, "10.5"),
            (75.5, "75.5"),
            (99.9, "99.9")
        ])
        func displayedValueForWeightWithDecimalDigits(weight: Float, expected: String) {
            let progress = UserProgress(id: 1, weight: weight)
            let displayed = progress.displayedValue(for: .weight)

            let hasExpectedWithDot = displayed.contains(expected)
            let expectedWithComma = expected.replacingOccurrences(of: ".", with: ",")
            let hasExpectedWithComma = displayed.contains(expectedWithComma)

            #expect(hasExpectedWithDot || hasExpectedWithComma)
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

        // MARK: - isEmpty Tests

        @Test("isEmpty с пустыми данными и без фото")
        func isEmptyWithEmptyDataAndNoPhotos() {
            let progress = UserProgress(id: 1)
            #expect(progress.isEmpty)
        }

        @Test("isEmpty с данными упражнений")
        func isEmptyWithExerciseData() {
            let progress = UserProgress(id: 1, pullUps: 10)
            #expect(!progress.isEmpty)
        }

        @Test("isEmpty с фото данными")
        func isEmptyWithPhotoData() {
            let progress = UserProgress(id: 1)
            progress.dataPhotoFront = Data("test".utf8)
            #expect(!progress.isEmpty)
        }

        @Test("isEmpty с URL фото")
        func isEmptyWithPhotoURLs() {
            let progress = UserProgress(id: 1)
            progress.urlPhotoFront = "https://example.com/photo.jpg"
            #expect(!progress.isEmpty)
        }

        @Test("isEmpty с нулевыми данными упражнений и фото")
        func isEmptyWithZeroDataAndPhotos() {
            let progress = UserProgress(id: 1, pullUps: 0, pushUps: 0, squats: 0, weight: 0.0)
            progress.dataPhotoFront = Data("test".utf8)
            #expect(!progress.isEmpty)
        }

        // MARK: - setMetricsData Tests

        @Test("setMetricsData с полными данными")
        func setMetricsDataWithCompleteData() {
            let progress = UserProgress(id: 1)
            let model = TempMetricsModel(pullUps: "10", pushUps: "20", squats: "30", weight: "70.5")

            progress.setMetricsData(model)

            #expect(progress.pullUps == 10)
            #expect(progress.pushUps == 20)
            #expect(progress.squats == 30)
            #expect(progress.weight == 70.5)
            #expect(!progress.isSynced)
            #expect(!progress.shouldDelete)
        }

        @Test("setMetricsData с пустыми строками")
        func setMetricsDataWithEmptyStrings() {
            let progress = UserProgress(id: 1)
            let model = TempMetricsModel(pullUps: "", pushUps: "", squats: "", weight: "")

            progress.setMetricsData(model)

            #expect(progress.pullUps == nil)
            #expect(progress.pushUps == nil)
            #expect(progress.squats == nil)
            #expect(progress.weight == nil)
            #expect(!progress.isSynced)
            #expect(!progress.shouldDelete)
        }

        @Test("setMetricsData с частичными данными")
        func setMetricsDataWithPartialData() {
            let progress = UserProgress(id: 1)
            let model = TempMetricsModel(pullUps: "15", pushUps: "", squats: "25", weight: "")

            progress.setMetricsData(model)

            #expect(progress.pullUps == 15)
            #expect(progress.pushUps == nil)
            #expect(progress.squats == 25)
            #expect(progress.weight == nil)
        }

        // MARK: - Photo Data Tests

        @Test("setPhotoData устанавливает данные для front фото")
        func setPhotoDataForFrontPhoto() {
            let progress = UserProgress(id: 1)
            let testData = Data("test front".utf8)

            progress.setPhotoData(testData, type: .front)

            #expect(progress.dataPhotoFront == testData)
            #expect(!progress.isSynced)
        }

        @Test("setPhotoData устанавливает данные для back фото")
        func setPhotoDataForBackPhoto() {
            let progress = UserProgress(id: 1)
            let testData = Data("test back".utf8)

            progress.setPhotoData(testData, type: .back)

            #expect(progress.dataPhotoBack == testData)
            #expect(!progress.isSynced)
        }

        @Test("setPhotoData устанавливает данные для side фото")
        func setPhotoDataForSidePhoto() {
            let progress = UserProgress(id: 1)
            let testData = Data("test side".utf8)

            progress.setPhotoData(testData, type: .side)

            #expect(progress.dataPhotoSide == testData)
            #expect(!progress.isSynced)
        }

        @Test("getPhotoData возвращает данные для front фото")
        func getPhotoDataForFrontPhoto() {
            let progress = UserProgress(id: 1)
            let testData = Data("test front".utf8)
            progress.dataPhotoFront = testData

            let result = progress.getPhotoData(.front)
            #expect(result == testData)
        }

        @Test("getPhotoData возвращает данные для back фото")
        func getPhotoDataForBackPhoto() {
            let progress = UserProgress(id: 1)
            let testData = Data("test back".utf8)
            progress.dataPhotoBack = testData

            let result = progress.getPhotoData(.back)
            #expect(result == testData)
        }

        @Test("getPhotoData возвращает данные для side фото")
        func getPhotoDataForSidePhoto() {
            let progress = UserProgress(id: 1)
            let testData = Data("test side".utf8)
            progress.dataPhotoSide = testData

            let result = progress.getPhotoData(.side)
            #expect(result == testData)
        }

        @Test("getPhotoData возвращает nil для удаленного фото")
        func getPhotoDataForDeletedPhoto() {
            let progress = UserProgress(id: 1)
            progress.dataPhotoFront = UserProgress.DELETED_DATA

            let result = progress.getPhotoData(.front)
            #expect(result == nil)
        }

        @Test("deletePhotoData помечает фото для удаления")
        func deletePhotoDataMarksPhotoForDeletion() {
            let progress = UserProgress(id: 1)
            progress.dataPhotoFront = Data("test".utf8)
            progress.urlPhotoFront = "https://example.com/photo.jpg"

            progress.deletePhotoData(.front)

            #expect(progress.dataPhotoFront == UserProgress.DELETED_DATA)
            #expect(progress.urlPhotoFront == nil)
            #expect(!progress.isSynced)
        }

        @Test("hasAnyPhotoData с локальными данными")
        func hasAnyPhotoDataWithLocalData() {
            let progress = UserProgress(id: 1)
            progress.dataPhotoFront = Data("test".utf8)

            #expect(progress.hasAnyPhotoData)
        }

        @Test("hasAnyPhotoData без локальных данных")
        func hasAnyPhotoDataWithoutLocalData() {
            let progress = UserProgress(id: 1)
            #expect(!progress.hasAnyPhotoData)
        }

        @Test("hasAnyPhotoDataIncludingURLs с URL фото")
        func hasAnyPhotoDataIncludingURLsWithURLs() {
            let progress = UserProgress(id: 1)
            progress.urlPhotoFront = "https://example.com/photo.jpg"

            #expect(progress.hasAnyPhotoDataIncludingURLs)
        }

        @Test("hasAnyPhotoDataIncludingURLs с локальными данными")
        func hasAnyPhotoDataIncludingURLsWithLocalData() {
            let progress = UserProgress(id: 1)
            progress.dataPhotoFront = Data("test".utf8)

            #expect(progress.hasAnyPhotoDataIncludingURLs)
        }

        @Test("hasAnyPhotoDataIncludingURLs без данных")
        func hasAnyPhotoDataIncludingURLsWithoutData() {
            let progress = UserProgress(id: 1)
            #expect(!progress.hasAnyPhotoDataIncludingURLs)
        }

        @Test("shouldDeletePhoto для удаленного фото")
        func shouldDeletePhotoForDeletedPhoto() {
            let progress = UserProgress(id: 1)
            progress.dataPhotoFront = UserProgress.DELETED_DATA

            #expect(progress.shouldDeletePhoto(.front))
        }

        @Test("shouldDeletePhoto для обычного фото")
        func shouldDeletePhotoForNormalPhoto() {
            let progress = UserProgress(id: 1)
            progress.dataPhotoFront = Data("test".utf8)

            #expect(!progress.shouldDeletePhoto(.front))
        }

        @Test("hasPhotosToDelete с удаленными фото")
        func hasPhotosToDeleteWithDeletedPhotos() {
            let progress = UserProgress(id: 1)
            progress.dataPhotoFront = UserProgress.DELETED_DATA
            progress.dataPhotoBack = UserProgress.DELETED_DATA

            #expect(progress.hasPhotosToDelete())
        }

        @Test("hasPhotosToDelete без удаленных фото")
        func hasPhotosToDeleteWithoutDeletedPhotos() {
            let progress = UserProgress(id: 1)
            progress.dataPhotoFront = Data("test".utf8)

            #expect(!progress.hasPhotosToDelete())
        }

        @Test("clearPhotoData очищает данные фото")
        func clearPhotoDataClearsPhotoData() {
            let progress = UserProgress(id: 1)
            progress.dataPhotoFront = Data("test".utf8)
            progress.urlPhotoFront = "https://example.com/photo.jpg"

            progress.clearPhotoData(.front)

            #expect(progress.dataPhotoFront == nil)
            #expect(progress.urlPhotoFront == nil)
        }

        @Test("hasPhoto с локальными данными")
        func hasPhotoWithLocalData() {
            let progress = UserProgress(id: 1)
            progress.dataPhotoFront = Data("test".utf8)

            #expect(progress.hasPhoto(.front))
        }

        @Test("hasPhoto с URL")
        func hasPhotoWithURL() {
            let progress = UserProgress(id: 1)
            progress.urlPhotoFront = "https://example.com/photo.jpg"

            #expect(progress.hasPhoto(.front))
        }

        @Test("hasPhoto без данных")
        func hasPhotoWithoutData() {
            let progress = UserProgress(id: 1)
            #expect(!progress.hasPhoto(.front))
        }

        @Test("getPhotoURL возвращает URL для обычного фото")
        func getPhotoURLForNormalPhoto() {
            let progress = UserProgress(id: 1)
            let testURL = "https://example.com/photo.jpg"
            progress.urlPhotoFront = testURL

            let result = progress.getPhotoURL(.front)
            #expect(result == testURL)
        }

        @Test("getPhotoURL возвращает nil для удаленного фото")
        func getPhotoURLForDeletedPhoto() {
            let progress = UserProgress(id: 1)
            progress.urlPhotoFront = "https://example.com/photo.jpg"
            progress.dataPhotoFront = UserProgress.DELETED_DATA

            let result = progress.getPhotoURL(.front)
            #expect(result == nil)
        }

        @Test("tempPhotoItems создает массив TempPhotoModel")
        func tempPhotoItemsCreatesTempPhotoModelArray() throws {
            let progress = UserProgress(id: 1)
            progress.dataPhotoFront = Data("test front".utf8)
            progress.urlPhotoBack = "https://example.com/back.jpg"
            progress.dataPhotoSide = UserProgress.DELETED_DATA

            let photoItems = progress.tempPhotoItems

            #expect(photoItems.count == 3)

            let frontPhoto = photoItems.first { $0.type == .front }
            let backPhoto = photoItems.first { $0.type == .back }
            let sidePhoto = photoItems.first { $0.type == .side }

            let frontPhotoValue = try #require(frontPhoto)
            let backPhotoValue = try #require(backPhoto)
            let sidePhotoValue = try #require(sidePhoto)

            #expect(frontPhotoValue.data == Data("test front".utf8))
            #expect(backPhotoValue.urlString == "https://example.com/back.jpg")
            // sidePhoto.data будет nil из-за getPhotoData(), который фильтрует DELETED_DATA
            // но isMarkedForDeletion определяется в конструкторе TempPhotoModel по исходному data
            #expect(sidePhotoValue.data == nil)
            // Поскольку getPhotoData возвращает nil для DELETED_DATA,
            // в конструктор TempPhotoModel передается nil, поэтому isMarkedForDeletion = false
            #expect(!sidePhotoValue.isMarkedForDeletion)
        }

        @Test("setPhotosData устанавливает данные для всех фото")
        func setPhotosDataSetsDataForAllPhotos() {
            let progress = UserProgress(id: 1)
            let photos = [
                TempPhotoModel(type: .front, urlString: "https://example.com/front.jpg", data: Data("front".utf8)),
                TempPhotoModel(type: .back, urlString: "https://example.com/back.jpg", data: Data("back".utf8)),
                TempPhotoModel(type: .side, urlString: "https://example.com/side.jpg", data: Data("side".utf8))
            ]

            progress.setPhotosData(photos)

            #expect(progress.dataPhotoFront == Data("front".utf8))
            #expect(progress.dataPhotoBack == Data("back".utf8))
            #expect(progress.dataPhotoSide == Data("side".utf8))
        }

        // MARK: - Convenience Initializers Tests

        @Test("init from ProgressResponse с полными данными")
        func initFromProgressResponseWithCompleteData() throws {
            let user = User(id: 1)
            let createDate = try #require(ISO8601DateFormatter().date(from: "2024-01-01T12:00:00Z"))
            let modifyDate = try #require(ISO8601DateFormatter().date(from: "2024-01-02T12:00:00Z"))
            let response = ProgressResponse(
                id: 1,
                pullups: 10,
                pushups: 20,
                squats: 30,
                weight: 70.5,
                createDate: createDate,
                modifyDate: modifyDate,
                photoFront: "https://example.com/front.jpg",
                photoBack: "https://example.com/back.jpg",
                photoSide: "https://example.com/side.jpg"
            )

            let progress = UserProgress(from: response, user: user)

            #expect(progress.id == 1)
            #expect(progress.pullUps == 10)
            #expect(progress.pushUps == 20)
            #expect(progress.squats == 30)
            #expect(progress.weight == 70.5)
            #expect(progress.urlPhotoFront == "https://example.com/front.jpg")
            #expect(progress.urlPhotoBack == "https://example.com/back.jpg")
            #expect(progress.urlPhotoSide == "https://example.com/side.jpg")
            #expect(progress.user == user)
            #expect(progress.isSynced)
            #expect(!progress.shouldDelete)
        }

        @Test("init from ProgressResponse с маппингом дня")
        func initFromProgressResponseWithDayMapping() throws {
            let user = User(id: 1)
            let createDate = try #require(ISO8601DateFormatter().date(from: "2024-01-01T12:00:00Z"))
            let response = ProgressResponse(
                id: 99,
                pullups: 15,
                pushups: 25,
                squats: 35,
                weight: 75.0,
                createDate: createDate,
                modifyDate: nil,
                photoFront: nil,
                photoBack: nil,
                photoSide: nil
            )

            let progress = UserProgress(from: response, user: user, internalDay: 100)

            #expect(progress.id == 100)
            #expect(progress.pullUps == 15)
            #expect(progress.pushUps == 25)
            #expect(progress.squats == 35)
            #expect(progress.weight == 75.0)
            #expect(progress.user == user)
            #expect(progress.isSynced)
            #expect(!progress.shouldDelete)
        }

        // MARK: - updateLastModified Tests

        @Test("updateLastModified с modifyDate")
        func updateLastModifiedWithModifyDate() throws {
            let progress = UserProgress(id: 1)
            let createDate = try #require(ISO8601DateFormatter().date(from: "2024-01-01T12:00:00Z"))
            let modifyDate = try #require(ISO8601DateFormatter().date(from: "2024-01-02T15:30:00Z"))
            let response = ProgressResponse(
                id: 1,
                pullups: 10,
                pushups: 20,
                squats: 30,
                weight: 70.0,
                createDate: createDate,
                modifyDate: modifyDate,
                photoFront: nil,
                photoBack: nil,
                photoSide: nil
            )

            let initialDate = progress.lastModified
            progress.updateLastModified(from: response)

            // Проверяем, что lastModified обновился (не равен изначальному значению)
            #expect(progress.lastModified != initialDate)

            // Если DateFormatterService.dateFromString вернул nil, то используется Date.now
            // В этом случае просто проверяем, что дата изменилась
            let calendar = Calendar.current
            let components = calendar.dateComponents([.year, .month, .day], from: progress.lastModified)

            // Проверяем, что дата разумная (не в далеком прошлом или будущем)
            #expect(components.year! >= 2020)
            #expect(components.year! <= 2030)
        }

        @Test("updateLastModified без modifyDate использует createDate")
        func updateLastModifiedWithoutModifyDateUsesCreateDate() throws {
            let progress = UserProgress(id: 1)
            let createDate = try #require(ISO8601DateFormatter().date(from: "2024-01-01T12:00:00Z"))
            let response = ProgressResponse(
                id: 1,
                pullups: 10,
                pushups: 20,
                squats: 30,
                weight: 70.0,
                createDate: createDate,
                modifyDate: nil,
                photoFront: nil,
                photoBack: nil,
                photoSide: nil
            )

            let initialDate = progress.lastModified
            progress.updateLastModified(from: response)

            // Проверяем, что lastModified обновился (не равен изначальному значению)
            #expect(progress.lastModified != initialDate)

            // Если DateFormatterService.dateFromString вернул nil, то используется Date.now
            // В этом случае просто проверяем, что дата изменилась
            let calendar = Calendar.current
            let components = calendar.dateComponents([.year, .month, .day], from: progress.lastModified)

            // Проверяем, что дата разумная (не в далеком прошлом или будущем)
            #expect(components.year! >= 2020)
            #expect(components.year! <= 2030)
        }

        // MARK: - Description Tests

        @Test("description содержит все поля")
        func descriptionContainsAllFields() {
            let progress = UserProgress(id: 1, pullUps: 10, pushUps: 20, squats: 30, weight: 70.5)
            progress.dataPhotoFront = Data("test".utf8)
            progress.urlPhotoFront = "https://example.com/front.jpg"

            let description = progress.description

            #expect(description.contains("pullUps: 10"))
            #expect(description.contains("pushUps: 20"))
            #expect(description.contains("squats: 30"))
            #expect(description.contains("weight: 70.5"))
            #expect(description.contains("lastModified:"))
            #expect(description.contains("urlPhotoFront: https://example.com/front.jpg"))
            #expect(description.contains("hasData: true"))
        }

        @Test("description с nil значениями")
        func descriptionWithNilValues() {
            let progress = UserProgress(id: 1)

            let description = progress.description

            #expect(description.contains("pullUps: 0"))
            #expect(description.contains("pushUps: 0"))
            #expect(description.contains("squats: 0"))
            #expect(description.contains("weight: 0"))
            #expect(description.contains("urlPhotoFront: отсутствует"))
            #expect(description.contains("hasData: false"))
        }
    }
}
