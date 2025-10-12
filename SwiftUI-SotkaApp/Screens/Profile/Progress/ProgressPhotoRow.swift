import OSLog
import SwiftUI

struct ProgressPhotoRow: View {
    private let logger = Logger(subsystem: "SotkaApp", category: "ProgressPhotoRow")
    @State private var showDialog = false
    let progress: Progress
    let photoType: PhotoType
    let onPhotoTap: (Action) -> Void

    var body: some View {
        HStack(spacing: 12) {
            Text(photoType.localizedTitle)
                .frame(maxWidth: .infinity, alignment: .leading)
                .multilineTextAlignment(.leading)
            Button {
                showDialog.toggle()
            } label: {
                imageView
            }
            .buttonStyle(.plain)
            .confirmationDialog(
                "Progress.Photo.DialogTitle",
                isPresented: $showDialog
            ) {
                Button("Take a photo") {
                    onPhotoTap(.camera)
                }
                Button("Pick from gallery") {
                    onPhotoTap(.library)
                }
                if progress.getPhoto(photoType) != nil {
                    Button(.commonDelete, role: .destructive) {
                        logger.info("Пользователь нажал кнопку удаления для \(photoType.localizedTitle)")
                        onPhotoTap(.delete(photoType))
                    }
                }
            }
        }
    }
}

extension ProgressPhotoRow {
    enum Action {
        case camera
        case library
        case delete(PhotoType)
    }
}

private extension ProgressPhotoRow {
    @ViewBuilder
    var imageView: some View {
        ZStack {
            if let photo = progress.getPhoto(photoType),
               let data = photo.data,
               let image = UIImage(data: data) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                Image(systemName: "photo")
                    .font(.title)
                    .frame(maxHeight: .infinity)
            }
        }
        .aspectRatio(0.72, contentMode: .fit)
        .containerRelativeFrame(.horizontal) { length, _ in
            length * 0.55
        }
        .background(.secondary.opacity(0.5))
        .clipShape(.rect(cornerRadius: 12))
    }
}

#if DEBUG
#Preview {
    VStack(spacing: 16) {
        ProgressPhotoRow(
            progress: .previewDay1,
            photoType: .front,
            onPhotoTap: { _ in }
        )
        ProgressPhotoRow(
            progress: .previewDay49,
            photoType: .back,
            onPhotoTap: { _ in }
        )
        ProgressPhotoRow(
            progress: .previewDay100,
            photoType: .side,
            onPhotoTap: { _ in }
        )
    }
    .padding()
}
#endif
