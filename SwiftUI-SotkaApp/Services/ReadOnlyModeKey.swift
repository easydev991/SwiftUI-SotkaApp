import SwiftUI

extension EnvironmentValues {
    @Entry var isReadOnlyMode: Bool = AppConfiguration.isReadOnlyMode
}
