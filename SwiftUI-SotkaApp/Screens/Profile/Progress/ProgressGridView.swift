import SwiftUI

struct ProgressGridView: View {
    let user: User
    let progressItems: [Progress]
    let currentDay: Int
    let onProgressTap: (Progress) -> Void
    let onPhotoTap: (Progress, PhotoType) -> Void

    var body: some View {
        gridView
    }
}

private extension ProgressGridView {
    var gridView: some View {
        Grid(horizontalSpacing: 16, verticalSpacing: 20) {
            // Заголовки столбцов (дни)
            GridRow {
                // Пустая ячейка для выравнивания с иконками
                Color.clear
                    .frame(width: 10, height: 10)
                // Заголовки для каждой секции
                ForEach(Progress.Section.allCases, id: \.self) { section in
                    dayHeaderView(for: section)
                }
            }

            // Разделитель
            GridRow {
                Color.clear.frame(height: 1)
                Color.clear.frame(height: 1)
                Color.clear.frame(height: 1)
                Color.clear.frame(height: 1)
            }
            .background(Color.gray.opacity(0.3))

            // Данные для каждого типа упражнения
            ForEach(Progress.DataType.allCases, id: \.self) { dataType in
                GridRow {
                    // Иконка типа упражнения
                    exerciseIconView(for: dataType)

                    // Данные прогресса для каждого дня
                    ForEach(Progress.Section.allCases, id: \.self) { section in
                        let (progress, isDisabled) = makeModel(for: section)
                        Button {
                            onProgressTap(progress)
                        } label: {
                            progressDataView(progress: progress, type: dataType)
                        }
                        .buttonStyle(.plain)
                        .disabled(isDisabled)
                    }
                }
            }

            // Фотографии для каждого типа
            ForEach(PhotoType.allCases, id: \.self) { photoType in
                GridRow {
                    // Локализованный текст типа фотографии
                    Text(photoType.localizedTitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize()
                        .frame(maxWidth: .infinity, alignment: .leading)

                    // Фотографии для каждого дня
                    ForEach(Progress.Section.allCases, id: \.self) { section in
                        let (progress, isDisabled) = makeModel(for: section)
                        Button {
                            onPhotoTap(progress, photoType)
                        } label: {
                            progressPhotoView(progress: progress, type: photoType)
                        }
                        .buttonStyle(.plain)
                        .disabled(isDisabled)
                    }
                }
            }
        }
    }

    func dayHeaderView(for section: Progress.Section) -> some View {
        VStack(spacing: 4) {
            Text("Day")
                .font(.footnote)
                .foregroundColor(.secondary)
            Text("\(section.rawValue)")
                .font(.headline)
                .fontWeight(.semibold)
        }
    }

    func exerciseIconView(for dataType: Progress.DataType) -> some View {
        VStack(spacing: 4) {
            dataType.icon
                .resizable()
                .scaledToFit()
                .frame(width: 30, height: 30)
                .foregroundStyle(.blue)
            Text(dataType.localizedTitle)
                .font(.caption)
                .foregroundColor(.secondary)
                .fixedSize()
        }
    }

    func progressDataView(
        progress: Progress,
        type: Progress.DataType
    ) -> some View {
        Text(progress.displayedValue(for: type))
            .lineLimit(1)
            .minimumScaleFactor(0.75)
    }

    func progressPhotoView(
        progress: Progress,
        type: PhotoType
    ) -> some View {
        ZStack {
            // Приоритет локальным данным, fallback на URL
            if let photoData = progress.getPhotoData(type),
               let uiImage = UIImage(data: photoData) {
                // Локальное изображение (быстрый доступ)
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
            } else if let urlString = progress.getPhotoURL(type),
                      let url = URL(string: urlString) {
                // Изображение с сервера (асинхронная загрузка)
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
                    .font(.title2)
            }
        }
        .frame(width: 80, height: 110)
        .background(.secondary.opacity(0.5))
        .clipShape(.rect(cornerRadius: 12))
    }

    /// Возвращает модель прогресса для указанной секции или заглушку
    func makeModel(for section: Progress.Section) -> (progress: Progress, isDisabled: Bool) {
        let progress = progressItems.first { $0.id == section.rawValue } ?? .init(id: section.rawValue)
        let isDisabled = currentDay < section.rawValue
        return (progress, isDisabled)
    }
}

#if DEBUG
#Preview("Без прогресса") {
    ProgressGridView(
        user: .preview,
        progressItems: [],
        currentDay: 1,
        onProgressTap: { progress in
            print("нажали на день \(progress.id)")
        },
        onPhotoTap: { progress, photoType in
            print("нажали на фото \(photoType.localizedTitle) для дня \(progress.id)")
        }
    )
}

