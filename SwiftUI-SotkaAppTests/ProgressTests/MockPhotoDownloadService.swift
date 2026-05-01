import Foundation
@testable import SwiftUI_SotkaApp

final class MockPhotoDownloadService: PhotoDownloadServiceProtocol {
    var downloadAllPhotosCallCount = 0

    @MainActor
    func downloadAllPhotos(for _: UserProgress) async {
        downloadAllPhotosCallCount += 1
    }
}
