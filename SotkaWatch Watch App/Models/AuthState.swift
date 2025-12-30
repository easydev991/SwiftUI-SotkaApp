import Foundation

enum AuthState: Equatable {
    case idle
    case loading
    case error

    var localizedTitle: String {
        switch self {
        case .idle, .loading: String(localized: .watchAuthRequiredMessage)
        case .error: String(localized: .watchAuthRequiredError)
        }
    }

    var isLoading: Bool {
        self == .loading
    }
}
