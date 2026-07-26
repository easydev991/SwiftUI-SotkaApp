# Аудит over-engineering: весь репозиторий

Дата аудита: 2026-07-25. Дата фактического применения `delete`-этапа: 2026-07-26 (коммит `ed82f6e9`). Дата применения `[FIX]` и `[restore]`-этапа: 2026-07-26 (коммит `22dace92`).
Скоуп: только избыточная сложность (не корректность, не безопасность, не производительность).

Контекст: `AppConfiguration.isReadOnlyMode = true` на постоянной основе — серверные API закрыты, поэтому весь сетевой слой (синхронизация прогресса, авторизация на сервере, разрешение конфликтов дат, серверный профиль/смена пароля) — мёртвый код и подлежит удалению. UI-тесты и mock-bootstrap по-прежнему передают `isReadOnlyMode: false`, чтобы симулировать нормальное поведение для скриншот-тестов.

**ВАЖНО (обнаружено 2026-07-26, исправлено в `22dace92`):** Изначальный план аудита ошибочно пометил как «мёртвый код» инфраструктуру UI-тестовых fixture-данных. `Client+.swift` содержал реализации мок-клиентов (`MockDaysClient`/`MockProgressClient`/`MockExerciseClient`/`MockInfopostsClient`), которые через `MockSWClient` → `createMockServices()` поставляли в приложение 12 дней тренировок, прогресс пользователя (день 1), 3 демо-упражнения и прочитанные инфопосты. Без них скриншот-тесты `testMakeScreenshots` падали. **Серверные протоколы мертвы для продакшена, но мок-реализации заменены прямым SwiftData-seed'ом в `ScreenshotDemoData.seedDemoData()` (`22dace92`).** Подробности — раздел 7.

Предыдущий аудит от 2026-07-21 — большая часть находок остаётся валидной. Изменения с момента прошлого аудита: коммит `1c890e2` (Periphery-чистка от 2026-05-01, ~1937 строк) уже удалил часть мёртвого кода из SWDesignSystem/SWUtils/SWKeychain/PreviewContent; добавлены находки, которых не было в прошлом аудите (`SyncStartDateScreen`, `ChangePasswordScreen`, `EditProfileScreen`, `StatusManagerLogoutTests`, `StatusManagerProcessAuthStatusTests`, sync-методы в `DailyActivitiesService`/`CustomExercisesService`/`InfopostsService` + связанные мёртвые протоколы). Линейные счётчики обновлены. Исправлены обоснования (`StatusManager` — перечислены 5 независимых гейтов вместо «всё после строки 153»; `MockSWClient` помечен warning из-за 14 живых unit-тестов).

Теги: `delete` — мёртвый код; `stdlib` — велосипед вместо стандартной библиотеки; `native` — то, что платформа делает сама; `yagni` — абстракция с одной реализацией; `shrink` — та же логика короче.

Статусы: `[x]` выполнено в коммитах `ed82f6e9`/`22dace92`, `[ ]` не выполнено (см. причину), `[NEW]` — новая находка, появившаяся после удаления мёртвого кода, `[FIX]`/`[restore]` — исправление критических побочных эффектов (коммит `22dace92`).

## 1. Сетевой слой / синхронизация / авторизация (read-only mode)

Всё, что обращается к серверу, синхронизирует данные или реализует авторизацию, — **мёртвый код**. Сервер закрыт навсегда.

### Целиком мёртвые сервисы

- [x] **Удалены 4 сетевых сервиса:** `SWClient`, `ProgressSyncService`, `PhotoDownloadService`, `CountriesUpdateService`. ~1686 стр.
- [ ] shrink `AuthHelper.swift` — частично выполнено: удалены серверные методы (`authToken`, `saveAuthData`, `updateAuthData`, `didAuthorize`, импорт `KeychainWrapper`). **Осталось 62 стр.** в виде `AuthHelperImp` с локальной логикой (`isAuthorized`/`isOfflineOnly`/`performOfflineLogin`/`triggerLogout`). Класс **живой** — используется `OfflineLoginView`, `MoreScreen.triggerLogout()`, `RootScreen`, `SwiftUI_SotkaAppApp`. Полное удаление требует переноса `isOfflineOnly` флага в `User` (UserDefaults-бэкап) и inlining `triggerLogout` в `MoreScreen`. **См. раздел 4 «На границе скоупа».**

