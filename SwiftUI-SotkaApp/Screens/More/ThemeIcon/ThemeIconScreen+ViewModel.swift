import Observation
import OSLog
import SwiftUI
import UIKit

extension ThemeIconScreen {
    @Observable
    @MainActor
    final class ViewModel {
        private let logger = Logger(
            subsystem: Bundle.main.bundleIdentifier ?? "SotkaApp",
            category: String(describing: ViewModel.self)
        )
        private let analytics: AnalyticsService
        private(set) var currentAppIcon: IconVariant

        init(analytics: AnalyticsService) {
            self.analytics = analytics
            let alternateIconName = UIApplication.shared.alternateIconName
            self.currentAppIcon = IconVariant(name: alternateIconName)
        }

        func setIcon(_ icon: IconVariant) async {
            analytics.log(.userAction(action: .selectAppIcon(iconName: icon.rawValue)))
            do {
                guard UIApplication.shared.supportsAlternateIcons else {
                    throw IconError.alternateIconsNotSupported
                }
                guard icon.alternateName != UIApplication.shared.alternateIconName else { return }
                try await UIApplication.shared.setAlternateIconName(icon.alternateName)
                currentAppIcon = icon
                logger.info("Установили иконку: \(icon.rawValue)")
            } catch {
                analytics.log(.appError(kind: .setIconFailed, error: error))
                logger.error("\(error.localizedDescription)")
            }
        }
    }
}

extension ThemeIconScreen.ViewModel {
    enum IconError: Error, LocalizedError {
        case alternateIconsNotSupported

        var errorDescription: String? {
            switch self {
            case .alternateIconsNotSupported:
                String(localized: .errorAlternateIconsNotSupported)
            }
        }
    }
}
