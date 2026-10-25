import Foundation
import SwiftData
@testable import SwiftUI_SotkaApp
import Testing

@Suite("Тесты SwiftData миграции")
@MainActor
struct SwiftDataMigrationTests {
    @Test("Апгрейд c релизов 4.0/4.1 на текущую схему сохраняет данные")
    func opensStoreFromRelease40AndPreservesData() throws {
        let (directoryURL, storeURL) = makeStoreURLs()
        defer { try? FileManager.default.removeItem(at: directoryURL) }

        do {
            let oldSchema = makeRelease40Schema()
            let oldConfiguration = ModelConfiguration("MigrationFrom40", schema: oldSchema, url: storeURL)
            let oldContainer = try ModelContainer(for: oldSchema, configurations: [oldConfiguration])
            let oldContext = oldContainer.mainContext

            let user = User(id: 401, userName: "legacy-40-user")
            let progress = UserProgress(id: 7, pullUps: 11, pushUps: 22, squats: 33, weight: 70)
            progress.user = user

            oldContext.insert(user)
            oldContext.insert(progress)
            try oldContext.save()
        }

        let newSchema = makeCurrentSchema()
        let newConfiguration = ModelConfiguration("MigrationFrom40", schema: newSchema, url: storeURL)
        let migratedContainer = try ModelContainer(for: newSchema, configurations: [newConfiguration])
        let context = migratedContainer.mainContext

        let users = try context.fetch(FetchDescriptor<User>())
        let progressList = try context.fetch(FetchDescriptor<UserProgress>())
        let firstUser = try #require(users.first)
        let firstProgress = try #require(progressList.first)

        #expect(users.count == 1)
        #expect(firstUser.id == 401)
        #expect(progressList.count == 1)
        #expect(firstProgress.id == 7)

        let extensions = try context.fetch(FetchDescriptor<CalendarExtensionRecord>())
        #expect(extensions.isEmpty)
    }

    @Test("Открытие legacy БД не падает и сохраняет данные")
    func opensLegacySchemaAndPreservesData() throws {
        let (directoryURL, storeURL) = makeStoreURLs()
        defer { try? FileManager.default.removeItem(at: directoryURL) }

        do {
            let oldSchema = makeLegacySchema()
            let oldConfiguration = ModelConfiguration("MigrationTest", schema: oldSchema, url: storeURL)
            let oldContainer = try ModelContainer(for: oldSchema, configurations: [oldConfiguration])
            let oldContext = oldContainer.mainContext

            let user = User(id: 42, userName: "legacy-user")
            let progress = UserProgress(id: 49, pullUps: 10, pushUps: 20, squats: 30, weight: 75)
            progress.user = user

            oldContext.insert(user)
            oldContext.insert(progress)
            try oldContext.save()
        }

        let newSchema = makeCurrentSchema()
        let newConfiguration = ModelConfiguration("MigrationTest", schema: newSchema, url: storeURL)
        let migratedContainer = try ModelContainer(for: newSchema, configurations: [newConfiguration])
        let context = migratedContainer.mainContext

        let users = try context.fetch(FetchDescriptor<User>())
        let progressList = try context.fetch(FetchDescriptor<UserProgress>())
        let extensions = try context.fetch(FetchDescriptor<CalendarExtensionRecord>())
        let firstUser = try #require(users.first)
        let firstProgress = try #require(progressList.first)

        #expect(users.count == 1)
        #expect(firstUser.id == 42)
        #expect(progressList.count == 1)
        #expect(firstProgress.id == 49)
        #expect(extensions.isEmpty)
    }

    @Test("Новая сущность CalendarExtensionRecord доступна после открытия legacy БД")
    func calendarExtensionEntityIsAvailableAfterLegacyOpen() throws {
        let (directoryURL, storeURL) = makeStoreURLs()
        defer { try? FileManager.default.removeItem(at: directoryURL) }

        do {
            let oldSchema = makeLegacySchema()
            let oldConfiguration = ModelConfiguration("MigrationEntityTest", schema: oldSchema, url: storeURL)
            _ = try ModelContainer(for: oldSchema, configurations: [oldConfiguration])
        }

        let newSchema = makeCurrentSchema()
        let newConfiguration = ModelConfiguration("MigrationEntityTest", schema: newSchema, url: storeURL)
        let migratedContainer = try ModelContainer(for: newSchema, configurations: [newConfiguration])
        let context = migratedContainer.mainContext

        let user = User(id: 777, userName: "post-migration-user")
        context.insert(user)

        let record = CalendarExtensionRecord(
            date: Date(timeIntervalSince1970: 1_700_000_000),
            shouldDelete: false,
            user: user
        )
        context.insert(record)
        try context.save()

        let stored = try context.fetch(FetchDescriptor<CalendarExtensionRecord>())
        let firstStoredRecord = try #require(stored.first)
        #expect(stored.count == 1)
        let storedUser = try #require(firstStoredRecord.user)
        #expect(storedUser.id == 777)
    }

