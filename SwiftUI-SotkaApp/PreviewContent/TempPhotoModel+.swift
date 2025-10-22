#if DEBUG
import Foundation

extension TempPhotoModel {
    static func makePreviews(for types: [PhotoType] = PhotoType.allCases) -> [Self] {
        types.map {
            .init(type: $0, urlString: nil, data: nil)
        }
    }

    func makeSinglePreview(for type: PhotoType, isMarkedForDeletion: Bool) -> Self {
        .init(type: type, urlString: nil, data: isMarkedForDeletion ? Progress.DELETED_DATA : nil)
    }
}
#endif
