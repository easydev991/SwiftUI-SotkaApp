#if DEBUG
import Foundation

extension User {
    static var preview: User {
        User(
            id: 280084,
            userName: "DemoUserName",
            fullName: "DemoFullName",
            email: "demo_mail@mail.ru",
            imageStringURL: "https://workout.su/uploads/avatars/2019/10/2019-10-07-01-10-08-yow.jpg",
            cityID: 1,
            countryID: 17,
            genderCode: 0,
            birthDateIsoString: "1990-10-10"
        )
    }

    static var previewWithProgress: User {
        let user = preview
        let progress = Progress(id: 1)
        progress.pullUps = 10
        progress.pushUps = 20
        progress.squats = 30
        progress.weight = 70.0
        user.progressResults.append(progress)
        return user
    }

    // MARK: - Progress Combinations

    static var previewWithDay1Progress: User {
        let user = preview
        user.progressResults.append(Progress.previewDay1)
        return user
    }

    static var previewWithDay49Progress: User {
        let user = preview
        user.progressResults.append(Progress.previewDay49)
        return user
    }

    static var previewWithDay100Progress: User {
        let user = preview
        user.progressResults.append(Progress.previewDay100)
        return user
    }

    static var previewWithDay1And49Progress: User {
        let user = preview
        user.progressResults.append(Progress.previewDay1)
        user.progressResults.append(Progress.previewDay49)
        return user
    }

    static var previewWithDay49And100Progress: User {
        let user = preview
        user.progressResults.append(Progress.previewDay49)
        user.progressResults.append(Progress.previewDay100)
        return user
    }

    static var previewWithDay1And100Progress: User {
        let user = preview
        user.progressResults.append(Progress.previewDay1)
        user.progressResults.append(Progress.previewDay100)
        return user
    }

    static var previewWithAllProgress: User {
        let user = preview
        user.progressResults.append(Progress.previewDay1)
        user.progressResults.append(Progress.previewDay49)
        user.progressResults.append(Progress.previewDay100)
        return user
    }
}
#endif
