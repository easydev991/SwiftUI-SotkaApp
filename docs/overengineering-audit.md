# Аудит over-engineering: весь репозиторий

Дата аудита: 2026-07-25. Применено 19 коммитов 2026-07-25..26: `ed82f6e9` (delete) → `22dace92` (FIX+restore) → `19081bad`/`2555914a`/`c2e906a3`/`56726fe2` (delete-2: 4 [NEW] модели + SWFileManager + DateFormatter + String + ImageProcessor + Infopost + SWNetwork + SWKeychain + SWAlert + ScreenshotDemoData) → `9cb2646` (NetworkStatus) → `f10157a`/`f1065ca`/`65d39dc`/`606f7b2` (4 docs-этапа) → `68e4bca` (правка плана Review) → `bc0a76f` (Review Фаза A) → `095af10` (move shouldAttemptMilestone) → `f7f6a61`/`af3cf6b` (update-plan × 2) → `d7f7682c` (delete-3: ponytail audit — KeyedDecodingContainer+/MediaFile/InfopostHTMLProcessor/FilenameManager/HomeDayCountModel/AppLanguage, −647 LOC) → `21608712` (fix: ProgressServiceTests ModelContext crash) → `c6f9d9e7` (compress-plan: 229 → 220 строк) → `6753c89` (Tier 1 ponytail: VibrationService + Date+ + ContentInSheet, −119 LOC) → `e75e49db` (compress-plan: 234 → 167 строк).
Скоуп: только избыточная сложность (не корректность, не безопасность, не производительность).

Контекст: `AppConfiguration.isReadOnlyMode = true` на постоянной основе — серверные API закрыты, поэтому весь сетевой слой (синхронизация прогресса, авторизация на сервере, разрешение конфликтов дат, серверный профиль/смена пароля) — мёртвый код и подлежит удалению. UI-тесты и mock-bootstrap по-прежнему передают `isReadOnlyMode: false`, чтобы симулировать нормальное поведение для скриншот-тестов.

**ВАЖНО (`22dace92`):** моки серверных протоколов в `Client+.swift` (~685 стр.) — UI-тестовая инфраструктура, не мёртвый код. Заменены прямым SwiftData-seed'ом в `ScreenshotDemoData.seedDemoData()`. Подробности — раздел 7.

Предыдущий аудит 2026-07-21 валиден. С тех пор: `1c890e2` (Periphery, 2026-05-01, ~1937 строк); добавлены находки (SyncStartDateScreen/ChangePasswordScreen/EditProfileScreen/StatusManagerLogoutTests/sync-методы в 3 сервисах + 4 мёртвых протокола); обновлены счётчики и обоснования (`StatusManager` — 5 независимых гейтов, `MockSWClient` — warning из-за 14 живых unit-тестов). **Periphery re-run 2026-07-26** (после `e75e49db`): 46 warnings в 17 файлах, 18 false-positives отфильтрованы ручной верификацией (DataSnapshot struct Equatable, protocol-required properties, `Package.swift` build metadata). Подтверждённый dead code ≈122 LOC — раздел 4.

Теги: `delete` — мёртвый код; `stdlib` — велосипед вместо стандартной библиотеки; `native` — то, что платформа делает сама; `yagni` — абстракция с одной реализацией; `shrink` — та же логика короче.

Статусы: `[x]` выполнено в коммитах `ed82f6e9`/`22dace92`/`19081bad`/`2555914a`/`c2e906a3`/`56726fe2`/`9cb2646`/`f10157a`/`f1065ca`/`65d39dc`/`606f7b2`/`bc0a76f`/`095af10`/`f7f6a61`/`d7f7682c`/`21608712`/`c6f9d9e7`/`6753c89`/`e75e49db`, `[ ]` не выполнено (см. причину), `[NEW]` — новая находка, появившаяся после удаления мёртвого кода, `[FIX]`/`[restore]` — исправление критических побочных эффектов (коммит `22dace92`).

## 1. Сетевой слой / синхронизация / авторизация (read-only mode)

Всё, что обращается к серверу, синхронизирует данные или реализует авторизацию, — **мёртвый код**. Сервер закрыт навсегда.

### Целиком мёртвые сервисы