### Удалено в `ed82f6e9` (delete-этап, ~16 530 стр.)

- [x] **9 мёртвых экранов** (`OnlineLoginView`, `ChangePasswordScreen`, `EditProfileScreen`, `SyncStartDateScreen`, `SyncStartDateHelpScreen`, `SyncJournalScreen`, `SyncJournalEntryDetailsScreen`, `SyncJournalRowView`, `SyncResultBadge`). На смену `OnlineLoginView` — живой `OfflineLoginView`. ~1089 стр.
- [x] **4 модели** (`SyncJournalEntry`, `SyncJournalDateGroup`, `SyncResult`, `SyncDateComparisonPolicy`) + директория `Models/SyncJournal/`. ~495 стр.
- [x] **9 протоколов клиентов** (вся `Services/Protocols/`): `LoginClient`, `ProfileClient`, `PurchasesClient`, `DaysClient`, `ExerciseClient`, `InfopostsClient`, `ProgressClient`, `StatusClient`, `CountriesClient`. ~109 стр.
- [x] **10 серверных DTO** (`DayRequest/Response`, `ProgressRequest/Response`, `CustomExerciseRequest/Response`, `UserResponse`, `CountryResponse`, `CityResponse`, `CurrentRunResponse`). ~593 стр.
- [x] **6 preview-файлов** (`SyncJournalEntry+`, `DayProgressStatus+`, `Infopost+`, `MockSWClient`, `ReviewManager+`, `UserResponse+`). ~155 стр.
- [x] **`StatusManager+`** — переписан (preview-расширения нужны для превью).
- [x] **9 моков серверных протоколов** (`MockAuthHelper`, `MockStatusClient`, `MockDaysClient`, `MockExerciseClient`, `MockInfopostsClient`, `MockProgressClient`, `MockPurchasesClient`, `MockPhotoDownloadService`, `MockCountriesClient`). В `Mocks/` оставлены: `MockReviewEventReporter`, `MockStatusManager`, `MockUserDefaults`, `MockWCSession`. ~642 стр.
- [x] **30 мёртвых тестов** (sync + Progress + DailyActivities + DTO-зависимые + `SwiftDataMigrationTests`): вся директория `DailyActivitiesTests/` удалена. ~9700 стр.
- [x] **5 sync-гейтов в `StatusManager`** (`statusClient`, `purchasesClient`/`fetchAndMergeServerPurchases`, `syncJournalAndProgress`, `syncCalendarPurchasesOn*`, `processAuthStatus`, `conflictingSyncModel`+sheet в `HomeScreen`, `syncWithSiteDate`). Файл 1559 → 1107 строк. ~360 стр.
- [x] **Sync-блоки в 3 активных сервисах** (`DailyActivitiesService` 509→422 стр., `CustomExercisesService` 372→97 стр., `InfopostsService` 77→382 стр.). ~958 стр. production + 136 стр. тестов.

### keep (живые, не тронуты)

- [x] `WorkoutDataResponse.swift` (WatchConnectivity), `ProgressServiceTests.swift` (локальный `ProgressService`), sync-флаги `isSynced`/`shouldDelete`/`lastModified` (см. раздел 5).

## 2. Пакеты и native-замены

### Целиком мёртвые пакеты

- [ ] delete **SWNetwork** (~1412 стр.: 631 sources + 757 tests + 24 package). Каталог `SwiftUI-SotkaApp/Libraries/SWNetwork/` **всё ещё существует**. `import SWNetwork` в проде — 0 ссылок (после удаления `SWClient`/`CustomExercisesService` sync-блока). **Удаление требует:** удалить каталог + убрать пакет из `Package.swift`/`xcodeproj`. **Не выполнено в `ed82f6e9`** (выходит за рамки задачи «выполнить delete-теги» — требует модификации project-файлов).
- [ ] delete **SWKeychain** (~230 стр.). Каталог `SwiftUI-SotkaApp/Libraries/SWKeychain/` **всё ещё существует**. `import SWKeychain` в проде — 0 ссылок (после strip `AuthHelper`). **Не выполнено в `ed82f6e9`** по той же причине.

**Подитого пакетов на удаление: ~1642 стр. — не выполнено (out of scope).**

### Пакеты, которые оставляем

- [x] **Оставлены 3 живых пакета:** `CachedAsyncImage` (333 стр.), `SWDesignSystem` (1533 стр., 37 импортов), `SWUtils` (1613 стр. с тестами, 44 импорта). Не тронуты.

