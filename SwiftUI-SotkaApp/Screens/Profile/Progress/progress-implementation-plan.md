# Экран прогресса (Progress)

Этот документ описывает реализованный функционал экрана прогресса, включая интеграцию фотографий, устройство локального хранения, офлайн-приоритет и логику сервисов.

## Реализованный функционал (кратко)

### Основные данные прогресса ✅
- **Сетка прогресса**: отображение результатов по контрольным точкам (день 1, 49, 100) с группировкой по типам упражнений
- **Редактирование**: форма ввода результатов (подтягивания, отжимания, приседания, вес) с валидацией
- **Создание/обновление**: локальное сохранение в SwiftData, последующая синхронизация в фоне
- **Удаление**: мягкое удаление (soft delete) — элемент помечается флагом, сразу скрывается из UI
- **Навигация**: переходы сетка → редактирование с сохранением состояния
- **Интеграция с главным экраном**: секция "Заполнить результаты" появляется при отсутствии активного прогресса

### Интеграция фотографий прогресса ✅
- **Типы фотографий**: фронтальная, сзади, сбоку для каждой контрольной точки (день 1, 49, 100)
- **Хранение**: локальные бинарные данные в SwiftData + URL для синхронизации
- **Обработка изображений**: `ImageProcessor` для масштабирования (1280x720) и сжатия JPEG (100%)
- **UI компоненты**: `ProgressPhotoView`, `ProgressPhotoPicker`, `ProgressPhotoGrid`
- **Синхронизация**: multipart/form-data загрузка через `ProgressClient`
- **Офлайн-приоритет**: все операции сначала локально, синхронизация асинхронно в фоне
- **Изменение фотографий**: ✅ корректно работает - при синхронизации новая фотография отправляется на сервер и заменяет прежнюю

### Модель данных
- **Progress**: основные данные (pullUps, pushUps, squats, weight) + метаданные синхронизации
- **ProgressPhoto**: модель для фотографий (удалена в пользу единой архитектуры)
- **ProgressRequest/Response**: модели для сетевого обмена данными

### Сервисы
- **ProgressService**: управление данными прогресса и валидация
- **ProgressSyncService**: двунаправленная синхронизация с сервером
- **ImageProcessor**: обработка изображений (масштабирование, сжатие, валидация)
- **PhotoDownloadService**: автоматическая загрузка фотографий по URL (структура)

### Архитектура синхронизации
- **Офлайн-приоритет**: локальные изменения сохраняются сразу, синхронизация асинхронная
- **LWW конфликты**: разрешение по `lastModified` дате
- **Параллельная обработка**: конкурентная синхронизация через TaskGroup
- **Снимки данных**: `ProgressSnapshot` для передачи данных между потоками

### Валидация и UI улучшения
- **Валидация ввода**: реальное время, поддержка запятой/точки, запрет множественных разделителей
- **Частичное заполнение**: разрешены неполные данные (как в Android приложении)
- **Отключение кнопок**: прогресс недоступен до наступления соответствующего дня программы
- **Локализация**: все тексты на русском языке

### Тестирование
- **361 unit-тест** для всех компонентов (модели, сервисы, валидация)
- **Тесты синхронизации** с моками сетевых клиентов
- **Edge case тесты** для валидации ввода и обработки ошибок

### Проблемы и исправления ✅
- **Исправлена логика дней**: день 49 вместо дня 50 для среднего прогресса
- **Упрощена синхронизация**: единый `updateProgress` вместо двойной попытки
- **Исправлена валидация**: частично заполненные данные теперь валидны
- **Исправлено удаление**: мягкое удаление вместо физического (с сохранением информации для сервера)

## Критическая проблема: удаление фотографий

### Текущая проблема ❌

**Ситуация**: Невозможно удалить выборочную фотографию из прогресса без удаления всего прогресса целиком.

**Текущее поведение:**
1. **Локальное удаление**: фотография физически удаляется из массива `progress.photos`
2. **Отсутствие информации для сервера**: при создании снимка для синхронизации проверяется `hasPhotosToDelete = progress.photos.contains { $0.isDeleted }`, но после физического удаления фото НЕТ в массиве
3. **Повторное появление**: при синхронизации сервер возвращает все фотографии (включая "удаленные"), и они создаются заново в локальной базе

**Доступные операции:**
- ✅ Удалить весь прогресс целиком (удаляются все данные + все фото)
- ✅ Удалить единственную фотографию в прогрессе (удаляется весь прогресс)
- ✅ Изменить существующую фотографию (новая корректно отправляется на сервер и заменяет прежнюю)
- ❌ Удалить выборочную фотографию без удаления других данных прогресса

### Анализ реализации в старом приложении (SOTKA-OBJc)

