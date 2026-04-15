# Firebase Analytics Architecture

Документ фиксирует архитектуру и текущее рабочее покрытие Firebase Analytics в `SwiftUI-SotkaApp`.

## 1. Назначение

- Основная цель аналитики: диагностика ошибок и сбоев.
- Аналитика используется как breadcrumbs-контекст для Crashlytics:
  - какой экран был открыт перед сбоем;
  - какие ключевые действия пользователь нажимал;
  - какие ошибки приложения (`app_error`) произошли в сценарии.

## 2. Архитектура

- Единая модель событий: `AnalyticsEvent`
  - `screenView(screen: AppScreen)`
  - `userAction(action: UserAction)`
  - `appError(kind: AppErrorKind, error: Error)`
- Провайдерная схема:
  - `AnalyticsProvider` (протокол)
  - `FirebaseAnalyticsProvider` (отправка в Firebase)
  - `NoopAnalyticsProvider` (тесты/превью)
- `AnalyticsService` выполняет fan-out во все подключенные провайдеры.

## 3. Интеграция и DI

- `AnalyticsService` создается в `SwiftUI_SotkaAppApp` и передается через `Environment` (`\.analyticsService`).
- В `View` используется `@Environment(\.analyticsService)`.
- Для открытия экранов используется `View.trackScreen(...)`.
- Для сервисов/VM аналитика передается через инъекцию (`init(analytics:)` или `setAnalytics(...)`).
- Прямые вызовы Firebase из экранов и ViewModel не используются.

## 4. Правила трекинга

- Открытие экрана логируется только через `.trackScreen(...)`.
- `userAction` логируется только для реальных пользовательских `Button`-действий.
- Логирование `userAction` выполняется в точке нажатия:
  - до `guard`-проверок;
  - до сетевых запросов;
  - до ранних `return`.
- Навигационные переходы через `NavigationLink` отдельно как `userAction` не логируются.
- Для `edit/delete/select`-сценариев передаются диагностические поля (идентификатор, title, dayNumber и т.п.).
- Для `appError` передаются `operation`, `error_domain`, `error_code`.

## 5. Каталог ключевых событий

- Сценарные названия действий (без generic `tapEdit/tapSave/tapDelete`), например:
  - `editWorkout(dayNumber)`
  - `saveWorkoutExercises(dayNumber)`
  - `editProgress(dayNumber)`
  - `saveProfile`
  - `savePassword`
  - `delete...`/`select...` с диагностическими параметрами сущности
- Для прогресс-фото:
  - `addProgressPhoto` разделяется по источнику (`camera`/`library`);
  - `deleteProgressPhoto` передает `photoType.rawValue`.
- Удалены лишние/дублирующие события открытия экранов, которые покрываются `trackScreen`.

## 6. Покрытие экранов

- `screenView` внедрен для основных экранов приложения (welcome/online/offline auth, home, infoposts, workout, journal, progress, custom exercises, more/settings, sync).
- Ключевые `userAction` и `appError` внедрены в критичных пользовательских сценариях тех же модулей.

## 7. Текущее состояние внедрения

- Инфраструктура аналитики внедрена и используется в прод-коде.
- Тесты `AnalyticsService` покрывают fan-out и базовые контракты событий.
- Crashlytics breadcrumbs формируются через связку `trackScreen + userAction`.
- Debug smoke-check и ручная валидация событий в Firebase выполняются как регрессионная проверка перед релизом.

## 8. Критерии поддержки в дальнейшем

- Каждый новый экран обязан иметь `.trackScreen(...)`.
- Каждое новое критичное действие пользователя обязано иметь `userAction` в точке нажатия.
- Любая новая error-ветка в ключевых сервисах/экранах должна логировать `appError`.
- Имена событий должны оставаться сценарными и диагностически полезными.

## 9. Ключевые файлы

- `SwiftUI-SotkaApp/Models/AnalyticsEvent.swift`
- `SwiftUI-SotkaApp/Services/Analytics/AnalyticsService.swift`
- `SwiftUI-SotkaApp/Services/Analytics/FirebaseAnalyticsProvider.swift`
- `SwiftUI-SotkaApp/Extensions/View+Analytics.swift`
- `SwiftUI-SotkaApp/Extensions/EnvironmentValues+Analytics.swift`
