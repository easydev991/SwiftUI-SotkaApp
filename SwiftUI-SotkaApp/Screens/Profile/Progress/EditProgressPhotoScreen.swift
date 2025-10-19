import OSLog
import SWDesignSystem
import SwiftData
import SwiftUI
import SWUtils

struct EditProgressPhotoScreen: View {
    private let logger = Logger(subsystem: "SotkaApp", category: "EditProgressPhotoScreen")
    @Bindable private var progress: Progress
    @Environment(\.modelContext) private var modelContext
    @Environment(ProgressService.self) private var progressService: ProgressService
    @State private var pickerSourceType: UIImagePickerController.SourceType?
    @State private var selectedPhotoType: PhotoType?
    @State private var photoToDelete: PhotoType?

    init(progress: Progress) {
        self.progress = progress
    }

    var body: some View {
        listView
            .navigationTitle(.progressPhotosScreenTitle)
            .confirmationDialog(
                .progressPhotoDeleteConfirm,
                isPresented: $photoToDelete.mappedToBool(),
                titleVisibility: .visible
            ) {
                deleteDialogContent
            } message: {
                deleteDialogMessage
            }
            .fullScreenCover(item: $pickerSourceType) { sourceType in
                makeImagePickerView(for: sourceType)
            }
            .onChange(of: photoToDelete) { _, newValue in
                if newValue != nil {
                    selectedPhotoType = nil
                }
            }
            .onAppear {
                logger.info("EditProgressPhotoScreen появился для прогресса дня \(progress.id)")
            }
    }
}

private extension EditProgressPhotoScreen {
    var listView: some View {
        List(PhotoType.allCases, id: \.self) { photoType in
            ProgressPhotoRow(
                progress: progress,
                photoType: photoType,
                onPhotoTap: { action in
                    switch action {
                    case .camera:
                        selectedPhotoType = photoType
                        pickerSourceType = .camera
                    case .library:
                        selectedPhotoType = photoType
                        pickerSourceType = .photoLibrary
                    case let .delete(photoType):
                        logger
                            .info(
                                "Пользователь выбрал удаление фотографии типа: \(photoType.localizedTitle) для прогресса дня \(progress.id)"
                            )
                        photoToDelete = photoType
                    }
                }
            )
            .listRowSeparator(.hidden)
        }
        .listStyle(.plain)
        .background(Color.swBackground)
    }

    var deleteDialogContent: some View {
        Button("Common.Delete", role: .destructive) {
            if let photoToDelete {
                do {
                    try progressService.deletePhoto(photoToDelete, context: modelContext)
                } catch {
                    logger.error("Ошибка удаления фото \(photoToDelete.localizedTitle): \(error.localizedDescription)")
                }
            } else {
                logger.warning("Попытка удаления фотографии, но photoToDelete = nil")
            }
        }
    }

    @ViewBuilder
    var deleteDialogMessage: some View {
        if let photoToDelete {
            Text(.progressPhotoDeleteMessage(photoToDelete.localizedTitle))
        }
    }

    func makeImagePickerView(
        for sourceType: UIImagePickerController.SourceType
    ) -> some View {
        SWImagePicker(sourceType: sourceType) { image in
            if let selectedPhotoType {
                let processedData = ImageProcessor.processImage(image)
                do {
                    try progressService.addPhoto(
                        processedData,
                        type: selectedPhotoType,
                        context: modelContext
                    )
                } catch {
                    logger.error("Ошибка добавления фото: \(error.localizedDescription)")
                }
            }
        }
        .ignoresSafeArea()
    }
}

#if DEBUG
#Preview {
    NavigationStack {
        EditProgressPhotoScreen(progress: .previewDay1)
            .environment(ProgressService(progress: .previewDay1, mode: .photos))
            .modelContainer(PreviewModelContainer.make(with: .preview))
    }
}
#endif
