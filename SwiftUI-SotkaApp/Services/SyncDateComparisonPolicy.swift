import Foundation

enum SyncDateComparisonResult {
    case localNewer
    case serverNewer
    case equal
}

enum SyncDateComparisonPolicy {
    static func compare(local: Date, server: Date) -> SyncDateComparisonResult {
        if local > server {
            return .localNewer
        }

        if server > local {
            return .serverNewer
        }

        return .equal
    }
}
