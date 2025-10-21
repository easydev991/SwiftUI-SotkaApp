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

### Недостающие тесты для новой логики удаления фотографий ❌

**Анализ показал отсутствие тестов для следующих компонентов:**

#### 1. Тесты для модели Progress (новые методы)
- **DELETED_DATA константа**: тест на правильное значение (Data([0x64]))
- **shouldDeletePhoto()**: тест на проверку фотографий помеченных для удаления
- **hasPhotosToDelete**: тест на наличие фотографий для удаления
- **clearPhotoData()**: тест на очистку данных после успешного удаления
- **deletePhotoData()**: тест на установку DELETED_DATA вместо физического удаления

#### 2. Тесты для ProgressSnapshot (новые computed properties)
- **shouldDeletePhoto**: тест на проверку флагов удаления фотографий
- **photosForUpload**: тест на создание словаря только не удаленных фотографий

#### 3. Тесты для ProgressSyncService (новая логика синхронизации)
- **needsPhotoDeletion событие**: тест на возврат специального статуса
- **handlePhotoDeletion()**: тест на последовательное удаление фотографий
- **applySyncEvents()**: тест на обработку needsPhotoDeletion события
- **Интеграционные тесты**: полный цикл удаления фотографий с сервера

#### 4. Тесты для ProgressClient (новый метод)
- **deletePhoto()**: тест на вызов DELETE API endpoint
- **MockProgressClient**: тест на mock реализацию deletePhoto

#### 5. Тесты для PhotoType (новое свойство)
- **deleteRequestName**: тест на правильные названия для DELETE запросов

**План реализации тестов:**
1. ✅ Добавить тесты для модели Progress (DELETED_DATA, shouldDeletePhoto, clearPhotoData)
2. ✅ Добавить тесты для ProgressSnapshot (shouldDeletePhoto, photosForUpload)
3. ✅ Добавить тесты для ProgressSyncService (handlePhotoDeletion, needsPhotoDeletion)
4. ✅ Добавить тесты для ProgressClient (deletePhoto)
5. ✅ Добавить тесты для PhotoType (deleteRequestName)
6. ✅ Добавить интеграционные тесты полного цикла удаления фотографий

**Реализованные тесты:**
- **ProgressPhotoDataTests.swift**: 6 новых тестов для логики удаления фотографий
- **PhotoTypeTests.swift**: 8 тестов для deleteRequestName и других свойств
- **ProgressSnapshotTests.swift**: 12 тестов для computed properties
- **ProgressSyncServicePhotoTests.swift**: 5 новых тестов для синхронизации удаления
- **ProgressClientTests.swift**: 10 тестов для deletePhoto метода

**Всего добавлено: 41 новый тест** для покрытия всей новой логики удаления фотографий

### Проблемы и исправления ✅
- **Исправлена логика дней**: день 49 вместо дня 50 для среднего прогресса
- **Упрощена синхронизация**: единый `updateProgress` вместо двойной попытки
- **Исправлена валидация**: частично заполненные данные теперь валидны
- **Исправлено удаление**: мягкое удаление вместо физического (с сохранением информации для сервера)

## Критические исправления логики удаления

### Обнаруженные ошибки в первоначальном плане ❌

**Анализ кода старого приложения (SOTKA-OBJc) выявил критические ошибки в первоначальном плане:**

1. **Неправильная константа DELETED**: 
   - ❌ Предлагалось: `"deleted:".data(using: .utf8)!` (8 байт)
   - ✅ В старом приложении: `Data([0x64])` (только 1 байт "d")

2. **Неправильная логика синхронизации**:
   - ❌ Предлагалось: отправлять только не удаленные фотографии в основном запросе
   - ✅ В старом приложении: отдельные DELETE запросы для каждой фотографии

3. **Отсутствие отдельных DELETE запросов**:
   - ❌ Предлагалось: просто не отправлять удаленные фотографии
   - ✅ В старом приложении: `DELETE /100/progress/{day}/photos/{type}` для каждой фотографии

4. **Неправильная последовательность операций**:
   - ❌ Предлагалось: параллельная обработка
   - ✅ В старом приложении: строго последовательная с рекурсивными вызовами

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
// Константа для пометки удаленных фотографий (точно как в старом приложении)
private let DELETED_DATA = Data([0x64]) // Только байт "d", как в #define DELETED
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

