import SWDesignSystem
import SwiftUI

struct HomeCalendarExtensionView: View {
    @Environment(StatusManager.self) private var statusManager
    @Environment(\.analyticsService) private var analytics

    let calculator: DayCalculator

    var body: some View {
        if calculator.shouldShowExtensionButton {
            VStack(spacing: 8) {
                Button(.homeCalendarExtensionButton, action: extendCalendarAction)
                    .buttonStyle(SWButtonStyle(mode: .filled, size: .large))
                    .accessibilityIdentifier("HomeExtendCalendarButton")

                Text(.homeCalendarExtensionHint)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
            }
            .insideCardBackground()
        }
    }
}

private extension HomeCalendarExtensionView {
    func extendCalendarAction() {
        analytics.log(
            .userAction(
                action: .extendCalendar(targetTotalDays: calculator.nextExtensionTotalDays)
            )
        )
        statusManager.extendCalendar()
    }
}

#if DEBUG
#Preview("Кнопка скрыта") {
    HomeCalendarExtensionView(calculator: .init(previewDay: 99))
        .environment(StatusManager.preview)
        .padding()
}

#Preview("Кнопка показана") {
    HomeCalendarExtensionView(calculator: .init(previewDay: 100))
        .environment(StatusManager.preview)
        .padding()
}

#Preview("После продления кнопка скрыта (день 101)") {
    HomeCalendarExtensionView(calculator: .init(previewDay: 101, extensionCount: 1))
        .environment(StatusManager.previewWithCalendarExtension)
        .padding()
}

#Preview("Следующая граница продления (день 200)") {
    HomeCalendarExtensionView(calculator: .init(previewDay: 200, extensionCount: 1))
        .environment(StatusManager.previewWithCalendarExtension)
        .padding()
}
#endif