- [x] **Удалены 4 сетевых сервиса:** `SWClient`, `ProgressSyncService`, `PhotoDownloadService`, `CountriesUpdateService`. ~1686 стр.
- [ ] shrink `AuthHelper.swift` — частично выполнено: удалены серверные методы (`authToken`, `saveAuthData`, `updateAuthData`, `didAuthorize`, импорт `KeychainWrapper`). **Осталось 62 стр.** в виде `AuthHelperImp` с локальной логикой (`isAuthorized`/`isOfflineOnly`/`performOfflineLogin`/`triggerLogout`). Класс **живой** — используется `OfflineLoginView`, `MoreScreen.triggerLogout()`, `RootScreen`, `SwiftUI_SotkaAppApp`. Полное удаление требует переноса `isOfflineOnly` флага в `User` (UserDefaults-бэкап) и inlining `triggerLogout` в `MoreScreen`. **См. раздел 4 «На границе скоупа».**

### Удалено в `ed82f6e9` (delete-этап, ~16 530 стр.)

- [x] **UI/Models** (9 экранов, 4 SyncJournal, 9 протоколов, 10 DTO) + **Preview/моки** (6 preview, 9 моков, `StatusManager` 1559→1107) + **Sync-логика** (5 гейтов + 3 сервиса) + 30 мёртвых тестов.

### keep (живые, не тронуты)

- [x] `WorkoutDataResponse`, `ProgressServiceTests`, sync-флаги (см. раздел 5).

## 2. Пакеты и native-замены

### Целиком мёртвые пакеты

- [x] delete **SWNetwork** (~1412 стр.: 631 sources + 757 tests + 24 package) — удалён в `2555914a`. Каталог `SwiftUI-SotkaApp/Libraries/SWNetwork/` + пакет из `.xcodeproj` убраны. Также удалены 2 unit-теста из `SwiftUI-SotkaAppTests/Models/` (`ErrorResponseTests.swift` 299 стр + `DateDecodingRoundTripTests.swift` 34 стр).
- [x] delete **SWKeychain** (~230 стр.) — удалён в `2555914a`. Каталог + пакет убраны. 0 prod-ссылок, 0 тестов с импортом.

**Итого пакетов на удаление: ~1975 стр. (1642 sources/tests + 333 тестов) — выполнено в `2555914a`.**

### Пакеты, которые оставляем

- [x] **Оставлены 3 живых пакета:** `CachedAsyncImage` (333 стр.), `SWDesignSystem` (1533 стр., 37 импортов), `SWUtils` (1363 стр. с тестами, 35 импортов — было 1613/44). Не тронуты.

### Native-замены внутри пакетов

- [x] **Native/delete в пакетах** (19081bad/c2e906a3): `SWAlert` 108+20 тестов (UIKit alert → SwiftUI/нативный), `SWFileManager` 44+48 тестов (0 использований), `DateFormatterService.readableDate`+`makeFormat`+3 enum case'a (только в тестах), `String.capitalizingFirstLetter` (только в тестах).
- [x] [NEW] **NetworkStatus** (текущий коммит): `NetworkStatus`+`NetworkStatusEnvironmentKey` (~46 стр.), `@State`+`.networkStatus(...)` в `SwiftUI_SotkaAppApp.swift`. Write-only: `@Environment(\.isNetworkConnected)` = 0 ссылок, 0 тестов, 0 ссылок в Watch app — `NWPathMonitor` запускался впустую.

## 3. Review-слой (yagni — избыточная абстракция)

Система «оценить приложение в App Store» реализована через **9 production-файлов (256 стр. после Фазы A) + 7 тестовых файлов (636 стр.)**. Исходно было 12 production-файлов / 270 стр. — 3 файла (`ReviewAttemptRules`/`ReviewSkipReason`/`ReviewStorageKeys`) удалены в Фазе A. **Вся зачистка этого раздела не выполнена в `ed82f6e9`** (выходит за рамки delete-этапа).

