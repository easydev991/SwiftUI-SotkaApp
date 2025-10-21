# План доработки логики работы с фотографиями

## Цель

Изменить логику работы с фотографиями так, чтобы все изменения сначала накапливались в `ProgressService`, а сохранялись в SwiftData только по нажатию на кнопку `saveButton` в `EditProgressScreen`.

## Текущая проблема

Сейчас при добавлении/удалении фотографий в `EditProgressPhotoScreen` изменения сразу применяются к модели `Progress` через методы `progressService.addPhoto()` и `progressService.deletePhoto()`, которые вызывают `context.save()`. Это нарушает паттерн "редактирование → сохранение", используемый для метрик (pullUps, pushUps, squats, weight).

## Архитектурное решение

### 1. Добавление новых свойств в ProgressService

**Файл:** `SwiftUI-SotkaApp/Services/ProgressService.swift`

Добавить новые свойства для временного хранения данных фотографий:

```swift
@Observable
final class ProgressService {
    // ... существующие свойства ...
    
    // MARK: - Photo Edited Values (временные данные фотографий для редактирования)
    
    /// Временные данные фотографии спереди
    /// - nil: не загружено/не изменялось
    /// - Progress.DELETED_DATA: помечено для удаления
    /// - Data: новое изображение для загрузки
    var editedPhotoFront: Data?
    
    /// Временные данные фотографии сзади
    var editedPhotoBack: Data?
    
    /// Временные данные фотографии сбоку
    var editedPhotoSide: Data?
}
```

### 2. Обновление метода loadProgress()

**Файл:** `SwiftUI-SotkaApp/Services/ProgressService.swift`

Дополнить метод `loadProgress()` для загрузки фотографий в временные свойства:

```swift
func loadProgress() {
    // ... существующая логика для метрик ...
    
    // Загружаем фотографии в временные свойства
    editedPhotoFront = progressModel.getPhotoData(.front)
    editedPhotoBack = progressModel.getPhotoData(.back)
    editedPhotoSide = progressModel.getPhotoData(.side)
    
    logger.info("Данные фотографий загружены в editedPhoto* свойства")
}
```

### 3. Новые методы для работы с временными данными фотографий

**Файл:** `SwiftUI-SotkaApp/Services/ProgressService.swift`

Создать новые методы для изменения временных данных фотографий:

```swift
// MARK: - Temporary Photo Management (работа с временными данными фотографий)

/// Устанавливает временные данные фотографии (для последующего сохранения)
/// ВАЖНО: Метод выполняет валидацию и обработку изображения перед сохранением
/// - Parameters:
///   - data: Данные изображения (необработанные)
///   - type: Тип фотографии
/// - Throws: ProgressError если данные невалидны или обработка не удалась
func setTemporaryPhoto(_ data: Data?, type: PhotoType) throws {
    guard let data else {
        throw ProgressError.invalidImageData
    }

    // Валидация размера и формата (из старого addPhoto)
    guard ImageProcessor.validateImageSize(data),
          ImageProcessor.validateImageFormat(data) else {
        throw ProgressError.invalidImageData
    }

    guard let image = UIImage(data: data) else {
        throw ProgressError.invalidImageData
    }

    // Обработка изображения (сжатие и масштабирование)
    let processedData = ImageProcessor.processImage(image)
    guard let processedData else {
        throw ProgressError.imageProcessingFailed
    }

    // Сохраняем обработанные данные во временное хранилище
    switch type {
    case .front:
        editedPhotoFront = processedData
    case .back:
        editedPhotoBack = processedData
    case .side:
        editedPhotoSide = processedData
    }
    
    logger.info("Временные данные фотографии \(type.localizedTitle) обновлены (размер: \(processedData.count) байт)")
}

/// Помечает фотографию для удаления (устанавливает DELETED_DATA)
/// - Parameter type: Тип фотографии
func markPhotoForDeletion(_ type: PhotoType) {
    switch type {
    case .front:
        editedPhotoFront = Progress.DELETED_DATA
    case .back:
        editedPhotoBack = Progress.DELETED_DATA
    case .side:
        editedPhotoSide = Progress.DELETED_DATA
    }
    logger.info("Фотография \(type.localizedTitle) помечена для удаления")
}

/// Получает временные данные фотографии (для отображения в UI)
/// - Parameter type: Тип фотографии
/// - Returns: Данные фотографии или nil (если не загружена или помечена для удаления)
func getTemporaryPhoto(_ type: PhotoType) -> Data? {
    let data: Data? = switch type {
    case .front: editedPhotoFront
    case .back: editedPhotoBack
    case .side: editedPhotoSide
    }
    // Возвращаем nil для DELETED_DATA (как в Progress.getPhotoData)
    return data == Progress.DELETED_DATA ? nil : data
}

/// Проверяет, помечена ли фотография для удаления
/// - Parameter type: Тип фотографии
/// - Returns: true, если фотография помечена для удаления
func isPhotoMarkedForDeletion(_ type: PhotoType) -> Bool {
    let data: Data? = switch type {
    case .front: editedPhotoFront
    case .back: editedPhotoBack
    case .side: editedPhotoSide
    }
    return data == Progress.DELETED_DATA
}
```

