import Foundation
import SwiftData
@testable import SwiftUI_SotkaApp
import Testing

@MainActor
struct ProgressServiceTests {
    // MARK: - Валидация данных (canSave)

    @Test("canSave возвращает false для пустых данных")
    func canSaveReturnsFalseForEmptyData() {
        let progress = Progress(id: 1)
        let service = ProgressService(progress: progress, mode: .metrics)

        #expect(!service.canSave)
    }

    @Test("canSave возвращает false, если данные не изменились")
    func canSaveReturnsTrueForPullUpsOnly() {
        let progress = Progress(id: 1, pullUps: 10)
        let service = ProgressService(progress: progress, mode: .metrics)
        service.metricsModel.pullUps = "10"

        #expect(!service.canSave)
    }

    @Test("canSave возвращает true для данных только с весом")
    func canSaveReturnsTrueForWeightOnly() {
        let progress = Progress(id: 1, weight: 70.5)
        let service = ProgressService(progress: progress, mode: .metrics)
        service.metricsModel.weight = "70.5"

        #expect(service.canSave)
    }

    @Test("canSave возвращает true для полных данных")
    func canSaveReturnsTrueForCompleteData() {
        let progress = Progress(id: 1, pullUps: 10, pushUps: 20, squats: 30, weight: 70.5)
        let service = ProgressService(progress: progress, mode: .metrics)
        service.metricsModel.pullUps = "10"
        service.metricsModel.pushUps = "20"
        service.metricsModel.squats = "30"
        service.metricsModel.weight = "70.5"

        #expect(service.canSave)
    }

    @Test("canSave возвращает false для отрицательных значений подтягиваний")
    func canSaveReturnsFalseForNegativePullUps() {
        let progress = Progress(id: 1)
        let service = ProgressService(progress: progress, mode: .metrics)
        service.metricsModel.pullUps = "-5"

        #expect(!service.canSave)
    }

    @Test("canSave возвращает false для отрицательных значений отжиманий")
    func canSaveReturnsFalseForNegativePushUps() {
        let progress = Progress(id: 1)
        let service = ProgressService(progress: progress, mode: .metrics)
        service.metricsModel.pushUps = "-10"

        #expect(!service.canSave)
    }

    @Test("canSave возвращает false для отрицательных значений приседаний")
    func canSaveReturnsFalseForNegativeSquats() {
        let progress = Progress(id: 1)
        let service = ProgressService(progress: progress, mode: .metrics)
        service.metricsModel.squats = "-15"

        #expect(!service.canSave)
    }

    @Test("canSave возвращает false для отрицательного веса")
    func canSaveReturnsFalseForNegativeWeight() {
        let progress = Progress(id: 1)
        let service = ProgressService(progress: progress, mode: .metrics)
        service.metricsModel.weight = "-70.5"

        #expect(!service.canSave)
    }

    @Test("canSave возвращает true для нулевых значений подтягиваний")
    func canSaveReturnsTrueForZeroPullUps() {
        let progress = Progress(id: 1)
        let service = ProgressService(progress: progress, mode: .metrics)
        service.metricsModel.pullUps = "0"

        #expect(service.canSave)
    }

    @Test("canSave возвращает true для нулевых значений отжиманий")
    func canSaveReturnsTrueForZeroPushUps() {
        let progress = Progress(id: 1)
        let service = ProgressService(progress: progress, mode: .metrics)
        service.metricsModel.pushUps = "0"

        #expect(service.canSave)
    }

    @Test("canSave возвращает true для нулевых значений приседаний")
    func canSaveReturnsTrueForZeroSquats() {
        let progress = Progress(id: 1)
        let service = ProgressService(progress: progress, mode: .metrics)
        service.metricsModel.squats = "0"

        #expect(service.canSave)
    }

    @Test("canSave возвращает true для нулевого веса")
    func canSaveReturnsTrueForZeroWeight() {
        let progress = Progress(id: 1)
        let service = ProgressService(progress: progress, mode: .metrics)
        service.metricsModel.weight = "0"

        #expect(service.canSave)
    }