### Native-замены внутри пакетов

- [ ] native `SWAlert` (108 стр.) — UIKit alert (`UIAlertController`) с рекурсивным обходом VC. Все 5 потребителей (`OnlineLoginView`/`ChangePasswordScreen`/`EditProfileScreen`/`StatusManager:209`/`CountriesUpdateService:100`) удалены. Файл `SWUtils/Sources/SWUtils/SWAlert.swift` **всё ещё существует** (4.5 KB). `SWAlert.shared.presentNoConnection` нигде в проде не вызывается. **Удаление возможно сразу, но не входило в delete-этап.**
- [ ] delete `SWFileManager` (44 стр.) — ноль использований в проде. Файл `SWUtils/Sources/SWUtils/SWFileManager.swift` **всё ещё существует** (1.7 KB). **Не выполнено в `ed82f6e9`.**
- [ ] delete `DateFormatterService.readableDate` + хелпер `makeFormat` — `readableDate` вызывается только в `SWUtilsTests`. **Не выполнено в `ed82f6e9`.**
- [ ] delete `String.capitalizingFirstLetter` (3 стр.) — вызывается только в `SWUtilsTests`. **Не выполнено в `ed82f6e9`.**

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
**Подитого Review (tests): 646 стр. сохранены (7 тестовых файлов живы и входят в 982 passed).**

## 4. Другие мёртвые/yagni находки в приложении

### Watch-приложение

- [x] **Удалены `WatchWorkoutService.swift` + тесты (~285 стр.).** Реальная workout-логика — `WorkoutViewModel`. Watch ↔ iPhone синхронизация через `WatchConnectivityService`/`WCSession`/`WorkoutDataResponse` — не затронута.

### Прочее

- [ ] delete `ImageProcessor.createThumbnail` (3 стр.) — вызывается только из тестов. Файл `ImageProcessor.swift` (67 стр.) **живой**, метод `createThumbnail` (строка 27) — dead. **Не выполнено в `ed82f6e9`.**
- [ ] delete `InfopostAvailabilityManager.getAvailablePostsBySection` (4 стр.) — в проде используется только `filterAvailablePosts`. **Не выполнено в `ed82f6e9`.**

### PreviewContent остаток

- [x] `Client+.swift` удалён (`22dace92`). Демо-данные перенесены в `ScreenshotDemoData.seedDemoData()` (см. раздел 7).

### Новые мёртвые находки после `ed82f6e9` (не были в исходном аудите) [NEW]

Файлы, ставшие мёртвыми после удаления sync/DTO, но не отмеченные в исходном плане:

- [ ] [NEW] delete `Models/ConflictingStartDate.swift` (20 стр.) — использовался только `SyncStartDateScreen` (удалён). 0 ссылок в проде.
- [ ] [NEW] delete `Models/SWSharedModels/CalendarPurchasesResponse.swift` (28 стр.) — использовался только `StatusManager.syncJournalAndProgress()` (удалён). 0 ссылок в проде.
- [ ] [NEW] delete `Models/SWSharedModels/LoginCredentials.swift` (24 стр.) — использовался только `OnlineLoginView` (удалён). 0 ссылок в проде.
- [ ] [NEW] delete `Models/Progress/ProgressSnapshot.swift` (64 стр.) — использовался только `ProgressSyncService` (удалён). 0 ссылок в проде. Содержит `init(from: UserProgress)`, `photosForUpload` (для сервера) — мёртвые.

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

- [ ] `docs/daily-activities.md` — строки 126, 173: описывают `syncDailyActivities(context:) async throws -> SyncResult` (метод удалён).
- [ ] `docs/custom-exercises.md` — строки 86, 106: описывают `syncCustomExercises(context:)` (метод удалён).
- [ ] `docs/infoposts.md` — строка 82: описывает `syncReadPosts(context:)` (метод удалён).
- [ ] `docs/crash-swiftdata-invalid-future-backing-data.md` — строка 59: ссылается на `syncJournalAndProgress()` (метод удалён).
- [ ] `docs/testing-mocks.md` — описывает `MockDaysClient`/`MockProgressClient`/etc. со специфичными полями (`mockedDayResponses`, `errorToThrow`, `getReadPostsResult`). Удалённый `MockSWClient` был единственной реализацией этого API. Файл должен быть удалён или переписан под `MockStatusManager`/`MockWCSession`.
- [ ] `docs/ui-test-mock-client.md` — описывает `MockLoginClient`/`MockExerciseClient`/etc. (структуры удалены). Файл должен быть удалён.
- [ ] `docs/sync-journal.md` — **весь файл устарел** (53 стр., модель `SyncJournalEntry` и все связанные экраны/логика удалены). Должен быть удалён.
- [ ] `docs/data-migration.md` — строка 29: пример схемы содержит `SyncJournalEntry.self` (больше не существует). Список моделей в примере должен быть актуализирован или пример убран.
- [ ] `AGENTS.md` — строка 75: `Domain terms: ... SyncJournalEntry` — термин больше не существует, убрать из списка.

