import SwiftUI
import UIKit

extension ThemeIconScreen {
    enum IconVariant: String, CaseIterable, Equatable {
        case primary = "AppIcon1"
        case one = "AppIcon2"
        case two = "AppIcon3"

        var alternateName: String? {
            switch self {
            case .primary:
                nil
            default:
                rawValue
            }
        }

        var listImage: Image {
            Image("\(rawValue)Small")
        }

        @MainActor
        var isSelected: Bool {
            UIApplication.shared.alternateIconName == alternateName
        }

        @MainActor
        var accessibilityLabel: String {
            let baseLabel = switch self {
            case .primary:
                String(localized: .iconVariantPrimary)
            default:
                String(localized: .iconVariant(variantNumber))
            }
            let status = isSelected
                ? String(localized: .iconVariantSelected)
                : String(localized: .iconVariantNotSelected)
            return "\(baseLabel), \(status)"
        }

        init(name: String?) {
            self = IconVariant(rawValue: name ?? "") ?? .primary
        }

        private var variantNumber: Int {
            switch self {
            case .primary: 1
            case .one: 2
            case .two: 3
            }
        }
    }
}
