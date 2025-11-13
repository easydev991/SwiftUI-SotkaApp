import OSLog
import SWDesignSystem
import SwiftUI

struct ProgressGridView: View {
    private let logger = Logger(subsystem: "SotkaApp", category: "ProgressGridView")
    @Environment(\.currentDay) private var currentDay
    private var progressItems: [UserProgress] {
        user.progressResults.filter { !$0.shouldDelete }
    }

    let user: User
    let onProgressTap: (UserProgress) -> Void
    let onPhotoTap: (UserProgress) -> Void

    var body: some View {
        gridView
            .onAppear {
                let logItems = progressItems.map { "\($0.id): shouldDelete=\($0.shouldDelete)" }.joined(separator: ", ")
                logger.info("onAppear появился, загружено \(logItems.count) элементов: [\(logItems)]")
            }
            .onChange(of: progressItems) { _, newItems in
                let logItems = newItems.map { "\($0.id): shouldDelete=\($0.shouldDelete)" }.joined(separator: ", ")
                logger.info("onChange: изменились элементы, теперь \(newItems.count) элементов: [\(logItems)]")
            }
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
                ForEach(UserProgress.Section.allCases, id: \.self) { section in
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
            ForEach(UserProgress.DataType.allCases, id: \.self) { dataType in
                GridRow {
                    // Иконка типа упражнения
                    exerciseIconView(for: dataType)

                    // Данные прогресса для каждого дня
                    ForEach(UserProgress.Section.allCases, id: \.self) { section in
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
            ForEach(ProgressPhotoType.allCases, id: \.self) { photoType in
                GridRow {
                    // Локализованный текст типа фотографии
                    Text(photoType.localizedTitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize()
                        .frame(maxWidth: .infinity)

                    // Фотографии для каждого дня
                    ForEach(UserProgress.Section.allCases, id: \.self) { section in
                        let (progress, isDisabled) = makeModel(for: section)
                        Button {
                            onPhotoTap(progress)
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

    func dayHeaderView(for section: UserProgress.Section) -> some View {
        Text(section.localizedTitle)
            .fontWeight(.semibold)
            .fixedSize()
    }

    func exerciseIconView(for dataType: UserProgress.DataType) -> some View {
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
        progress: UserProgress,
        type: UserProgress.DataType
    ) -> some View {
        Text(progress.displayedValue(for: type))
            .lineLimit(1)
            .minimumScaleFactor(0.75)
    }

    func progressPhotoView(
        progress: UserProgress,
        type: ProgressPhotoType
    ) -> some View {
        ZStack {
            // Приоритет локальным данным, fallback на URL
            if let photoData = progress.getPhotoData(type),
               let uiImage = UIImage(data: photoData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
            } else if let urlString = progress.getPhotoURL(type) {
                CachedImage(url: URL(string: urlString), mode: .clean)
            } else {
                Image(systemName: "photo")
                    .font(.title2)
            }
        }
        .frame(width: 80, height: 110)
        .background(.secondary.opacity(0.5))
        .clipShape(.rect(cornerRadius: 12))
    }

    /// Возвращает модель прогресса для указанной секции или заглушку
    func makeModel(for section: UserProgress.Section) -> (progress: UserProgress, isDisabled: Bool) {
        let progress = progressItems.first { $0.id == section.rawValue } ?? .init(id: section.rawValue)
        let isDisabled = currentDay < section.rawValue
        return (progress, isDisabled)
    }
}

#if DEBUG
#Preview("Без прогресса") {
    ProgressGridView(
        user: .preview,
        onProgressTap: { progress in
            print("нажали на день \(progress.id)")
        },
        onPhotoTap: { progress in
            print("нажали на фото для дня \(progress.id)")
        }
    )
    .currentDay(1)
}

#Preview("День 1") {
    ProgressGridView(
        user: .previewWithDay1Progress,
        onProgressTap: { progress in
            print("нажали на день \(progress.id)")
        },
        onPhotoTap: { progress in
            print("нажали на фото для дня \(progress.id)")
        }
    )
    .currentDay(1)
}

#Preview("День 49 (продвинутый блок)") {
    ProgressGridView(
        user: .previewWithDay49Progress,
        onProgressTap: { progress in
            print("нажали на день \(progress.id)")
        },
        onPhotoTap: { progress in
            print("нажали на фото для дня \(progress.id)")
        }
    )
    .currentDay(49)
}

#Preview("День 100") {
    ProgressGridView(
        user: .previewWithDay100Progress,
        onProgressTap: { progress in
            print("нажали на день \(progress.id)")
        },
        onPhotoTap: { progress in
            print("нажали на фото для дня \(progress.id)")
        }
    )
    .currentDay(100)
}

#Preview("Дни 1 + 49 (продвинутый блок)") {
    ProgressGridView(
        user: .previewWithDay1And49Progress,
        onProgressTap: { progress in
            print("нажали на день \(progress.id)")
        },
        onPhotoTap: { progress in
            print("нажали на фото для дня \(progress.id)")
        }
    )
    .currentDay(49)
}

#Preview("Дни 49 + 100") {
    ProgressGridView(
        user: .previewWithDay49And100Progress,
        onProgressTap: { progress in
            print("нажали на день \(progress.id)")
        },
        onPhotoTap: { progress in
            print("нажали на фото для дня \(progress.id)")
        }
    )
    .currentDay(100)
}

#Preview("Дни 1 + 100") {
    ProgressGridView(
        user: .previewWithDay1And100Progress,
        onProgressTap: { progress in
            print("нажали на день \(progress.id)")
        },
        onPhotoTap: { progress in
            print("нажали на фото для дня \(progress.id)")
        }
    )
    .currentDay(100)
}

#Preview("Все дни") {
    ProgressGridView(
        user: .previewWithAllProgress,
        onProgressTap: { progress in
            print("нажали на день \(progress.id)")
        },
        onPhotoTap: { progress in
            print("нажали на фото для дня \(progress.id)")
        }
    )
    .currentDay(100)
}

#Preview("Доступность кнопок - день 1") {
    ProgressGridView(
        user: .preview,
        onProgressTap: { progress in
            print("нажали на день \(progress.id)")
        },
        onPhotoTap: { progress in
            print("нажали на фото для дня \(progress.id)")
        }
    )
    .currentDay(1)
}

#Preview("Доступность кнопок - день 49 (средний прогресс доступен)") {
    ProgressGridView(
        user: .previewWithDay49Progress,
        onProgressTap: { progress in
            print("нажали на день \(progress.id)")
        },
        onPhotoTap: { progress in
            print("нажали на фото для дня \(progress.id)")
        }
    )
    .currentDay(49)
}
#endif
