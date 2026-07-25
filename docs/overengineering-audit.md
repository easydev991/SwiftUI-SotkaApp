# Аудит over-engineering: весь репозиторий

Дата аудита: 2026-07-25. Дата фактического применения `delete`-этапа: 2026-07-26 (коммит `d184f37`).
Скоуп: только избыточная сложность (не корректность, не безопасность, не производительность).

Контекст: `AppConfiguration.isReadOnlyMode = true` на постоянной основе — серверные API закрыты, поэтому весь сетевой слой (синхронизация прогресса, авторизация на сервере, разрешение конфликтов дат, серверный профиль/смена пароля) — мёртвый код и подлежит удалению. UI-тесты и mock-bootstrap по-прежнему передают `isReadOnlyMode: false`, чтобы симулировать нормальное поведение для скриншот-тестов.

Предыдущий аудит от 2026-07-21 — большая часть находок остаётся валидной. Изменения с момента прошлого аудита: коммит `1c890e2` (Periphery-чистка от 2026-05-01, ~1937 строк) уже удалил часть мёртвого кода из SWDesignSystem/SWUtils/SWKeychain/PreviewContent; добавлены находки, которых не было в прошлом аудите (`SyncStartDateScreen`, `ChangePasswordScreen`, `EditProfileScreen`, `StatusManagerLogoutTests`, `StatusManagerProcessAuthStatusTests`, sync-методы в `DailyActivitiesService`/`CustomExercisesService`/`InfopostsService` + связанные мёртвые протоколы). Линейные счётчики обновлены. Исправлены обоснования (`StatusManager` — перечислены 5 независимых гейтов вместо «всё после строки 153»; `MockSWClient` помечен warning из-за 14 живых unit-тестов).

Теги: `delete` — мёртвый код; `stdlib` — велосипед вместо стандартной библиотеки; `native` — то, что платформа делает сама; `yagni` — абстракция с одной реализацией; `shrink` — та же логика короче.

Статусы: `[x]` выполнено в коммите `d184f37`, `[ ]` не выполнено (см. причину), `[NEW]` — новая находка, появившаяся после удаления мёртвого кода.

## 1. Сетевой слой / синхронизация / авторизация (read-only mode)

Всё, что обращается к серверу, синхронизирует данные или реализует авторизацию, — **мёртвый код**. Сервер закрыт навсегда.

### Целиком мёртвые сервисы

- [x] **Удалены 4 сетевых сервиса:** `SWClient.swift` (420), `ProgressSyncService.swift` (1095), `PhotoDownloadService.swift` (56), `CountriesUpdateService.swift` (115). ~1686 стр.
- [ ] shrink `AuthHelper.swift` — частично выполнено: удалены серверные методы (`authToken`, `saveAuthData`, `updateAuthData`, `didAuthorize`, импорт `KeychainWrapper`). **Осталось 62 стр.** в виде `AuthHelperImp` с локальной логикой (`isAuthorized`/`isOfflineOnly`/`performOfflineLogin`/`triggerLogout`). Класс **живой** — используется `OfflineLoginView`, `MoreScreen.triggerLogout()`, `RootScreen`, `SwiftUI_SotkaAppApp`. Полное удаление требует переноса `isOfflineOnly` флага в `User` (UserDefaults-бэкап) и inlining `triggerLogout` в `MoreScreen`. **См. раздел 4 «На границе скоупа».**

### Целиком мёртвые экраны

- [x] **Удалены 9 мёртвых экранов** (`OnlineLoginView`, `ChangePasswordScreen`, `EditProfileScreen`, `SyncStartDateScreen`, `SyncStartDateHelpScreen`, `SyncJournalScreen`, `SyncJournalEntryDetailsScreen`, `SyncJournalRowView`, `SyncResultBadge`). На смену `OnlineLoginView` — живой `OfflineLoginView`. ~1089 стр.

### Мёртвые модели журнала синхронизации

- [x] **Удалены 4 модели** (`SyncJournalEntry`, `SyncJournalDateGroup`, `SyncResult`, `SyncDateComparisonPolicy`). Директория `Models/SyncJournal/` удалена. ~495 стр.

### Мёртвые протоколы клиентов