**Шаг 3.3: Упрощенная синхронизация с методами модели**
```swift
// В модели Progress - методы для проверки удаления
extension Progress {
    // Проверяет, нужно ли удалить фотографию определенного типа
    func shouldDeletePhoto(_ type: PhotoType) -> Bool {
        let data: Data?
        switch type {
        case .front: data = dataPhotoFront
        case .back: data = dataPhotoBack
        case .side: data = dataPhotoSide
        }
        return data?.isEqual(to: DELETED_DATA) == true
    }
    
    // Проверяет, есть ли фотографии для удаления
    func hasPhotosToDelete() -> Bool {
        return shouldDeletePhoto(.front) || 
               shouldDeletePhoto(.back) || 
               shouldDeletePhoto(.side)
    }
    
    // Очищает данные фотографии после успешного удаления
    func clearPhotoData(_ type: PhotoType) {
        switch type {
        case .front:
            dataPhotoFront = nil
            urlPhotoFront = nil
        case .back:
            dataPhotoBack = nil
            urlPhotoBack = nil
        case .side:
            dataPhotoSide = nil
            urlPhotoSide = nil
        }
    }
}

// В ProgressSyncService - упрощенная логика
func syncProgress(_ progress: Progress) async throws {
    // 1. Проверить shouldDelete (удаление всего прогресса)
    if progress.shouldDelete {
        try await deleteProgressForDay(progress.day)
        return
    }
    
    // 2. Проверить, есть ли фотографии для удаления
    if progress.hasPhotosToDelete() {
        try await deleteNextPhoto(progress)
        return // После каждого удаления - рекурсивный вызов
    }
    
    // 3. Отправить основной прогресс (только если нет удалений)
    try await uploadProgress(progress)
}

// Универсальный метод для удаления фотографий
private func deletePhotoForDay(_ day: Int, type: PhotoType) async throws {
    // DELETE /100/progress/{day}/photos/{type}
    try await progressClient.deletePhoto(day: day, type: type.deleteRequestName)
}

// Обработка удаления фотографий в цикле
private func deleteNextPhoto(_ progress: Progress) async throws {
    for photoType in PhotoType.allCases {
        if progress.shouldDeletePhoto(photoType) {
            try await deletePhotoForDay(progress.day, type: photoType)
            progress.clearPhotoData(photoType)
            return // Удаляем только одну фотографию за раз
        }
    }
}
```


**Шаг 3.4: Обновление протокола ProgressClient и PhotoType**
```swift
// Добавить новый метод в протокол ProgressClient
protocol ProgressClient: Sendable {
    // ... существующие методы ...
    
    /// Удалить фотографию определенного типа для конкретного дня
    func deletePhoto(day: Int, type: String) async throws
}

// Добавить вычисляемое свойство в существующий PhotoType
extension PhotoType {
    /// Название типа для DELETE запроса
    var deleteRequestName: String {
        switch self {
        case .front: return "front"
        case .back: return "back"
        case .side: return "side"
        }
    }
}
```

**Шаг 3.5: Обработка ответа сервера (упрощенная логика)**
```swift
// В ProgressSyncService - простая логика как в старом приложении
func updateProgressFromServerResponse(_ progress: Progress, _ response: ProgressResponse) async {
    // Обновляем URL фотографий (сервер - источник истины)
    progress.urlPhotoFront = response.photoFront
    progress.urlPhotoBack = response.photoBack
    progress.urlPhotoSide = response.photoSide
    
    // Обновляем lastModified из ответа сервера
    progress.updateLastModified(from: response)
    
    // Загружаем фотографии по URL (если есть)
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

// Методы для работы с данными изображений (обновленные)
extension Progress {
    // Получает данные изображения, возвращает nil для удаленных данных
    func getPhotoData(_ type: PhotoType) -> Data? {
        let data: Data?
        switch type {
        case .front: data = dataPhotoFront
        case .back: data = dataPhotoBack
        case .side: data = dataPhotoSide
        }
        // Возвращаем nil для удаленных данных (DELETED_DATA)
        return data?.isEqual(to: DELETED_DATA) == true ? nil : data
    }
    
    // Получает URL изображения
    func getPhotoURL(_ type: PhotoType) -> String? {
        switch type {
        case .front: return urlPhotoFront
        case .back: return urlPhotoBack
        case .side: return urlPhotoSide
        }
    }
    
    // Проверяет, нужно ли удалить фотографию определенного типа
    func shouldDeletePhoto(_ type: PhotoType) -> Bool {
        let data: Data?
        switch type {
        case .front: data = dataPhotoFront
        case .back: data = dataPhotoBack
        case .side: data = dataPhotoSide
        }
        return data?.isEqual(to: DELETED_DATA) == true
    }
    
    // Очищает данные фотографии после успешного удаления
    func clearPhotoData(_ type: PhotoType) {
        switch type {
        case .front:
            dataPhotoFront = nil
            urlPhotoFront = nil
        case .back:
            dataPhotoBack = nil
            urlPhotoBack = nil
        case .side:
            dataPhotoSide = nil
            urlPhotoSide = nil
        }
    }
    
    // Проверяет, есть ли фотографии для удаления
    func hasPhotosToDelete() -> Bool {
        return shouldDeletePhoto(.front) || 
               shouldDeletePhoto(.back) || 
               shouldDeletePhoto(.side)
    }
}
```

