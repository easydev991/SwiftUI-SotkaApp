import SwiftUI

@main
struct SotkaWatchApp: App {
    @State private var viewModel: HomeViewModel = {
        let authService = WatchAuthService()
        let connectivityService = WatchConnectivityService(authService: authService)
        return HomeViewModel(
            authService: authService,
            connectivityService: connectivityService
        )
    }()

    var body: some Scene {
        WindowGroup {
            HomeView(viewModel: viewModel)
                .task {
                    await viewModel.loadData()
                }
        }
    }
}