- [x] **Удалена вся директория `Services/Protocols/`** (9 протоколов): `LoginClient`, `ProfileClient`, `PurchasesClient`, `DaysClient`, `ExerciseClient`, `InfopostsClient`, `ProgressClient`, `StatusClient`, `CountriesClient`. `WelcomeScreen.client` параметр удалён. ~109 стр.

### Мёртвые Request/Response DTO

- [x] **Удалены 10 серверных DTO** (`DayRequest/Response`, `ProgressRequest/Response`, `CustomExerciseRequest/Response`, `UserResponse`, `CountryResponse`, `CityResponse`, `CurrentRunResponse`). ~593 стр.
- [x] keep `WorkoutDataResponse.swift` (45 стр.) — используется WatchConnectivity. **Живой, не тронут.**

### Мёртвые preview-файлы

- [x] **Удалены 6 preview-файлов:** `SyncJournalEntry+`, `DayProgressStatus+`, `Infopost+`, `MockSWClient` (вариант b — вместе с sync-тестами `CustomExercisesServiceTests`), `ReviewManager+`, `UserResponse+`.
- [x] `StatusManager+.swift` — **переписан**, не удалён (preview-расширения нужны для превью: `StatusManager.preview`, `previewWithCalendarExtension`, `previewWithCalendarExtensionDay130`).

### Мёртвые тесты

- [x] **Удалены 16 sync/Progress/DailyActivities/SyncJournal-тестов** (`ProgressSyncServiceTests`, `MixedPhotoOperationsTests`, `ProgressSyncServicePhotoTests`, `PhotoDownloadServiceTests`, `ProgressClientTests`, `CountriesUpdateServiceTests`, `AuthHelperTests`, `StatusManagerSyncJournalTests`, `StatusManagerSyncDateTests`, `StatusManagerLogoutTests`, `StatusManagerProcessAuthStatusTests`, `InfopostsServiceSyncTests`, `SyncJournalEntryTests`, `SyncJournalDateGroupTests`, `SyncResultTests`, `SyncJournalRowViewTests`). ~6524 стр.
- [x] **Дополнительно удалены 14 тестов**, ставших мёртвыми после удаления DTO (`DailyActivitiesBasicOperationsTests`, `DailyActivitiesConflictResolutionTests`, `DailyActivitiesErrorHandlingTests`, `DailyActivitiesServiceTests`, `DailyActivitiesCommentTests`, `DailyActivitiesGetLastPassedWorkoutTests`, `DailyActivitiesSetMethodTests`, `DailyActivitiesTrainingsTests`, `DailyActivitiesUpdateExistingCrashTests`, `DayActivityTests`, `MainUserFormTests`, `UserProgressTests`, `ProgressPhotoDataTests`, `ExerciseSnapshotTests`, `SwiftDataMigrationTests`). Вся директория `DailyActivitiesTests/` удалена. ~3200 стр.
- [x] keep `ProgressServiceTests.swift` (335 стр.) — тестирует локальный `ProgressService`. **Живой, не тронут.**

### Мёртвые моки серверных протоколов

- [x] **Удалены все 9 моков серверных протоколов** (`MockAuthHelper`, `MockStatusClient`, `MockDaysClient`, `MockExerciseClient`, `MockInfopostsClient`, `MockProgressClient`, `MockPurchasesClient`, `MockPhotoDownloadService`, `MockCountriesClient`). `Mocks/` оставлен только с живыми: `MockReviewEventReporter`, `MockStatusManager`, `MockUserDefaults`, `MockWCSession`. ~642 стр.

### Дополнительная чистка в StatusManager

- [x] **Удалены все 5 sync-гейтов в `StatusManager`:** `statusClient` (в `getStatus()` и `startNewRun()`), `purchasesClient` + `fetchAndMergeServerPurchases`, `syncJournalAndProgress()`, `syncCalendarPurchasesOnGetStatus`/`OnSyncJournal`, `processAuthStatus()`, `conflictingSyncModel` + sheet в `HomeScreen`, `syncWithSiteDate()`. Файл сократился с 1559 → 1107 строк. ~360 стр.
- [x] keep sync-флаги `isSynced`, `shouldDelete`, `lastModified` на моделях — **оставлены** (см. раздел 5 «На границе скоупа»).

### Sync-методы в активных сервисах

