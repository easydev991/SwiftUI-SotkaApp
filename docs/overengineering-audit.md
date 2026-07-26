# Аудит over-engineering: весь репозиторий

Дата аудита: 2026-07-25. Дата фактического применения `delete`-этапа: 2026-07-26 (коммит `ed82f6e9`). Дата применения `[FIX]` и `[restore]`-этапа: 2026-07-26 (коммит `22dace92`). Дата применения `delete`-этапа-2 (Этапы 1+2+3+7): 2026-07-26 (коммиты `19081bad`/`2555914a`/`c2e906a3`/`56726fe2`). Дата применения `delete`-этапа-3 (NetworkStatus): 2026-07-26 (коммит `9cb2646`). Дата применения `delete`-этапа-4 (устаревшая документация): 2026-07-26 (коммит `f10157a`). Дата применения `delete`-этапа-5 (правка оставшейся документации): 2026-07-26 (коммит `f1065ca`). Дата применения `delete`-этапа-6 (снос устаревших секций): 2026-07-26 (коммит `65d39dc`).
Скоуп: только избыточная сложность (не корректность, не безопасность, не производительность).

Контекст: `AppConfiguration.isReadOnlyMode = true` на постоянной основе — серверные API закрыты, поэтому весь сетевой слой (синхронизация прогресса, авторизация на сервере, разрешение конфликтов дат, серверный профиль/смена пароля) — мёртвый код и подлежит удалению. UI-тесты и mock-bootstrap по-прежнему передают `isReadOnlyMode: false`, чтобы симулировать нормальное поведение для скриншот-тестов.

**ВАЖНО (обнаружено 2026-07-26, исправлено в `22dace92`):** Изначальный план аудита ошибочно пометил как «мёртвый код» инфраструктуру UI-тестовых fixture-данных. `Client+.swift` содержал реализации мок-клиентов (`MockDaysClient`/`MockProgressClient`/`MockExerciseClient`/`MockInfopostsClient`), которые через `MockSWClient` → `createMockServices()` поставляли в приложение 12 дней тренировок, прогресс пользователя (день 1), 3 демо-упражнения и прочитанные инфопосты. Без них скриншот-тесты `testMakeScreenshots` падали. **Серверные протоколы мертвы для продакшена, но мок-реализации заменены прямым SwiftData-seed'ом в `ScreenshotDemoData.seedDemoData()` (`22dace92`).** Подробности — раздел 7.

Предыдущий аудит от 2026-07-21 — большая часть находок остаётся валидной. Изменения с момента прошлого аудита: коммит `1c890e2` (Periphery-чистка от 2026-05-01, ~1937 строк) уже удалил часть мёртвого кода из SWDesignSystem/SWUtils/SWKeychain/PreviewContent; добавлены находки, которых не было в прошлом аудите (`SyncStartDateScreen`, `ChangePasswordScreen`, `EditProfileScreen`, `StatusManagerLogoutTests`, `StatusManagerProcessAuthStatusTests`, sync-методы в `DailyActivitiesService`/`CustomExercisesService`/`InfopostsService` + связанные мёртвые протоколы). Линейные счётчики обновлены. Исправлены обоснования (`StatusManager` — перечислены 5 независимых гейтов вместо «всё после строки 153»; `MockSWClient` помечен warning из-за 14 живых unit-тестов).

Теги: `delete` — мёртвый код; `stdlib` — велосипед вместо стандартной библиотеки; `native` — то, что платформа делает сама; `yagni` — абстракция с одной реализацией; `shrink` — та же логика короче.

Статусы: `[x]` выполнено в коммитах `ed82f6e9`/`22dace92`/`19081bad`/`2555914a`/`c2e906a3`/`56726fe2`/`9cb2646`/`f10157a`/`f1065ca`/`65d39dc`, `[ ]` не выполнено (см. причину), `[NEW]` — новая находка, появившаяся после удаления мёртвого кода, `[FIX]`/`[restore]` — исправление критических побочных эффектов (коммит `22dace92`).

## 1. Сетевой слой / синхронизация / авторизация (read-only mode)

Всё, что обращается к серверу, синхронизирует данные или реализует авторизацию, — **мёртвый код**. Сервер закрыт навсегда.

