import Foundation
@testable import SwiftUI_SotkaApp
import Testing

struct ExerciseExecutionTypeTests {
    @Test("ExerciseExecutionType имеет правильные rawValue")
    func exerciseExecutionTypeRawValues() {
        #expect(ExerciseExecutionType.cycles.rawValue == 0)
        #expect(ExerciseExecutionType.sets.rawValue == 1)
    }
}
