import Foundation
import Observation
import OSLog
import SwiftData

@Observable
final class ProgressStatsViewModel {
    @ObservationIgnored private let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier!,
        category: String(describing: ProgressStatsViewModel.self)
    )

    var fullProgressPercent = 0
    var infoPostsPercent = 0
    var activityPercent = 0
    var dayStatuses: [DayProgressStatus] = []

    func updateStats(
        modelContext: ModelContext,
        activities: [DayActivityType],
        currentDay: Int
    ) {
        do {
            guard let user = try modelContext.fetch(FetchDescriptor<User>()).first else {
                logger.error("Пользователь не найден в базе данных")
                return
            }

            let calculator = ProgressCalculator(user: user, activities: activities, currentDay: currentDay)

            fullProgressPercent = calculator.fullProgressPercent
            infoPostsPercent = calculator.infoPostsPercent
            activityPercent = calculator.activityPercent
            dayStatuses = calculator.dayStatuses

            logger
                .info(
                    "Статистика обновлена: полный=\(calculator.fullProgressPercent)%, инфопосты=\(calculator.infoPostsPercent)%, активности=\(calculator.activityPercent)%"
                )
        } catch {
            logger.error("Не удалось загрузить пользователя: \(error.localizedDescription)")
        }
    }
}
