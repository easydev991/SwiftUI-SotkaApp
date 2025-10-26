import SwiftUI

/// Горизонтальный прогресс-бар с сегментами для каждого дня
struct ProgressBarView: View {
    let days: [DayProgressStatus]

    var body: some View {
        HStack(spacing: 0) {
            ForEach(days) { day in
                day.color
            }
        }
        .frame(height: 25)
    }
}

#if DEBUG
#Preview(traits: .sizeThatFitsLayout) {
    VStack(spacing: 20) {
        ProgressBarView(days: .emptyProgress)
        ProgressBarView(days: .currentDay25)
        ProgressBarView(days: .currentDay50)
        ProgressBarView(days: .currentDay100)
        ProgressBarView(days: .currentDay100Completed)
    }
    .padding()
}
#endif