- [x] **Удалены sync-блоки в 3 активных сервисах:** `DailyActivitiesService` (sync: `syncDailyActivities`, `syncUnsyncedActivities`, `runSyncTasks`, `performNetworkSync`, `applySyncEvents`, `downloadServerActivities`, `updateLocalFromServer`, `makeActivitySnapshotsForSync`, `SyncEvent`, `AlreadySyncingError` — 509 стр. → файл 422 стр.); `CustomExercisesService` (`syncCustomExercises` и его сетевой блок — 372 стр. → файл 97 стр.); `InfopostsService` (`syncReadPosts`, `moveDaysToSynced`, `infopostsClient.setPostRead` — 77 стр. → файл 382 стр.). ~958 стр. production + 136 стр. тестов (`ProgressClientTests`).

## 2. Пакеты и native-замены

### Целиком мёртвые пакеты

- [ ] delete **SWNetwork** (~1412 стр.: 631 sources + 757 tests + 24 package). Каталог `SwiftUI-SotkaApp/Libraries/SWNetwork/` **всё ещё существует**. `import SWNetwork` в проде — 0 ссылок (после удаления `SWClient`/`CustomExercisesService` sync-блока). **Удаление требует:** удалить каталог + убрать пакет из `Package.swift`/`xcodeproj`. **Не выполнено в `d184f37`** (выходит за рамки задачи «выполнить delete-теги» — требует модификации project-файлов).
- [ ] delete **SWKeychain** (~230 стр.). Каталог `SwiftUI-SotkaApp/Libraries/SWKeychain/` **всё ещё существует**. `import SWKeychain` в проде — 0 ссылок (после strip `AuthHelper`). **Не выполнено в `d184f37`** по той же причине.

**Подитого пакетов на удаление: ~1642 стр. — не выполнено (out of scope).**

### Пакеты, которые оставляем

- [x] **Оставлены 3 живых пакета:** `CachedAsyncImage` (333 стр.), `SWDesignSystem` (1533 стр., 37 импортов), `SWUtils` (1613 стр. с тестами, 44 импорта). Не тронуты.

### Native-замены внутри пакетов

- [ ] native `SWAlert` (108 стр.) — UIKit alert (`UIAlertController`) с рекурсивным обходом VC. Все 5 потребителей (`OnlineLoginView`/`ChangePasswordScreen`/`EditProfileScreen`/`StatusManager:209`/`CountriesUpdateService:100`) удалены. Файл `SWUtils/Sources/SWUtils/SWAlert.swift` **всё ещё существует** (4.5 KB). `SWAlert.shared.presentNoConnection` нигде в проде не вызывается. **Удаление возможно сразу, но не входило в delete-этап.**
- [ ] delete `SWFileManager` (44 стр.) — ноль использований в проде. Файл `SWUtils/Sources/SWUtils/SWFileManager.swift` **всё ещё существует** (1.7 KB). **Не выполнено в `d184f37`.**
- [ ] delete `DateFormatterService.readableDate` + хелпер `makeFormat` — `readableDate` вызывается только в `SWUtilsTests`. **Не выполнено в `d184f37`.**
- [ ] delete `String.capitalizingFirstLetter` (3 стр.) — вызывается только в `SWUtilsTests`. **Не выполнено в `d184f37`.**

## 3. Review-слой (yagni — избыточная абстракция)

Система «оценить приложение в App Store» реализована через 12 файлов. **Вся зачистка этого раздела не выполнена в `d184f37`** (выходит за рамки delete-этапа — тесты были удалены вместе с sync-слоем, но yagni-схлопывание слоёв не сделано).

### yagni — протоколы с одной реализацией

- [ ] yagni `ReviewAttemptRules.swift` (10 стр.) — **живой** (вызывается из `ReviewManager.shouldAttemptMilestone()`).
- [ ] yagni `ReviewAttemptStoring.swift` (8 стр.) — **живой** (конформит `ReviewStorage`).
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
**Подитого Review (tests): 646 стр. → 0 (net −646) — частично выполнено: тесты Review-уровня удалены вместе с sync-слоем.**

## 4. Другие мёртвые/yagni находки в приложении

### Watch-приложение

- [x] **Удалены `WatchWorkoutService.swift` (78) + тесты (207).** Реальная workout-логика — `WorkoutViewModel` (живой, 0 ссылок на `WatchWorkoutService` в проде). Watch ↔ iPhone синхронизация через `WatchConnectivityService`/`WCSessionProtocol`/`WorkoutDataResponse`/`WatchStatusMessage` — не затронута. ~285 стр.