    @Test("Повторное открытие контейнера после legacy upgrade идемпотентно")
    func legacyUpgradeIsIdempotentOnReopen() throws {
        let (directoryURL, storeURL) = makeStoreURLs()
        defer { try? FileManager.default.removeItem(at: directoryURL) }

        do {
            let oldSchema = makeLegacySchema()
            let oldConfiguration = ModelConfiguration("MigrationIdempotentTest", schema: oldSchema, url: storeURL)
            let oldContainer = try ModelContainer(for: oldSchema, configurations: [oldConfiguration])
            let oldContext = oldContainer.mainContext
            oldContext.insert(User(id: 99, userName: "legacy"))
            try oldContext.save()
        }

        let newSchema = makeCurrentSchema()
        let newConfiguration = ModelConfiguration("MigrationIdempotentTest", schema: newSchema, url: storeURL)

        let firstOpenContainer = try ModelContainer(for: newSchema, configurations: [newConfiguration])
        var users = try firstOpenContainer.mainContext.fetch(FetchDescriptor<User>())
        #expect(users.count == 1)

        let secondOpenContainer = try ModelContainer(for: newSchema, configurations: [newConfiguration])
        users = try secondOpenContainer.mainContext.fetch(FetchDescriptor<User>())
        #expect(users.count == 1)
    }

    @Test("Миграция со старой схемой (с SyncJournalEntry) сохраняет User, Progress, DayActivity, CustomExercise, CalendarExtensionRecord")
    func opensStoreAfterRemovingSyncJournalEntryAndPreservesData() throws {
        let (directoryURL, storeURL) = makeStoreURLs()
        defer { try? FileManager.default.removeItem(at: directoryURL) }

        do {
            let oldSchema = makeLegacySchema()
            let oldConfiguration = ModelConfiguration("SyncJournalMigrationTest", schema: oldSchema, url: storeURL)
            let oldContainer = try ModelContainer(for: oldSchema, configurations: [oldConfiguration])
            let oldContext = oldContainer.mainContext

            let user = User(id: 1, userName: "migration-user")
            let progress = UserProgress(id: 1, pullUps: 10, pushUps: 20, squats: 30, weight: 75)
            progress.user = user

            let exercise = CustomExercise(
                id: "demo-exercise-1",
                name: "Тестовое упражнение",
                imageId: 0,
                createDate: .now,
                modifyDate: .now,
                user: user
            )

            let activity = DayActivity(
                day: 1,
                activityTypeRaw: DayActivityType.workout.rawValue,
                count: 4,
                executeTypeRaw: ExerciseExecutionType.cycles.rawValue,
                createDate: .now,
                modifyDate: .now,
                user: user
            )
            activity.trainings = [
                DayActivityTraining(count: 5, typeId: ExerciseType.pullups.rawValue, sortOrder: 0),
                DayActivityTraining(count: 10, typeId: ExerciseType.pushups.rawValue, sortOrder: 1),
                DayActivityTraining(count: 15, typeId: ExerciseType.squats.rawValue, sortOrder: 2)
            ]

            oldContext.insert(user)
            oldContext.insert(progress)
            oldContext.insert(exercise)
            oldContext.insert(activity)
            try oldContext.save()
        }

        let newSchema = makeCurrentSchema()
        let newConfiguration = ModelConfiguration("SyncJournalMigrationTest", schema: newSchema, url: storeURL)
        let migratedContainer = try ModelContainer(for: newSchema, configurations: [newConfiguration])
        let context = migratedContainer.mainContext

        let users = try context.fetch(FetchDescriptor<User>())
        let firstUser = try #require(users.first)
        #expect(users.count == 1)
        #expect(firstUser.id == 1)

        let progressList = try context.fetch(FetchDescriptor<UserProgress>())
        #expect(progressList.count == 1)
        let firstProgress = try #require(progressList.first)
        #expect(firstProgress.id == 1)
        #expect(firstProgress.pullUps == 10)

        let exercises = try context.fetch(FetchDescriptor<CustomExercise>())
        #expect(exercises.count == 1)

        let activities = try context.fetch(FetchDescriptor<DayActivity>())
        #expect(activities.count == 1)
        let firstActivity = try #require(activities.first)
        #expect(firstActivity.day == 1)

        let extensions = try context.fetch(FetchDescriptor<CalendarExtensionRecord>())
        #expect(extensions.isEmpty)
    }