### Целиком мёртвые сервисы

- [x] **Удалены 4 сетевых сервиса:** `SWClient`, `ProgressSyncService`, `PhotoDownloadService`, `CountriesUpdateService`. ~1686 стр.
- [ ] shrink `AuthHelper.swift` — частично выполнено: удалены серверные методы (`authToken`, `saveAuthData`, `updateAuthData`, `didAuthorize`, импорт `KeychainWrapper`). **Осталось 62 стр.** в виде `AuthHelperImp` с локальной логикой (`isAuthorized`/`isOfflineOnly`/`performOfflineLogin`/`triggerLogout`). Класс **живой** — используется `OfflineLoginView`, `MoreScreen.triggerLogout()`, `RootScreen`, `SwiftUI_SotkaAppApp`. Полное удаление требует переноса `isOfflineOnly` флага в `User` (UserDefaults-бэкап) и inlining `triggerLogout` в `MoreScreen`. **См. раздел 4 «На границе скоупа».**

### Удалено в `ed82f6e9` (delete-этап, ~16 530 стр.)

- [x] **UI/Models:** 9 мёртвых экранов (на смену `OnlineLoginView` — `OfflineLoginView`), 4 модели SyncJournal + директория `Models/SyncJournal/`, 9 протоколов клиентов + 10 серверных DTO.
- [x] **Preview + моки:** 6 preview-файлов + `StatusManager+` переписан; 9 моков серверных протоколов (в `Mocks/` оставлены `MockReviewEventReporter`/`MockStatusManager`/`MockUserDefaults`/`MockWCSession`).
- [x] **Sync-логика + тесты:** 5 sync-гейтов в `StatusManager` (1559→1107 стр.) + sync-блоки в `DailyActivitiesService`/`CustomExercisesService`/`InfopostsService`; 30 мёртвых тестов удалено (sync + Progress + DailyActivities + DTO-зависимые, вся `DailyActivitiesTests/`).

### keep (живые, не тронуты)

- [x] `WorkoutDataResponse.swift` (WatchConnectivity), `ProgressServiceTests.swift` (локальный `ProgressService`), sync-флаги `isSynced`/`shouldDelete`/`lastModified` (см. раздел 5).

## 2. Пакеты и native-замены

### Целиком мёртвые пакеты

- [x] delete **SWNetwork** (~1412 стр.: 631 sources + 757 tests + 24 package) — удалён в `2555914a`. Каталог `SwiftUI-SotkaApp/Libraries/SWNetwork/` + пакет из `.xcodeproj` убраны. Также удалены 2 unit-теста из `SwiftUI-SotkaAppTests/Models/` (`ErrorResponseTests.swift` 299 стр + `DateDecodingRoundTripTests.swift` 34 стр).
- [x] delete **SWKeychain** (~230 стр.) — удалён в `2555914a`. Каталог + пакет убраны. 0 prod-ссылок, 0 тестов с импортом.

**Итого пакетов на удаление: ~1975 стр. (1642 sources/tests + 333 тестов) — выполнено в `2555914a`.**

### Пакеты, которые оставляем

- [x] **Оставлены 3 живых пакета:** `CachedAsyncImage` (333 стр.), `SWDesignSystem` (1533 стр., 37 импортов), `SWUtils` (1363 стр. с тестами, 35 импортов — было 1613/44). Не тронуты.

### Native-замены внутри пакетов