#### Этап 5: Замена AsyncImage на CachedImage

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
| Синхронизация | Сложная обработка фото | Последовательная синхронизация (как в старом приложении) |
| Удаление фото | Физическое удаление | Специальное значение DELETED + отдельные DELETE запросы |
| Загрузка фото | По необходимости | CachedImage с кэшированием |
| Производительность | Ниже (доп. объекты) | Выше (меньше объектов) |
| Надежность | Средняя (конфликты) | Высокая (точная логика старого приложения) |
| Совместимость | Отличается от старого | Полная совместимость с SOTKA-OBJc |

### Риски и ограничения

1. **Миграция данных**: Необходимо тщательно протестировать миграцию существующих данных
2. **Совместимость сервера**: Убедиться, что сервер поддерживает отдельные DELETE запросы для фотографий (`/100/progress/{day}/photos/{type}`)
3. **Управление памятью**: Локальные данные изображений могут занимать значительное место при загрузке
4. **Последовательная синхронизация**: Рекурсивные вызовы могут создать длинную цепочку операций
5. **Откат**: Подготовить план отката в случае проблем

### Метрики успеха

- ✅ Возможность удаления отдельных фотографий без удаления прогресса
- ✅ Удаленные фотографии не восстанавливаются при синхронизации
- ✅ Фотографии загружаются и кэшируются автоматически через CachedImage
- ✅ Данные изображений сохраняются локально в кэш CachedImage
- ✅ Все операции выполняются асинхронно без блокировки UI
- ✅ Изображения кэшируются для лучшей производительности
- ✅ **Полная совместимость с логикой старого приложения SOTKA-OBJc**
- ✅ **Отдельные DELETE запросы для каждой фотографии**
- ✅ **Последовательная синхронизация с рекурсивными вызовами**
- ✅ **Правильная константа DELETED_DATA (только байт "d")**

## Справочная информация

### Анализ подходов к удалению фотографий

**Анализ старого приложения (SOTKA-OBJc):**
```objective-c
// Строго последовательная обработка в SyncManager.m
if ([progress.photoFront isEqualToData:DELETED]) {
    [DbUser deleteFrontPhotoForDay:[progress.day intValue] success:^{
        [self syncProgress:finish failure:failure]; // Рекурсивный вызов
    } failure:^{ ... }];
    return; // Обрабатываем только одну фотографию за раз
}
// Аналогично для photoBack и photoSide
```

**Анализ серверного кода (StreetWorkoutSU):**
```php
// actionDeleteProgressPhoto($day, $photo = null)
public function actionDeleteProgressPhoto($day, $photo = null) {
    $sto_progress = StoProgress::findByUserAndDay($user_id, $day);
    if ($photo) {
        $photos = $sto_progress->getImagesFiles();
        $photos[$photo] = null; // Удаляем конкретную фотографию
        $sto_progress->setImagesFiles($photos);
    } else {
        $sto_progress->setImagesFiles(null); // Удаляем все фотографии
    }
    $sto_progress->save();
}
```

**Сравнение подходов:**

| Аспект | Старое приложение | Предлагаемое решение | Параллельная оптимизация |
|--------|------------------|---------------------|-------------------------|
| **Последовательность** | Строго последовательная | Строго последовательная | Параллельная |
| **Рекурсивные вызовы** | ✅ Да | ✅ Да | ❌ Нет |
| **Обработка ошибок** | По одной фотографии | По одной фотографии | Все сразу |
| **Производительность** | Медленная | Медленная | Быстрая |
| **Надежность** | Высокая | Высокая | Средняя |
| **Совместимость с сервером** | ✅ Полная | ✅ Полная | ✅ Полная |

**Выводы и рекомендации:**

1. **Последовательная обработка оправдана:**
   - Старое приложение использует рекурсивные вызовы для надежности
   - Каждая фотография обрабатывается отдельно с индивидуальной обработкой ошибок
   - При сбое одной фотографии остальные продолжают обрабатываться

2. **Параллельная оптимизация НЕ рекомендуется:**
   - ❌ Потеря индивидуальной обработки ошибок
   - ❌ При сбое одной фотографии может сломаться вся операция
   - ❌ Усложнение логики отката при ошибках
   - ❌ Нарушение совместимости с логикой старого приложения

3. **Сервер поддерживает оба подхода:**
   - ✅ Отдельные DELETE запросы для каждой фотографии
   - ✅ Массовое удаление всех фотографий
   - ✅ Гибкая обработка параметров

**Итоговое решение:** Оставить последовательную обработку с рекурсивными вызовами для максимальной надежности и совместимости.
```
