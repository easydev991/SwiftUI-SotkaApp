import Foundation
import OSLog

/// Менеджер для управления доступностью инфопостов в зависимости от текущего дня программы
struct InfopostAvailabilityManager {
    private let logger = Logger(subsystem: "SotkaApp", category: "InfopostAvailabilityManager")

    private let currentDay: Int
    private let maxReadInfoPostDay: Int

    init(currentDay: Int, maxReadInfoPostDay: Int = 0) {
        self.currentDay = currentDay
        self.maxReadInfoPostDay = maxReadInfoPostDay
    }

    /// Максимальный доступный день для чтения инфопостов
    var maxAvailableDay: Int {
        max(currentDay, maxReadInfoPostDay)
    }

    /// Проверяет, доступен ли инфопост для чтения
    func isInfopostAvailable(_ infopost: Infopost) -> Bool {
        // Подготовительные посты всегда доступны
        if infopost.section == .preparation {
            return true
        }

        // Для постов с номерами дней проверяем доступность
        if let dayNumber = infopost.dayNumber {
            return dayNumber <= maxAvailableDay
        }

        return false
    }

    /// Возвращает только доступные инфопосты из переданного списка
    func filterAvailablePosts(_ posts: [Infopost]) -> [Infopost] {
        posts.filter { isInfopostAvailable($0) }
    }

    /// Возвращает доступные инфопосты, сгруппированные по секциям
    func getAvailablePostsBySection(_ posts: [Infopost]) -> [InfopostSection: [Infopost]] {
        let availablePosts = filterAvailablePosts(posts)
        return Dictionary(grouping: availablePosts) { $0.section }
    }
}
