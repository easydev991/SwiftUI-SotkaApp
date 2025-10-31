import Foundation
@testable import SwiftUI_SotkaApp
import Testing

struct ExerciseTypeTests {
    @Test("ExerciseType имеет правильные rawValue")
    func exerciseTypeRawValues() {
        // Основные упражнения
        #expect(ExerciseType.pullups.rawValue == 0)
        #expect(ExerciseType.austrPullups.rawValue == 1)
        #expect(ExerciseType.squats.rawValue == 2)
        #expect(ExerciseType.pushups.rawValue == 3)
        #expect(ExerciseType.pushupsKnees.rawValue == 4)
        #expect(ExerciseType.lunges.rawValue == 5)

        // Турбо-упражнения 93
        #expect(ExerciseType.turbo93_1.rawValue == 93)
        #expect(ExerciseType.turbo93_2.rawValue == 932)
        #expect(ExerciseType.turbo93_3.rawValue == 933)
        #expect(ExerciseType.turbo93_4.rawValue == 934)
        #expect(ExerciseType.turbo93_5.rawValue == 935)

        // Турбо-упражнения 94
        #expect(ExerciseType.turbo94Pushups.rawValue == 94)
        #expect(ExerciseType.turbo94Squats.rawValue == 942)
        #expect(ExerciseType.turbo94Pullups.rawValue == 943)

        // Турбо-упражнения 95
        #expect(ExerciseType.turbo95_1.rawValue == 95)
        #expect(ExerciseType.turbo95_2.rawValue == 952)
        #expect(ExerciseType.turbo95_3.rawValue == 953)
        #expect(ExerciseType.turbo95_4.rawValue == 954)
        #expect(ExerciseType.turbo95_5.rawValue == 955)

        // Турбо-упражнения 96
        #expect(ExerciseType.turbo96Pushups.rawValue == 96)
        #expect(ExerciseType.turbo96Squats.rawValue == 962)
        #expect(ExerciseType.turbo96Pullups.rawValue == 963)

        // Турбо-упражнения 97
        #expect(ExerciseType.turbo97PushupsHigh.rawValue == 97)
        #expect(ExerciseType.turbo97PushupsHighArms.rawValue == 973)

        // Турбо-упражнения 98
        #expect(ExerciseType.turbo98Pullups.rawValue == 98)
        #expect(ExerciseType.turbo98Pushups.rawValue == 982)
        #expect(ExerciseType.turbo98Squats.rawValue == 983)
    }
}