- [x] native `SWAlert` (108 стр.) — UIKit alert (`UIAlertController`) с рекурсивным обходом VC. Удалён в `c2e906a3`. + 2 теста в `SWAlertTests.swift`.
- [x] delete `SWFileManager` (44 стр.) — ноль использований в проде. Удалён в `19081bad` (+ `SWFileManagerTests.swift` 48 стр.).
- [x] delete `DateFormatterService.readableDate` + хелпер `makeFormat` + 3 неиспользуемых enum case'a (`dayMonthMediumTime`, `dayMonth`, `mediumTime`) — `readableDate` вызывался только в `SWUtilsTests`. Удалены в `19081bad` (+ тест `readableDate`).
- [x] delete `String.capitalizingFirstLetter` (3 стр.) — вызывался только в `SWUtilsTests`. Удалён в `19081bad` (+ тест).
- [x] [NEW] delete `NetworkStatus` + `NetworkStatusEnvironmentKey` (~46 стр. в `Libraries/SWUtils/Sources/SWUtils/NetworkStatus/`) — пропущено оригинальным аудитом. `NetworkStatus` инстанцируется в `SwiftUI_SotkaAppApp.swift:15` и через модификатор `.networkStatus(...)` пишет в `EnvironmentValues.isNetworkConnected`, но **ни один view не читает это значение** (`@Environment(\.isNetworkConnected)` = 0 ссылок в репозитории). Тестов нет. Watch app: 0 ссылок. В read-only mode это write-only цепочка: `NWPathMonitor` запускался впустую на background queue. Удалено в текущем коммите: оба файла, директория `NetworkStatus/`, `@State private var networkStatus` (`:15`) и `.networkStatus(networkStatus.isOnline)` (`:135`) в `SwiftUI_SotkaAppApp.swift`.

## 3. Review-слой (yagni — избыточная абстракция)

Система «оценить приложение в App Store» реализована через 12 файлов. **Вся зачистка этого раздела не выполнена в `ed82f6e9`** (выходит за рамки delete-этапа — yagni-схлопывание слоёв не сделано, 7 тестовых файлов Review сохранены).

### yagni — протоколы с одной реализацией

- [ ] yagni `ReviewAttemptRules.swift` (10 стр.) — **живой** (вызывается из `ReviewManager.shouldAttemptMilestone()`).
- [ ] yagni `ReviewAttemptStoring.swift` (8 стр.) — **живой** (реализуется через `ReviewStorage`).
- [ ] yagni `WorkoutCompletionsCounting.swift` (5 стр.) — **живой**.
- [ ] yagni `ReviewContext.swift` (5 стр.) — **живой** (используется в `StatusManager:571` и `WorkoutPreviewViewModel:238`).
- [ ] yagni `ReviewStorageKeys.swift` (8 стр.) — **живой**.

### keep — протоколы с несколькими потребителями

- [x] keep `ReviewEventReporting.swift` (5 стр.) — **живой, не тронут.**

### shrink — типовые enum/struct

- [ ] shrink `ReviewSkipReason.swift` (9 стр.) — **живой** (поле `lastSkipReason`).
- [ ] shrink `ReviewMilestone.swift` (17 стр.) — **живой** (метод `milestone(forCompletedWorkoutCount:)`).

### Итоговая цель Review-слоя (не достигнута)

Одна `ReviewManager` (~50 стр.) с захардкоженным списком milestones и одним вызовом `SKStoreReviewController.requestReview()`. Остальные 9 файлов — удалить.

**Подитого Review (production): 287 стр. → ~50 стр. (net −237) — не выполнено.**
**Подитого Review (tests): 646 стр. сохранены (7 тестовых файлов живы и входят в 903 passed).**

## 4. Другие мёртвые/yagni находки в приложении

### Watch-приложение

- [x] **Удалены `WatchWorkoutService.swift` + тесты (~285 стр.).** Реальная workout-логика — `WorkoutViewModel`. Watch ↔ iPhone синхронизация через `WatchConnectivityService`/`WCSession`/`WorkoutDataResponse` — не затронута.

### Прочее

- [x] Удалены `ImageProcessor.createThumbnail` (5 стр. + 2 теста, вызывался только из тестов), `InfopostAvailabilityManager.getAvailablePostsBySection` (4 стр. + 1 тест, в проде только `filterAvailablePosts`), `Client+.swift` (74 стр., демо-данные → `ScreenshotDemoData.seedDemoData()`, см. раздел 7), `ScreenshotDemoData.readInfopostDays` (1 константа, 0 вызовов).

### Новые мёртвые находки после `ed82f6e9` (не были в исходном аудите) [NEW]

Файлы, ставшие мёртвыми после удаления sync/DTO, но не отмеченные в исходном плане:

- [x] [NEW] Удалены 4 модели, ставшие мёртвыми после удаления sync/DTO: `ConflictingStartDate` (только `SyncStartDateScreen`), `CalendarPurchasesResponse` (только `syncJournalAndProgress`), `LoginCredentials` (только `OnlineLoginView`), `ProgressSnapshot` (только `ProgressSyncService` + `init(from: UserProgress)`/`photosForUpload` для сервера). Все 0 ссылок в проде.

### Ошибочно удалённые тесты [restore]

`SwiftDataMigrationTests.swift` (4 теста, ~200 стр.) был в `SwiftUI-SotkaAppTests/Persistence/` (коммит `0810beb`), удалён в `ed82f6e9` как «мёртвый», потому что его `makeLegacySchema()`/`makeCurrentSchema()` ссылались на `SyncJournalEntry.self`. **Удаление было ошибкой:** тесты проверяли критичный сценарий — открытие старого SwiftData store и сохранение данных пользователя при изменении схемы. Без них нет регрессионной защиты единственного места, где Apple не даёт гарантий (удаление entity + relationship в lightweight migration).

- [x] [restore] **Восстановлен `SwiftDataMigrationTests.swift`** (269 стр., `22dace92`): 4 существующих теста сохранены + новый `opensStoreAfterRemovingSyncJournalEntryAndPreservesData` (проверяет миграцию сценария пользователя с онлайн-историей). Все 5 тестов проходят.

## 5. На границе скоупа (не находки, решение за продуктом / оставить сейчас)

- Sync-флаги (`isSynced`, `shouldDelete`, `lastModified`) — оставляем на первой итерации. Без синхронизации они теряют смысл, но удаление их из SwiftData-моделей требует миграции (lightweight для nullable-полей или manual/поэтапная с обработкой существующих данных). Временные затраты и риск ошибки миграции/потери данных не оправданы ради чистоты. Второй итерацией их можно удалить вместе с плановой миграцией SwiftData.
- `AuthHelper` (62 стр. после strip серверной части) — жив и нужен: `OfflineLoginView` использует `performOfflineLogin()`, `MoreScreen` использует `triggerLogout()`. Полное удаление = inlining `isOfflineOnly` флага в `User` + перенос `triggerLogout` напрямую в `MoreScreen`. Чистый gain −62 стр., но снижение читаемости (User-логика + UI-логика смешиваются). **Решение за продуктом: оставить / удалить.**
- Firebase (Analytics + Crashlytics): оставляем 100%. Crashlytics полезен и офлайн (очередь + отправка при сети); Analytics — продуктовое решение. Слой провайдеров мал (~115 стр.), оставить.
- `StatusManager` (1107 стр. после чистки) — god object; экстракция `WatchCommandHandler`/`CalendarExtensionManager` нейтральна по строкам, делать только при следующем касании.
- `WorkoutProgramCreator` (449 стр.) — активно используется 3 ViewModels, не мёртвый. Оставить.
- `AnalyticsService` (317 стр.) — Firebase-провайдер функционален, протокол для тестируемости. Не over-engineering.
- `WorkoutPreviewViewModel`, `WorkoutScreenViewModel`, `DailyActivitiesService` (422 стр.) — крупные, но выполняют реальные функции. YAGNI не применяется.

## 6. Устаревшая документация (требует обновления вне `ed82f6e9`/`22dace92`)

Следующие файлы `docs/` всё ещё описывают удалённый sync-слой:

