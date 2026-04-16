#if DEBUG
import Foundation
import SwiftData

extension ReviewManager {
    @MainActor
    static var preview: ReviewManager {
        ReviewManager(
            attemptStore: ReviewStorage(),
            completionsCounter: WorkoutCompletionsCounter(modelContainer: PreviewModelContainer.make(with: .preview)),
            currentUserIdProvider: { nil }
        )
    }
}
#endif
