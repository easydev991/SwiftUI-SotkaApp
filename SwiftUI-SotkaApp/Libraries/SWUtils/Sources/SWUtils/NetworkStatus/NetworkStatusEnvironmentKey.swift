import SwiftUI

public extension EnvironmentValues {
    // `true` - есть подключение, `false` - нет подключения
    @Entry var isNetworkConnected = false
}

public extension View {
    func networkStatus(_ isOnline: Bool) -> some View {
        environment(\.isNetworkConnected, isOnline)
    }
}
