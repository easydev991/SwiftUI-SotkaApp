import SwiftUI

struct HomeView: View {
    let viewModel: HomeViewModel

    var body: some View {
        ZStack {
            if viewModel.isAuthorized, let dayNumber = viewModel.currentDay {
                DayActivityView(
                    onSelect: { activity in
                        Task {
                            await viewModel.selectActivity(activity)
                        }
                    },
                    onDelete: { day in
                        Task {
                            await viewModel.deleteActivity(day: day)
                        }
                    },
                    dayNumber: dayNumber,
                    selectedActivity: viewModel.currentActivity
                )
            } else {
                AuthRequiredView(
                    checkAuthAction: {
                        Task {
                            await viewModel.loadData()
                        }
                    },
                    state: authState
                )
            }
        }
        .opacity(viewModel.isLoading ? 0.5 : 1)
        .disabled(viewModel.isLoading)
        .overlay {
            if viewModel.isLoading {
                ProgressView()
            }
        }
        .animation(.default, value: viewModel.isAuthorized)
    }
}

private extension HomeView {
    var authState: AuthState {
        if viewModel.isAuthorized {
            .idle
        } else if viewModel.isLoading {
            .loading
        } else if viewModel.error != nil {
            .error
        } else {
            .idle
        }
    }
}

#if DEBUG
#Preview("Неавторизован") {
    let authService = PreviewWatchAuthService(isAuthorized: false)
    let connectivityService = PreviewWatchConnectivityService()
    let viewModel = HomeViewModel(
        authService: authService,
        connectivityService: connectivityService
    )
    HomeView(viewModel: viewModel)
}

#Preview("Авторизован") {
    let startDate = Calendar.current.date(byAdding: .day, value: -5, to: Date.now) ?? Date.now
    let authService = PreviewWatchAuthService(isAuthorized: true)
    let connectivityService = PreviewWatchConnectivityService()
    let appGroupHelper = PreviewWatchAppGroupHelper(
        isAuthorized: true,
        startDate: startDate
    )
    let viewModel = HomeViewModel(
        authService: authService,
        connectivityService: connectivityService,
        appGroupHelper: appGroupHelper
    )
    HomeView(viewModel: viewModel)
        .task {
            await viewModel.loadData()
        }
}
#endif
