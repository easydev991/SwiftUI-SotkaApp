import SwiftUI

extension SortOrder {
    var localizedTitle: String {
        switch self {
        case .forward:
            String(localized: .journalSortAscending)
        case .reverse:
            String(localized: .journalSortDescending)
        }
    }
}

/// Для использования с `@AppStorage`
extension SortOrder: @retroactive RawRepresentable {
    public init?(rawValue: Int) {
        switch rawValue {
        case 0:
            self = .forward
        case 1:
            self = .reverse
        default:
            return nil
        }
    }

    public var rawValue: Int {
        switch self {
        case .forward:
            0
        case .reverse:
            1
        }
    }
}

extension SortOrder: @retroactive CaseIterable {
    public static var allCases: [SortOrder] {
        [.forward, .reverse]
    }
}

extension SortOrder {
    static let appStorageKey = "JournalListView.SortOrder"
}
