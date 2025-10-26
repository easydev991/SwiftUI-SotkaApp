import SwiftData
import SwiftUI

/// Основная вьюха для отображения статистики прогресса
struct ProgressStatsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(StatusManager.self) private var statusManager
    @State private var viewModel = ProgressStatsViewModel()
    @State private var showInfoSheet = false

    var body: some View {
        Button {
            showInfoSheet.toggle()
        } label: {
            ProgressBarView(days: viewModel.dayStatuses)
        }
        .onAppear {
            // Загружаем данные при появлении вьюхи
            // В будущем здесь будет загрузка активностей из API
            let activities = createMockActivities()
            viewModel.updateStats(
                modelContext: modelContext,
                activities: activities,
                currentDay: statusManager.currentDayCalculator?.currentDay ?? 1
            )
        }
        .sheet(isPresented: $showInfoSheet) {
            ProgressStatsInfoView(
                fullProgressPercent: viewModel.fullProgressPercent,
                infoPostsPercent: viewModel.infoPostsPercent,
                activityPercent: viewModel.activityPercent
            )
            .presentationDetents([.medium, .large])
        }
    }

    /// Создает моковые активности для тестирования
    /// В будущем активности будут загружаться из API или другой модели
    private func createMockActivities() -> [DayActivityType] {
        var activities: [DayActivityType] = []

        for day in 1 ... 100 {
            if day <= (statusManager.currentDayCalculator?.currentDay ?? 1) {
                // Создаем разнообразные активности для дней до текущего
                if day % 7 == 0 {
                    activities.append(.rest) // Отдых каждую 7-ю день
                } else if day % 10 == 0 {
                    activities.append(.sick) // Болезнь каждую 10-ю день
                } else if day % 3 == 0 {
                    activities.append(.stretch) // Растяжка каждую 3-ю день
                } else {
                    activities.append(.workout) // Тренировка по умолчанию
                }
            } else {
                activities.append(.workout) // Заполняем до 100 элементов
            }
        }

        return activities
    }
}

#if DEBUG
#Preview {
    ProgressStatsView()
        .environment(StatusManager.preview)
        .modelContainer(for: User.self)
}
#endif
