import SWDesignSystem
import SwiftData
import SwiftUI

struct HomeScreen: View {
    @Environment(StatusManager.self) private var statusManager
    @Environment(DailyActivitiesService.self) private var activitiesService
    @Environment(\.currentDay) private var currentDay
    @Query private var users: [User]
    @State private var sheetItem: DayActivitySheetItem?
    private var user: User? {
        users.first
    }

    private var model: Model? {
        let calculator = statusManager.currentDayCalculator
        // Важно: во время логаута объекты SwiftData удаляются, поэтому нельзя обращаться к связям пользователя
        // если калькулятор отсутствует или пользователя нет.
        let isMaxFilled: Bool = {
            guard calculator != nil, let user else { return true }
            return user.isMaximumsFilled(for: currentDay)
        }()
        return .init(
            currentDay: currentDay,
            dayCalculator: calculator,
            isMaximumsFilled: isMaxFilled,
            todayInfopost: statusManager.infopostsService.todayInfopost
        )
    }

    var body: some View {
        NavigationStack {
            @Bindable var statusManager = statusManager
            ZStack {
                Color.swBackground.ignoresSafeArea()
                if let model {
                    ScrollView {
                        ViewThatFits {
                            makeHorizontalView(with: model)
                            makeVerticalView(with: model)
                        }
                        .padding()
                    }
                    .scrollBounceBehavior(.basedOnSize)
                    .sheet(item: $sheetItem, content: makeSheetContent)
                } else {
                    Text(.loading)
                }
            }
            .animation(.default, value: model)
            .frame(maxWidth: .infinity)
            .sheet(item: $statusManager.conflictingSyncModel) { model in
                SyncStartDateView(model: model)
            }
            .navigationTitle(.sotka)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink(destination: InfopostsListScreen()) {
                        Text(.infoposts)
                    }
                }
            }
            .navigationDestination(for: NavigationDestination.self, destination: makeView)
        }
    }
}

extension HomeScreen {
    enum NavigationDestination: Hashable {
        case userProgress
    }
}

extension HomeScreen {
    struct Model: Equatable {
        let calculator: DayCalculator
        let showActivitySection: Bool
        let showProgressSection: Bool
        let todayInfopost: Infopost?

        init?(
            currentDay: Int,
            dayCalculator: DayCalculator?,
            isMaximumsFilled: Bool,
            todayInfopost: Infopost?
        ) {
            guard let dayCalculator else { return nil }
            self.calculator = dayCalculator
            self.todayInfopost = todayInfopost
            self.showActivitySection = currentDay <= 100
            self.showProgressSection = !isMaximumsFilled
        }
    }
}

private extension HomeScreen {
    func makeHorizontalView(with model: Model) -> some View {
        VStack(spacing: 12) {
            HStack(spacing: 16) {
                HomeDayCountView(calculator: model.calculator)
                    .frame(maxHeight: .infinity)
                    .insideCardBackground()
                HomeInfopostSectionView(infopost: model.todayInfopost)
            }
            if model.showActivitySection {
                HomeActivitySectionView { sheetItem = $0 }
            }
            if model.showProgressSection {
                HomeFillProgressSectionView()
            }
        }
    }

    func makeVerticalView(with model: Model) -> some View {
        VStack(spacing: 12) {
            HomeDayCountView(calculator: model.calculator)
                .insideCardBackground()
            HomeInfopostSectionView(infopost: model.todayInfopost)
            if model.showActivitySection {
                HomeActivitySectionView { sheetItem = $0 }
            }
            if model.showProgressSection {
                HomeFillProgressSectionView()
            }
        }
    }

    @ViewBuilder
    func makeView(for destination: NavigationDestination) -> some View {
        switch destination {
        case .userProgress:
            if let user {
                ProgressScreen(user: user)
            }
        }
    }

    @ViewBuilder
    func makeSheetContent(for item: DayActivitySheetItem) -> some View {
        switch item {
        case let .comment(activity):
            EditCommentSheet(activity: activity)
        case let .workoutPreview(day):
            WorkoutPreviewScreen(activitiesService: activitiesService, day: day)
        }
    }
}

#if DEBUG
#Preview {
    HomeScreen()
        .environment(StatusManager.preview)
        .modelContainer(PreviewModelContainer.make(with: User(id: 1)))
}
#endif
