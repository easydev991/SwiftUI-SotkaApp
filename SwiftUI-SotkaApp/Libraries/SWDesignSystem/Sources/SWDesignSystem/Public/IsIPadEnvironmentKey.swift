import SwiftUI

public extension EnvironmentValues {
    /// Определяет, является ли устройство iPad на основе size classes
    /// Возвращает `true`, если оба size class (horizontal и vertical) равны `.regular`
    var isIPad: Bool {
        horizontalSizeClass == .regular && verticalSizeClass == .regular
    }
}
