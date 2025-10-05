import SWDesignSystem
import SwiftUI

/// Вьюха с днями сотки (текущий день и оставшиеся дни)
///
/// В старом приложении это `HomeCountCell`
struct DayCountView: View {
    let calculator: DayCalculator

    var body: some View {
        ZStack {
            if calculator.isOver {
                finishedView
            } else {
                notFinishedView
                    .frame(height: 90)
            }
        }
        .foregroundStyle(Color.swMainText)
        .insideCardBackground()
    }
}

private extension DayCountView {
    var finishedView: some View {
        VStack(spacing: 4) {
            VStack(spacing: 12) {
                Text("Congratulations.Title")
                    .font(.title2)
                makeNumberView(for: 100)
                    .frame(height: 80)
            }
            Text("Congratulations.Subtitle")
                .padding(.bottom, 8)
            Text("Congratulations.Body")
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal)
        .bold()
        .frame(maxWidth: .infinity)
    }

    var notFinishedView: some View {
        HStack(spacing: 0) {
            let currentDayTitle = NSLocalizedString("Current day", comment: "")
            let daysLeftTitle = NSLocalizedString("Days left", comment: "")
            makeDayStack(title: currentDayTitle, day: calculator.currentDay)
            Rectangle()
                .fill(Color.swSeparators)
                .frame(width: 1, height: 80)
            makeDayStack(title: daysLeftTitle, day: calculator.daysLeft)
        }
    }

    func makeDayStack(title: String, day: Int) -> some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.footnote.bold())
            makeNumberView(for: day)
        }
        .frame(maxWidth: .infinity)
    }

    func makeNumberView(for day: Int) -> some View {
        HStack(spacing: 2) {
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

#Preview("День 1") {
    DayCountView(calculator: .init(previewDay: 1))
        .padding()
}

#Preview("День 49") {
    DayCountView(calculator: .init(previewDay: 49))
        .padding()
}

#Preview("День 100") {
    DayCountView(calculator: .init(previewDay: 100))
        .padding()
}
