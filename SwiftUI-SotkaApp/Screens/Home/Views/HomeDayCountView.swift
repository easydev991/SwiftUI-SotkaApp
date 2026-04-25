import SWDesignSystem
import SwiftUI

/// Вьюха с днями сотки (текущий день и оставшиеся дни)
struct HomeDayCountView: View {
    @Environment(\.isIPad) private var isIpad
    private let calculator: DayCalculator
    private let isSolvingConflict: Bool

    /// Инициализатор
    /// - Parameters:
    ///   - calculator: Калькулятор текущего дня
    ///   - isSolvingConflict: `true` - вьюха отображается на экране решения конфликта дат
    ///   при синхронизации, `false` - обычное отображение
    init(calculator: DayCalculator, isSolvingConflict: Bool = false) {
        self.calculator = calculator
        self.isSolvingConflict = isSolvingConflict
    }

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
    var viewModel: HomeDayCountModel {
        HomeDayCountModel(currentDay: calculator.currentDay)
    }

    @ViewBuilder
    var finishedView: some View {
        if viewModel.isFirstProgramCompletionDay {
            firstFinishedView
        } else {
            extendedFinishedView
        }
    }

    var firstFinishedView: some View {
        VStack(spacing: isIpad ? 8 : 4) {
            VStack(spacing: isIpad ? 20 : 12) {
                Text(.congratulationsTitle)
                    .font(.title2)
                makeNumberView(for: calculator.currentDay)
                    .frame(height: isIpad ? 110 : 80)
            }
            Text(.congratulationsSubtitle)
                .padding(.bottom, isIpad ? 12 : 8)
            Text(.congratulationsBody)
                .multilineTextAlignment(.center)
            rateAppButton
        }
        .padding(.horizontal)
        .bold()
        .frame(maxWidth: .infinity)
    }

    var extendedFinishedView: some View {
        VStack(spacing: isIpad ? 20 : 12) {
            makeNumberView(for: calculator.currentDay)
                .frame(height: isIpad ? 110 : 80)
            rateAppButton
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
            let formattedDay = HomeDayCountModel.formattedDayString(for: day)
            let digits = Array(formattedDay)

            ForEach(digits.indices, id: \.self) { index in
                Image("n\(digits[index])")
                    .resizable()
                    .scaledToFit()
            }
        }
    }

    @ViewBuilder
    private var rateAppButton: some View {
        if let appReviewLink = Constants.appReviewURL, !isSolvingConflict {
            Link(.rateTheApp, destination: appReviewLink)
                .buttonStyle(SWButtonStyle(icon: .star, mode: .filled, size: .small))
                .padding(.top, 8)
                .accessibilityIdentifier("rateAppButton")
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

#Preview("День 101 (с продлением)") {
    HomeDayCountView(calculator: .init(previewDay: 101, extensionCount: 1))
        .padding()
}

#Preview("День 100, конфликт дат") {
    HomeDayCountView(
        calculator: .init(previewDay: 100),
        isSolvingConflict: true
    )
    .padding()
}
#endif
