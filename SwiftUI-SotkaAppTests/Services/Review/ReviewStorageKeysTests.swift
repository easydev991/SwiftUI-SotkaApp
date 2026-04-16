import Foundation
@testable import SwiftUI_SotkaApp
import Testing

@Suite("Тесты ключей ReviewStorage")
struct ReviewStorageKeysTests {
    @Test("Ключи имеют namespace review.")
    func keysUseReviewNamespace() {
        #expect(ReviewStorageKeys.attemptedMilestones.hasPrefix("review."))
        #expect(ReviewStorageKeys.lastReviewRequestAttemptDate.hasPrefix("review."))
    }

    @Test("Ключи уникальны")
    func keysAreUnique() {
        #expect(ReviewStorageKeys.attemptedMilestones != ReviewStorageKeys.lastReviewRequestAttemptDate)
    }
}