- [x] `docs/daily-activities.md` — строки 126, 173: описывал `syncDailyActivities(context:) async throws -> SyncResult` (метод удалён). **Удалено в текущем коммите.**
- [x] `docs/custom-exercises.md` — строки 86, 106: описывал `syncCustomExercises(context:)` (метод удалён). **Удалено в текущем коммите.**
- [x] `docs/infoposts.md` — строка 82: описывал `syncReadPosts(context:)` (метод удалён). **Удалено в текущем коммите.**
- [x] `docs/crash-swiftdata-invalid-future-backing-data.md` — **весь файл устарел** (sync-механизм, на который ссылался doc, удалён; проблемный UI-паттерн `DayActivityTrainingView` + live-relationship остался, но без sync триггера сценарий краша больше не описан в коде). **Файл удалён целиком в текущем коммите.**
- [x] `docs/testing-mocks.md` — описывал `MockDaysClient`/`MockProgressClient`/etc. со специфичными полями (`mockedDayResponses`, `errorToThrow`, `getReadPostsResult`). Удалённый `MockSWClient` был единственной реализацией этого API. **Файл удалён в текущем коммите.**
- [x] `docs/ui-test-mock-client.md` — описывал `MockLoginClient`/`MockExerciseClient`/etc. (структуры удалены). **Файл удалён в текущем коммите.**
- [x] `docs/sync-journal.md` — **весь файл устарел** (53 стр., модель `SyncJournalEntry` и все связанные экраны/логика удалены). **Файл удалён в текущем коммите.**
- [x] `docs/data-migration.md` — строка 29: пример схемы содержал `SyncJournalEntry.self` (больше не существует). **Удалено в текущем коммите.**
- [x] `docs/progress-screen.md` — строка 174: описывал `syncProgress(context:) async throws -> SyncResult` (метод удалён). **Удалено в текущем коммите** (не было в исходном ТЗ, обнаружено по той же проблеме).
- [x] `docs/calendar-extension.md` — строка 87 и секция «Retry» (строки 82-86): ссылается на `syncJournalAndProgress()` (метод удалён). **Удалено в текущем коммите** (не было в исходном ТЗ, обнаружено по той же проблеме; добавлена «Историческая справка»).
- [x] `AGENTS.md` — строка 75: `Domain terms: ... SyncJournalEntry` — термин больше не существует, убран из списка.

## 7. UI-тестовая инфраструктура: демо-данные (критическая ошибка аудита) [FIX]

**Обнаружено 2026-07-26, исправлено 2026-07-26 (коммит `22dace92`):** UI-тесты `testMakeScreenshots` падали после `ed82f6e9`, т.к. удалён код, создававший демо-данные. `22dace92` восстановил демо-данные прямым заполнением SwiftData.

### Как работало до удаления

`SwiftUI_SotkaAppApp.init()` при `UITest` вызывал `ScreenshotDemoData.setup()` (создавал `User`) и `createMockServices()` (создавал `StatusManager` с `MockSWClient` → мок-клиенты `Client+.swift` (~685 стр.) возвращали: 12 дней тренировок через `MockDaysClient.getDays()`; прогресс дня 1 через `MockProgressClient.getProgress()`; 3 демо-упражнения через `MockExerciseClient.getCustomExercises()`; `[1, 2, 3, 4, 5, 6, 7, 8, 9, 10]` прочитанных инфопостов через `MockInfopostsClient.getReadPosts()`). `setCurrentDayForDebug(12)` устанавливал день 12. Все 8 скриншотов проходили.

### Что сломано после удаления

`Client+.swift` лишился реализаций, `createMockServices()` создавал `StatusManager` без клиентов, `ScreenshotDemoData.setup()` создавал только голого `User`. `setCurrentDayForDebug(12)` работал корректно, но в SwiftData не было ни одной `DayActivity` — экран пуст, UI-тесты падали (`TodayActivityButton.0`, `progressTabButton`, `journalTabButton`, `customExercisesButton`).

### Что сделано в `22dace92` [FIX]

- [x] [FIX] **`ScreenshotDemoData.seedDemoData(context:user:)`** создаёт 11 `DayActivity` (8 тренировок + 2 отдыха + 1 растяжка), `UserProgress` дня 1, 3 `CustomExercise`, `Country`. День 12 намеренно пуст — для кнопок выбора типа в `HomeActivitySectionView` (отступление: 11 вместо 12). **`createMockServices()`** дополнен `authHelper.performOfflineLogin()` + `Tips.resetDatastore()` + `UIView.setAnimationsEnabled(false)`. **`Client+.swift`** удалён (−74 стр.).

### Почему аудит ошибся

Аудит классифицировал все 9 серверных протоколов как «мёртвый код» — верно для продакшена. **Ошибка:** мок-реализации в `Client+.swift` не распознаны как UI-тестовая инфраструктура. Это не «мёртвый код», а тестовые fixture-данные, которые нужно сохранить в другой форме (прямой SwiftData-seed). Аудит должен был пометить их как `adapt`, а не `delete`.

## Итог

### Фактический результат коммита `ed82f6e9` (delete-этап)

