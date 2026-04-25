import Foundation

enum JournalPagePersistence {
    static let storageKey = "Journal.SelectedPage"

    static func restoreSelectedPage(
        defaults: UserDefaults = .standard,
        totalDays: Int
    ) -> Int {
        let storedPage = defaults.integer(forKey: storageKey)
        return clamp(page: storedPage, totalDays: totalDays)
    }

    static func saveSelectedPage(
        _ page: Int,
        defaults: UserDefaults = .standard,
        totalDays: Int
    ) {
        let clampedPage = clamp(page: page, totalDays: totalDays)
        defaults.set(clampedPage, forKey: storageKey)
    }

    static func clear(defaults: UserDefaults = .standard) {
        defaults.removeObject(forKey: storageKey)
    }

    static func clamp(page: Int, totalDays: Int) -> Int {
        JournalGridPagination.clampPage(page, totalDays: totalDays)
    }
}