**Архитектура хранения в старом приложении:**
```objective-c
// В модели DbUser (CoreData)
@property (nonatomic, retain) NSData * photoFront;
@property (nonatomic, retain) NSData * photoBack; 
@property (nonatomic, retain) NSData * photoSide;
```

**Логика удаления в старом приложении:**
```objective-c
- (void) deleteProgressForDay:(NSInteger) day {
    DbUser* progress = [DbUser fetchForDay:day];
    if (progress == nil) return;

    progress.shouldDelete = YES;
    progress.synched = NO;

    // Специальное значение DELETED для каждой фотографии
    progress.photoBack = DELETED;
    progress.photoFront = DELETED;
    progress.photoSide = DELETED;
}
```

**Синхронизация в старом приложении:**
```objective-c
- (void) syncProgress:(void (^)(void))finish failure:(void (^)(void))failure {
    // Последовательная обработка по одной записи
    
    if (progress.shouldDelete) {
        // Удалить весь прогресс
        [progress deleteProgressForDay:[progress.day intValue] finish:...];
        return;
    }

    if ([progress.photoFront isEqualToData:DELETED]) {
        // Удалить фронтальную фотографию
        [DbUser deleteFrontPhotoForDay:[progress.day intValue] success:...];
        return;
    }
    // Аналогично для photoBack и photoSide
    
    // Загрузить прогресс на сервер
    [progress upload:...];
}
```

**Ключевые особенности старого подхода:**
1. **Фотографии хранятся как NSData** в полях модели (не отдельная модель)
2. **Специальное значение DELETED** для пометки удаленных фотографий
3. **Последовательная синхронизация** - обработка по одному элементу за раз
4. **Индивидуальные запросы** для удаления каждой фотографии отдельно
5. **Сохранение информации об удалении** до успешной синхронизации с сервером

### План исправления для нового приложения

#### Этап 1: Анализ текущей архитектуры
**Проблема текущей архитектуры:** Разделение на модели `Progress` и `ProgressPhoto` создает сложности синхронизации.

**Текущее состояние:**
- Модель `Progress` содержит прямые поля для хранения данных фотографий (dataPhotoFront, dataPhotoBack, dataPhotoSide)
- Сервер возвращает единый ответ с URL фотографий в модели ProgressResponse

**Целевая архитектура:** Единая модель `Progress` с прямыми полями для данных изображений.

#### Этап 2: Изменение архитектуры хранения фотографий

**Изменения в модели Progress:**
```swift
@Model
final class Progress {
    // Существующие поля...

    // URL фотографий с сервера
    var urlPhotoFront: String?
    var urlPhotoBack: String?
    var urlPhotoSide: String?

    // Данные изображений (скачиваются по URL)
    var dataPhotoFront: Data?
    var dataPhotoBack: Data?
    var dataPhotoSide: Data?

    // Методы для работы с данными изображений
    func setPhotoData(_ type: PhotoType, data: Data) {
        switch type {
        case .front: dataPhotoFront = data
        case .back: dataPhotoBack = data
        case .side: dataPhotoSide = data
        }
        lastModified = Date()
        isSynced = false
    }

    // Получает данные изображения, возвращает nil для удаленных данных
    func getPhotoData(_ type: PhotoType) -> Data? {
        let data: Data?
        switch type {
        case .front: data = dataPhotoFront
        case .back: data = dataPhotoBack
        case .side: data = dataPhotoSide
        }
        // Возвращаем nil для удаленных данных
        return data == DELETED_DATA ? nil : data
    }
}
```

**Преимущества новой архитектуры:**
- ✅ Единая модель данных (как в старом приложении)
- ✅ Простая синхронизация (перезапись URL + скачивание данных)
- ✅ Данные изображений загружаются только при необходимости
- ✅ Экономия памяти и трафика
- ✅ Совместимость с Android приложением
- ✅ Корректное изменение фотографий (новая заменяет прежнюю на сервере)

#### Этап 3: Реализация логики удаления фотографий

**Шаг 3.1: Специальное значение для удаления**
```swift
// Константа для пометки удаленных фотографий
private let DELETED_DATA = "deleted:".data(using: .utf8)!
```

**Шаг 3.2: Логика удаления в ProgressService**
```swift
func deletePhoto(_ type: PhotoType, from progress: Progress) throws {
    switch type {
    case .front:
        progress.dataPhotoFront = DELETED_DATA
        progress.urlPhotoFront = nil
    case .back:
        progress.dataPhotoBack = DELETED_DATA
        progress.urlPhotoBack = nil
    case .side:
        progress.dataPhotoSide = DELETED_DATA
        progress.urlPhotoSide = nil
    }
    
    progress.lastModified = Date()
    progress.isSynced = false
    try context.save()
}
```

