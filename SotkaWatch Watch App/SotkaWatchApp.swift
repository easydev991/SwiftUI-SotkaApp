import SwiftUI

@main
struct SotkaWatchApp: App {
    @State private var viewModel: HomeViewModel = {
        let authService = WatchAuthService()

        #if DEBUG
        // При аргументе UITest используем мок-сессию вместо реальной
        let connectivityService: WatchConnectivityService
        if ProcessInfo.processInfo.arguments.contains("UITest") {
            let mockSession = MockWatchSession()
            connectivityService = WatchConnectivityService(
                authService: authService,
                sessionProtocol: mockSession
            )
        } else {
            connectivityService = WatchConnectivityService(authService: authService)
        }
        #else
        let connectivityService = WatchConnectivityService(authService: authService)
        #endif

        return HomeViewModel(
            authService: authService,
            connectivityService: connectivityService
        )
    }()

    var body: some Scene {
        WindowGroup {
            HomeView()
                .environment(viewModel)
                .currentDay(viewModel.currentDay)
                .task {
                    await viewModel.checkAuthStatusOnActivation()
                    await viewModel.loadData()
                }
        }
    }
}
