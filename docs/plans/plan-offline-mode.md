# План: Офлайн-режим без синхронизации с сервером

## Цель

Добавить возможность использовать приложение без авторизации на сайте. Пользователь нажимает «Пропустить» → выбирает пол → нажимает «Начать» → создаётся локальный профиль `offline-user` → приложение работает полностью локально.

## Текущее состояние ✅

Все этапы реализованы. Офлайн-вход работает: `WelcomeScreen` → «Пропустить» → `OfflineLoginView` → `performOfflineLogin()` → авторизация. Все сервисы — offline-first, сетевые вызовы для офлайн-пользователя заблокированы на уровне `StatusManager`, `CountriesUpdateService`, `MoreScreen`. Выход удаляет все данные.

## Ключевые файлы

| Файл | Назначение |
|------|-----------|
| `Models/User.swift` | SwiftData модель с `isOfflineOnly` |
| `Services/AuthHelper.swift` | Офлайн-логин, флаг `isOfflineOnly` в UserDefaults |
| `Services/StatusManager.swift` | Пропуск синхронизации для офлайн |
| `Screens/Login/WelcomeScreen.swift` |welcome + навигация |
| `Screens/Login/OfflineLoginView.swift` | Выбор пола и офлайн-вход |
| `Screens/Profile/ProfileScreen.swift` | Скрытие UI для офлайн |
| `SwiftUI_SotkaAppApp.swift` | Точка входа, `showLoadingOverlay` без оверлея для офлайн |

---

## Этапы реализации

| # | Название | Статус | Тесты |
|---|----------|--------|-------|
| 1 | User.isOfflineOnly | ✅ | UserTests (37/37) |
| 2 | AuthHelper.performOfflineLogin() | ✅ | AuthHelperTests (15/15) |
| 3 | StatusManager — пропуск синхронизации | ✅ | StatusManagerOfflineTests (7/7), регрессия (35/35) |
| 4 | Экраны входа (Welcome, Offline, Online) | ✅ | LoginScreenOfflineTests (6/6) |
| 4.5 | Аналитика (OfflineLogin, OnlineLogin) | ✅ | AnalyticsServiceTests (6/6) |
| 5 | ProfileScreen — скрыть UI для офлайн | ✅ | — |
| 6 | Глобальная блокировка сети | ✅ | — |
| 7 | Интеграция и тестирование | ✅ | StatusManagerOfflineIntegrationTests |
| 8 | AuthHelper.isOfflineOnly — убрать loading overlay | ✅ | AuthHelperTests (15/15), все тесты (1672) |
| 9 | StatusManager — Watch Connectivity для офлайн | ✅ | StatusManagerWatchConnectivityTests+Offline (9/9) |

---

## Этап 9. StatusManager — Watch Connectivity для офлайн ✅

Реализовано 9 тестов в `StatusManagerWatchConnectivityTests+Offline.swift` (extension `OfflineTests`):
- **9.1** — `getStatus` не отправляет sendMessage/applicationContext для офлайн-пользователя
- **9.2** — `sendCurrentStatus` отправляет локальные данные на часы
- **9.3** — `sendDayDataToWatch` работает после `didLoadInitialData = true`
- **9.4–9.5** — `handleWatchCommand(setActivity/saveWorkout)` сохраняет локально + ответ на часы
- **9.6–9.7** — `sendApplicationContextOnActivation` отправляет/пропускает в зависимости от `didLoadInitialData`
- **9.8–9.9** — `processAuthStatus(true/false)` корректно отправляет статус авторизации на часы

Ключевые методы: `getStatus()` (L141), `sendDayDataToWatch()` (L294), `sendCurrentStatus()` (L319), `sendApplicationContextOnActivation()` (L386).

---

## Невыполненная задача

- [ ] **Ручное тестирование**: офлайн-вход, выбор пола, работа приложения, выход → вход с аккаунтом, перезапуск, отсутствие сетевых запросов

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
- [x] Указаны риски и重要ные замечания
- [x] Соблюдены правила AGENTS.md (offline-first, SwiftData, OSLog)