### Прочее

- [ ] delete `ImageProcessor.createThumbnail` (3 стр.) — вызывается только из тестов. Файл `ImageProcessor.swift` (67 стр.) **живой**, метод `createThumbnail` (строка 27) — dead. **Не выполнено в `d184f37`.**
- [ ] delete `InfopostAvailabilityManager.getAvailablePostsBySection` (4 стр.) — в проде используется только `filterAvailablePosts`. **Не выполнено в `d184f37`.**

### PreviewContent остаток

- [ ] shrink `Client+.swift` — **частично выполнено**: с 685 стр. до 74 стр. (содержит 7 тривиальных struct-стабов `MockLoginClient`/`MockExerciseClient`/`MockProgressClient`/`MockInfopostsClient`/`MockDaysClient`/`MockProfileClient`/`MockCountriesClient` с `MockResult`/`instantResponse` свойствами). **Все 7 стабов не используются нигде в коде** (только в `docs/ui-test-mock-client.md`/`docs/testing-mocks.md`). Файл можно удалить целиком, оставив только `MockResult` (live, в `PreviewContent/MockResult.swift`). **Финальная зачистка не выполнена в `d184f37`.**

### Новые мёртвые находки после `d184f37` (не были в исходном аудите) [NEW]

Файлы, ставшие мёртвыми после удаления sync/DTO, но не отмеченные в исходном плане:

- [ ] [NEW] delete `Models/ConflictingStartDate.swift` (20 стр.) — использовался только `SyncStartDateScreen` (удалён). 0 ссылок в проде.
- [ ] [NEW] delete `Models/SWSharedModels/CalendarPurchasesResponse.swift` (28 стр.) — использовался только `StatusManager.syncJournalAndProgress()` (удалён). 0 ссылок в проде.
- [ ] [NEW] delete `Models/SWSharedModels/LoginCredentials.swift` (24 стр.) — использовался только `OnlineLoginView` (удалён). 0 ссылок в проде.
- [ ] [NEW] delete `Models/Progress/ProgressSnapshot.swift` (64 стр.) — использовался только `ProgressSyncService` (удалён). 0 ссылок в проде. Содержит `init(from: UserProgress)`, `photosForUpload` (для сервера) — мёртвые.

## 5. На границе скоупа (не находки, решение за продуктом / оставить сейчас)

- Sync-флаги (`isSynced`, `shouldDelete`, `lastModified`) — оставляем на первой итерации. Без синхронизации они теряют смысл, но удаление их из SwiftData-моделей требует миграции (lightweight для nullable-полей или manual/поэтапная с обработкой существующих данных). Временные затраты и риск ошибки миграции/потери данных не оправданы ради чистоты. Второй итерацией их можно удалить вместе с плановой миграцией SwiftData.
- `AuthHelper` (62 стр. после strip серверной части) — жив и нужен: `OfflineLoginView` использует `performOfflineLogin()`, `MoreScreen` использует `triggerLogout()`. Полное удаление = inlining `isOfflineOnly` флага в `User` + перенос `triggerLogout` напрямую в `MoreScreen`. Чистый gain −62 стр., но снижение читаемости (User-логика + UI-логика смешиваются). **Решение за продуктом: оставить / удалить.**
- Firebase (Analytics + Crashlytics): оставляем 100%. Crashlytics полезен и офлайн (очередь + отправка при сети); Analytics — продуктовое решение. Слой провайдеров мал (~115 стр.), оставить.
- `StatusManager` (1107 стр. после чистки) — god object; экстракция `WatchCommandHandler`/`CalendarExtensionManager` нейтральна по строкам, делать только при следующем касании.
- `WorkoutProgramCreator` (449 стр.) — активно используется 3 ViewModels, не мёртвый. Оставить.
- `AnalyticsService` (317 стр.) — Firebase-провайдер функционален, протокол для тестируемости. Не over-engineering.
- `WorkoutPreviewViewModel`, `WorkoutScreenViewModel`, `DailyActivitiesService` (422 стр.) — крупные, но выполняют реальные функции. YAGNI не применяется.

## 6. Устаревшая документация (требует обновления вне `d184f37`)

Следующие файлы `docs/` всё ещё описывают удалённый sync-слой:

