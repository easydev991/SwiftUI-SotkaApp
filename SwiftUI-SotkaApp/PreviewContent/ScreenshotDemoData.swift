#if DEBUG
import Foundation
import SwiftData

enum ScreenshotDemoData {
    static func setup(context: ModelContext) {
        let user = User(
            id: 1,
            userName: "DemoUser",
            fullName: "Демо Пользователь",
            email: "demo@example.com",
            cityID: 1,
            countryID: 1,
            genderCode: 0,
            birthDateIsoString: "1990-01-01"
        )
        context.insert(user)
        do {
            try context.save()
        } catch {
            print("Ошибка сохранения пользователя: \(error.localizedDescription)")
        }
    }

    static let readInfopostDays = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
}
#endif