    /// Legacy-копии моделей со старыми полями (deprecated sync/profile-поля ещё присутствуют).
    /// Используются для проверки lightweight-миграции: SwiftData сопоставляет сущности по имени класса,
    /// поэтому имена типов внутри enum должны совпадать с текущими моделями.
    /// NOTE: enum не `private` — раскрытие макроса `@Model` не имеет доступа к приватным типам файла.
    enum LegacyModels {
        @Model
        final class User {
            @Attribute(.unique) var id: Int
            var userName: String?
            var fullName: String?
            var email: String?
            var imageStringURL: String?
            var cityId: Int?
            var countryId: Int?
            var genderCode: Int?
            var birthDateIsoString: String?
            @Relationship(deleteRule: .cascade) var customExercises: [CustomExercise] = []
            @Relationship(deleteRule: .cascade) var progressResults: [UserProgress] = []
            @Relationship(deleteRule: .cascade) var dayActivities: [DayActivity] = []
            private var favoriteInfopostIdsString = ""
            private var readInfopostDaysString = ""
            private var unsyncedReadInfopostDaysString = ""

            init(
                id: Int,
                userName: String? = nil,
                fullName: String? = nil,
                email: String? = nil,
                imageStringURL: String? = nil,
                cityId: Int? = nil,
                countryId: Int? = nil,
                genderCode: Int? = nil,
                birthDateIsoString: String? = nil
            ) {
                self.id = id
                self.userName = userName
                self.fullName = fullName
                self.email = email
                self.imageStringURL = imageStringURL
                self.cityId = cityId
                self.countryId = countryId
                self.genderCode = genderCode
                self.birthDateIsoString = birthDateIsoString
            }
        }

        @Model
        final class UserProgress {
            var id: Int
            var pullUps: Int?
            var pushUps: Int?
            var squats: Int?
            var weight: Float?
            var isSynced: Bool
            var shouldDelete: Bool
            var lastModified: Date
            var urlPhotoFront: String?
            var urlPhotoBack: String?
            var urlPhotoSide: String?
            var dataPhotoFront: Data?
            var dataPhotoBack: Data?
            var dataPhotoSide: Data?
            @Relationship(inverse: \User.progressResults) var user: User?

            init(
                id: Int,
                pullUps: Int? = nil,
                pushUps: Int? = nil,
                squats: Int? = nil,
                weight: Float? = nil,
                isSynced: Bool = false,
                shouldDelete: Bool = false,
                lastModified: Date = .now
            ) {
                self.id = id
                self.pullUps = pullUps
                self.pushUps = pushUps
                self.squats = squats
                self.weight = weight
                self.isSynced = isSynced
                self.shouldDelete = shouldDelete
                self.lastModified = lastModified
            }
        }

        @Model
        final class DayActivity {
            var day: Int
            var activityTypeRaw: Int?
            var count: Int?
            var plannedCount: Int?
            var executeTypeRaw: Int?
            var trainingTypeRaw: Int?
            var duration: Int?
            var comment: String?
            var createDate: Date
            var modifyDate: Date
            var isSynced: Bool
            var shouldDelete: Bool
            @Relationship(inverse: \User.dayActivities) var user: User?
            @Relationship(deleteRule: .cascade) var trainings: [DayActivityTraining] = []

            init(
                day: Int,
                activityTypeRaw: Int? = nil,
                count: Int? = nil,
                plannedCount: Int? = nil,
                executeTypeRaw: Int? = nil,
                trainingTypeRaw: Int? = nil,
                duration: Int? = nil,
                comment: String? = nil,
                createDate: Date,
                modifyDate: Date,
                isSynced: Bool = false,
                shouldDelete: Bool = false
            ) {
                self.day = day
                self.activityTypeRaw = activityTypeRaw
                self.count = count
                self.plannedCount = plannedCount
                self.executeTypeRaw = executeTypeRaw
                self.trainingTypeRaw = trainingTypeRaw
                self.duration = duration
                self.comment = comment
                self.createDate = createDate
                self.modifyDate = modifyDate
                self.isSynced = isSynced
                self.shouldDelete = shouldDelete
            }
        }

