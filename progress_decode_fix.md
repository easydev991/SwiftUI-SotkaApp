# Анализ проблемы декодирования прогресса и план исправления

## Описание проблемы

В логах наблюдается ошибка декодирования при загрузке прогресса с сервера:
- **Код ответа**: 200 (успешный)
- **Ошибка**: "Не удалось декодировать ответ" (код ошибки 9)
- **URL**: `https://workout.su/api/v3/100/progress/49` и `https://workout.su/api/v3/100/progress`

### Проблемные сценарии:
1. **Загрузка конкретного дня прогресса** (49) - возвращает пустой ответ
2. **Загрузка всего списка прогресса** - возвращает корректный JSON, но декодирование не удается
3. **Фотографии не загружаются и не удаляются** в новом приложении
4. **Изменения из старого приложения корректно синхронизируются**, но из нового - нет

## Анализ JSON ответов

### Ответ при получении списка прогресса (GET /100/progress):
```json
[
    {
        "id": 1,
        "pullups": 0,
        "pushups": 0,
        "squats": 0,
        "weight": 0,
        "create_date": "2025-10-18T22:41:06+03:00",
        "modify_date": "2025-10-19T01:40:57+03:00",
        "photo_back": "https://workout.su/uploads/userfiles/2025/10/2025-10-18-15-10-37-jp9.jpg",
        "photo_front": "https://workout.su/uploads/userfiles/2025/10/2025-10-18-15-10-14-cqw.jpg"
    },
    {
        "id": 49,
        "pullups": 12,
        "pushups": 22,
        "squats": 33,
        "weight": 0,
        "create_date": "2025-10-18T23:03:58+03:00",
        "modify_date": "2025-10-19T02:03:51+03:00"
    }
]
```

### Ответ при создании/изменении прогресса (POST /100/progress):
```json
{
    "id": "1",
    "pullups": "2",
    "pushups": "6",
    "squats": "10",
    "weight": "80",
    "create_date": "2025-05-11T18:41:24+03:00",
    "modify_date": null
}
```

### Ответ при получении конкретного дня (GET /100/progress/49):
```json
{
    "squats": "33",
    "weight": "0.0",
    "id": "49",
    "create_date": "2025-10-18T23:00:01+03:00",
    "pullups": "12",
    "pushups": "22",
    "modify_date": "2025-10-19T01:59:52+03:00"
}
```

## Сравнительный анализ реализаций

### 1. Старое iOS приложение (SOTKA-OBJc)

**Архитектура:**
- Использует **RestKit** для автоматического маппинга JSON → Core Data
- **DbUser** модель с полями: `day`, `pullups`, `pushups`, `squats`, `weight`, `photoFront`, `photoBack`, `photoSide`
- **SyncManager** управляет синхронизацией через RestKit
- **Автоматическое декодирование** через RestKit маппинги

**Особенности:**
- RestKit автоматически обрабатывает различные типы данных
- Фотографии хранятся как `Binary` данные в Core Data
- Синхронизация происходит через RestKit операции
- **Код закомментирован** - старая реализация неактивна

### 2. Android приложение (Android-SOTKA)

**Архитектура:**
- **Gson** для JSON десериализации
- **ProgressSyncDTO** с полями: `dayNumber`, `pullUps`, `pushUps`, `squats`, `weight`, `urlPhotoFront`, `urlPhotoBack`, `urlPhotoSide`
- **SyncInteractorImpl** обрабатывает синхронизацию
- **ProgressViewModel** управляет фотографиями локально

**Особенности:**
- Gson автоматически конвертирует строки в числа
- Фотографии загружаются отдельно и сохраняются локально
- **Корректно работает** с сервером

### 3. Новое iOS приложение (SwiftUI-SotkaApp)

**Архитектура:**
- **Swift Codable** для декодирования
- **ProgressResponse** модель с кастомным декодером
- **SWNetworkService** с JSONDecoder
- **ProgressSyncService** управляет синхронизацией

