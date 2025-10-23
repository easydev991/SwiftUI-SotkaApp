import Foundation
import SwiftData
@testable import SwiftUI_SotkaApp
import Testing
import UIKit

@MainActor
struct ProgressServicePhotoTests {
    // MARK: - Test Data

    private var testImageData: Data {
        let testImage = UIImage(systemName: "photo") ?? UIImage()
        return testImage.pngData() ?? Data()
    }

    private var largeImageData: Data {
        let size = CGSize(width: 2000, height: 2000)
        UIGraphicsBeginImageContextWithOptions(size, false, 1.0)
        defer { UIGraphicsEndImageContext() }

        UIColor.red.setFill()
        UIRectFill(CGRect(origin: .zero, size: size))

        let image = UIGraphicsGetImageFromCurrentImageContext() ?? UIImage()
        return image.pngData() ?? Data()
    }

    private var invalidImageData: Data {
        Data("not an image".utf8)
    }

    // MARK: - Helper Methods

    private func createTestModelContext() throws -> ModelContext {
        let modelConfiguration = ModelConfiguration(isStoredInMemoryOnly: true)
        let modelContainer = try ModelContainer(for: User.self, UserProgress.self, configurations: modelConfiguration)

        // Создаем тестового пользователя
        let user = User(id: 1, userName: "test", email: "test@test.com", cityID: nil)
        modelContainer.mainContext.insert(user)
        try modelContainer.mainContext.save()

        return modelContainer.mainContext
    }
}