#Preview("День 1") {
    ProgressGridView(
        user: .previewWithDay1Progress,
        progressItems: [.previewDay1],
        currentDay: 1,
        onProgressTap: { progress in
            print("нажали на день \(progress.id)")
        },
        onPhotoTap: { progress, photoType in
            print("нажали на фото \(photoType.localizedTitle) для дня \(progress.id)")
        }
    )
}

#Preview("День 49 (продвинутый блок)") {
    ProgressGridView(
        user: .previewWithDay49Progress,
        progressItems: [.previewDay49],
        currentDay: 49,
        onProgressTap: { progress in
            print("нажали на день \(progress.id)")
        },
        onPhotoTap: { progress, photoType in
            print("нажали на фото \(photoType.localizedTitle) для дня \(progress.id)")
        }
    )
}

#Preview("День 100") {
    ProgressGridView(
        user: .previewWithDay100Progress,
        progressItems: [.previewDay100],
        currentDay: 100,
        onProgressTap: { progress in
            print("нажали на день \(progress.id)")
        },
        onPhotoTap: { progress, photoType in
            print("нажали на фото \(photoType.localizedTitle) для дня \(progress.id)")
        }
    )
}

#Preview("Дни 1 + 49 (продвинутый блок)") {
    ProgressGridView(
        user: .previewWithDay1And49Progress,
        progressItems: [.previewDay1, .previewDay49],
        currentDay: 49,
        onProgressTap: { progress in
            print("нажали на день \(progress.id)")
        },
        onPhotoTap: { progress, photoType in
            print("нажали на фото \(photoType.localizedTitle) для дня \(progress.id)")
        }
    )
}

#Preview("Дни 49 + 100") {
    ProgressGridView(
        user: .previewWithDay49And100Progress,
        progressItems: [.previewDay49, .previewDay100],
        currentDay: 100,
        onProgressTap: { progress in
            print("нажали на день \(progress.id)")
        },
        onPhotoTap: { progress, photoType in
            print("нажали на фото \(photoType.localizedTitle) для дня \(progress.id)")
        }
    )
}

#Preview("Дни 1 + 100") {
    ProgressGridView(
        user: .previewWithDay1And100Progress,
        progressItems: [.previewDay1, .previewDay100],
        currentDay: 100,
        onProgressTap: { progress in
            print("нажали на день \(progress.id)")
        },
        onPhotoTap: { progress, photoType in
            print("нажали на фото \(photoType.localizedTitle) для дня \(progress.id)")
        }
    )
}

#Preview("Все дни") {
    ProgressGridView(
        user: .previewWithAllProgress,
        progressItems: [.previewDay1, .previewDay49, .previewDay100],
        currentDay: 100,
        onProgressTap: { progress in
            print("нажали на день \(progress.id)")
        },
        onPhotoTap: { progress, photoType in
            print("нажали на фото \(photoType.localizedTitle) для дня \(progress.id)")
        }
    )
}

#Preview("Доступность кнопок - день 1") {
    ProgressGridView(
        user: .preview,
        progressItems: [],
        currentDay: 1,
        onProgressTap: { progress in
            print("нажали на день \(progress.id)")
        },
        onPhotoTap: { progress, photoType in
            print("нажали на фото \(photoType.localizedTitle) для дня \(progress.id)")
        }
    )
}

#Preview("Доступность кнопок - день 25 (день 49 недоступен)") {
    ProgressGridView(
        user: .preview,
        progressItems: [],
        currentDay: 25,
        onProgressTap: { progress in
            print("нажали на день \(progress.id)")
        },
        onPhotoTap: { progress, photoType in
            print("нажали на фото \(photoType.localizedTitle) для дня \(progress.id)")
        }
    )
}

#Preview("Доступность кнопок - день 49 (средний прогресс доступен)") {
    ProgressGridView(
        user: .previewWithDay49Progress,
        progressItems: [.previewDay49],
        currentDay: 49,
        onProgressTap: { progress in
            print("нажали на день \(progress.id)")
        },
        onPhotoTap: { progress, photoType in
            print("нажали на фото \(photoType.localizedTitle) для дня \(progress.id)")
        }
    )
}

#Preview("Доступность кнопок - день 75 (день 100 недоступен)") {
    ProgressGridView(
        user: .preview,
        progressItems: [],
        currentDay: 75,
        onProgressTap: { progress in
            print("нажали на день \(progress.id)")
        },
        onPhotoTap: { progress, photoType in
            print("нажали на фото \(photoType.localizedTitle) для дня \(progress.id)")
        }
    )
}
#endif
