# Мок-клиент для UI-тестов

Этот документ описывает реализованный функционал мок-клиента для UI-тестов, который обеспечивает полную независимость от сервера при запуске приложения с аргументом "UITest".

## Оглавление

- [Краткий обзор функционала](#краткий-обзор-функционала)
- [Структура файлов](#структура-файлов)
- [Мок-клиенты с поддержкой мгновенного ответа](#мок-клиенты-с-поддержкой-мгновенного-ответа)
- [Единый мок-клиент: `MockSWClient`](#единый-мок-клиент-mockswclient)
- [Подготовка демо-данных: `ScreenshotDemoData.setup()`](#подготовка-демо-данных-screenshotdemodatasetup)
- [Инициализация приложения для UI-тестов](#инициализация-приложения-для-ui-тестов)
- [Полная независимость от сервера](#полная-независимость-от-сервера)
- [Демо-данные для экранов](#демо-данные-для-экранов)
- [Принципы расширения](#принципы-расширения)
- [Ключевые правила](#ключевые-правила)

### Краткий обзор функционала

- **Мгновенные ответы**: все запросы обрабатываются без задержек
- **Только успешные ответы**: мок-клиент всегда возвращает успешные результаты
- **Полная замена сетевых запросов**: никакой зависимости от реального сервера
- **Пропуск авторизации**: приложение сразу показывает главный экран без экрана входа
- **Демо-данные**: автоматическая подготовка данных в SwiftData для скриншотов
- **Условная активация**: используется только при аргументе запуска "UITest"

### Структура файлов

- `PreviewContent/Client+.swift` — моки с поддержкой `instantResponse` (весь файл обернут в `#if DEBUG`)
- `PreviewContent/MockSWClient.swift` — единый мок-клиент (отдельный файл, обернут в `#if DEBUG`)
- `PreviewContent/ScreenshotDemoData.swift` — функция `setup()` для подготовки демо-данных (отдельный файл, обернут в `#if DEBUG`)

### Мок-клиенты с поддержкой мгновенного ответа

Все моки в `PreviewContent/Client+.swift` поддерживают параметр `instantResponse`:

- `MockLoginClient`
- `MockExerciseClient`
- `MockProgressClient`
- `MockInfopostsClient`
- `MockDaysClient`
- `MockProfileClient`
- `MockCountriesClient`

Параметр `instantResponse: Bool = false` добавлен в инициализатор каждого мока. `Task.sleep` применяется только если `instantResponse == false`. По умолчанию `instantResponse = false` (сохраняется текущее поведение для превью в Xcode).

### Единый мок-клиент: `MockSWClient`

Создан единый мок-клиент `MockSWClient` в `PreviewContent/MockSWClient.swift`, реализующий все протоколы:

- `LoginClient` — методы `logIn(with:)`, `getUserByID(_:)`, `resetPassword(for:)`
- `StatusClient` — методы `start(date:)`, `current()` (делегируются `MockLoginClient`)
- `ExerciseClient` — методы `getCustomExercises()`, `saveCustomExercise(id:exercise:)`, `deleteCustomExercise(id:)`
- `InfopostsClient` — методы `getReadPosts()`, `setPostRead(day:)`, `deleteAllReadPosts()`
- `ProgressClient` — методы `getProgress()`, `getProgress(day:)`, `createProgress(progress:)`, `updateProgress(day:progress:)`, `deleteProgress(day:)`, `deletePhoto(day:type:)`
- `DaysClient` — методы `getDays()`, `createDay(_:)`, `updateDay(model:)`, `deleteDay(day:)`
- `ProfileClient` — методы `editUser(_:model:)`, `changePassword(current:new:)`
- `CountriesClient` — метод `getCountries()`

Инициализатор принимает `instantResponse: Bool = true` (по умолчанию мгновенные ответы). Каждый метод делегирует вызов соответствующему мок-клиенту.

**Демо-данные в моках:**

- `StatusClient.current()`: дата старта, соответствующая дню № 12 (11 дней назад от текущей даты)
- `DaysClient.getDays()`: активности от 1 до 11 дня по графику программы (дни 3 и 10: растяжка, день 7: отдых, остальные: тренировки)
- `ProgressClient.getProgress()`: прогресс для дня 1 (контрольная точка) с метриками (pullups: 7, pushups: 15, squats: 30, weight: 70.0)
- `ExerciseClient.getCustomExercises()`: список пользовательских упражнений (3 упражнения с ID: "demo-exercise-1", "demo-exercise-2", "demo-exercise-3")
- `InfopostsClient.getReadPosts()`: возвращает список прочитанных дней из `ScreenshotDemoData.readInfopostDays` (дни 1-10)
- `InfopostsClient.setPostRead()`: успешно обрабатывает запросы на синхронизацию статуса прочтения

### Подготовка демо-данных: `ScreenshotDemoData.setup()`

Функция `ScreenshotDemoData.setup()` создает демо-данные в SwiftData:

1. **User** — демо-пользователь (id: 1, userName: "DemoUser", fullName: "Демо Пользователь", email: "<demo@example.com>", cityID: 1, countryID: 1, genderCode: 0, birthDateIsoString: "1990-01-01")

**Примечание**: UserProgress, DayActivity и CustomExercise не создаются в `ScreenshotDemoData.setup()`. Они загружаются с "сервера" (мока) при синхронизации:

- `MockProgressClient.getProgress()` возвращает прогресс для дня 1 с метриками (pullups: 7, pushups: 15, squats: 30, weight: 70.0)
- `MockDaysClient.getDays()` возвращает активности от 1 до 11 дня по графику программы
- `MockExerciseClient.getCustomExercises()` возвращает 3 пользовательских упражнения

**Константа**: `ScreenshotDemoData.readInfopostDays = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]` — используется мок-клиентом для возврата списка прочитанных инфопостов.

Функция вызывается в `.task` модификаторе на `ZStack` внутри `WindowGroup` при аргументе "UITest".

### Инициализация приложения для UI-тестов

Функция `createMockServices()` в `SwiftUI_SotkaAppApp.swift`:

- Создает `MockSWClient` с `instantResponse: true`
- Использует `MockSWClient` для всех сервисов, включая инфопосты
- Создает настоящий `SWClient` только для свойства `client` (для `LoginScreen`, хотя он не показывается)

В `init()` используется `if-else` структура:

- При аргументе "UITest": очищается UserDefaults, создаются мок-сервисы, отключаются анимации (`UIView.setAnimationsEnabled(false)`), устанавливается день № 12 через `setCurrentDayForDebug(12)`, вызывается `authHelper.didAuthorize()` для пропуска авторизации
- Иначе: обычная инициализация для production

В `.task` модификаторе при аргументе "UITest" дополнительно вызываются:

- `ScreenshotDemoData.setup(context: statusManager.modelContainer.mainContext)` для подготовки демо-данных
- `statusManager.loadInfopostsWithUserGender()` для загрузки инфопостов

### Полная независимость от сервера

При запуске UI-тестов с аргументом "UITest":

- Приложение использует мок-клиент для всех операций, включая инфопосты
- Инфопосты загружаются из bundle (не требуют сетевых запросов)
- Синхронизация статуса прочтения работает через мок-клиент
- Авторизация пропущена, показывается главный экран
- Установлен день № 12
- Анимации отключены
- Демо-данные загружены в SwiftData через `ScreenshotDemoData.setup()`
- Все экраны готовы для скриншотов без ожидания сетевых запросов
- Приложение полностью независимо от сервера для UI-тестов

### Демо-данные для экранов

#### HomeScreen

- День № 12 установлен через `setCurrentDayForDebug(12)`
- Инфопост для дня 12 загружается из bundle через `InfopostsService`
- Показывается секция активности (день <= 100)

#### InfopostDetailScreen

- Инфопост для дня 12 загружается из bundle через `InfopostsService`
- Статус прочтения синхронизируется через мок-клиент

#### WorkoutExerciseEditorScreen

- Доступны стандартные упражнения
- Доступны пользовательские упражнения (CustomExercise) из демо-данных
- Можно редактировать упражнения дня 12

#### JournalScreen

- Дни от 1 до 11 заполнены по графику программы (дни 3 и 10: растяжка, день 7: отдых, остальные: тренировки)
- День 12 пустой (текущий день, еще не заполнен)
- Можно переключаться между списком и сеткой

#### ProgressScreen

- Прогресс для дня 1 (контрольная точка) с метриками (pullups: 7, pushups: 15, squats: 30, weight: 70.0)
- Фото прогресса отсутствуют
- Статистика прогресса

### Принципы расширения

- Новые мок-клиенты добавлять в `PreviewContent/Client+.swift` с поддержкой `instantResponse`
- Новые методы в `MockSWClient` должны делегировать вызовы соответствующим мок-клиентам
- Демо-данные для новых экранов добавлять в `ScreenshotDemoData.setup()`
- Все мок-файлы должны быть обернуты в `#if DEBUG` для исключения из production сборки

### Ключевые правила

- Мок-клиент используется только при аргументе запуска "UITest"
- Все ответы мок-клиента должны быть мгновенными (без задержек)
- Все ответы мок-клиента должны быть успешными
- Демо-данные должны покрывать все основные экраны для скриншотов
- Приложение должно работать полностью независимо от сервера при запуске UI-тестов
- Инфопосты загружаются из bundle, не требуют сетевых запросов
