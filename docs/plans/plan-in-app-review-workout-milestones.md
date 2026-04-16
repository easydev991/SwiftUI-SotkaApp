# План внедрения системного in-app review после 1, 10 и 30 тренировок (TDD)

## Цель

Добавить системный prompt на оценку приложения через API Apple (`@Environment(\.requestReview)`) после успешного завершения тренировок-милстоунов: 1-й, 10-й и 30-й (тип активности `workout`).

## Важные ограничения

- Только системный API Apple, без кастомных review-попапов.
- Не рассчитывать на гарантированный показ: система может не показать prompt.
- Хранить факт попытки (`attempt`), а не факт показа.
- Не вызывать prompt поверх `sheet`/`fullScreenCover`/`alert`.
- Новый код состояния делать на Observation (`@Observable`, `@ObservationIgnored`).
- `StoreKit` импортируется только в UI-слой обработки review, который вызывает `requestReview()`.

## Границы задачи

- Включаем in-app review только для iOS-приложения.
- Обрабатываем успешные завершения тренировок как с iPhone, так и из сценария сохранения с часов (через iPhone).
- Триггеры строго по milestone: 1, 10, 30 успешных тренировок.
- Существующий ручной entry point «Оценить приложение» не удаляем.
- Архитектурно используем один сервис `ReviewManager` (без разделения на `ReviewEligibilityService` и `ReviewCoordinator`).

## Актуальный статус

- [x] Этапы 1–5.1 завершены: доменные типы, `ReviewManager`, `ReviewStorage`, `WorkoutCompletionsCounter`, UI-модификатор `reviewRequestHandling`, интеграция в iPhone/watch flow, рефакторинг (`sceneActive` удалён, отправка через явный `Task { await }` на call sites).
- [ ] Остаются этапы 6 (OSLog-логирование) и 7 (регрессия, ручная валидация).
- Тесты: review-модуль `38/0`, целевой прогон `20/0`.
- Код: `SwiftUI-SotkaApp/Services/Review/`.

### Уточнения реализации

- `ReviewContext` содержит только `hadRecentError` (`sceneActive` удалён — оба call site на `@MainActor` после пользовательского действия).
- `WorkoutCompletionsCounter` — отдельный тип с `ModelContainer`, фильтрация: `activityType == .workout`, `count != nil`, `!shouldDelete`, post-filter по `userId`.
- `ReviewEventReporting` — протокол с `workoutCompletedSuccessfully(context:) async`.
- DI: `StatusManager` — через `init`, `WorkoutPreviewViewModel` — через параметр метода `saveTrainingAsPassed(...)`.
- `didRequestReviewThisSession` — in-memory, без `UserDefaults`.
- `lastReviewRequestAttemptDate` сохраняется для будущего cooldown.
- UI-модификатор: configurable delay, `task(id:)`, `StoreKit` изолирован.
- `ReviewManager` передан через `.environment()` в `RootScreen`.

## Этап 6. Логирование и аналитика attempts (без зависимости от факта показа)

### Red

- [ ] Тесты/проверки, что при каждом решении eligibility фиксируется причина (`eligible`/`skipped_reason`).

### Green

- [ ] Добавить OSLog-события:
  - [ ] `review_eligible_true`;
  - [ ] `review_eligible_false` + причина;
  - [ ] `review_request_attempted`.
- [ ] Enum причин skip уже существует (`ReviewSkipReason`):
  - [ ] `milestone_not_reached`;
  - [ ] `milestone_already_attempted`;
  - [ ] `already_attempted_this_session`;
  - [ ] `recent_error`.

### Refactor

- [ ] Централизовать формат логов в одном месте coordinator/service.

**Критерий завершения:** в логах видны только попытки и причины отказа, без ложных предположений о факте показа prompt.

---

## Этап 7. Регрессия, форматирование и финальная валидация

- [x] Запустить `make format`.
- [ ] Запустить целевые тесты:
  - [ ] `WorkoutPreviewViewModelTests`;
  - [ ] `StatusManagerTests` (watch save scenarios);
  - [ ] новые тесты `Review*`.
- [ ] Прогнать `make test` перед merge (или в CI).
- [ ] Ручная проверка сценариев:
  - [ ] первая успешная тренировка -> попытка review;
  - [ ] 10-я успешная тренировка -> попытка review;
  - [ ] 30-я успешная тренировка -> попытка review;
  - [ ] повтор внутри одной сессии не происходит;
  - [ ] prompt не инициируется поверх модалок/алертов.
  - [ ] проверка UI-обработки review выполнена вручную (без автотестов UI).

**Критерий завершения:** функционал стабильно работает по milestone 1/10/30, без нарушения UX и проектных правил.

---

## Зависимости этапов

1. Этап 6 после 5.1.
2. Этап 7 после 6.

## Риски и решения

- Риск: prompt может не появиться даже при корректном вызове.
- Решение: опираться на attempts и не связывать бизнес-логику с фактом показа.

- Риск: дубли запросов из двух источников (iPhone + watch).
- Решение: единый coordinator + идемпотентная проверка milestones.

- Риск: показ в неподходящий UX-момент.
- Решение: UI-обработчик review с defer-вызовом после `dismiss` (задержка ~0.5–1.0 сек).

## Соответствие правилам проекта

- Observation-first (`@Observable`) для нового состояния.
- Офлайн-first: локальная логика и persistence без сетевых зависимостей.
- Без force unwrap, с безопасной работой с optional.
- Логи через `OSLog`.
