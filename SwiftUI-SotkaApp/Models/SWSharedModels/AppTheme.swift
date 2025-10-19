import SwiftUI

enum AppTheme: Int, CaseIterable, Identifiable {
    var id: Int { rawValue }
    case system = 0
    case light = 1
    case dark = 2

    var title: String {
        switch self {
        case .system: String(localized: .system)
        case .light: String(localized: .light)
        case .dark: String(localized: .dark)
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .light: .light
        case .dark: .dark
        case .system: nil
        }
    }
}
