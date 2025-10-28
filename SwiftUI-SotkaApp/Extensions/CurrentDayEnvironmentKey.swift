import SwiftUI

private struct CurrentDayEnvironmentKey: EnvironmentKey {
    static let defaultValue = 1
}

extension EnvironmentValues {
    var currentDay: Int {
        get { self[CurrentDayEnvironmentKey.self] }
        set { self[CurrentDayEnvironmentKey.self] = newValue }
    }
}

extension View {
    func currentDay(_ day: Int?) -> some View {
        environment(\.currentDay, day ?? 1)
    }
}
