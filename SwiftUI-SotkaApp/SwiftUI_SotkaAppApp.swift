import SWDesignSystem
import SwiftData
import SwiftUI
import SWUtils

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
    private var showLoadingOverlay: Bool {
        let isLoadingInitialData = statusManager.state.isLoadingInitialData
        let isAuthorized = authHelper.isAuthorized
        let isDayCalculatorAvailable = statusManager.currentDayCalculator != nil
        return isAuthorized
            ? isLoadingInitialData || !isDayCalculatorAvailable
            : false
    }

    init() {
        let authHelper = AuthHelperImp()
        let client = SWClient(with: authHelper)
        self.statusManager = StatusManager(
            customExercisesService: .init(client: client),
            infopostsService: .init(
                language: Locale.current.language.languageCode?.identifier ?? "ru",
                infopostsClient: client
            ),
            progressSyncService: .init(client: client),
            dailyActivitiesService: .init(client: client),
            statusClient: client
        )
        self.countriesService = .init(client: client)
        self.authHelper = authHelper
        self.client = client
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
                            appSettings.setWorkoutNotificationsEnabled(true)
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
            .onChange(of: statusManager.currentDayCalculator) { _, _ in
                guard authHelper.isAuthorized else { return }
                statusManager.loadInfopostsWithUserGender(context: modelContainer.mainContext)
            }
            .onChange(of: scenePhase) { _, newPhase in
                guard newPhase == .active else { return }
                countriesService.update(modelContainer.mainContext)
            }
        }
        .modelContainer(modelContainer)
        .onChange(of: authHelper.isAuthorized) { _, isAuthorized in
            if !isAuthorized {
                appSettings.didLogout()
                statusManager.didLogout()
                do {
                    try modelContainer.mainContext.delete(model: User.self)
                } catch {
                    fatalError("Не удалось удалить данные пользователя: \(error.localizedDescription)")
                }
            }
        }
    }
}
