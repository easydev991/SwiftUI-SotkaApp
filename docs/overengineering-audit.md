# Аудит over-engineering: весь репозиторий

Дата аудита: 2026-07-25. Применено 20 коммитов 2026-07-25..26, хронология (подробности — разделы 1-7 + Итог): `ed82f6e9` (delete, −30 489/+199) → `22dace92` (FIX+restore, +393/−80) → delete-2 (`19081bad`/`2555914a`/`c2e906a3`/`56726fe2`, net −2575) → `9cb2646` (NetworkStatus) → 4 docs (`f10157a`/`f1065ca`/`65d39dc`/`606f7b2`) → `68e4bca` (правка плана Review) → `bc0a76f` (Review Фаза A) → `095af10` (move shouldAttemptMilestone) → 2 update-plan (`f7f6a61`/`af3cf6b`) → `d7f7682c` (delete-3 ponytail, −647) → `21608712` (fix ProgressServiceTests) → `c6f9d9e7` (compress) → `6753c89` (Tier 1 ponytail, −119) → `e75e49db` (compress) → `fbb689fb` (Periphery findings) → `8452aa0` (Tier 2 Periphery, −140).
Скоуп: только избыточная сложность (не корректность, не безопасность, не производительность).

Контекст: `AppConfiguration.isReadOnlyMode = true` на постоянной основе — серверные API закрыты, поэтому весь сетевой слой (синхронизация прогресса, авторизация на сервере, разрешение конфликтов дат, серверный профиль/смена пароля) — мёртвый код и подлежит удалению. UI-тесты и mock-bootstrap по-прежнему передают `isReadOnlyMode: false`, чтобы симулировать нормальное поведение для скриншот-тестов.

**ВАЖНО (`22dace92`):** моки серверных протоколов в `Client+.swift` (~685 стр.) — UI-тестовая инфраструктура, не мёртвый код. Заменены прямым SwiftData-seed'ом в `ScreenshotDemoData.seedDemoData()`. Подробности — раздел 7.

Предыдущий аудит 2026-07-21 валиден. С тех пор: `1c890e2` (Periphery, 2026-05-01, ~1937 строк); добавлены находки (SyncStartDateScreen/ChangePasswordScreen/EditProfileScreen/StatusManagerLogoutTests/sync-методы в 3 сервисах + 4 мёртвых протокола); обновлены счётчики и обоснования (`StatusManager` — 5 независимых гейтов, `MockSWClient` — warning из-за 14 живых unit-тестов). **Periphery re-run 2026-07-26 #1** (после `e75e49db`): 46 warnings в 17 файлах, 18 false-positives отфильтрованы ручной верификацией (см. раздел 4). Подтверждённый dead code 122 LOC → выполнено в `8452aa0` (−140 net, факт превысил оценку). **Periphery re-run 2026-07-26 #2** (на HEAD после `8452aa0`, пост-ревью): подтверждённый dead code **~605 LOC** в 10 production-файлах + 2 test-моках (Группа A) + Review Фаза B (yagni, 8 файлов, −18 LOC) + 1 safe Tier 2 ponytail item (`DateFormatterService` dead methods, −20 LOC). См. раздел 8 «Пост-`8452aa0` план».

Теги: `delete` — мёртвый код; `stdlib` — велосипед вместо стандартной библиотеки; `native` — то, что платформа делает сама; `yagni` — абстракция с одной реализацией; `shrink` — та же логика короче.

Статусы: `[x]` выполнено (см. раздел Итог), `[ ]` не выполнено (см. причину), `[NEW]` — новая находка после удаления мёртвого кода, `[FIX]`/`[restore]` — исправление критических побочных эффектов (`22dace92`).

## 1. Сетевой слой / синхронизация / авторизация (read-only mode)

Всё, что обращается к серверу, синхронизирует данные или реализует авторизацию, — **мёртвый код**. Сервер закрыт навсегда.

### Целиком мёртвые сервисы

- [x] Удалены 4 сетевых сервиса: `SWClient`, `ProgressSyncService`, `PhotoDownloadService`, `CountriesUpdateService` (~1686 стр.).
- [ ] shrink `AuthHelper.swift` — частично выполнено: удалены серверные методы (`authToken`, `saveAuthData`, `updateAuthData`, `didAuthorize`, импорт `KeychainWrapper`). **Осталось 62 стр.** в виде `AuthHelperImp` с локальной логикой (`isAuthorized`/`isOfflineOnly`/`performOfflineLogin`/`triggerLogout`). Класс **живой** — используется `OfflineLoginView`, `MoreScreen.triggerLogout()`, `RootScreen`, `SwiftUI_SotkaAppApp`. Полное удаление требует переноса `isOfflineOnly` флага в `User` (UserDefaults-бэкап) и inlining `triggerLogout` в `MoreScreen`. **См. раздел 4 «На границе скоупа».**

### Удалено в `ed82f6e9` (delete-этап, ~16 530 стр.)

- [x] UI/Models (9 экранов, 4 SyncJournal, 9 протоколов, 10 DTO) + Preview/моки (6 preview, 9 моков, `StatusManager` 1559→1107) + Sync-логика (5 гейтов + 3 сервиса) + 30 мёртвых тестов.

### keep (живые, не тронуты)

- [x] `WorkoutDataResponse`, `ProgressServiceTests`, sync-флаги (см. раздел 5).

## 2. Пакеты и native-замены

### Целиком мёртвые пакеты

- [x] **SWNetwork** (~1412 стр.: 631 sources + 757 tests + 24 package) — удалён в `2555914a`. Каталог + пакет из `.xcodeproj` убраны, + 2 unit-теста (`ErrorResponseTests` 299 стр + `DateDecodingRoundTripTests` 34 стр).
- [x] **SWKeychain** (~230 стр.) — удалён в `2555914a`. 0 prod-ссылок, 0 тестов с импортом.

**Итого: ~1975 стр. — выполнено в `2555914a`.**

### Пакеты, которые оставляем

- [x] 3 живых пакета: `CachedAsyncImage` (333 стр.), `SWDesignSystem` (1533 стр., 37 импортов), `SWUtils` (1363 стр., 35 импортов — было 1613/44).