**Проблемы:**
- Кастомный декодер не обрабатывает все случаи
- Отсутствует обработка пустых ответов
- Неправильная обработка фотографий

## Выявленные проблемы

### 1. Проблема с декодированием

**Корень проблемы:**
- **SWNetworkService** использует `JSONDecoder` с `convertFromSnakeCase` стратегией
- **ProgressResponse** имеет кастомный декодер, который конфликтует с автоматической стратегией
- **Двойное декодирование** - сначала автоматическое, потом кастомное
- **Разные форматы ответов** - сервер возвращает разные типы данных в зависимости от операции

**Конкретные ошибки:**
```swift
// В SWNetworkService
decoder.keyDecodingStrategy = .convertFromSnakeCase  // Автоматически конвертирует snake_case

// В ProgressResponse
case createDate = "create_date"  // Ручной маппинг конфликтует с автоматическим
```

**Проблема с разными форматами:**
- **GET /100/progress** (список) - возвращает числа: `"id": 1, "pullups": 0`
- **POST/PUT /100/progress** (создание/изменение) - возвращает строки: `"id": "1", "pullups": "2"`
- **GET /100/progress/49** (конкретный день) - возвращает строки: `"id": "49", "pullups": "12"`
- **Отсутствие полей** - в некоторых ответах нет `photo_front`, `photo_back`, `photo_side`

### 2. Проблема с пустыми ответами и 404 ошибками

**Проблема:**
- Запрос `/100/progress/49` возвращает **404 ошибку** (не пустой ответ)
- Декодер ожидает объект, но получает HTTP 404
- Отсутствует обработка случая "прогресс не найден"
- **Подтверждено серверным кодом**: `$this->notFound()` при отсутствии записи

### 3. Проблема с фотографиями

**Проблема:**
- Фотографии не загружаются из URL
- Отсутствует сервис загрузки изображений
- Нет обработки удаления фотографий

## План исправления

### Этап 1: Исправление декодирования (КРИТИЧНО)

#### 1.1 Убрать конфликт декодеров
```swift
// В SWNetworkService - убрать автоматическую стратегию для прогресса
// Или в ProgressResponse - убрать кастомный декодер и использовать автоматический
```

#### 1.2 Исправить ProgressResponse
```swift
// Вариант A: Использовать автоматическую стратегию + кастомный декодер для разных форматов
struct ProgressResponse: Codable {
    let id: Int
    let pullups: Int?
    let pushups: Int?
    let squats: Int?
    let weight: Float?
    let createDate: String  // Автоматически мапится с create_date
    let modifyDate: String?
    let photoFront: String?  // Автоматически мапится с photo_front
    let photoBack: String?
    let photoSide: String?
    
    // Кастомный декодер для обработки разных форматов (числа/строки)
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Декодируем id как Int или String
        if let idInt = try container.decodeIfPresent(Int.self, forKey: .id) {
            self.id = idInt
        } else if let idString = try container.decodeIfPresent(String.self, forKey: .id),
                  let idInt = Int(idString) {
            self.id = idInt
        } else {
            throw DecodingError.typeMismatch(Int.self, DecodingError.Context(
                codingPath: decoder.codingPath + [CodingKeys.id],
                debugDescription: "Ожидается Int или String, конвертируемый в Int, но поле отсутствует или имеет неверный тип"
            ))
        }
        
        // Декодируем pullups как Int? или String?
        if let pullupsInt = try container.decodeIfPresent(Int.self, forKey: .pullups) {
            self.pullups = pullupsInt
        } else if let pullupsString = try container.decodeIfPresent(String.self, forKey: .pullups),
                  let pullupsInt = Int(pullupsString) {
            self.pullups = pullupsInt
        } else {
            self.pullups = nil
        }
        
        // Декодируем pushups как Int? или String?
        if let pushupsInt = try container.decodeIfPresent(Int.self, forKey: .pushups) {
            self.pushups = pushupsInt
        } else if let pushupsString = try container.decodeIfPresent(String.self, forKey: .pushups),
                  let pushupsInt = Int(pushupsString) {
            self.pushups = pushupsInt
        } else {
            self.pushups = nil
        }
        
        // Декодируем squats как Int? или String?
        if let squatsInt = try container.decodeIfPresent(Int.self, forKey: .squats) {
            self.squats = squatsInt
        } else if let squatsString = try container.decodeIfPresent(String.self, forKey: .squats),
                  let squatsInt = Int(squatsString) {
            self.squats = squatsInt
        } else {
            self.squats = nil
        }
        
        // Декодируем weight как Float? или String?
        if let weightFloat = try container.decodeIfPresent(Float.self, forKey: .weight) {
            self.weight = weightFloat
        } else if let weightString = try container.decodeIfPresent(String.self, forKey: .weight),
                  let weightFloat = Float(weightString) {
            self.weight = weightFloat
        } else {
            self.weight = nil
        }
        
        // Декодируем строковые поля
        self.createDate = try container.decode(String.self, forKey: .createDate)
        self.modifyDate = try container.decodeIfPresent(String.self, forKey: .modifyDate)
        self.photoFront = try container.decodeIfPresent(String.self, forKey: .photoFront)
        self.photoBack = try container.decodeIfPresent(String.self, forKey: .photoBack)
        self.photoSide = try container.decodeIfPresent(String.self, forKey: .photoSide)
    }
}

// Вариант B: Создать отдельный декодер для ProgressResponse
// В SWNetworkService добавить специальную обработку для ProgressResponse
```

