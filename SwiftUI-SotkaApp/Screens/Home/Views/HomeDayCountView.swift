import SWDesignSystem
import SwiftUI

/// Вьюха с днями сотки (текущий день и оставшиеся дни)
///
/// В старом приложении это `HomeCountCell`
struct HomeDayCountView: View {
    @Environment(\.isIPad) private var isIpad
    let calculator: DayCalculator

    var body: some View {
        ZStack {
            if calculator.isOver {
                finishedView
            } else {
                notFinishedView
                    .frame(height: isIpad ? 120 : 90)
            }
        }
        .foregroundStyle(Color.swMainText)
    }
}

private extension HomeDayCountView {
    var finishedView: some View {
        VStack(spacing: isIpad ? 8 : 4) {
            VStack(spacing: isIpad ? 20 : 12) {
                Text(.congratulationsTitle)
                    .font(.title2)
                makeNumberView(for: 100)
                    .frame(height: isIpad ? 110 : 80)
            }
            Text(.congratulationsSubtitle)
                .padding(.bottom, isIpad ? 12 : 8)
            Text(.congratulationsBody)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal)
        .bold()
        .frame(maxWidth: .infinity)
    }

    var notFinishedView: some View {
        HStack(spacing: 0) {
            let currentDayTitle = String(localized: .currentDay)
            let daysLeftTitle = String(localized: .daysLeft)
            makeDayStack(title: currentDayTitle, day: calculator.currentDay)
            Rectangle()
                .fill(Color.swSeparators)
                .frame(width: 1, height: isIpad ? 110 : 80)
            makeDayStack(title: daysLeftTitle, day: calculator.daysLeft)
        }
    }

    func makeDayStack(title: String, day: Int) -> some View {
        VStack(spacing: isIpad ? 8 : 4) {
            Text(title)
                .font(isIpad ? .body : .footnote)
                .bold()
            makeNumberView(for: day)
        }
        .frame(maxWidth: .infinity)
    }

    func makeNumberView(for day: Int) -> some View {
        HStack(spacing: isIpad ? 4 : 2) {
            // Форматируем число как строку с ведущим нулём (например, "07")
            let formattedDay = String(format: "%02d", day)
            let digits = Array(formattedDay)

            ForEach(digits.indices, id: \.self) { index in
                Image("n\(digits[index])")
                    .resizable()
                    .scaledToFit()
            }
        }
    }
}

#if DEBUG
#Preview("День 1") {
    HomeDayCountView(calculator: .init(previewDay: 1))
        .padding()
}

#Preview("День 49") {
    HomeDayCountView(calculator: .init(previewDay: 49))
        .padding()
}

#Preview("День 100") {
    HomeDayCountView(calculator: .init(previewDay: 100))
        .padding()
}
#endif
