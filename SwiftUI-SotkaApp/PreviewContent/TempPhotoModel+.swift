#if DEBUG
import Foundation

extension TempPhotoModel {
    static func makePreviews(for types: [ProgressPhotoType] = ProgressPhotoType.allCases) -> [Self] {
        types.map {
            .init(type: $0, urlString: nil, data: nil)
        }
    }

    func makeSinglePreview(for type: ProgressPhotoType, isMarkedForDeletion: Bool) -> Self {
        .init(type: type, urlString: nil, data: isMarkedForDeletion ? UserProgress.DELETED_DATA : nil)
    }
}
#endif
