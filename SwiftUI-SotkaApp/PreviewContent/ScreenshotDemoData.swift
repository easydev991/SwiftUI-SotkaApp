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

        let user = User(from: .preview)
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
