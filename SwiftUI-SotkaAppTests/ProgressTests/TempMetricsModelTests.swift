import Foundation
import SwiftData
@testable import SwiftUI_SotkaApp
import Testing

extension AllProgressTests {
    struct TempMetricsModelTests {
        @Test("Инициализация с пустыми значениями")
        func initWithEmptyValues() {
            let model = TempMetricsModel()

            #expect(model.pullUps == "")
            #expect(model.pushUps == "")
            #expect(model.squats == "")
            #expect(model.weight == "")
        }

        @Test("Инициализация с кастомными значениями")
        func initWithCustomValues() {
            let model = TempMetricsModel(
                pullUps: "10",
                pushUps: "20",
                squats: "30",
                weight: "70.5"
            )

            #expect(model.pullUps == "10")
            #expect(model.pushUps == "20")
            #expect(model.squats == "30")
            #expect(model.weight == "70.5")
        }

        @Test("Инициализация из UserProgress с полными данными")
        func initFromUserProgressWithFullData() {
            let progress = UserProgress(id: 1, pullUps: 10, pushUps: 20, squats: 30, weight: 70.5)
            let model = TempMetricsModel(progress: progress)
            #expect(model.pullUps == "10")
            #expect(model.pushUps == "20")
            #expect(model.squats == "30")
            #expect(model.weight == "70,5")
        }

        @Test("Инициализация из UserProgress с nil значениями")
        func initFromUserProgressWithNilValues() {
            let progress = UserProgress(id: 1, pullUps: nil, pushUps: nil, squats: nil, weight: nil)
            let model = TempMetricsModel(progress: progress)
            #expect(model.pullUps == "")
            #expect(model.pushUps == "")
            #expect(model.squats == "")
            #expect(model.weight == "")
        }

