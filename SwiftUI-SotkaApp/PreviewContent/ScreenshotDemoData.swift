#if DEBUG
import Foundation
import SwiftData

enum ScreenshotDemoData {
    static func setup(context: ModelContext) {
        // Делаем seed детерминированным: очищаем предыдущие данные пользователей
        // (каскадно удаляются связанные активности/упражнения/прогресс), чтобы UITest
        // не зависел от остатков прошлых запусков.
        let users = (try? context.fetch(FetchDescriptor<User>())) ?? []
        for user in users {
            context.delete(user)
        }
        try? context.save()

        let user = User(
            id: 280_084,
            userName: "DemoUserName",
            fullName: "DemoFullName",
            email: "demo_mail@mail.ru",
            imageStringURL: nil,
            cityID: 1,
            countryID: 17,
            genderCode: 0,
            birthDateIsoString: "1990-10-10"
        )
        context.insert(user)
        try? context.save()

        // Демо-данные: 11 дней активностей, прогресс дня 1, 3 пользовательских упражнения, страна
        // День 12 = текущий день (setCurrentDayForDebug(12)), оставлен без активности —
        // HomeActivitySectionView покажет кнопки выбора типа (TodayActivityButton.0)
        seedDemoData(context: context, user: user)
    }

    private static func seedDemoData(context: ModelContext, user: User) {
        let calendar = Calendar.current
        let now = Date()
        // setCurrentDayForDebug(12) вычисляет startDate = now - 11 дней
        guard let baseDate = calendar.date(byAdding: .day, value: -11, to: now) else { return }

        // Дни 1-11: 8 тренировок + 2 отдых + 1 растяжка
        let workoutDays = [
            (1, 5, 10, 15),
            (2, 6, 12, 18),
            (4, 7, 14, 21),
            (5, 8, 16, 24),
            (6, 9, 18, 27),
            (8, 10, 20, 30),
            (9, 11, 22, 33),
            (11, 12, 24, 36)
        ]
        for (day, pullups, pushups, squats) in workoutDays {
            guard let activityDate = calendar.date(byAdding: .day, value: day - 1, to: baseDate) else { continue }
            let activity = DayActivity(
                day: day,
                activityTypeRaw: DayActivityType.workout.rawValue,
                count: 4,
                plannedCount: 4,
                executeTypeRaw: ExerciseExecutionType.cycles.rawValue,
                createDate: activityDate,
                modifyDate: activityDate,
                user: user
            )
            activity.trainings = [
                DayActivityTraining(count: pullups, typeId: ExerciseType.pullups.rawValue, sortOrder: 0),
                DayActivityTraining(count: pushups, typeId: ExerciseType.pushups.rawValue, sortOrder: 1),
                DayActivityTraining(count: squats, typeId: ExerciseType.squats.rawValue, sortOrder: 2)
            ]
            context.insert(activity)
        }

        // День 3: отдых
        if let restDate = calendar.date(byAdding: .day, value: 2, to: baseDate) {
            let restActivity = DayActivity(
                day: 3,
                activityTypeRaw: DayActivityType.rest.rawValue,
                createDate: restDate,
                modifyDate: restDate,
                user: user
            )
            context.insert(restActivity)
        }

        // День 7: отдых
        if let restDate = calendar.date(byAdding: .day, value: 6, to: baseDate) {
            let restActivity = DayActivity(
                day: 7,
                activityTypeRaw: DayActivityType.rest.rawValue,
                createDate: restDate,
                modifyDate: restDate,
                user: user
            )
            context.insert(restActivity)
        }

        // День 10: растяжка
        if let stretchDate = calendar.date(byAdding: .day, value: 9, to: baseDate) {
            let stretchActivity = DayActivity(
                day: 10,
                activityTypeRaw: DayActivityType.stretch.rawValue,
                createDate: stretchDate,
                modifyDate: stretchDate,
                user: user
            )
            context.insert(stretchActivity)
        }

        // Прогресс дня 1 (контрольная точка)
        let progress = UserProgress(id: 1, pullUps: 7, pushUps: 15, squats: 30, weight: 70)
        progress.user = user
        context.insert(progress)

        // 3 демо-упражнения
        let demoExercises: [(id: String, name: String, imageId: Int, dayOffset: Int)] = [
            ("demo-exercise-1", String(localized: .demoExerciseClapPushUps), 0, -5),
            ("demo-exercise-2", String(localized: .demoExerciseBoxJumps), 2, -3),
            ("demo-exercise-3", String(localized: .demoExerciseBurpees), 11, -2)
        ]
        for (id, name, imageId, dayOffset) in demoExercises {
            guard let exerciseDate = calendar.date(byAdding: .day, value: dayOffset, to: now) else { continue }
            let exercise = CustomExercise(
                id: id,
                name: name,
                imageId: imageId,
                createDate: exerciseDate,
                modifyDate: exerciseDate,
                user: user
            )
            context.insert(exercise)
        }

        // Страна по умолчанию
        let country = Country.makeDefaultCountry()
        context.insert(country)

        try? context.save()
    }

    static let readInfopostDays = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
}
#endif
