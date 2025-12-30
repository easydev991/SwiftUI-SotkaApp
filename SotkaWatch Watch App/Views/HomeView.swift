import SWDesignSystem
import SwiftUI

struct HomeView: View {
    @Environment(HomeViewModel.self) private var viewModel
    @State private var showEditWorkout = false

    var body: some View {
        ZStack {
            if viewModel.isAuthorized {
                DayActivityView(
                    onSelect: { activity in
                        if activity == .workout {
                            showEditWorkout = true
                        } else {
                            Task {
                                await viewModel.selectActivity(activity)
                            }
                        }
                    },
                    onDelete: { day in
                        Task {
                            await viewModel.deleteActivity(day: day)
                        }
                    },
                    selectedActivity: viewModel.currentActivity,
                    workoutData: viewModel.workoutData,
                    workoutExecutionCount: viewModel.workoutExecutionCount,
                    comment: viewModel.workoutComment
                )
            } else {
                AuthRequiredView(
                    checkAuthAction: {
                        Task { await viewModel.loadData() }
                    },
                    state: authState
                )
            }
        }
        .loadingOverlay(if: viewModel.isLoading)
        .animation(.default, value: viewModel.isAuthorized)
        .fullScreenCover(isPresented: $showEditWorkout) {
            WorkoutPreviewView(
                connectivityService: viewModel.connectivityService
            )
        }
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
    HomeView()
        .environment(viewModel)
}

#Preview("Авторизован") {
    let authService = PreviewWatchAuthService(isAuthorized: true)
    let connectivityService = PreviewWatchConnectivityService()
    let viewModel = HomeViewModel(
        authService: authService,
        connectivityService: connectivityService
    )
    HomeView()
        .environment(viewModel)
        .task {
            await viewModel.loadData()
        }
}
#endif
