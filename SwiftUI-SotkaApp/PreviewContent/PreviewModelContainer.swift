#if DEBUG
import Foundation
import SwiftData

enum PreviewModelContainer {
    @MainActor
    static func make(with user: User) -> ModelContainer {
        let schema = Schema(
            [
                User.self,
                Country.self,
                CustomExercise.self,
                UserProgress.self,
                DayActivity.self,
                DayActivityTraining.self,
                SyncJournalEntry.self
            ]
        )
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: schema, configurations: config)
        container.mainContext.insert(user)

        // Создаем активности после вставки user в контекст
        if user.id == User.preview.id {
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
            workoutActivity.trainings = [
                DayActivityTraining(
                    count: 5,
                    typeId: ExerciseType.pullups.rawValue,
                    sortOrder: 0
                ),
                DayActivityTraining(
                    count: 10,
                    typeId: ExerciseType.pushups.rawValue,
                    sortOrder: 1
                ),
                DayActivityTraining(
                    count: 15,
                    typeId: ExerciseType.squats.rawValue,
                    sortOrder: 2
                )
            ]
            container.mainContext.insert(workoutActivity)

            // Отдых - день 2
            let restDate = calendar.date(byAdding: .day, value: -2, to: now) ?? now
            let restActivity = DayActivity(
                day: 2,
                activityTypeRaw: DayActivityType.rest.rawValue,
                createDate: restDate,
                modifyDate: restDate,
                user: user
            )
            container.mainContext.insert(restActivity)

            // Растяжка - день 3
            let stretchDate = calendar.date(byAdding: .day, value: -1, to: now) ?? now
            let stretchActivity = DayActivity(
                day: 3,
                activityTypeRaw: DayActivityType.stretch.rawValue,
                createDate: stretchDate,
                modifyDate: stretchDate,
                user: user
            )
            container.mainContext.insert(stretchActivity)

            // Болезнь - день 4
            let sickActivity = DayActivity(
                day: 4,
                activityTypeRaw: DayActivityType.sick.rawValue,
                createDate: now,
                modifyDate: now,
                user: user
            )
            container.mainContext.insert(sickActivity)

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
                    sortOrder: 0
                ),
                DayActivityTraining(
                    count: 12,
                    typeId: ExerciseType.pushupsKnees.rawValue,
                    sortOrder: 1
                ),
                DayActivityTraining(
                    count: 20,
                    typeId: ExerciseType.lunges.rawValue,
                    sortOrder: 2
                )
            ]
            container.mainContext.insert(setsWorkoutActivity)

            // Тренировка с комментарием - день 7
            let commentDate = calendar.date(byAdding: .day, value: 3, to: now) ?? now
            let commentActivity = DayActivity(
                day: 7,
                activityTypeRaw: DayActivityType.workout.rawValue,
                count: 4,
                executeTypeRaw: ExerciseExecutionType.cycles.rawValue,
                comment: "Отличная тренировка! Очень устал, но доволен результатом.",
                createDate: commentDate,
                modifyDate: commentDate,
                user: user
            )
            commentActivity.trainings = [
                DayActivityTraining(
                    count: 5,
                    typeId: ExerciseType.pullups.rawValue,
                    sortOrder: 0
                ),
                DayActivityTraining(
                    count: 10,
                    typeId: ExerciseType.pushups.rawValue,
                    sortOrder: 1
                )
            ]
            container.mainContext.insert(commentActivity)
        }

        let russia = CountryResponse.defaultCountry
        let country = Country(id: russia.id, name: russia.name, cities: russia.cities.map(City.init))
        container.mainContext.insert(country)
        return container
    }
}
#endif