        @Test("Инициализация из UserProgress с нулевыми значениями")
        func initFromUserProgressWithZeroValues() throws {
            let container = try ModelContainer(for: UserProgress.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
            let context = ModelContext(container)

            let progress = UserProgress(id: 1, pullUps: 0, pushUps: 0, squats: 0, weight: 0.0)
            context.insert(progress)

            let model = TempMetricsModel(progress: progress)

            #expect(model.pullUps == "")
            #expect(model.pushUps == "")
            #expect(model.squats == "")
            #expect(model.weight == "")
        }

        @Test("hasValidNumbers возвращает true для валидных значений")
        func hasValidNumbersReturnsTrueForValidValues() {
            let model = TempMetricsModel(
                pullUps: "10",
                pushUps: "20",
                squats: "30",
                weight: "70.5"
            )

            #expect(model.hasValidNumbers)
        }

        @Test("hasValidNumbers возвращает true для нулевых значений")
        func hasValidNumbersReturnsTrueForZeroValues() {
            let model = TempMetricsModel(
                pullUps: "0",
                pushUps: "0",
                squats: "0",
                weight: "0"
            )

            #expect(model.hasValidNumbers)
        }

        @Test("hasValidNumbers возвращает true для пустых значений")
        func hasValidNumbersReturnsTrueForEmptyValues() {
            let model = TempMetricsModel()

            #expect(model.hasValidNumbers)
        }

        @Test("hasValidNumbers возвращает false для отрицательных значений")
        func hasValidNumbersReturnsFalseForNegativeValues() {
            let model = TempMetricsModel(
                pullUps: "-5",
                pushUps: "-10",
                squats: "-15",
                weight: "-70.5"
            )

            #expect(!model.hasValidNumbers)
        }

        @Test("hasValidNumbers возвращает false для некорректных символов")
        func hasValidNumbersReturnsFalseForInvalidCharacters() {
            let model = TempMetricsModel(
                pullUps: "10a",
                pushUps: "20.5",
                squats: "abc",
                weight: "70.5.5"
            )

            #expect(!model.hasValidNumbers)
        }

        @Test("hasValidNumbers возвращает false для частично валидных значений")
        func hasValidNumbersReturnsFalseForPartiallyValidValues() {
            let model = TempMetricsModel(
                pullUps: "10",
                pushUps: "20",
                squats: "abc",
                weight: "70.5"
            )

            #expect(!model.hasValidNumbers)
        }

        @Test("hasAnyFilledValue возвращает true при наличии хотя бы одного значения")
        func hasAnyFilledValueReturnsTrueWhenAnyValueFilled() {
            let model1 = TempMetricsModel(pullUps: "10")
            #expect(model1.hasAnyFilledValue)

            let model2 = TempMetricsModel(pushUps: "20")
            #expect(model2.hasAnyFilledValue)

            let model3 = TempMetricsModel(squats: "30")
            #expect(model3.hasAnyFilledValue)

            let model4 = TempMetricsModel(weight: "70.5")
            #expect(model4.hasAnyFilledValue)
        }

        @Test("hasAnyFilledValue возвращает true для всех заполненных значений")
        func hasAnyFilledValueReturnsTrueForAllFilledValues() {
            let model = TempMetricsModel(
                pullUps: "10",
                pushUps: "20",
                squats: "30",
                weight: "70.5"
            )

            #expect(model.hasAnyFilledValue)
        }

        @Test("hasAnyFilledValue возвращает false для пустых значений")
        func hasAnyFilledValueReturnsFalseForEmptyValues() {
            let model = TempMetricsModel()

            #expect(!model.hasAnyFilledValue)
        }

        @Test("hasChanges возвращает false для идентичных значений")
        func hasChangesReturnsFalseForIdenticalValues() throws {
            let container = try ModelContainer(for: UserProgress.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
            let context = ModelContext(container)

            let progress = UserProgress(id: 1, pullUps: 10, pushUps: 20, squats: 30, weight: 70.5)
            context.insert(progress)

            let model = TempMetricsModel(progress: progress)

            #expect(!model.hasChanges(to: progress))
        }

        @Test("hasChanges возвращает true при изменении подтягиваний")
        func hasChangesReturnsTrueWhenPullUpsChanged() throws {
            let container = try ModelContainer(for: UserProgress.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
            let context = ModelContext(container)

            let progress = UserProgress(id: 1, pullUps: 10, pushUps: 20, squats: 30, weight: 70.5)
            context.insert(progress)

            var model = TempMetricsModel(progress: progress)
            model.pullUps = "15"

            #expect(model.hasChanges(to: progress))
        }

        @Test("hasChanges возвращает true при изменении отжиманий")
        func hasChangesReturnsTrueWhenPushUpsChanged() throws {
            let container = try ModelContainer(for: UserProgress.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
            let context = ModelContext(container)

            let progress = UserProgress(id: 1, pullUps: 10, pushUps: 20, squats: 30, weight: 70.5)
            context.insert(progress)

            var model = TempMetricsModel(progress: progress)
            model.pushUps = "25"

            #expect(model.hasChanges(to: progress))
        }

        @Test("hasChanges возвращает true при изменении приседаний")
        func hasChangesReturnsTrueWhenSquatsChanged() throws {
            let container = try ModelContainer(for: UserProgress.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
            let context = ModelContext(container)

            let progress = UserProgress(id: 1, pullUps: 10, pushUps: 20, squats: 30, weight: 70.5)
            context.insert(progress)

            var model = TempMetricsModel(progress: progress)
            model.squats = "35"

            #expect(model.hasChanges(to: progress))
        }

        @Test("hasChanges возвращает true при изменении веса")
        func hasChangesReturnsTrueWhenWeightChanged() throws {
            let container = try ModelContainer(for: UserProgress.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
            let context = ModelContext(container)

            let progress = UserProgress(id: 1, pullUps: 10, pushUps: 20, squats: 30, weight: 70.5)
            context.insert(progress)

            var model = TempMetricsModel(progress: progress)
            model.weight = "75.0"

            #expect(model.hasChanges(to: progress))
        }

        @Test("hasChanges возвращает true при изменении нескольких значений")
        func hasChangesReturnsTrueWhenMultipleValuesChanged() throws {
            let container = try ModelContainer(for: UserProgress.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
            let context = ModelContext(container)

            let progress = UserProgress(id: 1, pullUps: 10, pushUps: 20, squats: 30, weight: 70.5)
            context.insert(progress)

            var model = TempMetricsModel(progress: progress)
            model.pullUps = "15"
            model.weight = "75.0"

            #expect(model.hasChanges(to: progress))
        }

        @Test("hasChanges с nil значениями в UserProgress")
        func hasChangesWithNilValuesInUserProgress() throws {
            let container = try ModelContainer(for: UserProgress.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
            let context = ModelContext(container)

            let progress = UserProgress(id: 1, pullUps: nil, pushUps: nil, squats: nil, weight: nil)
            context.insert(progress)

            var model = TempMetricsModel(progress: progress)
            model.pullUps = "10"

            #expect(model.hasChanges(to: progress))
        }

        @Test("hasChanges с нулевыми значениями в UserProgress")
        func hasChangesWithZeroValuesInUserProgress() throws {
            let container = try ModelContainer(for: UserProgress.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
            let context = ModelContext(container)

            let progress = UserProgress(id: 1, pullUps: 0, pushUps: 0, squats: 0, weight: 0.0)
            context.insert(progress)

            var model = TempMetricsModel(progress: progress)
            model.pullUps = "10"

            #expect(model.hasChanges(to: progress))
        }

        @Test("Параметризированный тест hasValidNumbers - валидные значения", arguments: [
            ("10", "20", "30", "70.5"),
            ("0", "0", "0", "0"),
            ("", "", "", ""),
            ("100", "200", "300", "150.75"),
            ("1", "2", "3", "50.0")
        ])
        func hasValidNumbersParameterizedValid(pullUps: String, pushUps: String, squats: String, weight: String) {
            let model = TempMetricsModel(
                pullUps: pullUps,
                pushUps: pushUps,
                squats: squats,
                weight: weight
            )

            #expect(model.hasValidNumbers)
        }

        @Test("Тест hasValidNumbers - невалидные значения", arguments: [
            ("-5", "-10", "-15", "-70.5"),
            ("10a", "20.5", "abc", "70.5.5"),
            ("10", "20", "abc", "70.5"),
            ("abc", "def", "ghi", "jkl"),
            ("10.5", "20.5", "30.5", "70.5")
        ])
        func hasValidNumbersParameterizedInvalid(pullUps: String, pushUps: String, squats: String, weight: String) {
            let model = TempMetricsModel(
                pullUps: pullUps,
                pushUps: pushUps,
                squats: squats,
                weight: weight
            )

            #expect(!model.hasValidNumbers)
        }

        @Test("Тест hasAnyFilledValue - валидные значения", arguments: [
            ("10", "", "", ""),
            ("", "20", "", ""),
            ("", "", "30", ""),
            ("", "", "", "70.5"),
            ("10", "20", "30", "70.5"),
            ("5", "15", "25", "65.0")
        ])
        func hasAnyFilledValueParameterizedFilled(pullUps: String, pushUps: String, squats: String, weight: String) {
            let model = TempMetricsModel(
                pullUps: pullUps,
                pushUps: pushUps,
                squats: squats,
                weight: weight
            )

            #expect(model.hasAnyFilledValue)
        }

        @Test("Тест hasAnyFilledValue - невалидные значения")
        func hasAnyFilledValueParameterizedEmpty() {
            let model = TempMetricsModel()

            #expect(!model.hasAnyFilledValue)
        }

        @Test("CustomStringConvertible description")
        func customStringConvertibleDescription() {
            let model = TempMetricsModel(
                pullUps: "10",
                pushUps: "20",
                squats: "30",
                weight: "70.5"
            )

            let expectedDescription = "pullUps: 10, pushUps: 20, squats: 30, weight: 70.5"
            #expect(model.description == expectedDescription)
        }

        @Test("CustomStringConvertible description с пустыми значениями")
        func customStringConvertibleDescriptionWithEmptyValues() {
            let model = TempMetricsModel()

            let expectedDescription = "pullUps: , pushUps: , squats: , weight: "
            #expect(model.description == expectedDescription)
        }

        @Test("Проверка мутабельности свойств")
        func propertiesMutability() {
            var model = TempMetricsModel()

            model.pullUps = "15"
            model.pushUps = "25"
            model.squats = "35"
            model.weight = "75.0"

            #expect(model.pullUps == "15")
            #expect(model.pushUps == "25")
            #expect(model.squats == "35")
            #expect(model.weight == "75.0")
        }

        @Test("Проверка работы с дробными значениями веса")
        func fractionalWeightValues() {
            let model = TempMetricsModel(weight: "70.5")

            #expect(model.hasValidNumbers)
            #expect(model.hasAnyFilledValue)
            #expect(model.weight == "70.5")
        }

        @Test("Проверка работы с целыми значениями веса")
        func integerWeightValues() {
            let model = TempMetricsModel(weight: "70")

            #expect(model.hasValidNumbers)
            #expect(model.hasAnyFilledValue)
            #expect(model.weight == "70")
        }

        @Test("Проверка работы с большими значениями")
        func largeValues() {
            let model = TempMetricsModel(
                pullUps: "100",
                pushUps: "200",
                squats: "300",
                weight: "150.75"
            )

            #expect(model.hasValidNumbers)
            #expect(model.hasAnyFilledValue)
            #expect(model.pullUps == "100")
            #expect(model.pushUps == "200")
            #expect(model.squats == "300")
            #expect(model.weight == "150.75")
        }
    }
}
