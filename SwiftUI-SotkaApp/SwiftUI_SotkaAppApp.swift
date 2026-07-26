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
    @State private var appSettings = AppSettings()
    @State private var authHelper: AuthHelperImp
    @State private var networkStatus = NetworkStatus()
    @State private var reviewManager: ReviewManager
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
                CalendarExtensionRecord.self
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
            self.authHelper = mockServices.authHelper
            UIView.setAnimationsEnabled(false)
        } else {
            analytics = AnalyticsService(providers: [FirebaseAnalyticsProvider()])
            let authHelper = AuthHelperImp()
            self.statusManager = StatusManager(
                customExercisesService: .init(),
                infopostsService: .init(
                    language: Self.localeIdentifier,
                    analytics: analytics
                ),
                dailyActivitiesService: .init(),
                modelContainer: modelContainer,
                reviewEventReporter: reviewManager
            )
            self.authHelper = authHelper
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
        self.statusManager = StatusManager(
            customExercisesService: .init(modelContext: modelContainer.mainContext),
            infopostsService: .init(
                language: Self.localeIdentifier,
                analytics: analytics
            ),
            dailyActivitiesService: .init(modelContext: modelContainer.mainContext),
            modelContainer: modelContainer,
            reviewEventReporter: reviewManager
        )
        self.authHelper = authHelper
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
                    WelcomeScreen()
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
            .environment(\.isReadOnlyMode, isReadOnlyMode)
            .preferredColorScheme(appSettings.appTheme.colorScheme)
            .onChange(of: statusManager.currentDayCalculator) { _, newCalculator in
                guard authHelper.isAuthorized else { return }
                statusManager.loadInfopostsWithUserGender()
                statusManager.sendDayDataToWatch(currentDay: newCalculator?.currentDay)
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
            if !isAuthorized {
                appSettings.didLogout()
                reviewManager.reset()
            }
        }
    }
}

private extension SwiftUI_SotkaAppApp {
    var isReadOnlyMode: Bool {
        ProcessInfo.processInfo.arguments.contains("UITest")
            ? false
            : AppConfiguration.isReadOnlyMode
    }

    var showLoadingOverlay: Bool {
        guard authHelper.isAuthorized,
              !authHelper.isOfflineOnly,
              !AppConfiguration.isReadOnlyMode
        else { return false }
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
        authHelper: AuthHelperImp
    ) {
        let authHelper = AuthHelperImp()
        let statusManager = StatusManager(
            customExercisesService: .init(isReadOnlyMode: false),
            infopostsService: .init(
                language: Self.localeIdentifier,
                analytics: AnalyticsService(providers: [NoopAnalyticsProvider()]),
                isReadOnlyMode: false
            ),
            dailyActivitiesService: .init(isReadOnlyMode: false),
            modelContainer: modelContainer,
            isReadOnlyMode: false
        )

        statusManager.setCurrentDayForDebug(12)
        return (statusManager, authHelper)
    }
}
#endif
