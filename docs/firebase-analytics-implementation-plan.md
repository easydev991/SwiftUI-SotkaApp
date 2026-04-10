# План внедрения Firebase Analytics в SotkaApp

## Цель

Внедрить аналитику в SotkaApp с архитектурой SwiftUI-Days: единая модель событий (`AnalyticsEvent`), провайдерная архитектура (`AnalyticsProvider` + `AnalyticsService`), DI через `Environment` для `View`, constructor injection для ViewModel, обязательный трекинг экранов и ключевых действий.

## Текущее состояние

**Уже сделано**: Firebase SDK, `.gitignore`, `FIRAnalyticsDebugEnabled`, `AppDelegate`, `AnalyticsEvent` (25 экранов, 40 действий, 32 ошибки), `AnalyticsProvider`/`FirebaseAnalyticsProvider`/`NoopAnalyticsProvider`/`AnalyticsService` (fan-out), `EnvironmentValues+Analytics`, `View+Analytics`, DI в `SwiftUI_SotkaAppApp`.

**Референс в SwiftUI-Days**: `39b13a3`, `6a8923b`, `a1cf27b`

---

## Этапы 1–4: Инфраструктура (выполнено)

- [x] `AnalyticsEvent` с `screenView`, `userAction`, `appError`; 25 `AppScreen`, 40 `UserAction`, 32 `AppErrorKind`
- [x] `AnalyticsProvider`, `FirebaseAnalyticsProvider`, `NoopAnalyticsProvider`, `AnalyticsService` с fan-out
- [x] `EnvironmentValues+Analytics`, `View+Analytics` (`.trackScreen()`, `.trackEvent()`), DI в App
- [x] Архитектурное правило: `@Environment` для View, constructor injection для ViewModel, Firebase API только через сервис

---

## Этап 5: Покрытие экранов и действий

### 5.1 screenView для всех экранов

- [x] Все 25 экранов: `RootScreen`, `LoginScreen`, `HomeScreen`, `InfopostsListScreen`, `InfopostDetailScreen`, `WorkoutPreviewScreen`, `WorkoutExerciseEditorScreen`, `WorkoutScreen`, `WorkoutTimerScreen`, `ProfileScreen`, `EditProfileScreen`, `ChangePasswordScreen`, `JournalScreen`, `ProgressScreen`, `ProgressStatsView`, `EditProgressScreen`, `CustomExercisesScreen`, `CustomExerciseScreen`, `EditCustomExerciseScreen`, `MoreScreen`, `ThemeIconScreen`, `SyncJournalScreen`, `SyncJournalEntryDetailsScreen`, `SyncStartDateView`, `SyncStartDateHelpScreen`

### 5.2 Основные пользовательские действия

- [x] **Auth**: вход, выход, восстановление пароля
- [x] **Workout / Preview**: открыть редактор, добавить/удалить/переместить упражнение, сохранить, старт, завершение, принудительная остановка, таймер
- [x] **Profile**: открыть редактирование, сохранить, сменить пароль
- [x] **Journal**: сортировка, режим grid/list, тип активности, редактирование/удаление комментария
- [x] **Progress**: открыть редактирование, сохранить, удалить, фото (добавить/удалить), режим metrics/photos
- [x] **Custom Exercises**: создание, редактирование, удаление, выбор иконки
- [x] **Infoposts**: открытие экрана, display mode, "прочитано", избранное, размер шрифта
- [x] **More / Settings**: тема, иконка приложения, таймер/уведомления/вибрация, сброс программы, sync-журнал
- [x] **Sync Journal / Start Date**: открытие деталки, удаление записей, источник даты, подтверждение

### 5.3 Breadcrumbs-first правило

- [x] `.trackScreen(...)` для открытия экранов, `analytics.log(.userAction(...))` для действий в точке нажатия
- [x] `userAction` логируется до `guard`-проверок и сетевых запросов
- [x] Для `edit/delete/select` передаётся `entity_id`; исключение: `selectTheme`, `selectAppIcon`
- [x] `addProgressPhoto` — с `source` (camera/library); `deleteProgressPhoto` — с `photoType.rawValue`
- [x] Удалены лишние: `infopostOpened`, `openSyncJournalEntry`, `tapFinishTimer`
- [x] `infopostFontSizeChanged` заменено на `selectInfopostFontSize` с `rawValue`

---

## Этап 6: Логирование ошибок

- [x] `analytics.log(.appError(...))` с `operation`, `error_domain`, `error_code`
- [x] Покрыто: `LoginScreen`, `EditProfileScreen`, `ChangePasswordScreen`, `EditProgressScreen`, `ThemeIconScreen.ViewModel`, `InfopostDetailScreen`, `EditCustomExerciseScreen`
- [x] Добавлена обработка и логирование ошибок в flow `SyncJournalScreen`, `SyncStartDateView`
- [x] **WorkoutPreviewViewModel**: сохранение без типа выполнения, пустой список упражнений (2 места)
- [x] **InfopostsService**: загрузка about, проверка избранного, получение избранных, парсинг файла, синхронизация дня, синхронизация инфопоста без дня, проверка статуса прочитанного (9 мест)
- [x] **ProgressService**: валидация, пользователь не найден, ошибки сохранения (4 места)
- [x] **YouTubeVideoService**: видео не найдено, файл не найден, ошибки поиска/чтения файла (4 места)

---

## Этап 7: Тесты

- [x] `AnalyticsServiceTests.swift`: fan-out, порядок событий, пустой провайдер, `name`/`rawValue`, `NoopAnalyticsProvider`
- [ ] DEBUG smoke-check с `FIRAnalyticsDebugEnabled` и ручной проверкой в debug console

---

## Этап 8: Документация

- [ ] Создать `docs/firebase-analytics-rollout-plan.md`
- [ ] Зафиксировать: каталог экранов, действий, ошибок, правила именования

---

## Критерии готовности

- [x] Архитектура совпадает с SwiftUI-Days
- [ ] Все экраны отправляют `screenView`, ключевые действия — `user_action`, ошибки — `app_error`
- [ ] Unit-тесты проходят, `make format` и `make build` успешны
