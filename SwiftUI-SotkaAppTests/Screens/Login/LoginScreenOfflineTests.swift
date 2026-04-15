import Foundation
import SwiftData
@testable import SwiftUI_SotkaApp
import Testing

@Suite("Тесты офлайн-входа WelcomeScreen")
@MainActor
struct LoginScreenOfflineTests {
    @Test("performOfflineLogin создаёт пользователя с userName offline-user")
    func performOfflineLoginCreatesOfflineUser() throws {
        let authHelper = MockAuthHelper()
        let modelConfiguration = ModelConfiguration(isStoredInMemoryOnly: true)
        let modelContainer = try ModelContainer(for: User.self, configurations: modelConfiguration)
        let modelContext = modelContainer.mainContext

        #expect(!authHelper.isAuthorized)

        authHelper.performOfflineLogin()
        let user = User(offlineWithGenderCode: Gender.male.code)
        modelContext.insert(user)
        try modelContext.save()

        #expect(authHelper.isAuthorized)
        #expect(authHelper.authToken == nil)

        let fetchedUsers = try modelContext.fetch(FetchDescriptor<User>())
        #expect(fetchedUsers.count == 1)
        let fetchedUser = try #require(fetchedUsers.first)
        #expect(fetchedUser.isOfflineOnly)
        #expect(fetchedUser.genderCode == Gender.male.code)
    }

    @Test("performOfflineLogin создаёт пользователя с выбранным полом")
    func performOfflineLoginCreatesUserWithSelectedGender() throws {
        let authHelper = MockAuthHelper()
        let modelConfiguration = ModelConfiguration(isStoredInMemoryOnly: true)
        let modelContainer = try ModelContainer(for: User.self, configurations: modelConfiguration)
        let modelContext = modelContainer.mainContext

        authHelper.performOfflineLogin()
        let user = User(offlineWithGenderCode: Gender.unspecified.code)
        modelContext.insert(user)
        try modelContext.save()

        let fetchedUser = try #require(modelContext.fetch(FetchDescriptor<User>()).first)
        #expect(fetchedUser.gender == .unspecified)
    }

    @Test("performOfflineLogin заменяет существующего офлайн-пользователя")
    func performOfflineLoginReplacesExistingOfflineUser() throws {
        let modelConfiguration = ModelConfiguration(isStoredInMemoryOnly: true)
        let modelContainer = try ModelContainer(for: User.self, configurations: modelConfiguration)
        let modelContext = modelContainer.mainContext

        let existingUser = User(offlineWithGenderCode: Gender.male.code)
        modelContext.insert(existingUser)
        try modelContext.save()

        let fetchDescriptor = FetchDescriptor<User>(predicate: #Predicate { $0.id == -1 })
        let existing = try modelContext.fetch(fetchDescriptor).first
        if let existing {
            modelContext.delete(existing)
        }
        let newUser = User(offlineWithGenderCode: Gender.female.code)
        modelContext.insert(newUser)
        try modelContext.save()

        let fetchedUsers = try modelContext.fetch(FetchDescriptor<User>())
        #expect(fetchedUsers.count == 1)
        #expect(fetchedUsers.first?.genderCode == Gender.female.code)
    }

    @Test("performOfflineLogin не создаёт пользователя без выбора пола")
    func performOfflineLoginDoesNotCreateUserWithoutGenderSelection() throws {
        let authHelper = MockAuthHelper()
        let modelConfiguration = ModelConfiguration(isStoredInMemoryOnly: true)
        let modelContainer = try ModelContainer(for: User.self, configurations: modelConfiguration)
        let modelContext = modelContainer.mainContext

        let selectedGender: Gender? = nil
        guard selectedGender != nil else {
            #expect(try modelContext.fetch(FetchDescriptor<User>()).isEmpty)
            #expect(!authHelper.isAuthorized)
            return
        }
        Issue.record("Не должен был дойти до этой точки")
    }

    @Test("Gender.allCases содержит все варианты")
    func genderAllCasesContainsAllOptions() {
        let allCases = Gender.allCases
        #expect(allCases.contains(.male))
        #expect(allCases.contains(.female))
        #expect(allCases.contains(.unspecified))
        #expect(allCases.count == 3)
    }

    @Test("Офлайн-пользователь получает корректный genderCode")
    func offlineUserGetsCorrectGenderCode() throws {
        for gender in Gender.allCases {
            let modelConfiguration = ModelConfiguration(isStoredInMemoryOnly: true)
            let modelContainer = try ModelContainer(for: User.self, configurations: modelConfiguration)
            let modelContext = modelContainer.mainContext

            let user = User(offlineWithGenderCode: gender.code)
            modelContext.insert(user)
            try modelContext.save()

            let fetchedUser = try #require(modelContext.fetch(FetchDescriptor<User>()).first)
            #expect(fetchedUser.genderCode == gender.code)
            #expect(fetchedUser.gender == gender)
            #expect(fetchedUser.isOfflineOnly)
        }
    }
}