### 4. Обновление метода saveProgress()

**Файл:** `SwiftUI-SotkaApp/Services/ProgressService.swift`

Расширить метод `saveProgress()` для применения изменений фотографий:

```swift
func saveProgress(context: ModelContext) throws {
    // ... существующая логика для метрик ...
    
    // Применяем изменения фотографий из временных свойств
    let photoChangesApplied = applyPhotoChanges()
    
    // Обновляем флаги синхронизации если были изменения
    if hasRealChanges || photoChangesApplied {
        progressModel.isSynced = false
        progressModel.lastModified = Date.now
    }
    
    // ... остальная логика сохранения ...
    try context.save()
}

/// Применяет изменения фотографий из временных свойств к модели Progress
/// - Returns: true если были применены изменения, false если изменений не было
private func applyPhotoChanges() -> Bool {
    var hasChanges = false
    
    // Проверяем и применяем изменения для каждой фотографии
    if editedPhotoFront != progressModel.dataPhotoFront {
        if editedPhotoFront == Progress.DELETED_DATA {
            progressModel.deletePhotoData(.front)
        } else if let data = editedPhotoFront {
            progressModel.setPhotoData(.front, data: data)
        }
        hasChanges = true
    }
    
    if editedPhotoBack != progressModel.dataPhotoBack {
        if editedPhotoBack == Progress.DELETED_DATA {
            progressModel.deletePhotoData(.back)
        } else if let data = editedPhotoBack {
            progressModel.setPhotoData(.back, data: data)
        }
        hasChanges = true
    }
    
    if editedPhotoSide != progressModel.dataPhotoSide {
        if editedPhotoSide == Progress.DELETED_DATA {
            progressModel.deletePhotoData(.side)
        } else if let data = editedPhotoSide {
            progressModel.setPhotoData(.side, data: data)
        }
        hasChanges = true
    }
    
    if hasChanges {
        logger.info("Изменения фотографий применены к модели Progress")
    }
    
    return hasChanges
}
```

### 5. Обновление computed property hasChanges

**Файл:** `SwiftUI-SotkaApp/Services/ProgressService.swift`

Дополнить `hasChanges` для учета изменений фотографий:

```swift
var hasChanges: Bool {
    // ... существующая логика для метрик ...
    
    // Проверяем изменения в фотографиях путем сравнения временных данных с данными модели
    let photoFrontChanged = editedPhotoFront != progressModel.dataPhotoFront
    let photoBackChanged = editedPhotoBack != progressModel.dataPhotoBack
    let photoSideChanged = editedPhotoSide != progressModel.dataPhotoSide
    let hasPhotoChanges = photoFrontChanged || photoBackChanged || photoSideChanged
    
    // Возвращаем true если есть изменения в метриках ИЛИ в фотографиях
    return hasMetricChanges || hasPhotoChanges
}
```

### 6. Обновление computed property canSave

**Файл:** `SwiftUI-SotkaApp/Services/ProgressService.swift`

Дополнить `canSave` для учета данных фотографий:

```swift
var canSave: Bool {
    // Проверяем, что есть хотя бы одно заполненное поле или фото
    let hasTextData = [pullUps, pushUps, squats, weight].contains { !$0.isEmpty }
    
    // Проверяем наличие фотографий (включая временные)
    let hasPhotoData = editedPhotoFront != nil || editedPhotoBack != nil || editedPhotoSide != nil ||
                       progressModel.hasAnyPhotoData
    
    // ... остальная валидация ...
}
```

### 7. Удаление старых методов addPhoto и deletePhoto

**Файл:** `SwiftUI-SotkaApp/Services/ProgressService.swift`

Удалить методы `addPhoto()` и `deletePhoto()` из секции `// MARK: - Photo Management`, так как они больше не нужны (сохранение будет через `saveProgress()`).

### 8. Обновление EditProgressPhotoScreen

**Файл:** `SwiftUI-SotkaApp/Screens/Profile/Progress/EditProgressPhotoScreen.swift`

Изменить логику обработки действий с фотографиями:

```swift
// В методе makeImagePickerView:
func makeImagePickerView(for sourceType: UIImagePickerController.SourceType) -> some View {
    SWImagePicker(sourceType: sourceType) { image in
        if let selectedPhotoType {
            let processedData = ImageProcessor.processImage(image)
            // ❌ УДАЛИТЬ: try progressService.addPhoto(...)
            // ✅ НОВАЯ ЛОГИКА: сохраняем во временные свойства
            progressService.setTemporaryPhoto(processedData, type: selectedPhotoType)
            logger.info("Фотография \(selectedPhotoType.localizedTitle) сохранена во временные данные")
        }
    }
    .ignoresSafeArea()
}

// В deleteDialogContent:
var deleteDialogContent: some View {
    Button("Common.Delete", role: .destructive) {
        if let photoToDelete {
            // ❌ УДАЛИТЬ: try progressService.deletePhoto(...)
            // ✅ НОВАЯ ЛОГИКА: помечаем для удаления во временных данных
            progressService.markPhotoForDeletion(photoToDelete)
            logger.info("Фотография \(photoToDelete.localizedTitle) помечена для удаления во временных данных")
        } else {
            logger.warning("Попытка удаления фотографии, но photoToDelete = nil")
        }
    }
}
```