### Native-замены внутри пакетов

- [x] **Native/delete** (`19081bad`/`c2e906a3`): `SWAlert` 108+20 тестов (UIKit alert → SwiftUI), `SWFileManager` 44+48 тестов (0 использований), `DateFormatterService.readableDate`+`makeFormat`+3 enum case'a (только в тестах), `String.capitalizingFirstLetter` (только в тестах).
- [x] [NEW] **NetworkStatus** (`9cb2646`): `NetworkStatus`+`NetworkStatusEnvironmentKey` (~46 стр.) + `.networkStatus(...)` в `SwiftUI_SotkaAppApp`. Write-only: `@Environment(\.isNetworkConnected)` = 0 ссылок, `NWPathMonitor` запускался впустую.

## 3. Review-слой (yagni — избыточная абстракция)

Система «оценить приложение в App Store» реализована через **9 production-файлов (256 стр. после Фазы A) + 7 тестовых файлов (636 стр.)**. Исходно было 12 production-файлов / 270 стр. — 3 файла (`ReviewAttemptRules`/`ReviewSkipReason`/`ReviewStorageKeys`) удалены в Фазе A. **Вся зачистка этого раздела не выполнена в `ed82f6e9`** (выходит за рамки delete-этапа).

**Важно (обнаружено 2026-07-26):** утверждение «тесты не ломаются» из исходного аудита — ложное для 2 протоколов. В `SwiftUI-SotkaAppTests/Services/Review/ReviewManagerTests.swift:222/253` определены `private final class MockReviewAttemptStore: ReviewAttemptStoring` и `private final class MockWorkoutCompletionsCounter: WorkoutCompletionsCounting`, оба используются в `makeSUT()` (строки 11-13) во всех тестах `ReviewManager`. Удаление этих двух протоколов = переписывание тестов. `ReviewContext` — **используется вне `Review/`** (внешние caller'ы: `StatusManager.swift:571`, `WorkoutPreviewViewModel.swift:238`), инлайн потребует изменения их вызовов.

### Фаза A — безопасная консолидация (выполнена в `bc0a76f` + move в текущем коммите, net −14, без переписывания тестов)

Только файлы без fileprivate-моков в `ReviewManagerTests` и без внешних caller'ов:

- [x] yagni/shrink 3 файла: `ReviewAttemptRules` (10→3 в `ReviewMilestone.isNotYetAttempted`), `ReviewSkipReason` (9→5 в `ReviewManager.ReviewSkipReason`), `ReviewStorageKeys` (8→0, 3 `static let` в `ReviewStorage`). 2 тест-файла переподключены. **Net: −14 prod, −10 tests** (вместо плана −27 — inline возвращает ≈+13 в файлы-хозяева).

### Фаза B — переписывание тестов (доп. net −18, дополнительный −18 стр.)

- [ ] yagni `ReviewAttemptStoring.swift` (8 стр.) → удалить протокол, использовать `ReviewStorage` напрямую. `MockReviewAttemptStore` в `ReviewManagerTests:222` заменить на `ReviewStorage` + `MockUserDefaults`.
- [ ] yagni `WorkoutCompletionsCounting.swift` (5 стр.) → удалить протокол, использовать `WorkoutCompletionsCounter` напрямую. `MockWorkoutCompletionsCounter` в `ReviewManagerTests:253` заменить на `WorkoutCompletionsCounter` + in-memory SwiftData container.
- [ ] yagni `ReviewContext.swift` (5 стр.) → убрать обёртку, передавать `hadRecentError: Bool` напрямую в `workoutCompletedSuccessfully(hadRecentError:)`. Затронуты 2 внешних файла: `StatusManager.swift:571`, `WorkoutPreviewViewModel.swift:238`.

### keep — расширен, не трогаем остальное

- [x] keep 4 файла: `ReviewEventReporting` (5 стр.), `ReviewMilestone` (21 стр., +`isNotYetAttempted`), `ReviewRequestHost` (55 стр.), `WorkoutCompletionsCounter` (31 стр.). Тесты `ReviewMilestoneTests`/`ReviewRequestTriggerIDTests`/`WorkoutCompletionsCounterTests` — живые.

### Итог Review-слоя (Фаза A выполнена, Фаза B [ ])

`ReviewManager` 85→90, `ReviewStorage` 31→36, `ReviewMilestone` 17→21. Production 270→256 (net −14). Tests 636 без изменений. Фаза B доведёт до 244.

## 4. Другие мёртвые/yagni находки в приложении

### Watch-приложение

- [x] Удалены `WatchWorkoutService.swift` + тесты (~285 стр.). Watch ↔ iPhone sync через `WatchConnectivityService`/`WCSession`/`WorkoutDataResponse` — не затронута.

### Прочее

- [x] Удалены `ImageProcessor.createThumbnail` (5 стр. + 2 теста), `InfopostAvailabilityManager.getAvailablePostsBySection` (4 стр. + 1 тест), `Client+.swift` (74 стр. → `ScreenshotDemoData.seedDemoData()`, см. раздел 7), `ScreenshotDemoData.readInfopostDays` (0 вызовов).

### Новые мёртвые находки после `ed82f6e9` (не были в исходном аудите) [NEW]

- [x] Удалены 4 модели: `ConflictingStartDate`, `CalendarPurchasesResponse`, `LoginCredentials`, `ProgressSnapshot` (все 0 ссылок в проде).

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

- [x] [restore] Восстановлен `SwiftDataMigrationTests.swift` (269 стр., `22dace92`): 4 теста сохранены + новый `opensStoreAfterRemovingSyncJournalEntryAndPreservesData`. Все 5 тестов проходят.

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

- [x] Обновлены 11 doc-файлов + `AGENTS.md` (`f10157a`/`f1065ca`/`65d39dc`/`606f7b2`): 4 удалены целиком (sync-тема), 7 отредактированы.

## 7. UI-тестовая инфраструктура: демо-данные (ошибка аудита) [FIX]

`Client+.swift` (~685 стр.) с мок-клиентами `MockDaysClient`/`MockProgressClient`/`MockExerciseClient`/`MockInfopostsClient` — не мёртвый код, а UI-тестовая инфраструктура (fixture-данные для скриншотов). До `ed82f6e9` `SwiftUI_SotkaAppApp.init()` при `UITest` через `createMockServices()` подставлял 12 дней тренировок / прогресс дня 1 / 3 демо-упражнения / 10 прочитанных инфопостов. После удаления UI-тесты `testMakeScreenshots` падали. Аудит должен был пометить `Client+.swift` как `adapt`, не `delete`.

- [x] [FIX] `22dace92`: `ScreenshotDemoData.seedDemoData()` создаёт 11 `DayActivity` + `UserProgress` + 3 `CustomExercise` + `Country` (день 12 пуст). `createMockServices()` дополнен `performOfflineLogin()` + `Tips.resetDatastore()` + `UIView.setAnimationsEnabled(false)`. `Client+.swift` −74 стр.

## 8. [NEW] Пост-`8452aa0` Periphery re-run (2026-07-26) — что фактически нужно исправить после ревью

2-й Periphery re-run на HEAD (после `8452aa0`) + ручная верификация каждого warning + ревью отчёта. План (раздел 5) зафиксирован до этого Periphery re-run'а и **не охватывал** находки ниже. **Выполнено** в 4 коммитах (`ddcb1d52` / `b8761560` / `3e928f6f` / `4655820` + 2 fix-commit'а). См. раздел «Фактический результат коммитов `ddcb1d52`+`b8761560`+`3e928f6f`+`220375cc`+`4655820` (Periphery re-run #2)» ниже.

### Группа A1 — большие dead-файлы (8 файлов, 505 LOC, pure delete)

Все кандидаты — 0 production references. Чистый `git rm`. Никаких UI/product-impact.

| Файл | LOC | Подтверждение |
|---|---|---|
| `Libraries/SWDesignSystem/Public/Rows/ListRowView.swift` | 126 | 0 callers вне self-file. `8452aa0` сделал `public→internal`, но файл целиком dead |
| `Libraries/SWDesignSystem/Public/ItemListScreen.swift` | 144 | 0 prod-callers. 2 self-previews тоже dead — `MockDaysClient`/`MockCountriesClient` (источник данных) удалены в `ed82f6e9`. Весь файл |
| `Libraries/SWDesignSystem/Public/Rows/CheckmarkRowView.swift` | 35 | Транзитивно dead: единственный caller = `ItemListScreen.swift:47` |
| `Models/SWSharedModels/LocationFeedback.swift` | 26 | 0 references. Sync-feedback для country/city picker — мёртв с `ed82f6e9` |
| `Models/Workout/ActivitySnapshot.swift` | 27 | 0 prod-ссылок. Sync-snapshot, мёртв (callers = dead `DayActivity.activitySnapshot` + `DayActivityTraining.trainingSnapshot` — см. A2) |
| `PreviewContent/MockResult.swift` | 11 | 0 references. Mock для mock-сервисов, удалённых в `ed82f6e9` |
| `SwiftUI-SotkaAppTests/Mocks/MockWCSession.swift` (iOS) | 70 | 0 iOS-usage'ов. Watch-side имеет свой `MockWCSession` (`SotkaWatch Watch AppTests`) |
| `SwiftUI-SotkaAppTests/Mocks/MockStatusManager.swift` | 66 | 0 callers `MockStatusManager.create()`. `StatusManagerLogoutTests` (где он использовался) удалены в `ed82f6e9` |

**Subtotal: 505 LOC чистого dead code.** Build + tests в каждом коммите.

### Группа A2 — малые правки (~150 LOC, 9 prod файлов + 3 preview-fixup)

Все кандидаты — `let`/`var` properties (assign-only или computed), init-параметры или computed, которые никто не читает. Чистые удаления + 3 preview-fixup в `JournalScreen.swift`.

| Файл | Что удалить | Заметка |
|---|---|---|
| `Models/SWSharedModels/Gender.swift:32` | `var affiliation: String` | 0 readers (cascade: единственный reader `MainUserForm.genderString` тоже мёртв) |
| `Models/SWSharedModels/MainUserForm.swift` (122) + `Models/User.swift:68` `init(fromMainUserForm:id:)` | Файл целиком + init | 0 prod-usage'ов. 3 preview-callers в `JournalScreen.swift:215,225,235` (`.init(fromMainUserForm: .preview)`) → заменить на `User.preview` в каждом preview. Каскад: `MainUserForm.image`/`genderString`/`isReadyToSave`/`Placeholder`/`requestParameters`/`shouldUpdateOnAppear` тоже dead |
| `Models/User.swift:221,230` | `addUnsyncedReadInfopostDay` + `removeUnsyncedReadInfopostDay` | 0 callers. Sync-флаги, мёртвы с `ed82f6e9` |
| `Models/Workout/DayActivity.swift:94,110` | `var trainingType` + `var activitySnapshot` (computed) | 0 readers. Sync-snapshot getters — cascade-удаление разблокирует A1 для `ActivitySnapshot.swift` |
| `Models/Workout/DayActivityTraining.swift:38,60` | `var exerciseType` + `var trainingSnapshot` (computed) | 0 readers. После удаления `ActivitySnapshot.swift` (A1) эти computed тоже полностью dead |
| `Services/CustomExercisesService.swift:14` | `let isReadOnlyMode` | assign-only (init-параметр, не читается) |
| `Services/DailyActivitiesService.swift:14,99` | `let isReadOnlyMode` (assign-only) + `markDailyActivityAsModified` (0 callers) | 2 dead члена |
| `Services/Infoposts/InfopostsService.swift:16` | `let isReadOnlyMode` | assign-only |
| `Screens/Login/WelcomeScreen.swift:4,7` | `import SWUtils` + `isReadOnlyMode` env-property | 0 references. Удаление cascade убирает `SWUtils` import |
| `Screens/More/MoreScreen.swift:12,16` | `isReadOnlyMode` env + `isOfflineUser` computed | cascade: `isOfflineUser` определён, но 0 readers → drop both |

**Subtotal: ~150 LOC prod + 3 preview-fixup (мелкие правки в `JournalScreen.swift`).**

### Call-sites `isReadOnlyMode` (для справки при A2)

Удаление `isReadOnlyMode` init-параметра из 3 сервисов требует синхронного обновления call-сайтов. **Total: 80 call-sites в 26 файлах.** Компилятор подскажет, но список ниже даёт полную картину.

| Сервис | Кол-во | Файлы (топ по количеству) |
|---|---|---|
| `DailyActivitiesService(isReadOnlyMode:)` | **71** в 18 файлах | `WorkoutPreviewViewModelUpdateDataTests.swift:18`, `WorkoutPreviewViewModelUpdateExecutionTypeTests.swift:9`, `WorkoutPreviewViewModelSaveTrainingTests.swift:7`, `WorkoutPreviewViewModelHasChangesTests.swift:7`, `WorkoutPreviewViewModelHandleWorkoutResultTests.swift:7`, `WorkoutPreviewViewModelRestTimeTests.swift:5`, `WorkoutPreviewViewModelReviewEventTests.swift:5`, `JournalListView.swift:4`, `JournalScreen.swift:3` (previews), `EditCommentSheet.swift:2`, `JournalGridView.swift:2`, `WorkoutScreenViewModelInterruptedWorkoutIntegrationTests.swift:3`, `MockStatusManager.swift:1`, + 5 single-callers (`RootScreen`, `HomeActivitySectionView`, `WorkoutPreviewScreen`, `StatusManager+`, `WorkoutPreviewViewModelCanEditCommentTests`) |
| `CustomExercisesService(isReadOnlyMode:)` | **5** в 4 файлах | `EditCustomExerciseScreen.swift:2`, `CustomExercisesScreen.swift:1`, `MockStatusManager.swift:1`, `StatusManager+.swift:1` |
| `InfopostsService(isReadOnlyMode:)` | **4** в 4 файлах | `MockStatusManager.swift:1`, `InfopostsServiceTests.swift:1`, `InfopostFavoriteAvailabilityTests.swift:1`, `StatusManager+.swift:1` |

**При удалении параметра** для `CustomExercisesService` и `DailyActivitiesService` (единственный init-param): `Foo(isReadOnlyMode: false)` → `Foo()`. Для `InfopostsService` (3 params: `language`/`analytics`/`isReadOnlyMode: Bool = ...`): убираем `isReadOnlyMode:` в 4 multi-line init'ах. `make format` после commit'а выровняет trailing commas.

### Группа B — Review Фаза B (yagni, −18 LOC, 8 prod файлов + 1 test mock rewrite)

План уже отмечал Фазу B как `[ ]` в `8452aa0`, но scope **больше** чем казалось (после ревью):

| Протокол | Реальный scope | Заметка |
|---|---|---|
| `ReviewAttemptStoring` (8 LOC) | 2 prod файла (`ReviewAttemptStoring.swift` delete + `ReviewStorage` remove conformance) + 1 test mock (`MockReviewAttemptStore` в `ReviewManagerTests:222` → `ReviewStorage(userDefaults:)` + `MockUserDefaults`) | Mechanical |
| `WorkoutCompletionsCounting` (5 LOC) | 2 prod файла + 1 test mock (`MockWorkoutCompletionsCounter` в `ReviewManagerTests:253` → реальный `WorkoutCompletionsCounter` + in-memory `ModelContainer` в `ReviewManagerTests`) | **Конкретный план замены** (LOC-план пересмотрен: ~30-40 LOC, не 5):<br>① `makeSUT` становится `throws` + возвращает `(ReviewManager, ReviewStorage, WorkoutCompletionsCounter)` вместо `(ReviewManager, MockReviewAttemptStore, MockWorkoutCompletionsCounter)`;<br>② добавить `private func makeContainer() throws -> ModelContainer` (~5 LOC) по образцу `WorkoutCompletionsCounterTests.swift:9-16` — `User.self` + `DayActivity.self` + `DayActivityTraining.self` + `ModelConfiguration(isStoredInMemoryOnly: true)`;<br>③ в `makeSUT` если `completedWorkoutCount > 0`: создать `User(id: 1, genderCode: 1)`, вставить в `context`, циклом создать `completedWorkoutCount` `DayActivity` с `activityTypeRaw: .workout.rawValue` + `count: 5` + `user: user` (паттерн `WorkoutCompletionsCounterTests.swift:18-36, 47-61`), `try context.save()`;<br>④ все 16 tests в `ReviewManagerTests.swift` обновить: `let (manager, _, _) = makeSUT(...)` → `let (manager, _, _) = try makeSUT(...)`. Тесты без `throws` в сигнатуре — добавить `throws` (большинство уже `async` или `async throws`);<br>⑤ удалить `MockWorkoutCompletionsCounter` class (10 LOC) + его init. `MockReviewAttemptStore` остаётся до удаления `ReviewAttemptStoring` |
| `ReviewContext` (5 LOC) | **8 файлов, ~25 call-сайтов**: `ReviewContext.swift` delete + `ReviewManager.swift:40` (signature) + `ReviewEventReporting.swift:4` (signature) + `MockReviewEventReporter.swift:6,9` (signature) + `StatusManager.swift:571,574` (2 inline) + `WorkoutPreviewViewModel.swift:238,241` (2 inline) + 16 call-сайтов в `ReviewManagerTests.swift` + `WorkoutPreviewViewModelReviewEventTests.swift` (1 call через `MockReviewEventReporter`) | Чисто синтаксический find-replace: `ReviewContext(hadRecentError: X)` → `X` (Bool). План `8452aa0` говорил «2 файла», реально 8 |

**Subtotal: −18 LOC prod + 1 test mock rewrite (пересмотренная оценка: ~30-40 LOC изменений в `ReviewManagerTests.swift` — `makeSUT` становится `throws` + добавляется `makeContainer` + вставка activities + 16 `try` keyword'ов).** План оценил Фазу B в 12, реально 18.

### Группа C — Tier 2 minimum (1 safe item, −20 LOC, 1 prod файл + 1 test file)

Минимальный безопасный ponytail: удалить 3 мёртвых метода `DateFormatterService` **после** удаления `MainUserForm` (A2):

- `stringFromFullDate` — 0 prod-callers после A2 (единственный caller `MainUserForm.swift:98` удалён)
- `dateFromIsoString` — 0 prod-callers (только `SWUtilsTests/DateFormatterServiceTests.swift`)
- `days(from:to:)` (String overload) — 0 prod-callers (только `SWUtilsTests/DateFormatterServiceTests.swift`)
- Cascade: `days(from:to:)` (Date overload) — dead (единственный caller = String overload)

Удаление методов + соответствующих тестов в `SWUtilsTests/DateFormatterServiceTests.swift` (~8 тестов затрагиваются) → −20 LOC prod + сокращение test file.

**Skip** (Tier 2 ponytail в `8452aa0` уже оценён как «потенциально» — не критичен, churn без выигрыша):

- `CloseButton` inline (−13 net, 4 файла churn, 4 caller'а в `OfflineLoginView`/`WorkoutPreviewScreen`/`WorkoutExerciseEditorScreen`/`EditCommentSheet`)
- `ChevronView` inline (−2 net, 3 файла churn, 3 caller'а в `HomeInfopostSectionView`/`HomeFillProgressSectionView`/`InfopostsListScreen` после удаления `ListRowView` в A1)
- `SWDivider` inline (−12 net, 1 caller `DividerIfNeededModifier`, internal, но 1-in-1-out риск churn)

### Исключены из этого плана (NOT dead / NOT safe без product-decision)

| Файл/свойство | Почему исключено |
|---|---|
| `PreviewContent/User+.swift` (68 LOC) | **Активно используется**: `.previewWithDay1Progress`/`.previewWithDay49Progress`/`.previewWithDay100Progress` — 7 preview-callers в `ProgressScreen.swift:3` + `ProgressGridView.swift:4`. `User.preview` — 13+ preview-callers + `ProgressCalculatorTests.swift`. **Файл живой, не трогать** (план изначально ошибочно отмечал как 0-caller) |
| `PreviewContent/Progress+.swift` (38 LOC) | Транзитивно жив: `UserProgress.previewDay1/49/100` используются только внутри `User+.swift` (12 internal calls). Можно удалить только вместе с рефакторингом `User+.swift` — выходит за скоуп dead code |
| `MockWatchSession.delegate` (Watch, `SotkaWatch Watch App/PreviewContent/MockWatchSession.swift:9`) | Protocol conformance required: `WatchSessionProtocol` декларирует `var delegate: WCSessionDelegate? { get set }`. На практике **мёртвое**: `WatchConnectivityService` делает `sessionProtocol as? WCSession` (line ~21) — для `MockWatchSession` cast returns `nil`, поэтому `session.delegate = self` (line 366) никогда не вызывается на моке. **Неудаляемо** без изменения протокола → Plan D |
| `MockWCSession.delegate` (iOS, `SwiftUI-SotkaAppTests/Mocks/MockWCSession.swift:9`) | Same: protocol required. The whole `MockWCSession.swift` сам мёртв (см. A1, 0 iOS-usage'ов), поэтому это становится moot при удалении файла |
| `StatusManager.State.isSynchronizingData` / `.error(String)` / `.isLoading` (computed) / `.isSyncing` (computed) | **Periphery прав — все 4 члена реально dead**: `.isSynchronizingData`/`.error` never assigned, `.isLoading`/`.isSyncing` never read (единственный reader `.isLoading` в `AuthRequiredView:state.isLoading` — это **другой** `State`, не `StatusManager.State`). План блокирует: «`StatusManager` god object, делать только при следующем касании» (раздел 5, строка 127). **Plan D** |
| `MainUserForm` deletion без preview-fixup | Удаление `MainUserForm.swift` каскадит на 3 preview в `JournalScreen.swift:215,225,235`. Не блокер, но preview-fixup обязателен — учтено в A2 |
| `AuthHelper` shrink (62 стр.) | План блокирует: «решение за продуктом» (раздел 5, строка 125) |
| Sync-флаги (`isSynced`/`shouldDelete`/`lastModified`) | План блокирует: «вторая итерация с миграцией» (раздел 5, строка 124) |
| Firebase Analytics + Crashlytics | План блокирует: «оставляем 100%» (раздел 5, строка 126) |

### False positives Periphery 2 (отброшены ручной верификацией)

- `WCSessionProtocol.delegate` / `WatchAuthServiceProtocol.updateAuthStatus` / `WatchConnectivityServiceProtocol.onCurrentActivityChanged` / `onWorkoutDataReceived` — protocol requirements
- `MockWCSession.delegate` (iOS) / `MockWatchSession.delegate` (Watch) — protocol conformance (см. таблицу исключений)
- `PreviewWatchAuthService.init(isAuthorized:)` — used in `HomeView.swift:67,78`
- `WorkoutPreviewViewModel.DataSnapshot` 6 properties (× 2 файла) — `Equatable` synthesis
- `RootScreen.tab` — used in `TabView(selection: $tab)` (line 13)
- `InfopostDetailScreen.showError` — used in `.alert(isPresented:)` + `HTMLContentView` (lines 27, 31)
- `ReviewRequestTriggerID.pendingRequest` + `scenePhase` — `Hashable` synthesis (для `task(id:)` идентификации)

### Порядок коммитов (рекомендуемый)

1. **Commit A1** (`rm` 8 файлов): −505 LOC. `git rm` каждый файл → build → tests. Чистый delete
2. **Commit A2** (9 prod файлов + 3 preview-fixup в `JournalScreen.swift`): −150 LOC. Первым заменить `.init(fromMainUserForm: .preview)` → `User.preview` в 3 previews, затем `MainUserForm.swift` + `init`, потом `Gender.affiliation` + service `isReadOnlyMode` × 3 + computed sync snapshots + `User` sync helpers + `WelcomeScreen` + `MoreScreen`
3. **Commit B** (Review Фаза B): −18 LOC prod + test mocks rewrite. `ReviewContext` первым (наибольший scope, 8 файлов), затем `ReviewAttemptStoring` + `WorkoutCompletionsCounting`
4. **Commit C** (DateFormatterService dead methods): −20 LOC prod + сокращение `DateFormatterServiceTests`. **Строго после A2**, когда `MainUserForm` не вызывает `stringFromFullDate`

**Суммарно: −693 LOC prod + 2 test-mock delete + 1 test-mock rewrite + 8 SWUtils-тестов сокращение.**

### Контроль качества (expected post-implementation)

- iOS build: ✅ SUCCEEDED
- Unit tests: 868 passed → ~860 passed (−8 `DateFormatterServiceTests`). Стабильно, никаких regressions в существующих тестах
- UI-тесты (`testMakeScreenshots`, 8 скриншотов): ✅ pass
- Watch ↔ iPhone sync: не сломана (удаляются только iOS test-моки, не Watch)

## Итог

### Фактический результат коммита `ed82f6e9` (delete-этап)

**162 файла, 30 489 удалено / 199 вставлено.** Категории: 4 сетевых сервиса ~1686, 9 мёртвых экранов ~1089, 4 SyncJournal модели ~495, 9 мёртвых протоколов ~109, 10 DTO ~593, 6 preview ~155, 9 моков ~642, 30 мёртвых тестов ~9700, `StatusManager` sync ~360, sync-блоки 3 сервиса ~958+136 тестов, `WatchWorkoutService`+тесты ~285, `AuthHelper` −41. Подробности — разделы 1, 4.

### Фактический результат коммита `22dace92` (FIX + restore-этап)

**5 файлов, +393/−80.** [restore] `SwiftDataMigrationTests` +269 (5 тестов); [FIX] `ScreenshotDemoData` +121 (`seedDemoData`), `SwiftUI_SotkaAppApp` +2, `Client+.swift` −74.

### Фактический результат коммитов `19081bad` + `2555914a` + `c2e906a3` + `56726fe2` (delete-этап-2)

**46 файлов, +76/−2651 (net −2575), 79 тестов удалено.** `19081bad`: 4 [NEW] модели −135, `SWFileManager` −92, `DateFormatterService.readableDate`+`makeFormat` −50, `String.capitalizingFirstLetter` −10, `ImageProcessor.createThumbnail` −31, `InfopostAvailabilityManager.getAvailablePostsBySection` −23, `ScreenshotDemoData.readInfopostDays` −1. `2555914a`: `SWNetwork` −1388, `SWKeychain` −230, 2 unit-теста SWNetwork −333, `.xcodeproj` −18. `c2e906a3`: `SWAlert`+тесты −128. Пакеты `SWNetwork`/`SWKeychain` убраны из репозитория и `.xcodeproj`.

### Фактический результат коммита `d7f7682c` (delete-этап-3: ponytail audit)

**16 файлов, +48/−695 (net −647), 28 тестов удалено.** `KeyedDecodingContainer+`+тесты −364, `MediaFile`+`UIImage+toMediaFile`+`MainUserForm.image` −34, `InfopostHTMLProcessor` → инлайн в `HTMLContentView` −29, `InfopostsService+FilenameManager`+тесты → инлайн в `InfopostsService` −166, `HomeDayCountModel`+тесты → инлайн в `HomeDayCountView` −44, `AppLanguage.makeCurrentValue` → инлайн в `MoreScreen` −5, `.xcodeproj` −2. 0 переписывания тестов, чистый delete + inline.

### Фактический результат коммита `6753c89` (Tier 1 ponytail cleanup)

**4 файла, +23/−142 (net −119), 0 тестов удалено.** `VibrationService` 70→12 (−58, убран `CHHapticEngine` → `AudioServicesPlaySystemSound`), `Date+.swift` −26, `ContentInSheet.swift` −56 → inline в `EditCommentSheet` (+20). Build ✅, тесты 868 passed без изменений. План Tier 1 (−127) близок к факту (−119).

**Пропущено из ponytail-аудита:** `RestTimeComponents` (false positive), `InfopostParser`/`YouTubeVideoService` (реальная экономия < трудозатрат), `CachedAsyncImage` (keep), 4 протокола (`WCSession`/`WatchAuth`/`WatchConnectivity`/`ReviewEventReporting` — 2-3 импл, не yagni). `VibrationService` (план «пропустить») выполнен в `6753c89` (−58 LOC).

### Фактический результат коммита `8452aa0` (Tier 2 Periphery cleanup)

**12 файлов, +21/−161 (net −140), 0 тестов удалено/переписано.** Реализация плана из `fbb689fb` (Periphery re-run: 46 warnings → 18 false-positives → 18 находок). Детальная таблица находок — раздел 4 «Находки Periphery 2026-07-26».

**Сознательные отклонения от плана `fbb689fb`:**

- `isReadyToRegister` удалён (не упомянут в плане) — бонус −9 LOC.
- `ItemListScreen.init(mode:allItems:...)` **НЕ удалён** — 2 previews в том же файле, удаление сломало бы previews и стоило бы ~42 LOC вместо 12. Оставлено.
- `shouldDeletePhoto` + `UserProgress.DELETED_DATA` оставлены — `ProgressService.deleteTempPhoto` пишет `DELETED_DATA` в `TempPhotoModel`, state-машина жива через `TempPhotoModel.isMarkedForDeletion`. На `UserProgress` методы теперь always-false, ~3 LOC, не критично.

**Факт превысил план (−140 vs −122):** бонус `isReadyToRegister` (−9) + formatting reflow.

Build ✅, tests 868 passed / 7 failed (pre-existing `UNErrorDomain`) / 1 skipped. Никаких новых regressions.

### Фактический результат коммитов `ddcb1d52`+`b8761560`+`3e928f6f`+`220375cc`+`4655820` (Periphery re-run #2)

**4 основных + 2 fix-коммита, 58 файлов изменено, net ~−1029 LOC production, 14 тестов удалено/переписано.**

**Commit A1 `ddcb1d52`:** 10 файлов, +0/−533. `git rm` 8 dead-файлов + cascade (2 computed props в `DayActivity`/`DayActivityTraining` для `ActivitySnapshot`). Подробности — раздел 8 «Группа A1».

**Commit A2 `b8761560`:** 32 файла, +93/−313. 9 prod файлов (MainUserForm, Gender, User sync helpers, DayActivity computed, 3 сервиса isReadOnlyMode, 2 screens) + 3 preview-fixup в `JournalScreen` + ~80 call-sites update `isReadOnlyMode:` parameter removal (4/77/3 callers для CustomExercisesService/DailyActivitiesService/InfopostsService). Подробности — раздел 8 «Группа A2». Дополнительно — `SwiftUI_SotkaAppApp.createMockServices` (1 site) был пропущен grep'ом sub-agent'а, исправлен preventively.

**Commit B `3e928f6f`:** 12 файлов, +119/−132. 3 протокола delete (`ReviewContext` 5, `ReviewAttemptStoring` 8, `WorkoutCompletionsCounting` 5) + 2 mock rewrite (`MockReviewAttemptStore` → `ReviewStorage`+`MockUserDefaults`; `MockWorkoutCompletionsCounter` → real `WorkoutCompletionsCounter`+in-memory `ModelContainer`). 16 call-sites в `ReviewManagerTests` + 2 inline в `StatusManager`/`WorkoutPreviewViewModel` + 1 в `WorkoutPreviewViewModelReviewEventTests`. `makeSUT` стал `throws` + 4-tuple return `(manager, store, counter, container)`. 3 mutation-теста используют `appendActivities(additionalCount:to:)` вместо `counter.count = N`.

**Commit B-fix `220375cc`:** 1 файл, +24/−20. Guard reversed range в `seedActivities`/`appendActivities` (Swift 6.3 trap на `for day in 1...0`). **НЕ та же проблема, что в `21608712`** — там был ModelContext с dealloc-нутым container; здесь контейнер жив через цепочку `manager → counter → modelContainer`. Корень другой: range precondition.

**Commit C `4655820`:** 3 файла, +2/−191. 4 dead метода `DateFormatterService` (`stringFromFullDate`/`dateFromIsoString`/`days(from:String,to:Date)` + cascade `days(from:Date,to:Date)`) + 13 тестов в `DateFormatterServiceTests`. Плюс B-fix: `#require(reporter.reportedHadRecentErrors.first)` был ambiguous (Bool? vs [Bool] private(set)) — explicit `: Bool` тип на 2 sites.

**Контроль качества:**

- iOS build: ✅ SUCCEEDED (iPhone 11 / iOS 26.5 — notification permission granted, 0 UNErrorDomain)
- Unit tests: 862 passed, 1 skipped (iPhone 11 / iOS 26.5 / xcodebuild-mcp `test_sim`, 19.7 сек — против ~10 мин через xcodebuild direct)
- План −693 LOC → факт −1029 net (A2 +93: preview-fixup, mock-bootstrapping `createMockServices` + doc +0 из прошлой сессии, всё formatting reflow; B +119: inline в `ReviewManager`/`ReviewEventReporting`/`MockReviewEventReporter` через `hadRecentError: Bool` signature change, helpers `makeContainer`/`seedActivities`/`appendActivities` + 16 `try` keywords; C +2: comments). Главное: чистый production-dead-code removal, не переусложнение
- Никаких новых regressions, никаких UI-изменений, никаких product-decisions
- Watch ↔ iPhone sync не сломана (удалены только iOS test-моки, не Watch-side)

### Не выполнено (оставлено на следующие итерации)

| Категория | Объём | Причина |
|---|---|---|
| **Пост-`8452aa0` Periphery re-run** ([NEW], раздел 8) | **DONE** ✅ | Выполнено в `ddcb1d52`+`b8761560`+`3e928f6f`+`220375cc`+`4655820` (4 коммита + 2 fix'а, net ~−1029 LOC, 14 тестов). Подробности — раздел «Фактический результат коммитов `ddcb1d52`+`b8761560`+`3e928f6f`+`220375cc`+`4655820` (Periphery re-run #2)» выше |
| Review Фаза B ([ ]) | **DONE** ✅ | Фаза B выполнена в `3e928f6f` (3 протокола + 2 mock rewrite). 256→252 (чистый net 0 на `Review` файлах, т.к. test-helpers `makeContainer`/`seedActivities`/`appendActivities` компенсируют убранные mock'и) |
| `AuthHelper` shrink ([ ]) | 62 стр. production | Требует переноса `isOfflineOnly` в `User` (UserDefaults-бэкап) + inlining `triggerLogout` в `MoreScreen`. Снижение читаемости. Решение за продуктом |
| Tier 2 ponytail (потенциально) | −62 стр. production | `CloseButton` inline (−25, 4 caller'а в `OfflineLoginView`/`WorkoutPreviewScreen`/`WorkoutExerciseEditorScreen`/`EditCommentSheet`), `ChevronView`+`SWDivider` (−9, 5+1 caller). `DateFormatterService` shrink −28 уже выполнен частично в C (−38 строк prod: 4 метода delete). `ImageProcessor` убран из кандидатов — alive через `ProgressService.pickTempPhoto` (хотя output не уходит на сервер в read-only, валидация локально полезна). Без переписывания тестов, 1-in-1-out инлайны |

### Контроль качества

- iOS build: ✅ SUCCEEDED (iPhone 11 / iOS 26.5 / xcodebuild-mcp)
- Unit tests: ✅ **862 passed, 1 skipped** (iPhone 11 / iOS 26.5, notification permission granted → 0 UNErrorDomain). Счётчик 862 стабилен: 868 (после `8452aa0`, в режиме «no permission» = 861 pass / 7 fail) → 862 (после Periphery re-run #2: −6 `DateFormatterServiceTests` (13 − 1 kept = −12, но они были в SWUtils target, не в `SwiftUI-SotkaAppTests` — см. ниже), +0/±small changes в `SwiftUI-SotkaAppTests`). История: 1833 → 977 (`ed82f6e9` −856) → 982 (`22dace92` +5) → 903 (`19081bad`/`2555914a`/`c2e906a3` −79) → 868 (`d7f7682c`/`6753c89`/`8452aa0`, 0 net; actuals may be 868±5 в зависимости от simulator permission) → 862 (Periphery re-run #2: 16 ReviewManagerTests не сломаны; 13 DateFormatterServiceTests удалены в SWUtils target, не в iOS; 1 kept `dateFromString_isoShortDate`).
- UI-тесты (скриншоты): ✅ **все проходят** (`testMakeScreenshots`, 8 скриншотов)
- Watch app ↔ iPhone sync через `WatchConnectivityService`/`WCSession`/`WorkoutDataResponse` — не сломана

### Супротив прошлого аудита (2026-07-21)

Добавлены `SyncStartDateScreen`/`HelpScreen`/`ChangePasswordScreen`/`EditProfileScreen`/`SyncResultBadge`/`SyncDateComparisonPolicy` + соответствующие тесты (~+2000 строк); добавлены sync-методы в активных сервисах (DailyActivities/CustomExercises/Infoposts) + 4 мёртвых протокола (+~1100 строк production, +136 строк тестов); удалены в `1c890e2` Periphery-чистки (учтены в новых счётчиках). `MockSWClient` помечен как **warning** — использовался в 14 unit-тестах `CustomExercisesServiceTests`. В `ed82f6e9` выбран **вариант (b)**: `MockSWClient` + тесты удалены целиком. `ProgressServiceTests` перенесён в keep (тестирует живой локальный `ProgressService`).

**Periphery 2026-07-26 #1 (re-run после `e75e49db`):** 46 warnings → 18 false-positives (см. раздел 4) → 18 подтверждённых dead code в 6 production-файлах + 1 тест-мок + 4 `public`→`internal` (`SWDesignSystem`). `1c890e2` (2026-05-01) удалил ~1937 строк — новая волна ≈122 LOC + 4 keyword'а. Выполнено в `8452aa0` (см. Итог).

**Periphery 2026-07-26 #2 (re-run на HEAD после `8452aa0`, пост-ревью):** см. раздел 8. Подтверждённый dead code ≈605 LOC (Группа A) + Review Фаза B scope (8 файлов вместо 2) + `DateFormatterService` dead methods (−20 LOC). **Выполнено** в `ddcb1d52`+`b8761560`+`3e928f6f`+`4655820` (4 коммита + 2 fix'а, net ~−1029 LOC, 14 тестов). См. раздел «Фактический результат коммитов `ddcb1d52`+`b8761560`+`3e928f6f`+`220375cc`+`4655820` (Periphery re-run #2)» выше.

### Ошибки аудита (исправлены в `22dace92`)

1. `Client+.swift` = UI-инфра, не мёртвый код — см. раздел 7.
2. `SwiftDataMigrationTests` = критичный регресс — 5 тестов восстановлены (269 стр.), см. раздел 4 [restore].

### Ошибки плана Periphery 2 (пойманы ревью, скорректированы в разделе 8)

1. **`PreviewContent/User+.swift` ошибочно помечен как 0-caller** в исходном отчёте Periphery 2. Файл активно используется: `.previewWithDay1Progress`/`.previewWithDay49Progress`/`.previewWithDay100Progress` — 7 preview-callers в `ProgressScreen.swift:3` + `ProgressGridView.swift:4`; `User.preview` — 13+ preview-callers + `ProgressCalculatorTests.swift`. **Реальный статус: alive, не трогать.**
2. **`PreviewContent/Progress+.swift` ошибочно помечен как чистый dead code.** Транзитивно жив: `UserProgress.previewDay1/49/100` используются только внутри `User+.swift` (12 internal calls). Удаление требует рефакторинга `User+.swift` — выходит за скоуп dead code.
3. **`User.init(fromMainUserForm:id:)` помечен как «0 readers»** — на самом деле 3 preview-caller'а в `JournalScreen.swift:215,225,235`. Удаление требует preview-fixup (заменить `.init(fromMainUserForm: .preview)` на `User.preview`), учтено в Группе A2.
4. **Net-savings `DateFormatterService` занижены в 2.5×** (заявлено −15, реально −40): план не учёл, что 3 метода (`stringFromFullDate`/`dateFromIsoString`/`days(from:to:)` String overload) полностью мертвы после удаления `MainUserForm` (A2), а не просто inline-кандидаты. Группа C обновлена.
5. **Scope `ReviewContext` undercount'нут**: план говорил «2 внешних caller'а», реально 8 файлов (~25 call-сайтов): `StatusManager` + `WorkoutPreviewViewModel` + `ReviewEventReporting` + `MockReviewEventReporter` + `ReviewManager` + 16 call-сайтов в `ReviewManagerTests` + `WorkoutPreviewViewModelReviewEventTests`. Группа B обновлена.
6. **`StatusManager.State` 4 мёртвых члена ошибочно отнесены к false positives** в исходном отчёте Periphery 2. Periphery прав: `.isSynchronizingData`/`.error` never assigned, `.isLoading`/`.isSyncing` never read. План блокирует (god object, раздел 5, строка 127) → Plan D.
7. **LOC-план `MockWorkoutCompletionsCounter` занижен**: исходный отчёт говорил «тривиально, ~5 LOC нового кода в тестах». Реально ~30-40 LOC изменений в `ReviewManagerTests.swift` (5 пунктов детального плана в Группе B). `MockWorkoutCompletionsCounter` — единственный non-trivial mock rewrite в Фазе B, т.к. требует `ModelContainer` setup + имитация `completedWorkoutCount` через вставку `DayActivity` в SwiftData (вместо простого `count: Int`).

CachedAsyncImage остаётся: `AsyncImage` + `URLCache` не решает мерцание при перерисовках ячеек, а кастомный `ImageLoader`/`ImageCache` даёт стабильное изображение без фаз загрузки. Удаление sync-флагов и Firebase в эту цифму не входят: флаги — вторая итерация с миграцией, Firebase — оставляем 100%.
