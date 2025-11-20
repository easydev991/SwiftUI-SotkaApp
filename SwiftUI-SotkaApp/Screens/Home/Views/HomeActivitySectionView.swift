import SWDesignSystem
import SwiftData
import SwiftUI
import SWUtils

struct HomeActivitySectionView: View {
    @Environment(DailyActivitiesService.self) private var activitiesService
    @Environment(\.currentDay) private var currentDay
    @Environment(\.modelContext) private var modelContext
    @Query private var activities: [DayActivity]
    @State private var shouldShowDeleteConfirmation = false
    @State private var sheetItem: DayActivitySheetItem?

    private var currentActivity: DayActivity? {
        activities.first { $0.day == currentDay && !$0.shouldDelete }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            headerView
            contentView
        }
        .insideCardBackground(padding: 0)
        .confirmationDialog(
            .journalDeleteEntry,
            isPresented: $shouldShowDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button(.journalDelete, role: .destructive) {
                if let currentActivity {
                    activitiesService.deleteDailyActivity(currentActivity, context: modelContext)
                }
            }
        } message: {
            Text(.journalDeleteEntryMessage(currentDay))
        }
        .animation(.default, value: currentActivity)
        .sheet(item: $sheetItem) { item in
            switch item {
            case let .comment(activity):
                EditCommentSheet(activity: activity)
            case let .workoutPreview(day):
                WorkoutPreviewScreen(activitiesService: activitiesService, day: day)
            }
        }
    }
}

private extension HomeActivitySectionView {
    var headerView: some View {
        HomeSectionTitleView(
            title: String(localized: .homeActivity),
            showMenu: currentActivity != nil
        ) {
            if let currentActivity {
                DayActivityMenuView(
                    day: currentDay,
                    activity: currentActivity,
                    onComment: { _ in
                        sheetItem = .comment(currentActivity)
                    },
                    onDelete: { _ in
                        shouldShowDeleteConfirmation = true
                    },
                    onSelectType: { day, type in
                        actionFor(type, day: day)
                    }
                )
            }
        }
    }

    var contentView: some View {
        ZStack {
            if let currentActivity {
                VStack(spacing: 8) {
                    DayActivityContentView(activity: currentActivity)
                        .transition(.scale.combined(with: .opacity))
                    DayActivityCommentView(comment: currentActivity.comment)
                }
            } else {
                HStack(spacing: 12) {
                    ForEach(DayActivityType.allCases, id: \.self) {
                        makeButton(for: $0)
                            .buttonStyle(.plain)
                    }
                }
                .transition(.scale.combined(with: .opacity))
            }
        }
        .animation(.default, value: currentActivity)
        .padding([.horizontal, .bottom], 12)
    }

    func makeButton(for activityType: DayActivityType) -> some View {
        Button {
            actionFor(activityType, day: currentDay)
        } label: {
            VStack(spacing: 8) {
                Circle()
                    .fill(activityType.color)
                    .frame(maxHeight: 80)
                    .overlay {
                        activityType.image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 40, height: 40)
                            .foregroundStyle(.white)
                    }
                Text(activityType.localizedTitle)
                    .fixedSize()
                    .font(.footnote)
                    .minimumScaleFactor(0.5)
            }
            .frame(maxWidth: .infinity)
        }
        .accessibilityIdentifier("TodayActivityButton.\(activityType.rawValue)")
    }

    func actionFor(_ activityType: DayActivityType, day: Int) {
        if activityType == .workout {
            sheetItem = .workoutPreview(day)
        }
        activitiesService.set(activityType, for: day, context: modelContext)
    }
}

#if DEBUG
#Preview {
    HomeActivitySectionView()
        .environment(DailyActivitiesService(client: MockDaysClient(result: .success)))
        .modelContainer(PreviewModelContainer.make(with: .preview))
}
#endif
