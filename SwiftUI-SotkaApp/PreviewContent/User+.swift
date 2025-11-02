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
        let progress = UserProgress(id: 1)
        progress.pullUps = 10
        progress.pushUps = 20
        progress.squats = 30
        progress.weight = 70.0
        user.progressResults.append(progress)
        return user
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

    static var previewWithInfoposts: User {
        let user = preview
        // Добавляем прочитанные инфопосты для разных дней
        user.readInfopostDays = [1, 3, 5, 7, 10, 15, 20, 25, 30, 35, 40, 45, 50]
        return user
    }

    static var previewWithActivities: User {
        let user = preview
        let now = Date()
        let calendar = Calendar.current

        // Тренировка - день 1
        let workoutDate = calendar.date(byAdding: .day, value: -3, to: now) ?? now
        let workoutActivity = DayActivity(
            day: 1,
            activityTypeRaw: DayActivityType.workout.rawValue,
            count: 4,
            executeTypeRaw: ExerciseExecutionType.cycles.rawValue,
            createDate: workoutDate,
            modifyDate: workoutDate,
            user: user
        )
        // Добавляем упражнения для тренировки
        workoutActivity.trainings = [
            DayActivityTraining(
                count: 5,
                typeId: ExerciseType.pullups.rawValue,
                sortOrder: 0,
                dayActivity: workoutActivity
            ),
            DayActivityTraining(
                count: 10,
                typeId: ExerciseType.pushups.rawValue,
                sortOrder: 1,
                dayActivity: workoutActivity
            ),
            DayActivityTraining(
                count: 15,
                typeId: ExerciseType.squats.rawValue,
                sortOrder: 2,
                dayActivity: workoutActivity
            )
        ]
        user.dayActivities.append(workoutActivity)

        // Отдых - день 2
        let restDate = calendar.date(byAdding: .day, value: -2, to: now) ?? now
        let restActivity = DayActivity(
            day: 2,
            activityTypeRaw: DayActivityType.rest.rawValue,
            createDate: restDate,
            modifyDate: restDate,
            user: user
        )
        user.dayActivities.append(restActivity)

        // Растяжка - день 3
        let stretchDate = calendar.date(byAdding: .day, value: -1, to: now) ?? now
        let stretchActivity = DayActivity(
            day: 3,
            activityTypeRaw: DayActivityType.stretch.rawValue,
            createDate: stretchDate,
            modifyDate: stretchDate,
            user: user
        )
        user.dayActivities.append(stretchActivity)

        // Болезнь - день 4
        let sickActivity = DayActivity(
            day: 4,
            activityTypeRaw: DayActivityType.sick.rawValue,
            createDate: now,
            modifyDate: now,
            user: user
        )
        user.dayActivities.append(sickActivity)

        // Тренировка с подходами - день 5
        let setsDate = calendar.date(byAdding: .day, value: 1, to: now) ?? now
        let setsWorkoutActivity = DayActivity(
            day: 5,
            activityTypeRaw: DayActivityType.workout.rawValue,
            count: 3,
            executeTypeRaw: ExerciseExecutionType.sets.rawValue,
            createDate: setsDate,
            modifyDate: setsDate,
            user: user
        )
        setsWorkoutActivity.trainings = [
            DayActivityTraining(
                count: 8,
                typeId: ExerciseType.austrPullups.rawValue,
                sortOrder: 0,
                dayActivity: setsWorkoutActivity
            ),
            DayActivityTraining(
                count: 12,
                typeId: ExerciseType.pushupsKnees.rawValue,
                sortOrder: 1,
                dayActivity: setsWorkoutActivity
            ),
            DayActivityTraining(
                count: 20,
                typeId: ExerciseType.lunges.rawValue,
                sortOrder: 2,
                dayActivity: setsWorkoutActivity
            )
        ]
        user.dayActivities.append(setsWorkoutActivity)

        return user
    }
}
#endif
