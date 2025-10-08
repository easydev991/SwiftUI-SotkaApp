import Foundation
import SwiftUI

/// Модель для отображения секции с инфопостами
struct InfopostSectionDisplay: Identifiable, Equatable {
    let id: InfopostSection
    let section: InfopostSection
    let infoposts: [Infopost]
    let isCollapsed: Bool

    var hasContent: Bool {
        !infoposts.isEmpty
    }

    var title: LocalizedStringKey {
        section.localizedTitle
    }
}
