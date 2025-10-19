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

        // Специальные файлы относятся к подготовке
        switch filename {
        case "aims", "organiz", "d0-women":
            return .preparation
        default:
            return .preparation
        }
    }
}
