import SwiftUI
import SWUtils

struct DayActivityHeaderView: View {
    let dayNumber: Int
    let activityDate: Date?

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text(String(localized: .day(number: dayNumber)))
                .font(.headline)
            if let activityDate {
                Text(DateFormatterService.dateWithWeekday(activityDate))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
}

#Preview(traits: .sizeThatFitsLayout) {
    DayActivityHeaderView(
        dayNumber: 1,
        activityDate: .now
    )
}
