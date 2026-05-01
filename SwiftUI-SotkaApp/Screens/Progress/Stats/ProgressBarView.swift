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