- [ ] `docs/daily-activities.md` — строки 126, 173: описывают `syncDailyActivities(context:) async throws -> SyncResult` (метод удалён).
- [ ] `docs/custom-exercises.md` — строки 86, 106: описывают `syncCustomExercises(context:)` (метод удалён).
- [ ] `docs/infoposts.md` — строка 82: описывает `syncReadPosts(context:)` (метод удалён).
- [ ] `docs/crash-swiftdata-invalid-future-backing-data.md` — строка 59: ссылается на `syncJournalAndProgress()` (метод удалён).
- [ ] `docs/testing-mocks.md` — описывает `MockDaysClient`/`MockProgressClient`/etc. со специфичными полями (`mockedDayResponses`, `errorToThrow`, `getReadPostsResult`). Удалённый `MockSWClient` был единственной реализацией этого API. Файл должен быть удалён или переписан под `MockStatusManager`/`MockWCSession`.
- [ ] `docs/ui-test-mock-client.md` — описывает `MockLoginClient`/`MockExerciseClient`/etc. (структуры удалены). Файл должен быть удалён.

## Итог

### Фактический результат коммита `d184f37`

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

### Не выполнено в `d184f37` (оставлено на следующие итерации)

| Категория | Объём | Причина |
|---|---|---|
| `SWNetwork` пакет | ~1642 стр. | Требует удаления каталога + правки `Package.swift`/`.xcodeproj` |
| `SWKeychain` пакет | включено в SWNetwork | Та же причина |
| `SWAlert`, `SWFileManager`, `readableDate`, `capitalizingFirstLetter` в `SWUtils` | ~155 стр. | Выходит за рамки задачи |
| Review-слой yagni/shrink | ~237 стр. production + ~646 стр. тестов | Выходит за рамки задачи |
| `ImageProcessor.createThumbnail` | 3 стр. | Не включено в коммит |
| `InfopostAvailabilityManager.getAvailablePostsBySection` | 4 стр. | Не включено в коммит |
| `Client+.swift` финальная зачистка (удалить 7 неиспользуемых struct-стабов, оставить `MockResult`) | ~74 стр. | Выходит за рамки задачи |
| **Новые мёртвые файлы [NEW]:** `ConflictingStartDate.swift`, `CalendarPurchasesResponse.swift`, `LoginCredentials.swift`, `ProgressSnapshot.swift` | ~136 стр. | Не отмечены в исходном аудите |
| **Устаревшая документация `docs/`** | 6 файлов | Требует ревью и правки |

### Контроль качества после `d184f37`

- iOS build: ✅ SUCCEEDED (iPhone 17 / iOS 27)
- Unit tests на iPhone 11 (iOS 26.5): ✅ **977 passed, 0 failed, 1 skipped** (было 1833 → −856 мёртвых тестов)
- Watch app ↔ iPhone sync через `WatchConnectivityService`/`WCSession`/`WorkoutDataResponse` — **не сломана** (подтверждено проверкой зависимостей)

### Супротив прошлого аудита (2026-07-21)

Добавлены `SyncStartDateScreen`/`HelpScreen`/`ChangePasswordScreen`/`EditProfileScreen`/`SyncResultBadge`/`SyncDateComparisonPolicy` + соответствующие тесты (~+2000 строк); добавлены sync-методы в активных сервисах (DailyActivities/CustomExercises/Infoposts) + 4 мёртвых протокола (DaysClient/ExerciseClient/InfopostsClient/ProgressClient) (+~1100 строк production, +136 строк тестов); удалены в коммите `1c890e2` Periphery-чистки (учтены в новых счётчиках). `MockSWClient` помечен как **warning** — использовался в 14 unit-тестах `CustomExercisesServiceTests`. В `d184f37` выбран **вариант (b)**: `MockSWClient` + тесты удалены целиком (sync-тесты всё равно мёртвы). `ProgressServiceTests` перенесён из удаления в keep (тестирует живой локальный `ProgressService`).

CachedAsyncImage остаётся: `AsyncImage` + `URLCache` не решает мерцание при перерисовках ячеек, а кастомный `ImageLoader`/`ImageCache` даёт стабильное изображение без фаз загрузки. Удаление sync-флагов и Firebase в эту цифму не входят: флаги — вторая итерация с миграцией, Firebase — оставляем 100%.