        @Model
        final class CustomExercise {
            @Attribute(.unique) var id: String
            var name: String
            var imageId: Int
            var createDate: Date
            var modifyDate: Date
            var isSynced: Bool
            var shouldDelete: Bool
            @Relationship(inverse: \User.customExercises) var user: User?

            init(
                id: String,
                name: String,
                imageId: Int,
                createDate: Date,
                modifyDate: Date,
                isSynced: Bool = false,
                shouldDelete: Bool = false
            ) {
                self.id = id
                self.name = name
                self.imageId = imageId
                self.createDate = createDate
                self.modifyDate = modifyDate
                self.isSynced = isSynced
                self.shouldDelete = shouldDelete
            }
        }

        @Model
        final class DayActivityTraining {
            var count: Int?
            var typeId: Int?
            var customTypeId: String?
            var sortOrder: Int?
            @Relationship(inverse: \DayActivity.trainings) var dayActivity: DayActivity?

            init(
                count: Int? = nil,
                typeId: Int? = nil,
                customTypeId: String? = nil,
                sortOrder: Int? = nil,
                dayActivity: DayActivity? = nil
            ) {
                self.count = count
                self.typeId = typeId
                self.customTypeId = customTypeId
                self.sortOrder = sortOrder
                self.dayActivity = dayActivity
            }
        }

        @Model
        final class CalendarExtensionRecord {
            var date: Date
            var isSynced: Bool
            var shouldDelete: Bool
            var lastModified: Date
            var user: User?

            init(
                date: Date,
                isSynced: Bool = false,
                shouldDelete: Bool = false,
                lastModified: Date = .now,
                user: User? = nil
            ) {
                self.date = date
                self.isSynced = isSynced
                self.shouldDelete = shouldDelete
                self.lastModified = lastModified
                self.user = user
            }
        }
    }