    @Test("canSave возвращает true для дробного веса")
    func canSaveReturnsTrueForDecimalWeight() {
        let progress = Progress(id: 1)
        let service = ProgressService(progress: progress, mode: .metrics)
        service.metricsModel.weight = "70.5"

        #expect(service.canSave)
    }

    @Test("canSave возвращает false для некорректных символов в подтягиваниях")
    func canSaveReturnsFalseForInvalidCharactersInPullUps() {
        let progress = Progress(id: 1)
        let service = ProgressService(progress: progress, mode: .metrics)
        service.metricsModel.pullUps = "10a"

        #expect(!service.canSave)
    }

    @Test("canSave возвращает false для некорректных символов в весе")
    func canSaveReturnsFalseForInvalidCharactersInWeight() {
        let progress = Progress(id: 1)
        let service = ProgressService(progress: progress, mode: .metrics)
        service.metricsModel.weight = "70.5.5"

        #expect(!service.canSave)
    }

    // MARK: - Определение изменений (hasChanges)

    @Test("canSave возвращает false для нового прогресса без данных")
    func canSaveReturnsFalseForNewProgressWithoutData() {
        let progress = Progress(id: 1)
        let service = ProgressService(progress: progress, mode: .metrics)

        #expect(!service.canSave)
    }

    @Test("canSave возвращает true для нового прогресса с данными")
    func canSaveReturnsTrueForNewProgressWithData() {
        let progress = Progress(id: 1)
        let service = ProgressService(progress: progress, mode: .metrics)
        service.metricsModel.pullUps = "10"

        #expect(service.canSave)
    }

    @Test("canSave возвращает false для существующего прогресса без изменений")
    func canSaveReturnsFalseForExistingProgressWithoutChanges() {
        let progress = Progress(id: 1, pullUps: 10, pushUps: 20, squats: 30, weight: 70.5)
        let service = ProgressService(progress: progress, mode: .metrics)
        // Данные загружаются из прогресса, поэтому изменений нет

        #expect(!service.canSave)
    }

    @Test("canSave возвращает true при изменении подтягиваний")
    func canSaveReturnsTrueWhenPullUpsChanged() {
        let progress = Progress(id: 1, pullUps: 10, pushUps: 20, squats: 30, weight: 70.5)
        let service = ProgressService(progress: progress, mode: .metrics)
        service.metricsModel.pullUps = "15" // Изменили значение

        #expect(service.canSave)
    }

    @Test("canSave возвращает true при изменении веса")
    func canSaveReturnsTrueWhenWeightChanged() {
        let progress = Progress(id: 1, pullUps: 10, pushUps: 20, squats: 30, weight: 70.5)
        let service = ProgressService(progress: progress, mode: .metrics)
        service.metricsModel.weight = "75.0" // Изменили значение

        #expect(service.canSave)
    }

    @Test("canSave возвращает false при установке того же значения")
    func canSaveReturnsFalseWhenSettingSameValue() {
        let progress = Progress(id: 1, pullUps: 10, pushUps: 20, squats: 30, weight: 70.5)
        let service = ProgressService(progress: progress, mode: .metrics)
        service.metricsModel.pullUps = "10" // Установили то же значение

        #expect(!service.canSave)
    }

    // MARK: - Загрузка данных (loadProgress)

    @Test("loadProgress корректно загружает данные из прогресса")
    func loadProgressLoadsDataFromProgress() {
        let progress = Progress(id: 1, pullUps: 10, pushUps: 20, squats: 30, weight: 70.5)
        let service = ProgressService(progress: progress, mode: .metrics)

        #expect(service.metricsModel.pullUps == "10")
        #expect(service.metricsModel.pushUps == "20")
        #expect(service.metricsModel.squats == "30")
        #expect(service.metricsModel.weight == "70,5") // Конвертация точки в запятую для UI
    }

    @Test("loadProgress корректно обрабатывает nil значения")
    func loadProgressHandlesNilValues() {
        let progress = Progress(id: 1, pullUps: nil, pushUps: 20, squats: nil, weight: nil)
        let service = ProgressService(progress: progress, mode: .metrics)

        #expect(service.metricsModel.pullUps == "")
        #expect(service.metricsModel.pushUps == "20")
        #expect(service.metricsModel.squats == "")
        #expect(service.metricsModel.weight == "")
    }

