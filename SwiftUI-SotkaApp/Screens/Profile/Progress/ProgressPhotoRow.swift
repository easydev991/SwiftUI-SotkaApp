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
        .onAppear {
            logger.info("ProgressPhotoRow.onAppear: прогресс день \(progress.id), тип фотографии \(photoType.rawValue)")
            if let photo = progress.getPhoto(photoType) {
                logger
                    .info(
                        "ProgressPhotoRow.onAppear: найдена фотография, data=\(photo.data != nil ? "есть" : "нет"), urlString=\(photo.urlString ?? "нет"), isSynced=\(photo.isSynced)"
                    )
            } else {
                logger.info("ProgressPhotoRow.onAppear: фотография не найдена")
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
            if let photo = progress.getPhoto(photoType) {
                if let data = photo.data,
                   let image = UIImage(data: data) {
                    // Локальное изображение
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                } else if let urlString = photo.urlString,
                          let url = URL(string: urlString) {
                    // Изображение с сервера
                    AsyncImage(url: url) { image in
                        image
                            .resizable()
                            .scaledToFill()
                    } placeholder: {
                        ProgressView()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                } else {
                    // Нет изображения
                    Image(systemName: "photo")
                        .font(.title)
                        .frame(maxHeight: .infinity)
                }
            } else {
                // Нет фотографии
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
