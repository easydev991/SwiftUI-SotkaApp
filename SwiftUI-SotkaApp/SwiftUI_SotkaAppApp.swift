import SWDesignSystem
import SwiftData
import SwiftUI
import SWUtils
import TipKit

@main
struct SwiftUI_SotkaAppApp: App {
    @Environment(\.scenePhase) private var scenePhase
    private let youtubeVideoService = YouTubeVideoService()
    private let statusManager: StatusManager
    private let countriesService: CountriesUpdateService
    @State private var appSettings = AppSettings()
    @State private var authHelper: AuthHelperImp
    @State private var networkStatus = NetworkStatus()
    private let client: SWClient

    init() {
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("UITest") {
            UserDefaults.standard.removePersistentDomain(forName: Bundle.main.bundleIdentifier!)
            let mockServices = Self.createMockServices()
            self.statusManager = mockServices.statusManager
            self.countriesService = mockServices.countriesService
            self.authHelper = mockServices.authHelper
            self.client = mockServices.client
            UIView.setAnimationsEnabled(false)
        } else {
            let authHelper = AuthHelperImp()
            let client = SWClient(with: authHelper)
            self.statusManager = StatusManager(
                customExercisesService: .init(client: client),
                infopostsService: .init(
                    language: Self.localeIdentifier,
                    infopostsClient: client
                ),
                progressSyncService: .init(client: client),
                dailyActivitiesService: .init(client: client),
                statusClient: client
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
        let authHelper = AuthHelperImp()
        let client = SWClient(with: authHelper)
        self.statusManager = StatusManager(
            customExercisesService: .init(client: client),
            infopostsService: .init(
                language: Self.localeIdentifier,
                infopostsClient: client
            ),
            progressSyncService: .init(client: client),
            dailyActivitiesService: .init(client: client),
            statusClient: client
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
    }

    private var modelContainer: ModelContainer = {
        let schema = Schema(
            [
                User.self,
                Country.self,
                CustomExercise.self,
                UserProgress.self,
                DayActivity.self,
                DayActivityTraining.self
            ]
        )
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Не смогли создать ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ZStack {
                if authHelper.isAuthorized {
                    RootScreen()
                        .task(id: scenePhase) {
                            guard scenePhase == .active else { return }
                            guard authHelper.isAuthorized else { return }
                            await statusManager.getStatus(context: modelContainer.mainContext)
                            await appSettings.syncNotificationSettings()
                        }
                } else {
                    LoginScreen(client: client)
                }
            }
            .loadingOverlay(if: showLoadingOverlay)
            .animation(.default, value: authHelper.isAuthorized)
            .dynamicTypeSize(...DynamicTypeSize.accessibility2)
            .environment(appSettings)
            .environment(authHelper)
            .environment(statusManager)
            .environment(statusManager.customExercisesService)
            .environment(statusManager.dailyActivitiesService)
            .environment(statusManager.infopostsService)
            .currentDay(statusManager.currentDayCalculator?.currentDay)
            .restTimeBetweenSets(appSettings.restTime)
            .networkStatus(networkStatus.isOnline)
            .environment(youtubeVideoService)
            .preferredColorScheme(appSettings.appTheme.colorScheme)
            .onChange(of: statusManager.currentDayCalculator) { _, newCalculator in
                guard authHelper.isAuthorized else { return }
                statusManager.loadInfopostsWithUserGender(context: modelContainer.mainContext)
                statusManager.sendDayDataToWatch(
                    currentDay: newCalculator?.currentDay,
                    context: modelContainer.mainContext
                )
            }
            .onChange(of: scenePhase) { _, newPhase in
                guard newPhase == .active else { return }
                countriesService.update(modelContainer.mainContext)
            }
            .task {
                #if DEBUG
                if ProcessInfo.processInfo.arguments.contains("UITest") {
                    ScreenshotDemoData.setup(context: modelContainer.mainContext)
                    statusManager.loadInfopostsWithUserGender(context: modelContainer.mainContext)
                }
                #endif
            }
        }
        .modelContainer(modelContainer)
        .onChange(of: authHelper.isAuthorized) { _, isAuthorized in
            statusManager.processAuthStatus(isAuthorized: isAuthorized, context: modelContainer.mainContext)
            if !isAuthorized {
                appSettings.didLogout()
            }
        }
    }
}

private extension SwiftUI_SotkaAppApp {
    var showLoadingOverlay: Bool {
        let isLoadingInitialData = statusManager.state.isLoadingInitialData
        let isAuthorized = authHelper.isAuthorized
        let isDayCalculatorAvailable = statusManager.currentDayCalculator != nil
        return isAuthorized
            ? isLoadingInitialData || !isDayCalculatorAvailable
            : false
    }

    static var localeIdentifier: String {
        Locale.current.language.languageCode?.identifier ?? "ru"
    }
}

#if DEBUG
private extension SwiftUI_SotkaAppApp {
    static func createMockServices() -> (
        statusManager: StatusManager,
        countriesService: CountriesUpdateService,
        authHelper: AuthHelperImp,
        client: SWClient
    ) {
        let authHelper = AuthHelperImp()
        let mockClient = MockSWClient(instantResponse: true)
        // Настоящий клиент только для для LoginScreen, хотя он не показывается
        let clientForProperty = SWClient(with: authHelper)
        let statusManager = StatusManager(
            customExercisesService: .init(client: mockClient),
            infopostsService: .init(
                language: Self.localeIdentifier,
                infopostsClient: mockClient
            ),
            progressSyncService: .init(client: mockClient),
            dailyActivitiesService: .init(client: mockClient),
            statusClient: mockClient
        )

        let countriesService = CountriesUpdateService(client: mockClient)
        authHelper.didAuthorize()
        statusManager.setCurrentDayForDebug(12)
        // Возвращаем настоящий клиент для LoginScreen (хотя он не показывается, так как авторизация пропущена)
        return (statusManager, countriesService, authHelper, clientForProperty)
    }
}
#endif
