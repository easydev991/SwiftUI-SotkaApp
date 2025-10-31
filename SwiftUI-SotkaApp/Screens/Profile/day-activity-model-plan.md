# План реализации модели DayActivity для SwiftData

## Цель
Создать модель `DayActivity` для хранения ежедневных активностей в SwiftData по аналогии с моделью `CustomExercise`, подготовить фундамент для дальнейшего развития функционала дневника тренировок.

## Анализ существующих моделей

### CustomExercise (эталон для DayActivity)
- **SwiftData модель**: `CustomExercise.swift` - `@Model` класс с основными полями и флагами синхронизации
- **Request модель**: `CustomExerciseRequest.swift` - для отправки данных на сервер
- **Response модель**: `CustomExerciseResponse.swift` - для получения данных с сервера
- **Relationship**: связь с `User` через `@Relationship(inverse: \User.customExercises)` с каскадным удалением

### DayActivity (существующие модели для API)
- **Request модель**: `DayRequest.swift` - уже существует, для отправки данных на сервер
- **Response модель**: `DayResponse.swift` - уже существует, для получения данных с сервера
- **Тип активности**: `DayActivityType.swift` - enum с типами (workout, stretch, rest, sick)
- **Тип выполнения**: `ExerciseExecutionType.swift` - enum с типами (cycles, sets)
- **Тип упражнения**: `ExerciseType.swift` - enum с типами упражнений (уже имеет `rawValue: Int`)

## Структура данных DayActivity

### Основные поля (на основе DayRequest/DayResponse и Android-приложения)
- `day: Int` - номер дня (1-100), уникальный для пользователя
- `activityTypeRaw: Int?` - тип активности (0=тренировка, 1=отдых, 2=растяжка, 3=болезнь) - для хранения в SwiftData
- `count: Int?` - фактическое количество кругов/повторений
- `plannedCount: Int?` - запланированное количество повторений
- `executeTypeRaw: Int?` - тип выполнения (0=круги, 1=подходы) - для хранения в SwiftData
- `trainingTypeRaw: Int?` - тип тренировки (соответствует `ExerciseType.rawValue`: 0-5 для основных упражнений, 93-983 для турбо-упражнений) - для хранения в SwiftData
- `duration: Int?` - продолжительность в секундах/минутах
- `comment: String?` - комментарий пользователя
- `createDate: Date` - дата создания записи
- `modifyDate: Date` - дата последнего изменения

### Флаги синхронизации (по аналогии с CustomExercise)
- `isSynced: Bool = false` - флаг синхронизации с сервером
- `shouldDelete: Bool = false` - флаг для удаления с сервера

### Relationship
- ✅ `user: User?` - связь с пользователем через `@Relationship(inverse: \User.dayActivities)`
- ✅ В модели `User` добавлено: `@Relationship(deleteRule: .cascade) var dayActivities: [DayActivity] = []`

### Trainings (тренировки дня) ✅
**Реализация**: Создана отдельная модель `DayActivityTraining` с relationship к `DayActivity` для хранения массива выполненных упражнений в день тренировки.
- ✅ Модель `DayActivityTraining` хранит: `count`, `typeId`, `customTypeId`, `sortOrder`
- ✅ Relationship с `DayActivity`: `@Relationship(deleteRule: .cascade)` для каскадного удаления
- ✅ Соответствует структуре из Android приложения и старого iOS приложения (Core Data `DbTraining`)

## План реализации ✅ ВЫПОЛНЕНО

### Выполненные этапы
✅ **Этап 0**: Подготовлены enum'ы с `rawValue: Int` (DayActivityType, ExerciseExecutionType, ExerciseType - все 27 значений проверены).
✅ **Этапы 1-3**: Созданы модели `DayActivity` и `DayActivityTraining` с relationships (User ↔ DayActivity ↔ DayActivityTraining), инициализаторами из `DayResponse`, computed properties, добавлены в schema.
✅ **Этап 4**: Проверены все места создания ModelContainer, модели добавлены где необходимо.
✅ **Этап 5**: Созданы тестовые файлы для enum'ов (DayActivityTypeTests, ExerciseExecutionTypeTests, ExerciseTypeTests) и моделей (DayActivityTests - 23 теста), все тесты проходят успешно.

## Детали реализации

### Дата создания/изменения
- При создании локально: `createDate = Date.now`, `modifyDate = Date.now`
- При обновлении: `modifyDate = Date.now`
- Из сервера: парсить из ISO строк через `DateFormatterService`

### Уникальность дня для пользователя
- Использовать составной уникальный ключ через `@Attribute(.unique)` на комбинацию `(day, user.id)`
- Или проверять уникальность на уровне бизнес-логики

### Trainings
- Модель `DayActivityTraining` создана как отдельная SwiftData модель с relationship к `DayActivity`
- При синхронизации преобразовывать из/в `DayResponse.Training` через инициализаторы
- Массив trainings необходим для корректной отправки данных на сервер через `DayRequest`

## Следующие этапы (не входят в текущую задачу)

1. Создание сервиса для синхронизации DayActivity с сервером
2. Создание экранов для отображения и редактирования DayActivity
3. Реализация логики создания/обновления/удаления дней
4. Интеграция с календарем и уведомлениями
5. Визуализация статистики по дням

## Критерии готовности ✅

✅ Все enum'ы подготовлены с `rawValue: Int` и проверены тестами (DayActivityType, ExerciseExecutionType, все 27 значений ExerciseType).
✅ Модели `DayActivity` и `DayActivityTraining` созданы, следуют паттернам `CustomExercise`, relationships настроены (User ↔ DayActivity ↔ DayActivityTraining с каскадным удалением).
✅ Модели добавлены в schema, компилируются без ошибок, работают computed properties, каскадное удаление протестировано.
✅ Инициализаторы из `DayResponse` реализованы, созданы тесты (DayActivityTypeTests, ExerciseExecutionTypeTests, ExerciseTypeTests, DayActivityTests - 23 теста).

## Примечания

- Следовать правилам проекта: безопасное извлечение опционалов, OSLog для логирования
- Использовать `SWUtils` для работы с датами (`DateFormatterService`)
- Не использовать force unwrap (`!`)
- Сохранять консистентность с существующими моделями (`CustomExercise`, `UserProgress`)