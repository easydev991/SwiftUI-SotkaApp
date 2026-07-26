import Foundation
@testable import SwiftUI_SotkaApp
import Testing

@Suite("Тесты ключей ReviewStorage")
struct ReviewStorageKeysTests {
    @Test("Ключи имеют namespace review.")
    func keysUseReviewNamespace() {
        #expect(ReviewStorage.attemptedMilestones.hasPrefix("review."))
        #expect(ReviewStorage.lastReviewRequestAttemptDate.hasPrefix("review."))
    }

    @Test("Ключи уникальны")
    func keysAreUnique() {
        #expect(ReviewStorage.attemptedMilestones != ReviewStorage.lastReviewRequestAttemptDate)
    }
}
