# План внедрения системного in-app review после 1, 10 и 30 тренировок (TDD)

## Цель

Добавить системный prompt на оценку приложения через API Apple (`@Environment(\.requestReview)`) после успешного завершения тренировок-милстоунов: 1-й, 10-й и 30-й (тип активности `workout`).

## Важные ограничения

- Только системный API Apple, без кастомных review-попапов.
- Не рассчитывать на гарантированный показ: система может не показать prompt.
- Хранить факт попытки (`attempt`), а не факт показа.
- Не вызывать prompt поверх `sheet`/`fullScreenCover`/`alert`.
- Новый код состояния делать на Observation (`@Observable`, `@ObservationIgnored`).
- `StoreKit` импортируется только в UI host, который вызывает `requestReview()`.

## Границы задачи

- Включаем in-app review только для iOS-приложения.
- Обрабатываем успешные завершения тренировок как с iPhone, так и из сценария сохранения с часов (через iPhone).
- Триггеры строго по milestone: 1, 10, 30 успешных тренировок.
- Существующий ручной entry point «Оценить приложение» не удаляем.
- Архитектурно используем один сервис `ReviewManager` (без разделения на `ReviewEligibilityService` и `ReviewCoordinator`).

## Этап 1. Domain-модели и контракты (TDD)

### Red

- [ ] Добавить unit-тесты для модели milestone и правил попыток:
  - [ ] milestone = 1/10/30 поддерживаются;
  - [ ] остальные значения не триггерят запрос;
  - [ ] повторный триггер того же milestone блокируется.

### Green

- [ ] Создать `ReviewMilestone` (например, enum/int-backed) со значениями `first`, `tenth`, `thirtieth`.
- [ ] Создать протоколы:
  - [ ] `ReviewAttemptStoring` (хранение attempts/сессионного флага);
  - [ ] `WorkoutCompletionsCounting` (получение числа успешных тренировок).
- [ ] Добавить структуру контекста для проверки UX-условий (`sceneActive`, `hadRecentError`).

### Refactor

- [ ] Убрать дублирование ключей UserDefaults в единый namespace `review.*`.
- [ ] Уточнить нейминг событий/типов для читаемости.

**Критерий завершения:** доменные типы и протоколы покрыты тестами, сборка тест-таргета проходит.

---

## Этап 2. Бизнес-логика eligibility и координации (TDD)

### Red

- [ ] Написать тесты для `ReviewManager` (eligibility внутри менеджера):
  - [ ] `true`, когда достигнут новый milestone 1/10/30;
  - [ ] `false`, если milestone уже был attempted ранее;
  - [ ] `false`, если уже была попытка в текущей сессии;
  - [ ] `false`, если в контексте отмечена недавняя ошибка.
- [ ] Написать тесты на координацию pending state в `ReviewManager`:
  - [ ] выставляет pending-запрос только один раз за сессию;
  - [ ] после `markConsumed()` сбрасывает pending и сохраняет attempt;
  - [ ] не зависит от факта реального показа prompt.

### Green

- [ ] Реализовать `ReviewManager` c приватной eligibility-проверкой на основе:
  - [ ] milestone 1/10/30;
  - [ ] защиты от дублей attempts;
  - [ ] UX-гейтов (`sceneActive`, `hadRecentError`).
- [ ] Реализовать `ReviewManager` (`@Observable`, `@MainActor`):
  - [ ] принимает доменное событие `workoutCompletedSuccessfully`;
  - [ ] рассчитывает milestone по текущему числу завершённых тренировок;
  - [ ] выставляет `pendingRequest` для UI-слоя.

### Refactor

- [ ] Вынести причины отказа eligibility в enum (для логирования/аналитики).

**Критерий завершения:** логика eligibility и координации в `ReviewManager` полностью покрыта unit-тестами, все кейсы 1/10/30 детерминированы.

---

## Этап 3. Локальное хранение состояния attempts (TDD)

### Red

- [ ] Тесты на persistence attempts:
  - [ ] хранится список milestone attempts;
  - [ ] хранится `lastReviewRequestAttemptDate`;
  - [ ] `didRequestReviewThisSession` сбрасывается при новом запуске.

### Green

- [ ] Реализовать `ReviewStorage` на `UserDefaults`:
  - [ ] `attemptedMilestones`;
  - [ ] `lastReviewRequestAttemptDate`;
  - [ ] `didRequestReviewThisSession`.
- [ ] Реализовать источник количества завершённых тренировок через SwiftData:
  - [ ] считать только `DayActivity` с `activityType == .workout`, `count != nil`, `!shouldDelete`;
  - [ ] учитывать только текущего пользователя.
- [ ] Источнику подсчёта передавать `ModelContainer` через init (а `ModelContext` брать как `modelContainer.mainContext` в `@MainActor`), чтобы не зависеть от `@Environment(\.modelContext)`.
- [ ] Явно определить и документировать, что `didRequestReviewThisSession = false` сбрасывается в app entry point (`SwiftUI_SotkaAppApp` в `.task {}` при старте сессии).

### Refactor

