import SwiftUI

private struct RestTimeEnvironmentKey: EnvironmentKey {
    static let defaultValue = Constants.defaultRestTime
}

extension EnvironmentValues {
    var restTime: Int {
        get { self[RestTimeEnvironmentKey.self] }
        set { self[RestTimeEnvironmentKey.self] = newValue }
    }
}

extension View {
    func restTimeBetweenSets(_ time: Int) -> some View {
        environment(\.restTime, time)
    }
}
