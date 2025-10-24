import Foundation
@testable import SwiftUI_SotkaApp

final class MockPhotoDownloadService: PhotoDownloadServiceProtocol {
    var downloadAllPhotosCallCount = 0
    var lastProgress: UserProgress?

    @MainActor
    func downloadAllPhotos(for progress: UserProgress) async {
        downloadAllPhotosCallCount += 1
        lastProgress = progress
    }
}
