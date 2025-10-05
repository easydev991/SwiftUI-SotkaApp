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
    var localizedTitle: LocalizedStringKey {
        switch self {
        case .preparation:
            "Section.Preparation"
        case .base:
            "Section.BasicBlock"
        case .advanced:
            "Section.AdvancedBlock"
        case .turbo:
            "Section.TurboBlock"
        case .conclusion:
            "Section.Conclusion"
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
        case "about", "aims", "organiz", "d0-women":
            return .preparation
        default:
            return .preparation
        }
    }
}
