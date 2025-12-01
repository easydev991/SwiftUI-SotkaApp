import SwiftUI

// TODO: доработать для кейса .workout отображение данных тренировки аналогично DayActivityContentView + DayActivityCommentView (как в основном приложении)
struct SelectedActivityView: View {
    let activity: DayActivityType
    let onSelect: (DayActivityType) -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                HStack(spacing: 12) {
                    activity.image
                        .padding()
                        .background {
                            Circle().fill(activity.color)
                        }
                    Text(activity.localizedTitle)
                        .bold()
                }
                NavigationLink {
                    DayActivitySelectionView(
                        onSelect: onSelect,
                        selectedActivity: activity
                    )
                } label: {
                    Text(.edit)
                }
            }
            .padding()
        }
    }
}

#Preview {
    NavigationStack {
        SelectedActivityView(activity: .workout) {
            print("Выбрали активность \($0)")
        }
    }
}
