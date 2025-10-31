import Foundation
@testable import SwiftUI_SotkaApp
import Testing

struct DayActivityTypeTests {
    @Test("DayActivityType имеет правильные rawValue")
    func dayActivityTypeRawValues() {
        #expect(DayActivityType.workout.rawValue == 0)
        #expect(DayActivityType.rest.rawValue == 1)
        #expect(DayActivityType.stretch.rawValue == 2)
        #expect(DayActivityType.sick.rawValue == 3)
    }
}