    @Test("Миграция с deprecated sync/profile-полями на текущую схему сохраняет данные")
    func opensStoreWithDeprecatedFieldsAndPreservesData() throws {
        let (directoryURL, storeURL) = makeStoreURLs()
        defer { try? FileManager.default.removeItem(at: directoryURL) }

        do {
            let oldSchema = Schema(
                [
                    LegacyModels.User.self,
                    LegacyModels.UserProgress.self,
                    LegacyModels.DayActivity.self,
                    LegacyModels.DayActivityTraining.self,
                    LegacyModels.CustomExercise.self,
                    LegacyModels.CalendarExtensionRecord.self
                ]
            )
            let oldConfiguration = ModelConfiguration("DeprecatedFieldsMigrationTest", schema: oldSchema, url: storeURL)
            let oldContainer = try ModelContainer(for: oldSchema, configurations: [oldConfiguration])
            let oldContext = oldContainer.mainContext

            let legacyUser = LegacyModels.User(
                id: 301,
                userName: "legacy-fields-user",
                fullName: "Старое Имя",
                email: "old@example.com",
                cityId: 3,
                countryId: 8,
                genderCode: 0,
                birthDateIsoString: "1985-05-15"
            )
            let legacyProgress = LegacyModels.UserProgress(
                id: 49,
                pullUps: 12,
                pushUps: 24,
                squats: 36,
                weight: 72.5,
                isSynced: true,
                shouldDelete: false,
                lastModified: Date(timeIntervalSince1970: 1_700_000_100)
            )
            let legacyActivity = LegacyModels.DayActivity(
                day: 7,
                activityTypeRaw: DayActivityType.workout.rawValue,
                count: 4,
                duration: 300,
                comment: "legacy comment",
                createDate: Date(timeIntervalSince1970: 1_700_000_200),
                modifyDate: Date(timeIntervalSince1970: 1_700_000_300),
                isSynced: true,
                shouldDelete: false
            )
            let legacyExercise = LegacyModels.CustomExercise(
                id: "legacy-exercise",
                name: "Старое упражнение",
                imageId: 2,
                createDate: Date(timeIntervalSince1970: 1_700_000_400),
                modifyDate: Date(timeIntervalSince1970: 1_700_000_500),
                isSynced: true,
                shouldDelete: false
            )
            let legacyExtension = LegacyModels.CalendarExtensionRecord(
                date: Date(timeIntervalSince1970: 1_700_000_600),
                isSynced: true,
                shouldDelete: false,
                lastModified: Date(timeIntervalSince1970: 1_700_000_700),
                user: legacyUser
            )
            let legacyTraining = LegacyModels.DayActivityTraining(count: 4, sortOrder: 0)

            oldContext.insert(legacyUser)
            oldContext.insert(legacyProgress)
            oldContext.insert(legacyActivity)
            oldContext.insert(legacyExercise)
            oldContext.insert(legacyExtension)
            oldContext.insert(legacyTraining)
            legacyProgress.user = legacyUser
            legacyActivity.user = legacyUser
            legacyExercise.user = legacyUser
            legacyTraining.dayActivity = legacyActivity
            try oldContext.save()
        }

        let newSchema = makeCurrentSchema()
        let newConfiguration = ModelConfiguration("DeprecatedFieldsMigrationTest", schema: newSchema, url: storeURL)
        let migratedContainer = try ModelContainer(for: newSchema, configurations: [newConfiguration])
        let context = migratedContainer.mainContext

        let users = try context.fetch(FetchDescriptor<User>())
        #expect(users.count == 1)
        let firstUser = try #require(users.first)
        #expect(firstUser.id == 301)
        #expect(firstUser.userName == "legacy-fields-user")
        #expect(firstUser.genderCode == 0)

        let progressList = try context.fetch(FetchDescriptor<UserProgress>())
        #expect(progressList.count == 1)
        let firstProgress = try #require(progressList.first)
        #expect(firstProgress.id == 49)
        #expect(firstProgress.pullUps == 12)
        #expect(firstProgress.pushUps == 24)
        #expect(firstProgress.squats == 36)
        #expect(firstProgress.weight == 72.5)
        #expect(!firstProgress.shouldDelete)

        let activities = try context.fetch(FetchDescriptor<DayActivity>())
        #expect(activities.count == 1)
        let firstActivity = try #require(activities.first)
        #expect(firstActivity.day == 7)
        #expect(firstActivity.activityType == .workout)
        #expect(firstActivity.count == 4)
        #expect(firstActivity.duration == 300)
        #expect(firstActivity.comment == "legacy comment")
        #expect(!firstActivity.shouldDelete)

        let exercises = try context.fetch(FetchDescriptor<CustomExercise>())
        #expect(exercises.count == 1)
        let firstExercise = try #require(exercises.first)
        #expect(firstExercise.id == "legacy-exercise")
        #expect(firstExercise.name == "Старое упражнение")
        #expect(firstExercise.imageId == 2)
        #expect(!firstExercise.shouldDelete)

        let extensions = try context.fetch(FetchDescriptor<CalendarExtensionRecord>())
        #expect(extensions.count == 1)
        let firstExtension = try #require(extensions.first)
        #expect(firstExtension.date == Date(timeIntervalSince1970: 1_700_000_600))
        #expect(!firstExtension.shouldDelete)
        #expect(firstExtension.user?.id == 301)

        #expect(firstUser.dayActivities.count == 1)
        #expect(firstActivity.user?.id == 301)
        #expect(firstActivity.trainings.count == 1)
        #expect(firstActivity.trainings.first?.count == 4)
    }

    private func makeLegacySchema() -> Schema {
        Schema(
            [
                User.self,
                Country.self,
                CustomExercise.self,
                UserProgress.self,
                DayActivity.self,
                DayActivityTraining.self
            ]
        )
    }

    private func makeRelease40Schema() -> Schema {
        Schema(
            [
                User.self,
                Country.self,
                CustomExercise.self,
                UserProgress.self,
                DayActivity.self,
                DayActivityTraining.self
            ]
        )
    }

    private func makeCurrentSchema() -> Schema {
        Schema(
            [
                User.self,
                Country.self,
                CustomExercise.self,
                UserProgress.self,
                DayActivity.self,
                DayActivityTraining.self,
                CalendarExtensionRecord.self
            ]
        )
    }

    private func makeStoreURLs() -> (directory: URL, store: URL) {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("SwiftDataMigrationTests", isDirectory: true)
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return (directory, directory.appendingPathComponent("store.sqlite"))
    }
}