#### 1.2.1 Создать специализированный декодер для ProgressResponse
```swift
// В SWNetworkService добавить метод для ProgressResponse
func requestProgressData(components: RequestComponents) async throws -> [ProgressResponse] {
    // Используем отдельный декодер без convertFromSnakeCase
    let customDecoder = JSONDecoder()
    customDecoder.dateDecodingStrategy = .iso8601
    // НЕ устанавливаем keyDecodingStrategy для ProgressResponse
    
    let data = try await requestData(components: components)
    return try customDecoder.decode([ProgressResponse].self, from: data)
}
```

#### 1.3 Добавить обработку 404 ошибок и пустых ответов
```swift
// В SWClient добавить метод для получения конкретного дня прогресса
func getProgress(day: Int) async throws -> ProgressResponse? {
    let endpoint = Endpoint.getProgress(day: day)
    
    do {
        return try await makeResult(for: endpoint)
    } catch {
        // Обрабатываем 404 как нормальный случай (прогресс не найден)
        if case APIError.notFound = error {
            return nil
        }
        throw error
    }
}

// В SWClient.getProgress() добавить проверку на пустой ответ
func getProgress() async throws -> [ProgressResponse] {
    let endpoint = Endpoint.getProgress
    let data: Data = try await makeData(for: endpoint)
    
    // Проверяем на пустой ответ
    if data.isEmpty || String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == true {
        return []
    }
    
    return try decoder.decode([ProgressResponse].self, from: data)
}
```


### Этап 2: Улучшение логирования (ВАЖНО)

#### 2.1 Добавить детальное логирование в SWNetworkService
```swift
// Логировать сырой JSON ответ перед декодированием
logger.info("Сырой JSON ответ: \(String(data: data, encoding: .utf8) ?? "nil")")
logger.info("Размер ответа: \(data.count) байт")
logger.info("Тип контента: \(response.mimeType ?? "неизвестно")")
```

#### 2.2 Добавить логирование в ProgressSyncService
```swift
// Логировать каждый этап синхронизации
logger.info("Начинаем синхронизацию прогресса для пользователя: \(user.id)")
logger.info("Сервер вернул \(serverProgressList.count) записей прогресса")
for progress in serverProgressList {
    logger.info("Прогресс дня \(progress.id): подтягивания=\(progress.pullups ?? 0), отжимания=\(progress.pushups ?? 0), приседания=\(progress.squats ?? 0), вес=\(progress.weight ?? 0)")
}
```

