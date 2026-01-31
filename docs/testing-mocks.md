# Моки для тестирования

Документ описывает моки, используемые в unit-тестах проекта для изоляции тестируемого кода от внешних зависимостей.

## Оглавление

- [Назначение моков](#назначение-моков)
- [Список моков](#список-моков)
  - [MockCountriesClient](#mockcountriesclient)
  - [MockProgressClient](#mockprogressclient)
  - [MockDailyActivitiesService](#mockdailyactivitiesservice)
  - [MockDaysClient](#mockdaysclient)
  - [MockExerciseClient](#mockexerciseclient)
  - [MockInfopostsClient](#mockinfopostsclient)
  - [MockStatusClient](#mockstatusclient)
  - [MockStatusManager](#mockstatusmanager)
  - [MockUserDefaults](#mockuserdefaults)
  - [MockPhotoDownloadService](#mockphotodownloadservice)
  - [MockAuthHelper](#mockauthhelper)
  - [MockWCSession](#mockwcsession)
- [Общие паттерны использования](#общие-паттерны-использования)
- [Расположение](#расположение)

## Назначение моков

Моки используются для:

- Изоляции тестируемого кода от сетевых запросов
- Контроля поведения зависимостей в тестах
- Имитации различных сценариев (успех, ошибки)
- Отслеживания вызовов методов и параметров

## Список моков

### MockCountriesClient

**Назначение**: Мок клиента для работы со странами.

**Основные возможности**:

- Возврат списка стран через `mockedCountries`
- Имитация ошибок через `shouldThrowError` и кастомную ошибку `MockError` в extension
- Задержка выполнения через `delay`
- Счетчик вызовов `getCountriesCallCount`

**Использование**: Тестирование логики работы со странами.

### MockProgressClient

**Назначение**: Мок клиента для работы с прогрессом (контрольные точки).

**Основные возможности**:

- Возврат списка прогрессов через `mockedProgressResponses`
- Методы `getProgress()` и `getProgress(day: Int)` для получения прогресса
- Методы `createProgress(progress:)`, `updateProgress(day:progress:)`, `deleteProgress(day:)` для управления прогрессом
- Метод `deletePhoto(day:type:)` для удаления фотографий
- Имитация ошибок через `shouldThrowError` и `shouldThrowErrorOnGetProgress`
- Кастомная ошибка `MockError.demoError` в extension
- Специфичные ошибки для `deletePhoto` через `deletePhotoError`
- Счетчики вызовов методов (`getProgressCallCount`, `createProgressCallCount`, `updateProgressCallCount`, `deletePhotoCallCount`)
- Отслеживание параметров вызовов (`deletePhotoCalls`, `updateProgressCalls`)
- Отслеживание последних параметров `deletePhoto` через `lastDeletePhotoDay` и `lastDeletePhotoType`
- Последовательный возврат ответов через внутренний `responseIndex`
- Метод `reset()` для сброса состояния
- Extension `ProgressSyncService.makeMock()` для создания сервиса с моками

**Использование**: Тестирование синхронизации прогресса, создания и обновления контрольных точек, удаления фотографий.

### MockDailyActivitiesService

**Назначение**: Мок сервиса для работы с дневником тренировок.

**Основные возможности**:

- Счетчик вызовов `createDailyActivityCallCount`
- Отслеживание последних параметров (`lastActivity`, `lastContext`)
- Массив всех вызовов `createDailyActivityCalls`
- Метод `set(_:for:context:)` для установки типа активности
- Счетчик вызовов `set` через `setCallCount`
- Отслеживание последних параметров `set` через `lastSetActivityType`, `lastSetDay`, `lastSetContext`
- Массив всех вызовов `set` через `setCalls`
- Имитация ошибок через `shouldThrowError` и кастомную ошибку `MockError.demoError` в extension
- Метод `reset()` для сброса состояния

**Использование**: Тестирование ViewModel, которые используют `DailyActivitiesService`.

### MockDaysClient

**Назначение**: Мок клиента для работы с днями/активностями.

**Основные возможности**:

- Возврат списка активностей через `mockedDayResponses`
- Имитация серверного хранилища через внутренний словарь `serverActivities`
- Имитация ошибок через `shouldThrowError` и кастомную ошибку `MockError.demoError` в extension
- Счетчики вызовов методов (`getDaysCallCount`, `createDayCallCount`, `updateDayCallCount`, `deleteDayCallCount`)
- Отслеживание параметров вызовов (`createDayCalls`, `updateDayCalls`, `deleteDayCalls`)
- Методы `setServerActivity()` и `removeServerActivity(day:)` для прямого управления состоянием сервера
- Активности, установленные через `setServerActivity()`, сохраняются даже после `deleteDay()` (через `preservedDays`)
- Метод `reset()` для сброса состояния

**Использование**: Тестирование синхронизации дневника тренировок, создания, обновления и удаления активностей.

### MockExerciseClient

**Назначение**: Мок клиента для работы с пользовательскими упражнениями.

**Основные возможности**:

- Возврат списка упражнений через `mockedCustomExercises`
- Имитация серверного хранилища через внутренний словарь `serverExercises`
- Имитация ошибок через `shouldThrowError` и кастомную ошибку `MockError` в extension
- Счетчики вызовов методов (`getCustomExercisesCallCount`, `saveCustomExerciseCallCount`, `deleteCustomExerciseCallCount`)
- Отслеживание параметров вызовов (`saveCustomExerciseCalls`, `deleteCustomExerciseCalls`)
- Метод `reset()` для сброса состояния

**Использование**: Тестирование работы с пользовательскими упражнениями, их создания, обновления и удаления.

### MockInfopostsClient

**Назначение**: Мок клиента для работы с инфопостами.

**Основные возможности**:

- Настройка результатов через `Result` типы:
  - `getReadPostsResult` - результат получения прочитанных постов
  - `setPostReadResult` - результат отметки поста как прочитанного
  - `deleteAllReadPostsResult` - результат удаления всех прочитанных постов
  - `setPostReadResultsByDay` - специфичные результаты для конкретных дней
- Кастомная ошибка `MockError` в extension с кейсами: `serverError`, `syncError`, `networkError`

**Использование**: Тестирование логики индикатора прочитанных постов и работы с инфопостами.

### MockStatusClient

**Назначение**: Мок клиента для работы со статусом тренировок.

**Основные возможности**:

- Настройка результатов через `Result` типы:
  - `startResult` - результат запуска тренировки
  - `currentResult` - результат получения текущего статуса
- Кастомная ошибка `MockError.demoError` в extension
- Счетчики вызовов методов (`startCallCount`, `currentCallCount`)
- Отслеживание параметров вызовов (`lastStartDate`, `startCalls`)
- Метод `reset()` для сброса состояния

**Использование**: Тестирование логики запуска тренировок и получения текущего статуса.

### MockStatusManager

**Назначение**: Фабрика для создания `StatusManager` с моками всех зависимостей.

**Основные возможности**:

- Создание `StatusManager` с моками всех клиентов:
  - `statusClient` - мок клиента статуса
  - `exerciseClient` - мок клиента упражнений
  - `infopostsClient` - мок клиента инфопостов
  - `progressClient` - мок клиента прогресса
  - `daysClient` - мок клиента дней
- Настройка языка для `InfopostsService`
- Использование изолированного `UserDefaults` через `MockUserDefaults`
- Поддержка кастомного `ModelContainer` для тестирования
- Поддержка мокирования `WCSessionProtocol` через параметр `watchConnectivitySessionProtocol`

**Использование**: Тестирование `StatusManager` с полным контролем над всеми зависимостями.

### MockUserDefaults

**Назначение**: Создание изолированного `UserDefaults` для тестов.

**Основные возможности**:

- Создание нового изолированного `UserDefaults` через `create()`
- Каждый тест получает свой изолированный экземпляр
- Избежание конфликтов между тестами
- Кастомная ошибка `Error.failedToCreateUserDefaults` при неудачном создании

**Использование**: Тестирование кода, который использует `UserDefaults`, без влияния на другие тесты.

### MockPhotoDownloadService

**Назначение**: Мок сервиса для загрузки фотографий прогресса.

**Основные возможности**:

- Счетчик вызовов `downloadAllPhotosCallCount`
- Отслеживание последнего переданного прогресса через `lastProgress`
- Реализует протокол `PhotoDownloadServiceProtocol`

**Использование**: Тестирование логики загрузки фотографий прогресса, используется в `ProgressSyncService.makeMock()`.

### MockAuthHelper

**Назначение**: Мок для `AuthHelper` для тестирования `WatchConnectivityManager`.

**Основные возможности**:

- Управление состоянием авторизации через `isAuthorized` и `authToken`
- Счетчики вызовов методов (`didAuthorizeCallCount`, `triggerLogoutCallCount`, `saveAuthDataCallCount`)
- Отслеживание последних параметров через `lastAuthData`
- Замыкания для обработки событий (`onDidAuthorize`, `onTriggerLogout`)

**Использование**: Тестирование логики авторизации и работы с `WatchConnectivityManager`.

### MockWCSession

**Назначение**: Мок для `WCSessionProtocol` для тестирования `WatchConnectivityManager` на iPhone.

**Основные возможности**:

- Управление доступностью сессии через `isReachable`
- Имитация успешных/неуспешных операций через `shouldSucceed` и `mockError`
- Настройка ответов через `mockReply`
- Отслеживание отправленных сообщений через `sentMessages`
- Отслеживание полученных сообщений через `receivedMessages`
- Отслеживание контекстов приложения через `applicationContexts`
- Счетчик вызовов активации через `activateCallCount`
- Методы `simulateReceivedMessage()` и `simulateReceivedMessageWithReply()` для симуляции получения сообщений (оставлены для обратной совместимости)

**Использование**: Тестирование логики синхронизации между iPhone и Apple Watch.

## Общие паттерны использования

### Имитация успешных ответов

```swift
let mockClient = MockDaysClient(mockedDayResponses: [dayResponse1, dayResponse2])
let service = DailyActivitiesService(client: mockClient)
```

### Имитация ошибок

Использование кастомной ошибки мока (для всех моков с `MockError`):

```swift
let mockClient = MockProgressClient()
mockClient.shouldThrowError = true
mockClient.errorToThrow = MockProgressClient.MockError.demoError
```

```swift
let mockClient = MockDaysClient()
mockClient.shouldThrowError = true
mockClient.errorToThrow = MockDaysClient.MockError.demoError
```

```swift
let mockClient = MockInfopostsClient(getReadPostsResult: .failure(MockInfopostsClient.MockError.serverError))
```

```swift
let mockStatusClient = MockStatusClient(startResult: .failure(MockStatusClient.MockError.demoError))
```

```swift
let mockClient = MockCountriesClient()
mockClient.shouldThrowError = true
mockClient.errorToThrow = MockCountriesClient.MockError.demoError
```

```swift
let mockClient = MockExerciseClient()
mockClient.shouldThrowError = true
mockClient.errorToThrow = MockExerciseClient.MockError.demoError
```

### Проверка вызовов методов

```swift
let mockClient = MockExerciseClient()
// ... выполнение теста ...
#expect(mockClient.saveCustomExerciseCallCount == 1)
```

### Сброс состояния между тестами

```swift
let mockClient = MockDaysClient()
// ... первый тест ...
mockClient.reset()
// ... второй тест ...
```

## Расположение

- Основные моки находятся в папке `SwiftUI-SotkaAppTests/Mocks/`
- `MockPhotoDownloadService` находится в `SwiftUI-SotkaAppTests/ProgressTests/`
- Моки для Watch приложения находятся в `SotkaWatch Watch AppTests/Mocks/`
