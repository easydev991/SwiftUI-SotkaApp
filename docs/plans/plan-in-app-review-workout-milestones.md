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

- [x] Этапы 1–5.1 завершены: доменные типы, `ReviewManager`, `ReviewStorage`, `WorkoutCompletionsCounter`, UI-модификатор `reviewRequestHandling`, интеграция в iPhone/watch flow.
- [x] Этап 6 завершён: OSLog-логирование в `ReviewManager`.
- [x] Этап 7.1 завершён: багфикс — `reset()` при logout, тесты 1731/0.
- [ ] Этап 7: ручная валидация.
- Код: `SwiftUI-SotkaApp/Services/Review/`.

### Уточнения реализации

- `ReviewContext.hadRecentError` — единственное поле (`sceneActive` удалён).
- `WorkoutCompletionsCounter` — отдельный тип, фильтрация: `activityType == .workout`, `count != nil`, `!shouldDelete`, post-filter по `userId`.
- DI: `StatusManager` через `init`, `WorkoutPreviewViewModel` через параметр `saveTrainingAsPassed(...)`.
- `didRequestReviewThisSession` — in-memory; `lastReviewRequestAttemptDate` для будущего cooldown.
- UI-модификатор: configurable delay, `task(id:)`, `StoreKit` изолирован; `ReviewManager` через `.environment()` в `RootScreen`.

## Этап 6. Базовое OSLog-логирование в ReviewManager

- [x] Добавлено OSLog-логирование в `ReviewManager` (skip-причины, успех).

---

## Этап 7.1. Багфикс: сброс review-состояния при logout (TDD)

- [x] **RED:** Тест `ReviewStorageTests.resetClearsAllData`.
- [x] **GREEN:** `reset()` в `ReviewAttemptStoring` + `ReviewStorage`.
- [x] **RED:** Тест `ReviewManagerTests.resetClearsStateAndAllowsNewSession`.
- [x] **GREEN:** `reset()` в `ReviewManager`, обновлён `MockReviewAttemptStore`.
- [x] **INTEGRATE:** `reviewManager.reset()` в `onChange(of: authHelper.isAuthorized)` при logout.
- [x] Сборка + все тесты: 1731/0 (1 skipped).

---

## Этап 7. Регрессия, форматирование и финальная валидация

- [x] `make format` + целевые тесты (`WorkoutPreviewViewModelTests` 109/0, `StatusManagerTests` 136/0, `Review*` 32/0) + полный прогон `make test` 1729/0 (1 skipped).
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