## 7. UI-тестовая инфраструктура: демо-данные (критическая ошибка аудита) [FIX]

**Обнаружено 2026-07-26, исправлено 2026-07-26 (коммит `22dace92`):** UI-тесты `testMakeScreenshots` падали после `ed82f6e9`, т.к. удалён код, создававший демо-данные. `22dace92` восстановил демо-данные прямым заполнением SwiftData.

### Как работало до удаления

`SwiftUI_SotkaAppApp.init()` при `UITest` вызывал `ScreenshotDemoData.setup()` (создавал `User`) и `createMockServices()` (создавал `StatusManager` с `MockSWClient` → мок-клиенты `Client+.swift` (~685 стр.) возвращали: 12 дней тренировок через `MockDaysClient.getDays()`; прогресс дня 1 через `MockProgressClient.getProgress()`; 3 демо-упражнения через `MockExerciseClient.getCustomExercises()`; `[1, 2, 3, 4, 5, 6, 7, 8, 9, 10]` прочитанных инфопостов через `MockInfopostsClient.getReadPosts()`). `setCurrentDayForDebug(12)` устанавливал день 12. Все 8 скриншотов проходили.

### Что сломано после удаления

`Client+.swift` лишился реализаций, `createMockServices()` создавал `StatusManager` без клиентов, `ScreenshotDemoData.setup()` создавал только голого `User`. `setCurrentDayForDebug(12)` работал корректно, но в SwiftData не было ни одной `DayActivity` — экран пуст, UI-тесты падали (`TodayActivityButton.0`, `progressTabButton`, `journalTabButton`, `customExercisesButton`).

### Что сделано в `22dace92` [FIX]

- [x] [FIX] **`ScreenshotDemoData.seedDemoData(context:user:)`**: создаёт 11 `DayActivity` (дни 1-11: 8 тренировок с `DayActivityTraining` [pullups/pushups/squats], 2 отдыха [дни 3, 7], 1 растяжка [день 10]). День 12 намеренно пуст — `HomeActivitySectionView` показывает `TodayActivityButton.0`. + `UserProgress` дня 1 (pullups:7, pushups:15, squats:30, weight:70), 3 `CustomExercise` («хлопковые отжимания», «запрыгивания на ящик», «бурпи»), `Country.makeDefaultCountry()`. Даты привязаны к `setCurrentDayForDebug(12)`: `baseDate = now - 11 дней`. **Отступление:** 11 вместо 12 — день 12 пуст для кнопок выбора типа.
- [x] [FIX] **`Client+.swift`** удалён целиком (−74 стр.). Демо-данные перенесены в `ScreenshotDemoData`.
- [x] [FIX] **`createMockServices()`**: добавлены `authHelper.performOfflineLogin()`, `try? Tips.resetDatastore()`, `UIView.setAnimationsEnabled(false)` для стабильности UI-тестов.

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

### Не выполнено в `ed82f6e9` + `22dace92` (оставлено на следующие итерации)

