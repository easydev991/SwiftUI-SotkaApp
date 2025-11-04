import SWDesignSystem
import SwiftData
import SwiftUI
import SWUtils

struct HomeActivitySectionView: View {
    @Environment(DailyActivitiesService.self) private var activitiesService
    @Environment(\.currentDay) private var currentDay
    @Environment(\.modelContext) private var modelContext
    @Query private var activities: [DayActivity]
    @State private var activityForCommentSheet: DayActivity?
    @State private var shouldShowDeleteConfirmation = false

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
        .sheet(item: $activityForCommentSheet) { activity in
            EditCommentSheet(activity: activity)
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
                        activityForCommentSheet = currentActivity
                    },
                    onDelete: { _ in
                        shouldShowDeleteConfirmation = true
                    },
                    onSelectType: { day, type in
                        if type == .workout {
                            print("TODO: настроить тренировку, день \(day)")
                        }
                        activitiesService.set(type, for: day, context: modelContext)
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
            if activityType == .workout {
                print("TODO: настроить тренировку")
            }
            activitiesService.set(activityType, for: currentDay, context: modelContext)
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
    }
}

#if DEBUG
#Preview {
    HomeActivitySectionView()
        .environment(DailyActivitiesService(client: MockDaysClient(result: .success)))
        .modelContainer(PreviewModelContainer.make(with: .previewWithActivities))
}
#endif
