import OSLog
import SWDesignSystem
import SwiftUI

struct ProgressPhotoRow: View {
    private let logger = Logger(subsystem: "SotkaApp", category: "ProgressPhotoRow")
    @State private var showDialog = false
    let model: TempPhotoModel
    let onPhotoTap: (Action) -> Void

    var body: some View {
        HStack(spacing: 12) {
            Text(model.type.localizedTitle)
                .frame(maxWidth: .infinity, alignment: .leading)
                .multilineTextAlignment(.leading)
            Button {
                showDialog.toggle()
            } label: {
                imageView
            }
            .animation(.default, value: model)
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
                if model.canBeDeleted {
                    Button(.commonDelete, role: .destructive) {
                        logger.info("Пользователь нажал кнопку удаления для \(model.type.localizedTitle)")
                        onPhotoTap(.delete(model.type))
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
        case delete(ProgressPhotoType)
    }
}

private extension ProgressPhotoRow {
    @ViewBuilder
    var imageView: some View {
        ZStack {
            // Приоритет локальным данным, fallback на URL
            if let photoData = model.data,
               let uiImage = UIImage(data: photoData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
            } else if let urlString = model.urlString {
                CachedImage(url: URL(string: urlString), mode: .clean)
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
            model: .init(type: .front, urlString: nil, data: nil),
            onPhotoTap: { _ in }
        )
        ProgressPhotoRow(
            model: .init(type: .front, urlString: nil, data: UserProgress.DELETED_DATA),
            onPhotoTap: { _ in }
        )
    }
    .padding()
}
#endif
