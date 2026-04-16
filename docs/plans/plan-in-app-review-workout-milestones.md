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

- [x] Этапы 1–5.1: доменные типы, `ReviewManager`, `ReviewStorage`, `WorkoutCompletionsCounter`, UI-модификатор, интеграция.
- [x] Этапы 6, 7.1, 7.2 завершены: логирование, `reset()` при logout, milestone eligibility (`>=`), тесты 1736/0.
- [x] Этап 7.3 завершён: фикс pending review после watch-save в фоне (повторный триггер на `scenePhase == .active`).
- [ ] Этап 7: ручная валидация.
- Код: `SwiftUI-SotkaApp/Services/Review/`.

### Ключевые уточнения

- `ReviewContext.hadRecentError` — единственное поле.
- `WorkoutCompletionsCounter`: `activityType == .workout`, `!shouldDelete`, post-filter по `userId`.
- DI: `StatusManager` через `init`, `WorkoutPreviewViewModel` через параметр.
- `milestone(forCompletedWorkoutCount:)` — nearest milestone where `count >= milestone`.
- UI-модификатор: configurable delay, `task(id:)`, `StoreKit` изолирован.
- Trigger review-запроса учитывает и `pendingRequest`, и `scenePhase`.

## Этап 6. Базовое OSLog-логирование в ReviewManager

- [x] Добавлено OSLog-логирование в `ReviewManager` (skip-причины, успех).

---

## Этап 7.1. Багфикс: сброс review-состояния при logout (TDD)

- [x] Добавлен `reset()` в `ReviewAttemptStoring` + `ReviewStorage` + `ReviewManager`.
- [x] `reviewManager.reset()` вызывается при logout.
- [x] Тесты: 1731/0 (1 skipped).

---

## Этап 7.2. Багфикс: milestone eligibility при count > milestone (TDD)

**Проблема:** `milestone(forCompletedWorkoutCount:)` требовал точного совпадения count с milestone. При count=11 milestone 10 недостижим.

**Решение:** `count >= milestone.rawValue` (nearest milestone not yet attempted). `isMilestoneWorkoutCount` сохранён как точная проверка.

- [x] Реализована `>=` логика в `milestone(forCompletedWorkoutCount:)`.
- [x] Тесты: 1736/0 (1 skipped).

---

## Этап 7.3. Багфикс: pending review после watch-save в фоне (TDD)

**Проблема:** если milestone достигнут при сохранении с часов, пока iPhone-приложение не активно, `pendingRequest` выставляется, но review не показывается при возвращении в активное состояние, потому что `.task(id:)` был привязан только к `pendingRequest`.

**Решение:** привязать trigger `.task(id:)` к комбинации `(pendingRequest, scenePhase)`, чтобы при переходе в `.active` происходила повторная попытка показа pending review.

- [x] Добавлен `ReviewRequestTriggerID` (`pendingRequest + scenePhase`) и подключён в `reviewRequestHandling`.
- [x] Добавлены тесты `ReviewRequestTriggerIDTests` (изменение trigger при смене `scenePhase` и `pendingRequest`).
- [x] Целевой прогон после фикса: `ReviewRequestTriggerIDTests` + review-flow тесты — 25/0.

---

## Этап 7. Регрессия, форматирование и финальная валидация

- [x] `make format` + все тесты: 1729/0 (1 skipped).
- [ ] Ручная проверка: milestone 1/10/30 → попытка review, повтор в сессии не происходит, prompt не показывается поверх модалок.

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
