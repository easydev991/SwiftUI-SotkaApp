# План: Офлайн-режим без синхронизации с сервером

## Цель

Добавить возможность использовать приложение без авторизации на сайте. Пользователь нажимает «Пропустить» → выбирает пол → нажимает «Начать» → создаётся локальный профиль `offline-user` → приложение работает полностью локально.

## Текущее состояние ✅

Все этапы реализованы и протестированы. Офлайн-вход работает: `WelcomeScreen` → «Пропустить» → `OfflineLoginView` → `performOfflineLogin()` → авторизация. Все сервисы — offline-first, сетевые вызовы для офлайн-пользователя заблокированы на уровне `StatusManager`, `CountriesUpdateService`, `MoreScreen`. Выход удаляет все данные. UI-тесты пройдены, скриншоты сгенерированы (15.04.2026).

## Ключевые файлы

| Файл | Назначение |
|------|-----------|
| `Models/User.swift` | SwiftData модель с `isOfflineOnly`, convenience init `offlineWithGenderCode:` |
| `Services/AuthHelper.swift` | Офлайн-логин, флаг `isOfflineOnly` в UserDefaults |
| `Services/StatusManager.swift` | Пропуск синхронизации для офлайн (getStatus, sync, start, reset) |
| `Screens/Login/WelcomeScreen.swift` | Welcome + кнопки «Авторизоваться» / «Пропустить» |
| `Screens/Login/OfflineLoginView.swift` | Выбор пола и офлайн-вход |
| `Screens/More/MoreScreen.swift` | Скрытие EditProfile/SyncJournal для офлайн |
| `Screens/Root/RootScreen.swift` | 4 таба: home, journal, progress, more |
| `SwiftUI_SotkaAppApp.swift` | Точка входа, `showLoadingOverlay` без оверлея для офлайн |

---

## Этапы реализации

| # | Название | Статус | Тесты |
|---|----------|--------|-------|
| 1 | User.isOfflineOnly | ✅ | UserTests (37/37) |
| 2 | AuthHelper.performOfflineLogin() | ✅ | AuthHelperTests (15/15) |
| 3 | StatusManager — пропуск синхронизации | ✅ | StatusManagerOfflineTests (11), регрессия (35/35) |
| 4 | Экраны входа (Welcome, Offline, Online) | ✅ | LoginScreenOfflineTests (6/6) |
| 4.5 | Аналитика (OfflineLogin, OnlineLogin) | ✅ | AnalyticsServiceTests (6/6) |
| 5 | MoreScreen — скрыть UI для офлайн | ✅ | — |
| 6 | Глобальная блокировка сети | ✅ | — |
| 7 | Интеграция и тестирование | ✅ | StatusManagerOfflineIntegrationTests (5) |
| 8 | AuthHelper.isOfflineOnly — убрать loading overlay | ✅ | AuthHelperTests (15/15), все тесты (1672) |
| 9 | StatusManager — Watch Connectivity для офлайн | ✅ | StatusManagerWatchConnectivityTests+Offline (10) |
| 10 | Редизайн таб-бара (profile → journal + progress) | ✅ | UI-тесты, скриншоты |
| 11 | UI-тесты и скриншоты | ✅ | 16 PNG на устройство × 2 локали |

---

## Этап 9. StatusManager — Watch Connectivity для офлайн ✅

Реализовано 10 тестов в `StatusManagerWatchConnectivityTests+Offline.swift` (extension `OfflineTests`):

- **9.1** — `getStatus` не отправляет sendMessage/applicationContext для офлайн-пользователя
- **9.2** — `sendCurrentStatus` отправляет локальные данные на часы
- **9.3** — `sendDayDataToWatch` работает после `didLoadInitialData = true`
- **9.4–9.5** — `handleWatchCommand(setActivity/saveWorkout)` сохраняет локально + ответ на часы
- **9.6–9.7** — `sendApplicationContextOnActivation` отправляет/пропускает в зависимости от `didLoadInitialData`
- **9.8–9.9** — `processAuthStatus(true/false)` корректно отправляет статус авторизации на часы
- **9.10** — дополнительный тест для корректности данных

Ключевые методы: `getStatus()` (L141), `sendDayDataToWatch()` (L294), `sendCurrentStatus()` (L319), `sendApplicationContextOnActivation()` (L386).

---

## Этап 10. Редизайн таб-бара ✅

Выполнено в рамках плана `docs/plans/plan-redesign-tabs.md`. Таб `profile` заменён на `journal` + `progress`. Профиль (EditProfile, Logout) перемещён в `MoreScreen`. `ProfileScreen` удалён. `EditProfileScreen` продолжает использоваться из `Screens/Profile/Edit/`. `AnalyticsEvent.AppScreen.profile` удалён из аналитики. Скриншоты обновлены (15.04.2026).

---

## Этап 11. UI-тесты и скриншоты ✅

- `testMakeScreenshots` обновлён для новой структуры табов (home=0, journal=1, progress=2, more=3)
- Скриншоты сгенерированы: 16 PNG на устройство (iPhone 15 Pro Max, iPad Pro 12.9") × 2 локали (en-US, ru)
- Экраны: mainScreen, todayInfopost, workoutPreview, workoutEditor, userProgress, userJournalGrid, userJournalList, userExercises

---

## Технический долг

- [ ] **UI-тесты для офлайн-потока**: текущие UI-тесты покрывают только скриншоты с предзаполненными данными (ScreenshotDemoData). Нет UI-тестов для офлайн-входа (WelcomeScreen → Пропустить → OfflineLoginView → выбор пола → авторизация).
- [ ] **CI для UI-тестов**: `testMakeScreenshots` не запускается в CI (не настроена схема/destination).

---

## Риски

1. `isOfflineOnly` — вычисляемое, SwiftData миграция не нужна
2. `id: -1` — `@Attribute(.unique)`, при `triggerLogout()` все пользователи удаляются
3. `SWClient` и `authToken` — для офлайн `nil`, блокировка на уровне `StatusManager` критична
4. Watch Connectivity работает (локальные данные)
5. Инфопосты из бандла, страны не загружаются

---

## Чек-лист проверки плана

- [x] Для критичных изменений указаны тесты
- [x] Чёткое разделение на слои
- [x] Указаны зависимости между этапами
- [x] Указаны риски и важные замечания
- [x] Соблюдены правила AGENTS.md (offline-first, SwiftData, OSLog)