**Шаг 3.3: Синхронизация удаления**
```swift
// В ProgressSyncService
private func prepareProgressDataWithPhotos(_ progress: Progress) -> ProgressRequest {
    var photosData: [String: Data] = [:]
    
    // Отправляем только не удаленные фотографии
    if let frontData = progress.dataPhotoFront, !frontData.isEqual(to: DELETED_DATA) {
        photosData["photo_front"] = frontData
    }
    // Аналогично для back и side
    
    return ProgressRequest(
            id: progress.id,
            pullups: progress.pullUps,
            pushups: progress.pushUps,
            squats: progress.squats,
            weight: progress.weight,
        photos: photosData  // Только не удаленные фото
    )
}
```

**Шаг 3.4: Обработка ответа сервера**
```swift
// В ProgressSyncService
func updateProgressFromServerResponse(_ progress: Progress, _ response: ProgressResponse) async {
    // Обновляем URL фотографий только если они не помечены для удаления локально
    if !progress.shouldDeletePhotoFront {
        progress.urlPhotoFront = response.photoFront
    } else if response.photoFront == nil || response.photoFront?.isEmpty == true {
        // Сервер успешно удалил фото - очищаем локальный URL
        progress.urlPhotoFront = nil
        progress.shouldDeletePhotoFront = false
    }
    // Аналогично для photoBack и photoSide...

    // Загружаем фотографии синхронно
    await PhotoDownloadService().downloadAllPhotos(for: progress)

    progress.isSynced = true
}
```

#### Этап 4: UI обновления

**Обновление ProgressPhotoRow:**
```swift
struct ProgressPhotoRow: View {
    let progress: Progress
    let type: PhotoType

    var body: some View {
        // Показываем данные изображения или загружаем по URL
        if let photoData = progress.getPhotoData(type),
           let uiImage = UIImage(data: photoData) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFill()
        } else if let urlString = progress.getPhotoURL(type) {
            CachedImage(
                url: URL(string: urlString),
                mode: .userListItem,
                didTapImage: { uiImage in
                    // Обработка нажатия на изображение (опционально)
                    // Здесь можно добавить логику показа полноразмерного изображения
                }
            )
        } else {
            Image(systemName: "photo")
                .foregroundColor(.gray)
        }
    }
}
```

#### Этап 5: Удаление модели ProgressPhoto

**Полное удаление:**
- Удалить файл `Models/ProgressPhoto.swift`
- Удалить модель из схемы SwiftData
- Очистить все ссылки и импорты
- Обновить тесты

#### Этап 6: Замена AsyncImage на CachedImage

**Заменить AsyncImage на CachedImage из SWDesignSystem:**

**Преимущества CachedImage:**
- Автоматическое кэширование загруженных изображений в памяти и на диске
- Уменьшение сетевого трафика при повторных загрузках
- Лучшая производительность при прокрутке списков
- Автоматическая обработка ошибок загрузки с встроенным placeholder
- Предустановленные режимы отображения для разных размеров

**Задачи:**
- Импортировать CachedImage из SWDesignSystem
- Заменить все использования AsyncImage на CachedImage
- Выбрать подходящий режим отображения (.userListItem, .profileAvatar и т.д.)
- Настроить обработку нажатий на изображения (опционально)
- Убедиться в корректной работе кэширования

### Преимущества исправления

| Аспект | Текущее состояние | После исправления |
|--------|------------------|-------------------|
| Архитектура | Разделенные модели | Единая модель |
| Синхронизация | Сложная обработка фото | Простая перезапись URL |
| Удаление фото | Физическое удаление | Специальное значение DELETED |
| Загрузка фото | По необходимости | CachedImage с кэшированием |
| Производительность | Ниже (доп. объекты) | Выше (меньше объектов) |
| Надежность | Средняя (конфликты) | Высокая (сервер источник истины) |

### Риски и ограничения

1. **Миграция данных**: Необходимо тщательно протестировать миграцию существующих данных
2. **Совместимость сервера**: Убедиться, что сервер корректно обрабатывает nil значения для удаленных фотографий
3. **Управление памятью**: Локальные данные изображений могут занимать значительное место при загрузке
4. **Откат**: Подготовить план отката в случае проблем

### Метрики успеха

- ✅ Возможность удаления отдельных фотографий без удаления прогресса
- ✅ Удаленные фотографии не восстанавливаются при синхронизации
- ✅ Фотографии загружаются и кэшируются автоматически через CachedImage
- ✅ Данные изображений сохраняются локально в кэш CachedImage
- ✅ Все операции выполняются асинхронно без блокировки UI
- ✅ Изображения кэшируются для лучшей производительности
```
