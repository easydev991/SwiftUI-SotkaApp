import SWDesignSystem
import SwiftData
import SwiftUI
import SWUtils

@main
struct SwiftUI_SotkaAppApp: App {
    @Environment(\.scenePhase) private var scenePhase
    @State private var countriesService = CountriesUpdateService()
    @State private var statusManager = StatusManager()
    @State private var customExercisesService: CustomExercisesService
    @State private var appSettings = AppSettings()
    @State private var authHelper: AuthHelperImp
    @State private var networkStatus = NetworkStatus()
    private let client: SWClient

    init() {
        let authHelper = AuthHelperImp()
        let client = SWClient(with: authHelper)
        self.authHelper = authHelper
        self.client = client
        self.customExercisesService = CustomExercisesService(client: client)
    }

    private var modelContainer: ModelContainer = {
        let schema = Schema([User.self, Country.self, CustomExercise.self])
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
                } else {
                    LoginScreen(client: client)
                }
            }
            .loadingOverlay(if: countriesService.isLoading || statusManager.isLoading)
            .animation(.default, value: authHelper.isAuthorized)
            .dynamicTypeSize(...DynamicTypeSize.accessibility2)
            .environment(appSettings)
            .environment(authHelper)
            .environment(statusManager)
            .environment(customExercisesService)
            .environment(\.isNetworkConnected, networkStatus.isConnected)
            .preferredColorScheme(appSettings.appTheme.colorScheme)
            .task(id: scenePhase) {
                guard scenePhase == .active else { return }
                await countriesService.update(modelContainer.mainContext, client: client)
                guard authHelper.isAuthorized else { return }
                await statusManager.getStatus(client: client)
                await customExercisesService.syncCustomExercises(
                    context: modelContainer.mainContext
                )
            }
        }
        .modelContainer(modelContainer)
        .onChange(of: authHelper.isAuthorized) { _, isAuthorized in
            appSettings.setWorkoutNotificationsEnabled(isAuthorized)
            if !isAuthorized {
                appSettings.didLogout()
                statusManager.didLogout()
                do {
                    try modelContainer.mainContext.delete(model: User.self)
                    try modelContainer.mainContext.delete(model: CustomExercise.self)
                } catch {
                    fatalError("Не удалось удалить данные пользователя: \(error.localizedDescription)")
                }
            }
        }
    }
}
