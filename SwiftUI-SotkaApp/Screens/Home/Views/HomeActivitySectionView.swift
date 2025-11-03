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

    private var currentActivity: DayActivity? {
        activities.first { $0.day == currentDay && !$0.shouldDelete }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HomeSectionTitleView(
                title: String(localized: .homeActivity),
                showMenu: currentActivity != nil
            ) {
                if let currentActivity {
                    DayActivityMenuView(
                        day: currentDay,
                        activity: currentActivity,
                        onComment: { day in
                            print("TODO: добавить комментарий, день \(day)")
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

            ZStack {
                if let currentActivity {
                    DayActivityContentView(activity: currentActivity)
                        .transition(.scale.combined(with: .opacity))
                } else {
                    HStack(spacing: 12) {
                        ForEach(DayActivityType.allCases, id: \.self) {
                            makeView(for: $0)
                                .buttonStyle(.plain)
                        }
                    }
                    .transition(.scale.combined(with: .opacity))
                }
            }
            .animation(.default, value: currentActivity)
            .padding([.horizontal, .bottom], 12)
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
    }
}

private extension HomeActivitySectionView {
    func makeView(
        for activityType: DayActivityType
    ) -> some View {
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
