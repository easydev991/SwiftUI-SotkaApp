import SWDesignSystem
import SwiftData
import SwiftUI
import SWUtils
import TipKit

@main
struct SwiftUI_SotkaAppApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @Environment(\.scenePhase) private var scenePhase
    private let youtubeVideoService: YouTubeVideoService
    private let statusManager: StatusManager
    private let countriesService: CountriesUpdateService
    @State private var appSettings = AppSettings()
    @State private var authHelper: AuthHelperImp
    @State private var networkStatus = NetworkStatus()
    @State private var reviewManager: ReviewManager
    private let client: SWClient
    private let analyticsService: AnalyticsService

    init() {
        let schema = Schema(
            [
                User.self,
                Country.self,
                CustomExercise.self,
                UserProgress.self,
                DayActivity.self,
                DayActivityTraining.self,
                SyncJournalEntry.self
            ]
        )
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        let modelContainer: ModelContainer
        do {
            modelContainer = try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Не смогли создать ModelContainer: \(error)")
        }
        let reviewStorage = ReviewStorage()
        let completionsCounter = WorkoutCompletionsCounter(modelContainer: modelContainer)
        let container = modelContainer
        let reviewManager = ReviewManager(
            attemptStore: reviewStorage,
            completionsCounter: completionsCounter,
            currentUserIdProvider: {
                let context = container.mainContext
                let descriptor = FetchDescriptor<User>(predicate: #Predicate { _ in true })
                return (try? context.fetch(descriptor)).flatMap(\.first)?.id
            }
        )
        self.reviewManager = reviewManager

        let analytics: AnalyticsService
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("UITest") {
            UserDefaults.standard.removePersistentDomain(forName: Bundle.main.bundleIdentifier!)
            ScreenshotDemoData.setup(context: modelContainer.mainContext)
            analytics = AnalyticsService(providers: [NoopAnalyticsProvider()])
            let mockServices = Self.createMockServices(modelContainer: modelContainer)
            self.statusManager = mockServices.statusManager
            self.countriesService = mockServices.countriesService
            self.authHelper = mockServices.authHelper
            self.client = mockServices.client
            UIView.setAnimationsEnabled(false)
        } else {
            analytics = AnalyticsService(providers: [FirebaseAnalyticsProvider()])
            let authHelper = AuthHelperImp()
            let client = SWClient(with: authHelper)
            self.statusManager = StatusManager(
                customExercisesService: .init(client: client),
                infopostsService: .init(
                    language: Self.localeIdentifier,
                    infopostsClient: client,
                    analytics: analytics
                ),
                progressSyncService: .init(client: client),
                dailyActivitiesService: .init(client: client),
                statusClient: client,
                modelContainer: modelContainer,
                reviewEventReporter: reviewManager
            )
            self.countriesService = .init(client: client)
            self.authHelper = authHelper
            self.client = client
            do {
                try Tips.resetDatastore()
                try Tips.configure()
            } catch {
                assertionFailure(error.localizedDescription)
            }
        }
        #else
        analytics = AnalyticsService(providers: [FirebaseAnalyticsProvider()])
        let authHelper = AuthHelperImp()
        let client = SWClient(with: authHelper)
        self.statusManager = StatusManager(
            customExercisesService: .init(client: client),
            infopostsService: .init(
                language: Self.localeIdentifier,
                infopostsClient: client,
                analytics: analytics
            ),
            progressSyncService: .init(client: client),
            dailyActivitiesService: .init(client: client),
            statusClient: client,
            modelContainer: modelContainer,
            reviewEventReporter: reviewManager
        )
        self.countriesService = .init(client: client)
        self.authHelper = authHelper
        self.client = client
        do {
            try Tips.configure()
        } catch {
            print("Ошибка TipKit: \(error.localizedDescription)")
        }
        #endif
        self.analyticsService = analytics
        self.youtubeVideoService = .init(analytics: analytics)
    }

    var body: some Scene {
        WindowGroup {
            ZStack {
                if authHelper.isAuthorized {
                    RootScreen()
                        .task(id: scenePhase) {
                            guard scenePhase == .active else { return }
                            guard authHelper.isAuthorized else { return }
                            await statusManager.getStatus()
                            await appSettings.syncNotificationSettings()
                        }
                } else {
                    WelcomeScreen(client: client)
                }
            }
            .loadingOverlay(if: showLoadingOverlay)
            .animation(.default, value: authHelper.isAuthorized)
            .dynamicTypeSize(...DynamicTypeSize.accessibility2)
            .environment(appSettings)
            .environment(authHelper)
            .environment(reviewManager)
            .environment(statusManager)
            .environment(statusManager.customExercisesService)
            .environment(statusManager.dailyActivitiesService)
            .environment(statusManager.infopostsService)
            .currentDay(statusManager.currentDayCalculator?.currentDay)
            .restTimeBetweenSets(appSettings.restTime)
            .networkStatus(networkStatus.isOnline)
            .environment(youtubeVideoService)
            .environment(\.analyticsService, analyticsService)
            .preferredColorScheme(appSettings.appTheme.colorScheme)
            .onChange(of: statusManager.currentDayCalculator) { _, newCalculator in
                guard authHelper.isAuthorized else { return }
                statusManager.loadInfopostsWithUserGender()
                statusManager.sendDayDataToWatch(currentDay: newCalculator?.currentDay)
            }
            .onChange(of: scenePhase) { _, newPhase in
                guard newPhase == .active else { return }
                countriesService.update(statusManager.modelContainer.mainContext)
            }
            .task {
                #if DEBUG
                if ProcessInfo.processInfo.arguments.contains("UITest") {
                    statusManager.loadInfopostsWithUserGender()
                }
                #endif
            }
        }
        .modelContainer(statusManager.modelContainer)
        .onChange(of: authHelper.isAuthorized) { _, isAuthorized in
            statusManager.processAuthStatus(isAuthorized: isAuthorized)
            if !isAuthorized {
                appSettings.didLogout()
                reviewManager.reset()
            }
        }
    }
}

