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
                .progressPhotoDialogTitle,
                isPresented: $showDialog
            ) {
                Button(.takeAPhoto) {
                    onPhotoTap(.camera)
                }
                Button("Pick from gallery") {
                    onPhotoTap(.library)
                }
                if progress.hasPhoto(photoType) {
                    Button(.commonDelete, role: .destructive) {
                        logger.info("Пользователь нажал кнопку удаления для \(photoType.localizedTitle)")
                        onPhotoTap(.delete(photoType))
                    }
                }
            }
        }
        .onAppear {
            logger.info("ProgressPhotoRow.onAppear: прогресс день \(progress.id), тип фотографии \(photoType.rawValue)")
            if progress.hasPhoto(photoType) {
                logger
                    .info(
                        "ProgressPhotoRow.onAppear: найдена фотография, hasData=\(progress.hasPhotoData(photoType)), urlString=\(progress.getPhotoURL(photoType) ?? "нет")"
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
            // Приоритет локальным данным, fallback на URL
            if let photoData = progress.getPhotoData(photoType),
               let uiImage = UIImage(data: photoData) {
                // Локальное изображение (быстрый доступ)
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
            } else if let urlString = progress.getPhotoURL(photoType) {
                // Изображение с сервера (асинхронная загрузка)
                AsyncImage(url: URL(string: urlString)) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    case let .success(image):
                        image.resizable().scaledToFill()
                    case .failure:
                        Image(systemName: "photo")
                            .foregroundColor(.gray)
                            .font(.title)
                            .frame(maxHeight: .infinity)
                    @unknown default:
                        EmptyView()
                    }
                }
            } else {
                // Нет изображения
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