    @Test("loadProgress корректно обрабатывает нулевые значения")
    func loadProgressHandlesZeroValues() {
        let progress = Progress(id: 1, pullUps: 0, pushUps: 0, squats: 0, weight: 0.0)
        let service = ProgressService(progress: progress, mode: .metrics)

        #expect(service.metricsModel.pullUps == "")
        #expect(service.metricsModel.pushUps == "")
        #expect(service.metricsModel.squats == "")
        #expect(service.metricsModel.weight == "")
    }

    // MARK: - Сохранение данных (saveProgress)

    @Test("saveProgress обновляет данные прогресса")
    func saveProgressUpdatesProgressData() async throws {
        // Создаем отдельный модельный контекст для этого теста
        let modelConfiguration = ModelConfiguration(isStoredInMemoryOnly: true)
        let modelContainer = try ModelContainer(for: User.self, Progress.self, configurations: modelConfiguration)
        let modelContext = modelContainer.mainContext

        // Создаем тестового пользователя
        let user = User(id: 1, userName: "test", email: "test@test.com", cityID: nil)
        modelContext.insert(user)
        try modelContext.save()

        // Создаем прогресс через контекст
        let progress = Progress(id: 1)
        modelContext.insert(progress)
        try modelContext.save()

        let service = ProgressService(progress: progress, mode: .metrics)

        // Устанавливаем данные
        service.metricsModel.pullUps = "15"
        service.metricsModel.pushUps = "25"
        service.metricsModel.squats = "35"
        service.metricsModel.weight = "75.5"

        // Сохраняем
        try service.saveProgress(context: modelContext)

        // Проверяем, что данные обновились
        #expect(progress.pullUps == 15)
        #expect(progress.pushUps == 25)
        #expect(progress.squats == 35)
        #expect(progress.weight == 75.5)
        #expect(!progress.isSynced) // Должен быть помечен как несинхронизированный
    }

    @Test("saveProgress создает связь с пользователем")
    func saveProgressCreatesUserRelation() async throws {
        // Создаем отдельный модельный контекст для этого теста
        let modelConfiguration = ModelConfiguration(isStoredInMemoryOnly: true)
        let modelContainer = try ModelContainer(for: User.self, Progress.self, configurations: modelConfiguration)
        let modelContext = modelContainer.mainContext

        // Создаем тестового пользователя
        let user = User(id: 1, userName: "test", email: "test@test.com", cityID: nil)
        modelContext.insert(user)
        try modelContext.save()

        // Создаем прогресс через контекст
        let progress = Progress(id: 1)
        modelContext.insert(progress)
        try modelContext.save()

        let service = ProgressService(progress: progress, mode: .metrics)

        // Устанавливаем данные
        service.metricsModel.pullUps = "10"

        // Сохраняем
        try service.saveProgress(context: modelContext)

        // Проверяем, что связь с пользователем установлена
        #expect(progress.user != nil)
    }

    // MARK: - Удаление прогресса (deleteProgress)

    @Test("deleteProgress помечает прогресс для удаления")
    func deleteProgressMarksProgressForDeletion() async throws {
        let progress = Progress(id: 1, pullUps: 10)
        let service = ProgressService(progress: progress, mode: .metrics)

        // Создаем модельный контекст для теста
        let modelContext = try createTestModelContext()

        // Удаляем
        try service.deleteProgress(context: modelContext)

        // Проверяем, что прогресс помечен для удаления
        #expect(progress.shouldDelete)
        #expect(!progress.isSynced)
    }

    // MARK: - Вспомогательные методы

    private func createTestModelContext() throws -> ModelContext {
        let modelConfiguration = ModelConfiguration(isStoredInMemoryOnly: true)
        // Включаем обе модели в контейнер для корректной работы с отношениями
        let modelContainer = try ModelContainer(for: User.self, Progress.self, configurations: modelConfiguration)

        // Создаем тестового пользователя
        let user = User(id: 1, userName: "test", email: "test@test.com", cityID: nil)
        modelContainer.mainContext.insert(user)

        try modelContainer.mainContext.save()

        return modelContainer.mainContext
    }
}