### 9. Обновление ProgressPhotoRow для работы с временными данными

**Файл:** `SwiftUI-SotkaApp/Screens/Profile/Progress/ProgressPhotoRow.swift`

Изменить сигнатуру `ProgressPhotoRow` и передавать временные данные через параметры:

```swift
struct ProgressPhotoRow: View {
    let progress: Progress
    let photoType: PhotoType
    let onPhotoTap: (Action) -> Void
    
    // Новые параметры для временных данных
    let temporaryPhotoData: Data? // Временные данные фотографии из ProgressService
    let isMarkedForDeletion: Bool // Флаг удаления из ProgressService
    
    // Обновить imageView для отображения временных данных
    @ViewBuilder
    var imageView: some View {
        ZStack {
            // ПРИОРИТЕТ 1: Временные данные из ProgressService
            if let tempData = temporaryPhotoData,
               let uiImage = UIImage(data: tempData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
            }
            // ПРИОРИТЕТ 2: Локальные данные из Progress (если временные не менялись)
            else if let photoData = progress.getPhotoData(photoType),
                    let uiImage = UIImage(data: photoData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
            }
            // ПРИОРИТЕТ 3: URL с сервера (если нет локальных)
            else if progress.getPhotoURL(photoType) != nil, !isMarkedForDeletion {
                AsyncImage(url: URL(string: progress.getPhotoURL(photoType) ?? "")) { ... }
            }
            // ПРИОРИТЕТ 4: Placeholder (нет изображения)
            else {
                Image(systemName: "photo")
                    .font(.title)
                    .frame(maxHeight: .infinity)
            }
        }
        // ... остальная разметка ...
    }
}
```

**В EditProgressPhotoScreen при использовании ProgressPhotoRow:**

```swift
var listView: some View {
    List(PhotoType.allCases, id: \.self) { photoType in
        ProgressPhotoRow(
            progress: progressService.progress,
            photoType: photoType,
            onPhotoTap: { action in
                // ... обработка действий ...
            },
            temporaryPhotoData: progressService.getTemporaryPhoto(photoType),
            isMarkedForDeletion: progressService.isPhotoMarkedForDeletion(photoType)
        )
        .listRowSeparator(.hidden)
    }
    .listStyle(.plain)
    .background(Color.swBackground)
}
```

### 10. Обновление ProgressGridView (опционально)

**Файл:** `SwiftUI-SotkaApp/Screens/Profile/Progress/ProgressGridView.swift`

Для просмотра прогресса (`ProgressGridView`) временные данные НЕ нужны - там отображаются только сохраненные фотографии из модели `Progress`. Изменения не требуются.

## Преимущества подхода

1. **Консистентность**: Работа с фотографиями аналогична работе с метриками (pullUps, pushUps, squats, weight)
2. **Отмена изменений**: Пользователь может выйти из экрана без сохранения, изменения не применятся
3. **Единая точка сохранения**: Все изменения (метрики + фотографии) сохраняются одной транзакцией
4. **UX улучшение**: Кнопка `saveButton` становится активной при изменении фотографий
5. **Безопасность данных**: Нет риска сохранить половину изменений (метрики без фотографий или наоборот)

## Порядок реализации

1. Добавить новые свойства в `ProgressService` (editedPhotoFront, editedPhotoBack, editedPhotoSide)
2. Обновить `loadProgress()` для загрузки фотографий в временные свойства
3. Добавить методы для работы с временными данными фотографий (setTemporaryPhoto, markPhotoForDeletion, getTemporaryPhoto, isPhotoMarkedForDeletion)
4. Создать приватный метод `applyPhotoChanges()` для применения изменений фотографий
5. Обновить `saveProgress()` для вызова `applyPhotoChanges()`
6. Обновить `hasChanges` и `canSave` computed properties
7. Удалить старые методы `addPhoto()` и `deletePhoto()`
8. Обновить `EditProgressPhotoScreen` для использования временных данных
9. Обновить `ProgressPhotoRow` - добавить параметры temporaryPhotoData и isMarkedForDeletion
10. Протестировать все сценарии (добавление, удаление, отмена, сохранение)

## Тестовые сценарии

1. **Добавление фотографии**: добавить фото → НЕ нажимать Save → выйти → фото не сохранено
2. **Удаление фотографии**: удалить фото → НЕ нажимать Save → выйти → фото осталось
3. **Сохранение фотографии**: добавить фото → нажать Save → фото сохранено в SwiftData
4. **Смешанные изменения**: изменить метрики + добавить фото → Save → все сохранено
5. **Кнопка Save**: при добавлении/удалении фото кнопка становится активной
6. **Валидация**: можно сохранить прогресс только с фотографией (без метрик)