**Важно (обнаружено 2026-07-26):** утверждение «тесты не ломаются» из исходного аудита — ложное для 2 протоколов. В `SwiftUI-SotkaAppTests/Services/Review/ReviewManagerTests.swift:222/253` определены `private final class MockReviewAttemptStore: ReviewAttemptStoring` и `private final class MockWorkoutCompletionsCounter: WorkoutCompletionsCounting`, оба используются в `makeSUT()` (строки 11-13) во всех тестах `ReviewManager`. Удаление этих двух протоколов = переписывание тестов. `ReviewContext` — **используется вне `Review/`** (внешние caller'ы: `StatusManager.swift:571`, `WorkoutPreviewViewModel.swift:238`), инлайн потребует изменения их вызовов.

### Фаза A — безопасная консолидация (выполнена в `bc0a76f` + move в текущем коммите, net −14, без переписывания тестов)

Только файлы без fileprivate-моков в `ReviewManagerTests` и без внешних caller'ов:

- [x] yagni/shrink 3 файла: `ReviewAttemptRules` (10→3 стр. в `ReviewMilestone.isNotYetAttempted`), `ReviewSkipReason` (9→5 в `ReviewManager.ReviewSkipReason`), `ReviewStorageKeys` (8→0, 3 `static let` в `ReviewStorage`). 2 тест-файла переподключены. **Net: −14 prod, −10 tests** (вместо плана −27 — inline возвращает ≈+13 в файлы-хозяева).

### Фаза B — переписывание тестов (доп. net −18, дополнительный −18 стр.)

- [ ] yagni `ReviewAttemptStoring.swift` (8 стр.) → удалить протокол, использовать `ReviewStorage` напрямую. `MockReviewAttemptStore` в `ReviewManagerTests:222` заменить на `ReviewStorage` + `MockUserDefaults`.
- [ ] yagni `WorkoutCompletionsCounting.swift` (5 стр.) → удалить протокол, использовать `WorkoutCompletionsCounter` напрямую. `MockWorkoutCompletionsCounter` в `ReviewManagerTests:253` заменить на `WorkoutCompletionsCounter` + in-memory SwiftData container.
- [ ] yagni `ReviewContext.swift` (5 стр.) → убрать обёртку, передавать `hadRecentError: Bool` напрямую в `workoutCompletedSuccessfully(hadRecentError:)`. Затронуты 2 внешних файла: `StatusManager.swift:571`, `WorkoutPreviewViewModel.swift:238`.

### keep — расширен, не трогаем остальное

- [x] keep 4 файла: `ReviewEventReporting` (5 стр.), `ReviewMilestone` (21 стр., +`isNotYetAttempted`), `ReviewRequestHost` (55 стр., SwiftUI+StoreKit), `WorkoutCompletionsCounter` (31 стр., concrete). Тесты `ReviewMilestoneTests`/`ReviewRequestTriggerIDTests`/`WorkoutCompletionsCounterTests` — все живые.

### Итог Review-слоя (Фаза A выполнена, Фаза B [ ])

`ReviewManager` 85 → 90, `ReviewStorage` 31 → 36, `ReviewMilestone` 17 → 21. Production 270 → 256 (net −14). Tests 636 без изменений (2 теста в `ReviewAttemptRulesTests` 26 → 16). Фаза B (план) доведёт до 256 → 244.

## 4. Другие мёртвые/yagni находки в приложении

### Watch-приложение

- [x] **Удалены `WatchWorkoutService.swift` + тесты (~285 стр.).** Реальная workout-логика — `WorkoutViewModel`. Watch ↔ iPhone синхронизация через `WatchConnectivityService`/`WCSession`/`WorkoutDataResponse` — не затронута.

### Прочее

- [x] Удалены `ImageProcessor.createThumbnail` (5 стр. + 2 теста), `InfopostAvailabilityManager.getAvailablePostsBySection` (4 стр. + 1 тест), `Client+.swift` (74 стр., демо-данные → `ScreenshotDemoData.seedDemoData()`, см. раздел 7), `ScreenshotDemoData.readInfopostDays` (1 константа, 0 вызовов).

### Новые мёртвые находки после `ed82f6e9` (не были в исходном аудите) [NEW]

- [x] [NEW] **Удалены 4 модели, ставшие мёртвыми после удаления sync/DTO:** `ConflictingStartDate`, `CalendarPurchasesResponse`, `LoginCredentials`, `ProgressSnapshot`. Все 0 ссылок в проде.

### Находки Periphery 2026-07-26 (после `e75e49db`) [NEW]

Periphery re-run дал 46 warnings в 17 файлах. После ручной верификации (grep по call-сайтам, проверка `@Observable` struct + `Equatable`, protocol-required properties) подтверждено **dead code ≈122 LOC** в 6 production-файлах + 1 тест-моке + 4 `public`→`internal` в `SWDesignSystem`:

| Файл | Находка | Объём | Обоснование |
|---|---|---|---|
| `Models/Progress/UserProgress.swift:88` | `var section: Section` (computed) | 4 стр. | 0 caller'ов, enum `Section` жив (используется в `ProgressGridView`/`User`) |
| `Models/Progress/UserProgress.swift:131` | `static func getExternalDayFromProgressId` | 12 стр. | server-day mapping, мёртв с `ed82f6e9` (0 caller'ов) |
| `Models/Progress/UserProgress.swift:147` | `static func getInternalDayFromExternalDay` | 12 стр. | обратная функция, мёртв (0 caller'ов) |
| `Models/Progress/UserProgress.swift:280` | `func deletePhotoData` | 15 стр. | 0 caller'ов (флаг `DELETED_DATA` пишется, но обработчика нет) |
| `Models/Progress/UserProgress.swift:317` | `func hasPhotosToDelete` | 5 стр. | 0 caller'ов |
| `Models/Progress/UserProgress.swift:324` | `func clearPhotoData` | 15 стр. | 0 caller'ов (фото не отправляются на сервер в read-only) |
| `Models/Progress/UserProgress.swift:341` | `func hasPhoto` | 10 стр. | 0 caller'ов |
| `Models/SWSharedModels/MainUserForm.swift:111` | `func isReadyToSave` | 25 стр. | 0 caller'ов (форма только для previews + `User.init(fromMainUserForm:)`) |
| `Models/SWSharedModels/Constants.swift:5,9` | `minPasswordSize`, `minUserAge` | 2 стр. | transitively dead (только из `isReadyToSave`) |
| `Models/DayCalculator.swift:17` | `let startDate: Date` | 1 стр. | 0 reader'ов, struct жив через static methods |
| `Models/City.swift` + `Country.cities: [City]` | `City` struct целиком + `cities` data | 25 стр. | `cities` пишется в `makeDefaultCountry()`, не читается; `City.id`/`name`/`lat`/`lon` — 0 reader'ов в app коде |
| `SotkaWatchTests/Mocks/MockWatchConnectivityService.swift:21` | `requestedCurrentActivityDay` | 1 стр. | assign-only (`private(set) var`), 0 reader'ов в тестах |
| `Libraries/SWDesignSystem/.../SectionView.swift` | `public struct` + `public init` × 3 + `public extension` | 0 LOC | redundant public (используется только в `ItemListScreen.swift:39` + previews внутри пакета) |
| `Libraries/SWDesignSystem/.../SWDivider.swift` | `public struct` + `public init` + `public body` | 0 LOC | redundant public (используется только в `DividerIfNeededModifier.swift:15` + preview) |
| `Libraries/SWDesignSystem/.../Rows/ListRowView.swift` | `public struct` + `public extension` | 0 LOC | unused outside file (только previews) |
| `Libraries/SWDesignSystem/.../ItemListScreen.swift:23` | `init(mode:allItems:...)` | 12 стр. | 0 caller'ов вне previews |

**False positives (отброшены):** 6 `WorkoutPreviewViewModel` assign-only — это `let`-свойства `private struct DataSnapshot` (`Equatable` comparison в `hasChanges`); `PreviewWatchAuthService.init(isAuthorized:)` — используется в `HomeView.swift:67,78`; `WatchAuthServiceProtocol.updateAuthStatus` — production call в `WatchConnectivityService.swift:366`; `MockWCSession.delegate` / `MockWatchSession.delegate` — `WatchSessionProtocol` requires `var delegate: WCSessionDelegate? { get set }`; `Libraries/SWDesignSystem/Package.swift:6:5 package` — build metadata.

### Ошибочно удалённые тесты [restore]

`SwiftDataMigrationTests.swift` был удалён в `ed82f6e9` как «мёртвый», потому что ссылался на `SyncJournalEntry.self`. **Удаление было ошибкой** — тесты проверяли критичный сценарий (открытие старого SwiftData store + сохранение данных при изменении схемы).

- [x] [restore] **Восстановлен `SwiftDataMigrationTests.swift`** (269 стр., `22dace92`): 4 теста сохранены + новый `opensStoreAfterRemovingSyncJournalEntryAndPreservesData` (миграция пользователя с онлайн-историей). Все 5 тестов проходят.

## 5. На границе скоупа (не находки, решение за продуктом / оставить сейчас)

- Sync-флаги (`isSynced`, `shouldDelete`, `lastModified`) — оставляем на первой итерации. Без синхронизации они теряют смысл, но удаление их из SwiftData-моделей требует миграции (lightweight для nullable-полей или manual/поэтапная с обработкой существующих данных). Временные затраты и риск ошибки миграции/потери данных не оправданы ради чистоты. Второй итерацией их можно удалить вместе с плановой миграцией SwiftData.
- `AuthHelper` (62 стр. после strip серверной части) — жив и нужен: `OfflineLoginView` использует `performOfflineLogin()`, `MoreScreen` использует `triggerLogout()`. Полное удаление = inlining `isOfflineOnly` флага в `User` + перенос `triggerLogout` напрямую в `MoreScreen`. Чистый gain −62 стр., но снижение читаемости (User-логика + UI-логика смешиваются). **Решение за продуктом: оставить / удалить.**
- Firebase (Analytics + Crashlytics): оставляем 100%. Crashlytics полезен и офлайн (очередь + отправка при сети); Analytics — продуктовое решение. Слой провайдеров мал (~115 стр.), оставить.
- `StatusManager` (1107 стр. после чистки) — god object; экстракция `WatchCommandHandler`/`CalendarExtensionManager` нейтральна по строкам, делать только при следующем касании.
- `WorkoutProgramCreator` (449 стр.) — активно используется 3 ViewModels, не мёртвый. Оставить.
- `AnalyticsService` (317 стр.) — Firebase-провайдер функционален, протокол для тестируемости. Не over-engineering.
- `WorkoutPreviewViewModel`, `WorkoutScreenViewModel`, `DailyActivitiesService` (422 стр.) — крупные, но выполняют реальные функции. YAGNI не применяется.

## 6. Устаревшая документация (требует обновления вне `ed82f6e9`/`22dace92`)

Все файлы описывали удалённый sync-слой:

- [x] **11 doc-файлов + `AGENTS.md` обновлены** (`f10157a`/`f1065ca`/`65d39dc`/`606f7b2`): 4 удалены целиком (sync-тема), 7 отредактированы (`AGENTS.md:75` — убран `SyncJournalEntry`).

## 7. UI-тестовая инфраструктура: демо-данные (ошибка аудита) [FIX]

`Client+.swift` (~685 стр.) с мок-клиентами `MockDaysClient`/`MockProgressClient`/`MockExerciseClient`/`MockInfopostsClient` — не мёртвый код, а UI-тестовая инфраструктура (fixture-данные для скриншотов). До `ed82f6e9` `SwiftUI_SotkaAppApp.init()` при `UITest` через `createMockServices()` подставлял 12 дней тренировок / прогресс дня 1 / 3 демо-упражнения / 10 прочитанных инфопостов. После удаления UI-тесты `testMakeScreenshots` падали. Аудит должен был пометить `Client+.swift` как `adapt`, не `delete`.

- [x] [FIX] `22dace92`: `ScreenshotDemoData.seedDemoData()` создаёт 11 `DayActivity` + `UserProgress` + 3 `CustomExercise` + `Country` (день 12 пуст для type-buttons). `createMockServices()` дополнен `performOfflineLogin()` + `Tips.resetDatastore()` + `UIView.setAnimationsEnabled(false)`. `Client+.swift` удалён (−74 стр.).

## Итог

### Фактический результат коммита `ed82f6e9` (delete-этап)

**162 файла изменено, 30 489 удалено / 199 вставлено.** Категории: 4 сетевых сервиса ~1686, 9 мёртвых экранов ~1089, 4 SyncJournal модели ~495, 9 мёртвых протоколов ~109, 10 DTO ~593, 6 preview ~155, 9 моков ~642, 30 мёртвых тестов ~9700, `StatusManager` sync ~360, sync-блоки 3 сервиса ~958+136 тестов, `WatchWorkoutService`+тесты ~285, `AuthHelper` −41. Подробности — разделы 1, 4.

### Фактический результат коммита `22dace92` (FIX + restore-этап)

**5 файлов изменено, 393 вставлено / 80 удалено.** [restore] `SwiftDataMigrationTests` +269 (5 тестов); [FIX] `ScreenshotDemoData` +121 (`seedDemoData`), `SwiftUI_SotkaAppApp` +2 (UI-test bootstrap), `Client+.swift` −74.

### Фактический результат коммитов `19081bad` + `2555914a` + `c2e906a3` + `56726fe2` (delete-этап-2)

**46 файлов изменено, 76 вставлено / 2651 удалено (net −2575), 79 тестов удалено.** `19081bad`: 4 [NEW] модели (−135), `SWFileManager` (−92), `DateFormatterService.readableDate`+`makeFormat` (−50), `String.capitalizingFirstLetter` (−10), `ImageProcessor.createThumbnail` (−31), `InfopostAvailabilityManager.getAvailablePostsBySection` (−23), `ScreenshotDemoData.readInfopostDays` (−1). `2555914a`: пакет `SWNetwork` (−1388), пакет `SWKeychain` (−230), 2 unit-теста SWNetwork (−333), `.xcodeproj` (−18). `c2e906a3`: `SWAlert`+тесты (−128). Пакеты SWNetwork/SWKeychain полностью убраны из репозитория и `.xcodeproj`.

### Фактический результат коммита `d7f7682c` (delete-этап-3: ponytail audit)

**16 файлов изменено, 48 вставлено / 695 удалено (net −647), 28 тестов удалено.** `KeyedDecodingContainer+`+тесты (−364), `MediaFile`+`UIImage+toMediaFile`+`MainUserForm.image` (−34), `InfopostHTMLProcessor` → инлайн в `HTMLContentView` (−29), `InfopostsService+FilenameManager`+тесты → инлайн в `InfopostsService` (−166), `HomeDayCountModel`+тесты → инлайн в `HomeDayCountView` (−44), `AppLanguage.makeCurrentValue` → инлайн в `MoreScreen` (−5), `.xcodeproj` (−2). 0 переписывания тестов, чистый delete + inline.

### Фактический результат коммита `6753c89` (Tier 1 ponytail cleanup)

**4 файла изменено, 23 вставлено / 142 удалено (net −119), 0 тестов удалено.** `VibrationService` 70→12 (−58, убран `CHHapticEngine` → `AudioServicesPlaySystemSound`), `Date+.swift` −26 (0 caller'ов), `ContentInSheet.swift` −56 (inline в `EditCommentSheet`), `EditCommentSheet` +20 (inline). Build ✅, тесты 875 passed без изменений (7 pre-existing `UNErrorDomain` failures — notification permission в симуляторе). План Tier 1 (−127) близок к факту (−119).

**Пропущено из ponytail-аудита:** `RestTimeComponents` (false positive), `InfopostParser`/`YouTubeVideoService` (реальная экономия < трудозатрат), `CachedAsyncImage` (keep), 4 протокола (`WCSession`/`WatchAuth`/`WatchConnectivity`/`ReviewEventReporting` — 2-3 импл, не yagni). `VibrationService` (план «пропустить») выполнен в `6753c89` (−58 LOC).

### Не выполнено в `ed82f6e9` + `22dace92` + `19081bad` + `2555914a` + `c2e906a3` + `56726fe2` + `d7f7682c` + `21608712` + `c6f9d9e7` + `6753c89` (оставлено на следующие итерации)

| Категория | Объём | Причина |
|---|---|---|
| Review Фаза B ([ ]) | −12 стр. production (256 → 244) | Фаза A выполнена (`bc0a76f`+move, −14 стр.). Phase B blocked: 2 fileprivate-мока в `ReviewManagerTests:222/253` + 2 внешних caller'а `StatusManager:571` + `WorkoutPreviewViewModel:238`. Реальный net Фазы A = −14 (не −27): inline + move добавляют 13 стр. в файлы-хозяева |
| `AuthHelper` shrink ([ ]) | 62 стр. production | Требует переноса `isOfflineOnly` в `User` (UserDefaults-бэкап) + inlining `triggerLogout` в `MoreScreen`. Снижение читаемости. Решение за продуктом |
| Tier 2 ponytail (потенциально) | −82 стр. production | `DateFormatterService` shrink (−48, 2 caller'а: `DayActivityHeaderView:27` `dateWithWeekday`, `MainUserForm:98` `stringFromFullDate`; +4 теста удаляются), `CloseButton` inline (−25, 4 caller'а в `OfflineLoginView`/`WorkoutPreviewScreen`/`WorkoutExerciseEditorScreen`/`EditCommentSheet`), `ChevronView`+`SWDivider` (−9, 5+1 caller). Без переписывания тестов, 1-in-1-out инлайны. `ImageProcessor` убран из кандидатов — alive через `ProgressService.pickTempPhoto` (хотя output не уходит на сервер в read-only, валидация локально полезна). Решение за продуктом |
| Tier 2 Periphery cleanup (потенциально) | −122 стр. production + 4 `public`→`internal` | `UserProgress` 7 dead (~75 стр.), `MainUserForm.isReadyToSave` + `Constants` 2 мёртвых (≈27), `City` + `Country.cities` (≈25), `DayCalculator.startDate` (1), `MockWatchConnectivityService.requestedCurrentActivityDay` (1), `ItemListScreen.init(mode:allItems:...)` (12), `SWDesignSystem` `public`→`internal` (`SectionView`/`SWDivider`/`ListRowView`/`ItemListScreen` — 0 LOC). Подробности + false-positives в разделе 4 «Находки Periphery 2026-07-26». Без переписывания тестов (кроме удаления). Решение за продуктом |

### Контроль качества после `ed82f6e9` + `22dace92` + `19081bad` + `2555914a` + `c2e906a3` + `56726fe2` + `d7f7682c` + `21608712` + `c6f9d9e7` + `6753c89`

- iOS build: ✅ SUCCEEDED (iPhone 17 / iOS 27)
- Unit tests: ✅ **875 passed, 1 skipped** + 7 pre-existing `UNErrorDomain` failures (notification permission в симуляторе; при grant — проходят). Счётчик 875 стабилен с `d7f7682c`. История: 1833 → 977 (`ed82f6e9` −856) → 982 (`22dace92` +5) → 903 (`19081bad`/`2555914a`/`c2e906a3` −79) → 875 (`d7f7682c` −28).
- UI-тесты (скриншоты): ✅ **все проходят** (`testMakeScreenshots`, 8 скриншотов)
- Watch app ↔ iPhone sync через `WatchConnectivityService`/`WCSession`/`WorkoutDataResponse` — не сломана

### Супротив прошлого аудита (2026-07-21)

Добавлены `SyncStartDateScreen`/`HelpScreen`/`ChangePasswordScreen`/`EditProfileScreen`/`SyncResultBadge`/`SyncDateComparisonPolicy` + соответствующие тесты (~+2000 строк); добавлены sync-методы в активных сервисах (DailyActivities/CustomExercises/Infoposts) + 4 мёртвых протокола (+~1100 строк production, +136 строк тестов); удалены в `1c890e2` Periphery-чистки (учтены в новых счётчиках). `MockSWClient` помечен как **warning** — использовался в 14 unit-тестах `CustomExercisesServiceTests`. В `ed82f6e9` выбран **вариант (b)**: `MockSWClient` + тесты удалены целиком. `ProgressServiceTests` перенесён в keep (тестирует живой локальный `ProgressService`).

**Periphery 2026-07-26 (re-run после `e75e49db`):** 46 warnings → 18 false-positives (см. раздел 4) → 18 подтверждённых dead code в 6 production-файлах + 1 тест-мок + 4 `public`→`internal` (`SWDesignSystem`). `1c890e2` (2026-05-01) удалил ~1937 строк — новая волна ≈122 LOC + 4 keyword'а.

### Ошибки аудита (исправлены в `22dace92`)

1. `Client+.swift` = UI-инфра, не мёртвый код — см. раздел 7.
2. `SwiftDataMigrationTests` = критичный регресс — 5 тестов восстановлены (269 стр.), см. раздел 4 [restore].

CachedAsyncImage остаётся: `AsyncImage` + `URLCache` не решает мерцание при перерисовках ячеек, а кастомный `ImageLoader`/`ImageCache` даёт стабильное изображение без фаз загрузки. Удаление sync-флагов и Firebase в эту цифму не входят: флаги — вторая итерация с миграцией, Firebase — оставляем 100%.
