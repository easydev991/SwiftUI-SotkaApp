#if DEBUG
import Foundation

extension User {
    static var preview: User {
        User(
            id: 280084,
            userName: "DemoUserName",
            genderCode: 0
        )
    }

    // MARK: - UserProgress Combinations

    static var previewWithDay1Progress: User {
        let user = preview
        user.progressResults.append(UserProgress.previewDay1)
        return user
    }

    static var previewWithDay49Progress: User {
        let user = preview
        user.progressResults.append(UserProgress.previewDay49)
        return user
    }

    static var previewWithDay100Progress: User {
        let user = preview
        user.progressResults.append(UserProgress.previewDay100)
        return user
    }

    static var previewWithDay1And49Progress: User {
        let user = preview
        user.progressResults.append(UserProgress.previewDay1)
        user.progressResults.append(UserProgress.previewDay49)
        return user
    }

    static var previewWithDay49And100Progress: User {
        let user = preview
        user.progressResults.append(UserProgress.previewDay49)
        user.progressResults.append(UserProgress.previewDay100)
        return user
    }

    static var previewWithDay1And100Progress: User {
        let user = preview
        user.progressResults.append(UserProgress.previewDay1)
        user.progressResults.append(UserProgress.previewDay100)
        return user
    }

    static var previewWithAllProgress: User {
        let user = preview
        user.progressResults.append(UserProgress.previewDay1)
        user.progressResults.append(UserProgress.previewDay49)
        user.progressResults.append(UserProgress.previewDay100)
        return user
    }
}
#endif