| Категория | Объём | Причина |
|---|---|---|
| `SWNetwork` пакет | ~1642 стр. (sources + tests) | Требует удаления каталога + правки `Package.swift`/`.xcodeproj`. ⚠️ После `ed82f6e9` 2 unit-теста всё ещё импортируют SWNetwork (`ErrorResponseTests.swift`, `DateDecodingRoundTripTests.swift`) — при удалении пакета нужно удалить и эти тесты |
| `SWKeychain` пакет | включено в SWNetwork | Та же причина |
| `SWAlert`, `SWFileManager`, `readableDate`, `capitalizingFirstLetter` в `SWUtils` | ~155 стр. | Выходит за рамки задачи. ⚠️ `SWAlert` и `SWFileManager` уже нигде не используются в проде (только в своих собственных тестах) |
| Review-слой yagni/shrink | ~237 стр. production + ~646 стр. тестов | Выходит за рамки задачи |
| `ImageProcessor.createThumbnail` | 3 стр. | Используется только в `ImageProcessorTests`. Не включено в коммит |
| `InfopostAvailabilityManager.getAvailablePostsBySection` | 4 стр. | Используется только в `InfopostAvailabilityManagerTests`. Не включено в коммит |
| **Новые мёртвые файлы [NEW]:** `ConflictingStartDate.swift`, `CalendarPurchasesResponse.swift`, `LoginCredentials.swift`, `ProgressSnapshot.swift` | ~136 стр. | Не отмечены в исходном аудите |
| **Устаревшая документация `docs/` + `AGENTS.md`** | 8 файлов: `daily-activities.md`, `custom-exercises.md`, `infoposts.md`, `crash-swiftdata-invalid-future-backing-data.md`, `testing-mocks.md`, `ui-test-mock-client.md`, **`sync-journal.md`** (весь файл устарел), **`data-migration.md`** (пример содержит `SyncJournalEntry.self`); + `AGENTS.md` строка 75 | Требует ревью и правки/удаления |
| **Демо-данные UI-тестов: readInfopostDays** | 1 константа | `ScreenshotDemoData.readInfopostDays = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]` объявлена, но не применяется к demo User. UI-тесты проходят и без применения (экраны инфопостов не тестируются на состояние «прочитано»). Рекомендация: применить через `user.addReadInfopostDay(_:)` или удалить константу |

### Контроль качества после `ed82f6e9` + `22dace92`

- iOS build: ✅ SUCCEEDED (iPhone 17 / iOS 27)
- Unit tests на iPhone 11 (iOS 26.5): ✅ **982 passed, 0 failed, 1 skipped** (было 1833 → −856 мёртвых тестов; +5 миграционных после `22dace92`)
- UI-тесты (скриншоты): ✅ **все проходят** (`testMakeScreenshots`, 8 скриншотов)
- Watch app ↔ iPhone sync через `WatchConnectivityService`/`WCSession`/`WorkoutDataResponse` — не сломана

### Супротив прошлого аудита (2026-07-21)

Добавлены `SyncStartDateScreen`/`HelpScreen`/`ChangePasswordScreen`/`EditProfileScreen`/`SyncResultBadge`/`SyncDateComparisonPolicy` + соответствующие тесты (~+2000 строк); добавлены sync-методы в активных сервисах (DailyActivities/CustomExercises/Infoposts) + 4 мёртвых протокола (+~1100 строк production, +136 строк тестов); удалены в `1c890e2` Periphery-чистки (учтены в новых счётчиках). `MockSWClient` помечен как **warning** — использовался в 14 unit-тестах `CustomExercisesServiceTests`. В `ed82f6e9` выбран **вариант (b)**: `MockSWClient` + тесты удалены целиком. `ProgressServiceTests` перенесён в keep (тестирует живой локальный `ProgressService`).

### Ошибки аудита (обе исправлены в `22dace92`)

1. **`MockSWClient` = UI-инфраструктура, а не мёртвый код.** Аудит классифицировал мок-реализации протоколов в `Client+.swift` как мёртвый код, не распознав их как UI-тестовые fixture-данные. Исправлено: SwiftData-seed в `ScreenshotDemoData` (11 `DayActivity` + `UserProgress` + 3 `CustomExercise` + `Country`); `Client+.swift` удалён; `createMockServices()` дополнен `performOfflineLogin()` + `Tips.resetDatastore()` + `UIView.setAnimationsEnabled(false)`.
2. **`SwiftDataMigrationTests` = критичный регресс.** Тест ошибочно удалён как «мёртвый» (ссылался на `SyncJournalEntry.self`). Исправлено: 5 тестов восстановлены (269 стр.), схемы адаптированы, добавлен `opensStoreAfterRemovingSyncJournalEntryAndPreservesData`.

CachedAsyncImage остаётся: `AsyncImage` + `URLCache` не решает мерцание при перерисовках ячеек, а кастомный `ImageLoader`/`ImageCache` даёт стабильное изображение без фаз загрузки. Удаление sync-флагов и Firebase в эту цифму не входят: флаги — вторая итерация с миграцией, Firebase — оставляем 100%.
