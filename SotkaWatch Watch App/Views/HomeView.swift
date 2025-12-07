import SwiftUI

struct HomeView: View {
    @Environment(HomeViewModel.self) private var viewModel
    @State private var showEditWorkout = false
    private var dayNumber: Int? { viewModel.currentDay }

    var body: some View {
        ZStack {
            if viewModel.isAuthorized, let dayNumber {
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
                    dayNumber: dayNumber,
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
        .opacity(viewModel.isLoading ? 0.5 : 1)
        .disabled(viewModel.isLoading)
        .overlay {
            if viewModel.isLoading {
                ProgressView()
            }
        }
        .animation(.default, value: viewModel.isAuthorized)
        .fullScreenCover(isPresented: $showEditWorkout) {
            if let dayNumber {
                EmptyView() // TODO: экран WorkoutPreviewView
            }
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
    HomeView()
        .environment(viewModel)
        .task {
            await viewModel.loadData()
        }
}
#endif