#### 2.3 Добавить логирование ошибок декодирования
```swift
// В SWNetworkService при ошибке декодирования
catch {
    logger.error("Ошибка декодирования для типа \(T.self)")
    logger.error("Сырые данные: \(String(data: data, encoding: .utf8) ?? "nil")")
    logger.error("Ошибка: \(error)")
    throw APIError.decodingError
}
```

### Этап 3: Исправление работы с фотографиями (ВАЖНО)

#### 3.1 Создать PhotoDownloadService
```swift
class PhotoDownloadService {
    func downloadPhoto(from url: String) async throws -> Data
    func deletePhoto(url: String) async throws
    func cachePhoto(data: Data, for url: String) async
}
```

#### 3.2 Интегрировать загрузку фотографий в ProgressSyncService
```swift
// При получении ProgressResponse с URL фотографий
if let photoFrontURL = progressResponse.photoFront {
    let photoData = try await photoDownloadService.downloadPhoto(from: photoFrontURL)
    progress.dataPhotoFront = photoData
}
```

#### 3.3 Добавить обработку удаления фотографий
```swift
// В ProgressSyncService при синхронизации
if progress.shouldDelete {
    // Удаляем фотографии с сервера
    if let photoFrontURL = progress.urlPhotoFront {
        try await photoDownloadService.deletePhoto(url: photoFrontURL)
    }
    // Аналогично для photoBack и photoSide
}
```

### Этап 4: Тестирование и валидация

#### 4.1 Создать unit-тесты для декодирования
```swift
func testProgressResponseDecoding() {
    // Тест с числовыми значениями
    // Тест со строковыми значениями
    // Тест с пустыми значениями
    // Тест с отсутствующими полями
}
```

#### 4.2 Создать интеграционные тесты
```swift
func testProgressSyncWithRealServer() {
    // Тест загрузки прогресса
    // Тест создания прогресса
    // Тест обновления прогресса
    // Тест удаления прогресса
}
```

## Приоритеты исправления

### КРИТИЧНО (блокирует работу):
1. **Исправить конфликт декодеров** - убрать двойное декодирование
2. **Обработать разные форматы ответов** - числа vs строки в зависимости от операции
3. **Добавить обработку 404 ошибок** - для запросов конкретного дня (прогресс не найден)
4. **Добавить обработку пустых ответов** - для запросов списка прогресса
5. **Улучшить логирование** - для диагностики проблем

### ВАЖНО (функциональность):
6. **Реализовать загрузку фотографий** - PhotoDownloadService
7. **Добавить обработку удаления фотографий**
8. **Создать unit-тесты** для декодирования

### ЖЕЛАТЕЛЬНО (качество):
9. **Добавить интеграционные тесты**
10. **Оптимизировать производительность** синхронизации
11. **Добавить retry логику** для сетевых запросов

## Ожидаемые результаты

После исправления:
- ✅ Декодирование прогресса работает корректно для всех операций
- ✅ Обработка разных форматов ответов (числа/строки)
- ✅ Корректная обработка 404 ошибок (прогресс не найден)
- ✅ Обработка пустых ответов для списка прогресса
- ✅ Фотографии загружаются и отображаются
- ✅ Синхронизация работает в обе стороны
- ✅ Детальное логирование для диагностики
- ✅ Обработка всех edge cases (404, пустые ответы, отсутствующие поля, разные типы данных)

## Дополнительные рекомендации

1. **Изучить Android реализацию** - она работает корректно, можно взять логику оттуда
2. **Проверить серверные API** - убедиться в корректности ответов
3. **Добавить мониторинг** - отслеживать ошибки в продакшене
4. **Создать документацию** - описать процесс синхронизации для команды
