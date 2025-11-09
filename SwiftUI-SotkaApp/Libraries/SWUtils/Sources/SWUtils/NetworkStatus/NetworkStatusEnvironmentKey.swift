import SwiftUI

/// Ключ для получения состояния подключения к интернету
struct NetworkStatusEnvironmentKey: EnvironmentKey {
    static let defaultValue = false
}

public extension EnvironmentValues {
    /// `true` - есть подключение, `false` - нет подключения
    var isNetworkConnected: Bool {
        get { self[NetworkStatusEnvironmentKey.self] }
        set { self[NetworkStatusEnvironmentKey.self] = newValue }
    }
}

public extension View {
    func networkStatus(_ isOnline: Bool) -> some View {
        environment(\.isNetworkConnected, isOnline)
    }
}
