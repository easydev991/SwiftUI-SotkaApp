import SwiftUI

extension EnvironmentValues {
    @Entry var restTime: Int = Constants.defaultRestTime
}

extension View {
    func restTimeBetweenSets(_ time: Int) -> some View {
        environment(\.restTime, time)
    }
}
