import Foundation
@testable import SwiftUI_SotkaApp
import Testing

@MainActor
struct AudioPlayerServiceTests {
    @Test("Метод play должен возвращать false до настройки звука")
    func playReturnsFalseBeforeSetup() {
        let manager = AudioPlayerManager()
        let result = manager.play()
        #expect(!result)
    }
}
