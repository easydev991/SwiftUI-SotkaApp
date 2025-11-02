import SWDesignSystem
import SwiftUI
import SWUtils

struct DayActivityHeaderView: View {
    @Environment(\.currentDay) private var currentDay
    let dayNumber: Int
    let activityDate: Date?

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text(.day(number: dayNumber))
                .font(.headline)
            subtitleView
                .font(.subheadline)
        }
        .opacity(dayNumber > currentDay ? 0.6 : 1)
    }
}

private extension DayActivityHeaderView {
    @ViewBuilder
    var subtitleView: some View {
        if let activityDate {
            Text(DateFormatterService.dateWithWeekday(activityDate))
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .trailing)
        } else if dayNumber < currentDay {
            Text(.dayNotCompleted)
                .foregroundStyle(Color.swError)
                .frame(maxWidth: .infinity, alignment: .trailing)
        } else {
            Spacer()
        }
    }
}

#Preview(traits: .sizeThatFitsLayout) {
    VStack(spacing: 16) {
        DayActivityHeaderView(
            dayNumber: 1,
            activityDate: .now
        )
        DayActivityHeaderView(
            dayNumber: 5,
            activityDate: nil
        )
        .currentDay(10)
        DayActivityHeaderView(
            dayNumber: 6,
            activityDate: nil
        )
        .currentDay(6)
        DayActivityHeaderView(
            dayNumber: 10,
            activityDate: nil
        )
        .currentDay(5)
    }
    .padding()
}
