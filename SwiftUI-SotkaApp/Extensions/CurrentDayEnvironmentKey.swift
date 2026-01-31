import SwiftUI

extension EnvironmentValues {
    @Entry var currentDay = 1
}

extension View {
    func currentDay(_ day: Int?) -> some View {
        environment(\.currentDay, day ?? 1)
    }
}
