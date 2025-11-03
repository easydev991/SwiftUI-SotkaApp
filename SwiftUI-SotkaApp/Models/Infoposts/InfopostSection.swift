import Foundation
import SwiftUI

/// Секции инфопостов для группировки по блокам программы
enum InfopostSection: String, Codable, CaseIterable, Identifiable {
    var id: Self { self }
    case preparation
    case base
    case advanced
    case turbo
    case conclusion

    /// Локализованные заголовки секций
    var localizedTitle: String {
        switch self {
        case .preparation:
            String(localized: .sectionPreparation)
        case .base:
            String(localized: .sectionBasicBlock)
        case .advanced:
            String(localized: .sectionAdvancedBlock)
        case .turbo:
            String(localized: .sectionTurboBlock)
        case .conclusion:
            String(localized: .sectionConclusion)
        }
    }

    /// Определяет секцию по номеру дня
    static func section(for dayNumber: Int) -> InfopostSection {
        switch dayNumber {
        case 1 ... 49:
            .base
        case 50 ... 91:
            .advanced
        case 92 ... 98:
            .turbo
        case 99 ... 100:
            .conclusion
        default:
            .preparation
        }
    }

    /// Определяет секцию по имени файла
    static func section(for filename: String) -> InfopostSection {
        if filename.hasPrefix("d") {
            let dayString = String(filename.dropFirst())
            if let dayNumber = Int(dayString) {
                return section(for: dayNumber)
            }
        }
        return .preparation
    }

    /// Массив дней для секции дневника тренировок
    var days: [Int] {
        switch self {
        case .base:
            Array(1 ... 49)
        case .advanced:
            Array(50 ... 91)
        case .turbo:
            Array(92 ... 98)
        case .conclusion:
            Array(99 ... 100)
        case .preparation:
            []
        }
    }

    /// Секции, используемые в дневнике тренировок
    ///
    /// Все кроме подготовительного блока
    static var journalSections: [InfopostSection] {
        [.base, .advanced, .turbo, .conclusion]
    }

    /// Отсортированные секции дневника в соответствии с порядком сортировки
    ///
    /// - Parameter sortOrder: Порядок сортировки
    /// - Returns: Массив секций в соответствующем порядке
    static func sectionsSortedBy(_ sortOrder: SortOrder) -> [InfopostSection] {
        let sections = journalSections
        return sortOrder == .forward ? sections : sections.reversed()
    }

    /// Отсортированные дни секции в соответствии с порядком сортировки
    ///
    /// - Parameter sortOrder: Порядок сортировки
    /// - Returns: Массив дней в соответствующем порядке
    func daysSortedBy(_ sortOrder: SortOrder) -> [Int] {
        let days = days
        return sortOrder == .forward ? days : days.reversed()
    }
}
