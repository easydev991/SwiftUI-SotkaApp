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

- [x] Этапы 1–7.3 завершены: доменные типы, `ReviewManager`, `ReviewStorage`, `WorkoutCompletionsCounter`, UI-модификатор, интеграция, логирование, `reset()` при logout, milestone eligibility (`>=`), pending review при watch-save в фоне.
- [ ] Этап 7: ручная валидация.
- Код: `SwiftUI-SotkaApp/Services/Review/`.

### Ключевые детали реализации

- `ReviewContext.hadRecentError` — единственное поле.
- `WorkoutCompletionsCounter`: `activityType == .workout`, `!shouldDelete`, post-filter по `userId`.
- `milestone(forCompletedWorkoutCount:)` — nearest milestone where `count >= milestone`.
- UI-модификатор: configurable delay, `task(id:)`, `StoreKit` изолирован.

## Этапы 6–7.3: Реализация и багфиксы

- [x] Этап 6: OSLog-логирование в `ReviewManager` (skip-причины, успех).
- [x] Этап 7.1: `reset()` при logout, тесты 1731/0.
- [x] Этап 7.2: `>=` логика в `milestone(forCompletedWorkoutCount:)`, тесты 1736/0.
- [x] Этап 7.3: `ReviewRequestTriggerID` для pending review после watch-save в фоне, тесты 25/0.
- [x] Этап 7 (частично): `make format` + все тесты: 1729/0 (1 skipped).
- [ ] Ручная валидация: milestone 1/10/30 → попытка review, повтор в сессии не происходит, prompt не показывается поверх модалок.

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