**162 файла изменено, 30 489 удалено / 199 вставлено.** Основные категории:

| Категория | Удалено строк |
|---|---|
| Сетевые сервисы (`SWClient`, `ProgressSyncService`, `PhotoDownloadService`, `CountriesUpdateService`) | ~1686 |
| Мёртвые экраны (9 файлов) | ~1089 |
| SyncJournal модели (4 файла) | ~495 |
| Мёртвые протоколы (вся директория `Services/Protocols/`, 9 файлов) | ~109 |
| Серверные DTO (10 файлов) | ~593 |
| Мёртвые preview (6 файлов) | ~155 |
| Моки серверных протоколов (9 файлов) | ~642 |
| Мёртвые тесты (sync + Progress + DailyActivities + DTO-зависимые, 30 файлов) | ~9700 |
| `StatusManager` sync-код (5 гейтов) | ~360 |
| Sync-блоки в 3 активных сервисах | ~958 + 136 тестов |
| `WatchWorkoutService` + тесты | ~285 |
| `AuthHelper` server-методы | −41 (103 → 62) |

### Фактический результат коммита `22dace92` (FIX + restore-этап)

**5 файлов изменено, 393 вставлено / 80 удалено.** Восстановление побочных эффектов `ed82f6e9`:

| Категория | Изменение |
|---|---|
| `SwiftDataMigrationTests.swift` [restore] | +269 стр. — 5 тестов миграции SwiftData (без `SyncJournalEntry.self`); включая новый тест `opensStoreAfterRemovingSyncJournalEntryAndPreservesData` |
| `ScreenshotDemoData.swift` [FIX] | +121 стр. — `seedDemoData()` создаёт 11 `DayActivity` (8 тренировок + 2 отдыха + 1 растяжка), `UserProgress`, 3 `CustomExercise`, `Country` |
| `SwiftUI_SotkaAppApp.swift` [FIX] | +2 стр. — `authHelper.performOfflineLogin()` + `Tips.resetDatastore()` + `UIView.setAnimationsEnabled(false)` в UI-тестовом пути |
| `Client+.swift` [FIX] | −74 стр. — файл удалён целиком |

### Фактический результат коммитов `19081bad` + `2555914a` + `c2e906a3` + `56726fe2` (delete-этап-2)

**46 файлов изменено, 76 вставлено / 2651 удалено (net −2575).** Выполнение `[ ]`-пунктов плана:

| Коммит | Категория | Изменение |
|---|---|---|
| `19081bad` | 4 [NEW] мёртвых модели | −135 стр.: `ConflictingStartDate`/`ProgressSnapshot`/`CalendarPurchasesResponse`/`LoginCredentials` |
| `19081bad` | `SWFileManager` + тесты | −92 стр. (44 + 48) |
| `19081bad` | `DateFormatterService.readableDate`/`makeFormat` + 3 enum cases + тесты | −50 стр. (40 production + 10 tests) |
| `19081bad` | `String.capitalizingFirstLetter` + тест | −10 стр. |
| `19081bad` | `ImageProcessor.createThumbnail` + 2 теста | −31 стр. |
| `19081bad` | `InfopostAvailabilityManager.getAvailablePostsBySection` + тест | −23 стр. |
| `2555914a` | Пакет `SWNetwork` (sources + tests) | −1388 стр. |
| `2555914a` | Пакет `SWKeychain` (sources + tests) | −230 стр. |
| `2555914a` | 2 unit-теста импортирующих SWNetwork | −333 стр. (`ErrorResponseTests` 299 + `DateDecodingRoundTripTests` 34) |
| `2555914a` | `.xcodeproj/project.pbxproj` | −18 строк (PBXBuildFile/Frameworks/packageProductDependencies/membershipExceptions для SWNetwork/SWKeychain) |
| `c2e906a3` | `SWAlert.swift` + `SWAlertTests.swift` | −128 стр. (108 + 20) |
| `56726fe2` | `ScreenshotDemoData.readInfopostDays` (0 вызовов) | −1 стр. |

**Результат:** −2575 стр. net, 79 тестов удалено, пакеты SWNetwork/SWKeychain полностью убраны из репозитория и `.xcodeproj`.

