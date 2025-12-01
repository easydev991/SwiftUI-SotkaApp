import Foundation

enum AuthState: Equatable {
    case idle
    case loading
    case error

    var localizedTitle: String {
        switch self {
        case .idle, .loading: String(localized: "Watch.AuthRequired.Message")
        case .error: String(localized: "Watch.AuthRequired.Error")
        }
    }

    var isLoading: Bool {
        self == .loading
    }
}