private extension SwiftUI_SotkaAppApp {
    var showLoadingOverlay: Bool {
        guard authHelper.isAuthorized, !authHelper.isOfflineOnly else { return false }
        return statusManager.state.isLoadingInitialData
            || statusManager.currentDayCalculator == nil
    }

    static var localeIdentifier: String {
        Locale.current.language.languageCode?.identifier ?? "ru"
    }
}

#if DEBUG
private extension SwiftUI_SotkaAppApp {
    static func createMockServices(modelContainer: ModelContainer) -> (
        statusManager: StatusManager,
        countriesService: CountriesUpdateService,
        authHelper: AuthHelperImp,
        client: SWClient
    ) {
        let authHelper = AuthHelperImp()
        let mockClient = MockSWClient(instantResponse: true)
        // Настоящий клиент только для для WelcomeScreen, хотя он не показывается
        let clientForProperty = SWClient(with: authHelper)
        let statusManager = StatusManager(
            customExercisesService: .init(client: mockClient),
            infopostsService: .init(
                language: Self.localeIdentifier,
                infopostsClient: mockClient,
                analytics: AnalyticsService(providers: [NoopAnalyticsProvider()])
            ),
            progressSyncService: .init(client: mockClient),
            dailyActivitiesService: .init(client: mockClient),
            statusClient: mockClient,
            modelContainer: modelContainer
        )

        let countriesService = CountriesUpdateService(client: mockClient)
        authHelper.didAuthorize()
        statusManager.setCurrentDayForDebug(12)
        // Возвращаем настоящий клиент для WelcomeScreen (хотя он не показывается, так как авторизация пропущена)
        return (statusManager, countriesService, authHelper, clientForProperty)
    }
}
#endif