### Не выполнено в `ed82f6e9` + `22dace92` + `19081bad` + `2555914a` + `c2e906a3` + `56726fe2` (оставлено на следующие итерации)

| Категория | Объём | Причина |
|---|---|---|
| Review-слой yagni/shrink | ~237 стр. production + ~646 стр. тестов | Выходит за рамки задачи. Тесты Review (7 файлов, 646 стр.) сохраняются — входят в 903 passed |
| **`AuthHelper` shrink** | 62 стр. production | Требует переноса `isOfflineOnly` в `User` (UserDefaults-бэкап) + inlining `triggerLogout` в `MoreScreen`. Снижение читаемости. Решение за продуктом |
| **Устаревшая документация `docs/` + `AGENTS.md`** | 0 файлов: все 8 пунктов обработаны. Удалены целиком в `f10157a` + `<NEW>`: `testing-mocks.md`, `ui-test-mock-client.md`, **`sync-journal.md`**, **`crash-swiftdata-invalid-future-backing-data.md`**. Отредактированы: `daily-activities.md`, `custom-exercises.md`, `infoposts.md`, `progress-screen.md`, `calendar-extension.md`, `data-migration.md`, `AGENTS.md` строка 75 | Готово |

### Контроль качества после `ed82f6e9` + `22dace92` + `19081bad` + `2555914a` + `c2e906a3` + `56726fe2`

- iOS build: ✅ SUCCEEDED (iPhone 17 / iOS 27)
- Unit tests на iPhone 11 (iOS 26.5): ✅ **903 passed, 0 failed, 1 skipped** (было 1833 → −856 мёртвых тестов в `ed82f6e9`; +5 миграционных после `22dace92` = 982; −79 тестов после `19081bad`/`2555914a`/`c2e906a3` = 903)
- UI-тесты (скриншоты): ✅ **все проходят** (`testMakeScreenshots`, 8 скриншотов)
- Watch app ↔ iPhone sync через `WatchConnectivityService`/`WCSession`/`WorkoutDataResponse` — не сломана

### Супротив прошлого аудита (2026-07-21)

Добавлены `SyncStartDateScreen`/`HelpScreen`/`ChangePasswordScreen`/`EditProfileScreen`/`SyncResultBadge`/`SyncDateComparisonPolicy` + соответствующие тесты (~+2000 строк); добавлены sync-методы в активных сервисах (DailyActivities/CustomExercises/Infoposts) + 4 мёртвых протокола (+~1100 строк production, +136 строк тестов); удалены в `1c890e2` Periphery-чистки (учтены в новых счётчиках). `MockSWClient` помечен как **warning** — использовался в 14 unit-тестах `CustomExercisesServiceTests`. В `ed82f6e9` выбран **вариант (b)**: `MockSWClient` + тесты удалены целиком. `ProgressServiceTests` перенесён в keep (тестирует живой локальный `ProgressService`).

### Ошибки аудита (обе исправлены в `22dace92`)

1. **`MockSWClient` = UI-инфраструктура, а не мёртвый код.** Аудит классифицировал мок-реализации протоколов в `Client+.swift` как мёртвый код, не распознав их как UI-тестовые fixture-данные. Исправлено: SwiftData-seed в `ScreenshotDemoData` (11 `DayActivity` + `UserProgress` + 3 `CustomExercise` + `Country`); `Client+.swift` удалён; `createMockServices()` дополнен `performOfflineLogin()` + `Tips.resetDatastore()` + `UIView.setAnimationsEnabled(false)`.
2. **`SwiftDataMigrationTests` = критичный регресс.** Тест ошибочно удалён как «мёртвый» (ссылался на `SyncJournalEntry.self`). Исправлено: 5 тестов восстановлены (269 стр.), схемы адаптированы, добавлен `opensStoreAfterRemovingSyncJournalEntryAndPreservesData`.

CachedAsyncImage остаётся: `AsyncImage` + `URLCache` не решает мерцание при перерисовках ячеек, а кастомный `ImageLoader`/`ImageCache` даёт стабильное изображение без фаз загрузки. Удаление sync-флагов и Firebase в эту цифму не входят: флаги — вторая итерация с миграцией, Firebase — оставляем 100%.