- [ ] Стабилизировать ключи и маппинг массива milestones в отдельный helper.

**Критерий завершения:** состояние attempts переживает перезапуск приложения и корректно восстанавливается.

---

## Этап 4. UI Host для вызова системного prompt (TDD)

### Red

- [ ] Тесты (или lightweight integration-тесты) на поведение host:
  - [ ] при `pendingRequest = true` вызывается только системный `requestReview()`;
  - [ ] после вызова обязательно выполняется `markConsumed()`;
  - [ ] при `pendingRequest = false` вызова нет.
  - [ ] при событии из `sheet` prompt вызывается только после завершения `dismiss` (через defer/задержку).

### Green

- [ ] Добавить `ReviewRequestHost` в корневой UI-слой (рядом с `RootScreen`), где доступен `@Environment(\.requestReview)`.
- [ ] `ReviewRequestHost` — единственное место с `import StoreKit`.
- [ ] Вызывать `requestReview()` только при безопасном UI-моменте: после получения `pendingRequest` делать defer-задержку ~0.5–1.0 сек, чтобы не попасть на анимацию `dismiss()` из `sheet`.
- [ ] Передать `ReviewManager` через `.environment(...)` в дерево экранов.

### Refactor

- [ ] Минимизировать знание о StoreKit вне host-компонента.

**Критерий завершения:** единственная точка вызова review API находится в UI host, экраны не вызывают `requestReview()` напрямую.

---

## Этап 5. Интеграция доменных событий из текущих user flow (TDD)

### Red

- [ ] Тесты на iPhone flow: после успешного `saveTrainingAsPassed` событие отправляется из `WorkoutPreviewViewModel` (или из post-save callback сервиса, если выберем этот путь).
- [ ] Тесты на watch flow: после `saveWorkout` в `StatusManager` отправляется то же доменное событие.
- [ ] Тесты на отрицательные кейсы: незавершённая/невалидная тренировка не отправляет событие.
- [ ] Тесты на идемпотентность: повторное пересохранение дня не увеличивает число завершённых тренировок и не вызывает повтор milestone, если он уже был attempted.

### Green

- [ ] Встроить отправку события после успешного `createDailyActivity(...)`:
  - [ ] iPhone путь: в `WorkoutPreviewViewModel.saveTrainingAsPassed(...)` сразу после успешного сохранения;
  - [ ] watch путь: `StatusManager.handleSaveWorkoutCommand(...)`.
- [ ] Для `StatusManager` добавить зависимость через протокол (чтобы не смешивать слой сервиса и UI API).
- [ ] Гарантировать идемпотентность: событие может приходить на каждое успешное сохранение, но повторный запрос по тому же milestone блокируется через `attemptedMilestones`.

### Refactor

- [ ] Убрать дублирование кода отправки события в общий helper/use-case.

**Критерий завершения:** оба канала завершения тренировки (iPhone/watch) инициируют единый pipeline eligibility.

---

## Этап 6. Логирование и аналитика attempts (без зависимости от факта показа)

### Red

- [ ] Тесты/проверки, что при каждом решении eligibility фиксируется причина (`eligible`/`skipped_reason`).

### Green

- [ ] Добавить OSLog-события:
  - [ ] `review_eligible_true`;
  - [ ] `review_eligible_false` + причина;
  - [ ] `review_request_attempted`.
- [ ] Добавить enum причин skip:
  - [ ] `milestone_not_reached`;
  - [ ] `milestone_already_attempted`;
  - [ ] `already_attempted_this_session`;
  - [ ] `recent_error`;
  - [ ] `scene_not_active`.
  - [ ] `cooldown_active` (если включаем чтение `lastReviewRequestAttemptDate`, например 30 дней между attempts).

### Refactor

- [ ] Централизовать формат логов в одном месте coordinator/service.

**Критерий завершения:** в логах видны только попытки и причины отказа, без ложных предположений о факте показа prompt.

---

## Этап 7. Регрессия, форматирование и финальная валидация

- [ ] Запустить `make format`.
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

**Критерий завершения:** функционал стабильно работает по milestone 1/10/30, без нарушения UX и проектных правил.

---

## Зависимости этапов

1. Этап 1 -> Этап 2 -> Этап 3 -> Этап 4.
2. Этап 5 зависит от 2-4.
3. Этап 6 можно делать параллельно с 5 после готовности 2.
4. Этап 7 после 5-6.

## Риски и решения

- Риск: prompt может не появиться даже при корректном вызове.
- Решение: опираться на attempts и не связывать бизнес-логику с фактом показа.

- Риск: дубли запросов из двух источников (iPhone + watch).
- Решение: единый coordinator + идемпотентная проверка milestones.

- Риск: показ в неподходящий UX-момент.
- Решение: UI host с defer-вызовом после `dismiss` (задержка ~0.5–1.0 сек) и проверкой `sceneActive`.

## Соответствие правилам проекта

- Observation-first (`@Observable`) для нового состояния.
- Офлайн-first: локальная логика и persistence без сетевых зависимостей.
- Без force unwrap, с безопасной работой с optional.
- Логи через `OSLog`.
