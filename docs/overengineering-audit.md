# Аудит over-engineering: весь репозиторий

Дата аудита: 2026-07-25. Применено 44 коммита 2026-07-25..2026-08-01, хронология (подробности — разделы 1-8 + Итог): `ed82f6e9` (delete, −30 489/+199) → `22dace92` (FIX+restore, +393/−80) → delete-2 (`19081bad`/`2555914a`/`c2e906a3`/`56726fe2`, net −2575) → `9cb2646` (NetworkStatus) → 4 docs (`f10157a`/`f1065ca`/`65d39dc`/`606f7b2`) → `68e4bca` (правка плана Review) → `bc0a76f` (Review Фаза A) → `095af10` (move shouldAttemptMilestone) → 2 update-plan (`f7f6a61`/`af3cf6b`) → `d7f7682c` (delete-3 ponytail, −647) → `21608712` (fix ProgressServiceTests) → `c6f9d9e7` (compress) → `6753c89` (Tier 1 ponytail, −119) → `e75e49db` (compress) → `fbb689fb` (Periphery findings) → `8452aa0` (Tier 2 Periphery, −140) → Periphery re-run #2: `ddcb1d52`/`b8761560`/`3e928f6f`/`220375cc`/`4655820` (5 коммитов, ~−1029, раздел 8) → пост-чистки: `a63ef811` (Tier 2 inline: DividerIfNeededModifier + withDivider, −35 LOC) → `738e24d8` (docs) → `fd040669` (docs compress) → `1f051228` (SWDivider rm + doc drift, −13 LOC) → `fff7e885` (Watch schemes cosmetic, xcodebuild artifact) → `9a1fc327` (план update+compress) → `97c75839` (план: исправлены 8 фактических ошибок) → `8dfdf312` (план compress) → `de6d535` (restore logout flow, +164, см. §9 Tier 1) → `69fce28a` (Tier 1 follow-up: modelContainer.mainContext + getStatus автостарт, +47, см. §9 Tier 1) → **`6b28f00` (Tier 2: AuthHelper.isOfflineOnly −19 LOC, см. §9 Tier 2)** → **`fd5f845` (deprecated-аннотации @available: 12 полей User + sync-флагов, +12 LOC, см. §9 Sync/server fields)** → **`24ebd8d` (i18n: перевод deprecated-сообщений на русский, 12 строк)** → **`916e0194` (markPostAsRead: убраны лишние Task-обёртки)** → **`ef400e6e` (план: добавлены новые находки §10)** → **`7cc61231` (план: уточнены Safety check + SWTextField в §10)** → волна §10: **`3648fc2` (Группа E: SectionView + SectionHeaderView, −198)** → **`a3c7f8f` (Группа H: ReadOnlyModeKey, −6)** → **`af6a5bd` (Группа G: SWUtils dead extensions, −248)** → **`381ee78` (Группа F: ImageAssetManager test-only, −173)** → **`fc5efb0` (Группа D: Watch VM dead members, −493)** → **`626cc77` (план: §10 помечен выполненным)**. **Σ §10: −1118 строк за 5 prod-коммитов.**
Скоуп: только избыточная сложность (не корректность, не безопасность, не производительность).

Контекст: `AppConfiguration.isReadOnlyMode = true` на постоянной основе — серверные API закрыты, поэтому весь сетевой слой (синхронизация прогресса, авторизация на сервере, разрешение конфликтов дат, серверный профиль/смена пароля) — мёртвый код и подлежит удалению. UI-тесты и mock-bootstrap по-прежнему передают `isReadOnlyMode: false`, чтобы симулировать нормальное поведение для скриншот-тестов.

**ВАЖНО (`22dace92`):** моки серверных протоколов в `Client+.swift` (~685 стр.) — UI-тестовая инфраструктура, не мёртвый код. Заменены прямым SwiftData-seed'ом в `ScreenshotDemoData.seedDemoData()`. Подробности — раздел 7.

Предыдущий аудит 2026-07-21 валиден. С тех пор: `1c890e2` (Periphery, 2026-05-01, ~1937 строк); добавлены находки (SyncStartDateScreen/ChangePasswordScreen/EditProfileScreen/StatusManagerLogoutTests/sync-методы в 3 сервисах + 4 мёртвых протокола); обновлены счётчики и обоснования (`StatusManager` — 5 независимых гейтов, `MockSWClient` — warning из-за 14 живых unit-тестов). **Periphery re-run 2026-07-26 #1** (после `e75e49db`): 46 warnings в 17 файлах, 18 false-positives отфильтрованы ручной верификацией (см. раздел 4). Подтверждённый dead code 122 LOC → выполнено в `8452aa0` (−140 net, факт превысил оценку). **Periphery re-run 2026-07-26 #2** (на HEAD после `8452aa0`, пост-ревью): подтверждённый dead code **~605 LOC** в 10 production-файлах + 2 test-моках (Группа A) + Review Фаза B (yagni, 8 файлов, −18 LOC) + 1 safe Tier 2 ponytail item (`DateFormatterService` dead methods, −20 LOC). См. раздел 8 «Пост-`8452aa0` план». **2026-08-01:** план пересмотрен после уточнения пользовательского сценария (existing authorized vs new offline-only, раздел 9): `AuthHelper` переклассифицирован (корректная локальная абстракция, не over-engineering), sync-флаги и obsolete `User`-поля помечаются `// OBSOLETE: ...` комментариями без миграции (по решению продукта).

Теги: `delete` — мёртвый код; `stdlib` — велосипед вместо стандартной библиотеки; `native` — то, что платформа делает сама; `yagni` — абстракция с одной реализацией; `shrink` — та же логика короче.

Статусы: `[x]` выполнено (см. раздел Итог), `[ ]` не выполнено (см. причину), `[NEW]` — новая находка после удаления мёртвого кода, `[FIX]`/`[restore]` — исправление критических побочных эффектов (`22dace92`).

## 1. Сетевой слой / синхронизация / авторизация (read-only mode)

Всё, что обращается к серверу, синхронизирует данные или реализует авторизацию, — **мёртвый код**. Сервер закрыт навсегда.

### Целиком мёртвые сервисы

- [x] Удалены 4 мёртвых сетевых сервиса (~1686 стр., `ed82f6e9`).
- [x] [2026-08-01] `AuthHelper` переклассифицирован как корректная локальная абстракция (46 стр. после `6b28f00`, см. раздел 9).

### Удалено в `ed82f6e9` (delete-этап, ~16 530 стр.)

- [x] Удалены sync-экраны, SyncJournal, протоколы, DTO, моки, тесты, sync-сервисы (подробности — Итог).

### keep (живые, не тронуты)

- [x] `WorkoutDataResponse`, `ProgressServiceTests`, sync-флаги (см. раздел 5).

## 2. Пакеты и native-замены

### Целиком мёртвые пакеты

- [x] Удалены `SWNetwork` (~1412 стр.) + `SWKeychain` (~230 стр.) в `2555914a` (каталог + пакет из `.xcodeproj`).

### Пакеты, которые оставляем

- [x] 3 живых пакета сохранены (CachedAsyncImage, SWDesignSystem, SWUtils).

### Native-замены внутри пакетов

- [x] Native/delete (`19081bad`/`c2e906a3`): SWAlert, SWFileManager, DateFormatterService helpers, String.capitalizingFirstLetter.
- [x] [NEW] `NetworkStatus` (~46 стр., `9cb2646`) — write-only, 0 ссылок на `@Environment(\.isNetworkConnected)`.

## 3. Review-слой (yagni — избыточная абстракция)

Система «оценить приложение в App Store» реализована через **9 production-файлов (256 стр. после Фазы A) + 7 тестовых файлов (636 стр.)**. Исходно было 12 production-файлов / 270 стр. — 3 файла (`ReviewAttemptRules`/`ReviewSkipReason`/`ReviewStorageKeys`) удалены в Фазе A. **Вся зачистка этого раздела не выполнена в `ed82f6e9`** (выходит за рамки delete-этапа).

**Важно (обнаружено 2026-07-26):** утверждение «тесты не ломаются» из исходного аудита — ложное для 2 протоколов. В `SwiftUI-SotkaAppTests/Services/Review/ReviewManagerTests.swift:222/253` определены `private final class MockReviewAttemptStore: ReviewAttemptStoring` и `private final class MockWorkoutCompletionsCounter: WorkoutCompletionsCounting`, оба используются в `makeSUT()` (строки 11-13) во всех тестах `ReviewManager`. Удаление этих двух протоколов = переписывание тестов. `ReviewContext` — **используется вне `Review/`** (внешние caller'ы: `StatusManager.swift:571`, `WorkoutPreviewViewModel.swift:238`), инлайн потребует изменения их вызовов.

### Фаза A — безопасная консолидация (выполнена в `bc0a76f` + move в текущем коммите, net −14, без переписывания тестов)

Только файлы без fileprivate-моков в `ReviewManagerTests` и без внешних caller'ов:

- [x] yagni/shrink 3 файла (ReviewAttemptRules 10→3, ReviewSkipReason 9→5, ReviewStorageKeys 8→0, `bc0a76f`): 2 тест-файла переподключены, net −14 prod, −10 tests.

### Фаза B — переписывание тестов (доп. net −18, дополнительный −18 стр.)

- [x] yagni 3 протокола (`3e928f6f`, net −18 LOC prod + test mocks rewrite): `ReviewAttemptStoring`/`WorkoutCompletionsCounting`/`ReviewContext` — 8 файлов, ~25 call-сайтов.

### keep — расширен, не трогаем остальное

- [x] keep 4 файла: `ReviewEventReporting` (5), `ReviewMilestone` (21, +`isNotYetAttempted`), `ReviewRequestHost` (55), `WorkoutCompletionsCounter` (31). Тесты `ReviewMilestoneTests`/`ReviewRequestTriggerIDTests`/`WorkoutCompletionsCounterTests` — живые.

### Итог Review-слоя (Фазы A и B выполнены в `3e928f6f`)

Production 270→256 (net −14). Tests 636 без изменений. Подробности — Итог.

## 4. Другие мёртвые/yagni находки в приложении

### Watch-приложение

- [x] Удалены `WatchWorkoutService.swift` + тесты (~285 стр.). Watch sync через `WatchConnectivityService`/`WCSession`/`WorkoutDataResponse` — не затронута.

### Прочее

- [x] Удалены мелкие мёртвые члены: `ImageProcessor.createThumbnail`, `InfopostAvailabilityManager.getAvailablePostsBySection`, `Client+.swift` (→ `ScreenshotDemoData.seedDemoData`, §7), `ScreenshotDemoData.readInfopostDays`.

### Новые мёртвые находки после `ed82f6e9` (не были в исходном аудите) [NEW]

- [x] Удалены 4 мёртвые модели (0 ссылок в проде).

### Находки Periphery 2026-07-26 (после `e75e49db`) [NEW]

Periphery re-run: 46 warnings в 17 файлах → 18 false-positives → **dead code ≈122 LOC** в 6 prod-файлах + 1 тест-мок + 4 `public`→`internal` в `SWDesignSystem`. Выполнено в `8452aa0` (−140 net).

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
| `Libraries/SWDesignSystem/.../SWDivider.swift` | `struct` + `init` + `var body` | 13 LOC | **Стал entirely dead 2026-07-26** (пользователь удалил `DividerIfNeededModifier.swift` + `withDivider` extension — единственный consumer). 0 production-callers, 1 reference в собственном `#Preview`. Periphery-описание «redundant public» было неточным: `public` на struct'е уже не было в HEAD, файл всегда был `internal`. **`git rm` в `1f051228`** |
| `Libraries/SWDesignSystem/.../Rows/ListRowView.swift` | `public struct` + `public extension` | 0 LOC | unused outside file (только previews) |
| `Libraries/SWDesignSystem/.../ItemListScreen.swift:23` | `init(mode:allItems:...)` | 12 стр. | 0 caller'ов вне previews |

**False positives (отброшены):** 6 `WorkoutPreviewViewModel` assign-only (`private struct DataSnapshot`, `Equatable` comparison в `hasChanges`); `PreviewWatchAuthService.init(isAuthorized:)` (`HomeView.swift:67,78`); `WatchAuthServiceProtocol.updateAuthStatus` (`WatchConnectivityService.swift:366`); `MockWCSession.delegate`/`MockWatchSession.delegate` (`WatchSessionProtocol` requires `var delegate: WCSessionDelegate? { get set }`); `Libraries/SWDesignSystem/Package.swift:6:5 package` (build metadata).

### Ошибочно удалённые тесты [restore]

`SwiftDataMigrationTests.swift` удалён в `ed82f6e9` как «мёртвый» (ссылался на `SyncJournalEntry.self`). **Удаление было ошибкой** — тесты проверяли критичный сценарий (открытие старого SwiftData store + сохранение данных при изменении схемы).

- [x] [restore] Восстановлен `SwiftDataMigrationTests.swift` (269 стр., `22dace92`): 4 теста сохранены + новый `opensStoreAfterRemovingSyncJournalEntryAndPreservesData`. Все 5 тестов проходят.

## 5. На границе скоупа (не находки, решение за продуктом / оставить сейчас)

- Sync-флаги (`isSynced`) на `@Model` (`CustomExercise`/`DayActivity`/`UserProgress`/`CalendarExtensionRecord`) — **оставляем в схеме, помечаем deprecated** (без удаления). По решению продукта 2026-08-01 миграция SwiftData нецелесообразна: риск потери данных existing authorized users + несколько лишних полей не критичны. Аннотация: `@available(*, deprecated, message: "Sync-флаг, оставлен для стабильности схемы (сервер закрыт 2026-08-01).")` — выполнено в `fd5f845` (см. §9). **Живые sync-связанные поля оставлены без аннотации:** `shouldDelete` (используется как soft-delete filter в queries), `createDate`/`modifyDate` (display/sort/audit), `CalendarExtensionRecord.lastModified` (sort comparator в `StatusManager.swift:1008-1009`).
- `AuthHelper` (62 стр.) — **жив и нужен** (см. раздел 9). `OfflineLoginView` использует `performOfflineLogin()` (создаёт User с sentinel id -1, `userName == "offline-user"`), `MoreScreen` использует `triggerLogout()` (UserDefaults reset → триггер `.onChange` для logout-флоу, см. Tier 1), `SwiftUI_SotkaAppApp.body` ветвит Welcome ↔ Root по `authHelper.isAuthorized`. Полное удаление **не рекомендуется** — gain −62 стр. не оправдывает риск сломать (уже сломанный после `ed82f6e9`) logout flow и смешать auth-state с UI. Минимальная чистка — см. раздел 9 (Tier 1: восстановление logout-флоу + тестов, Tier 2: опциональное удаление дубля `isOfflineOnly`).
- Firebase (Analytics + Crashlytics): оставляем 100%. Crashlytics полезен и офлайн (очередь + отправка при сети); Analytics — продуктовое решение. Слой провайдеров мал (~115 стр.), оставить.
- `StatusManager` (1106 стр. после Periphery re-run #2) — god object; экстракция `WatchCommandHandler`/`CalendarExtensionManager` нейтральна по строкам, делать только при следующем касании. **Logout flow восстановлен 2026-08-01 в `de6d535`:** `didLogout()` (lines 169–177) вызывается из `.onChange(of: authHelper.isAuthorized)` при `!isAuthorized` (вместе с `try modelContext.delete(model: User.self)`, errors через `logger.error`). 4 dead члена `State.isSynchronizingData`/`.error`/`.isLoading`/`.isSyncing` — оставить в Plan D (god object, делать при следующем касании).
- **User model obsolete поля** (2026-08-01) — 7 nullable полей на `User` (`fullName`/`email`/`imageStringURL`/`cityId`/`countryId`/`birthDateIsoString`/`unsyncedReadInfopostDaysString`) — server-profile + sync fields, obsolete после отключения сервера. **Не удалять** (нет миграции, по решению продукта). Помечены `@available(*, deprecated, ...)` аннотациями в `fd5f845` (русский текст сообщений — `24ebd8d`).
- **AuthHelper.isOfflineOnly** (2026-08-01) — дубль с `User.isOfflineOnly` (computed `userName == "offline-user"`). 1 reader (`SwiftUI_SotkaAppApp.showLoadingOverlay`). **Удалено в `6b28f00`** (Tier 2): −19 LOC (Constants −2, AuthHelper −16, SwiftUI_SotkaAppApp −1). Инвариант сохранён: `User.isOfflineOnly` остался source of truth.
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

2-й Periphery re-run на HEAD (после `8452aa0`) + ручная верификация каждого warning + ревью отчёта. План (раздел 5) зафиксирован до этого Periphery re-run'а и **не охватывал** находки ниже. **Выполнено** в 5 коммитах (`ddcb1d52`+`b8761560`+`3e928f6f`+`220375cc`+`4655820`, net ~−1029 LOC, 14 тестов). Детальные таблицы per-file — см. Итог.

### Группы A1/A2/B/C (выполнено в Periphery re-run #2)

- [x] **A1 `ddcb1d52` (−533):** `git rm` 8 dead-файлов: `ListRowView`/`ItemListScreen`/`CheckmarkRowView` (SWDesignSystem), `LocationFeedback`/`ActivitySnapshot`/`MockResult`/`MockWCSession`/`MockStatusManager`. Все 0 prod-callers; pure delete без UI/product-impact. `MockStatusManager` восстановлен в `de6d535` (Tier 1) вместе с logout flow.
- [x] **A2 `b8761560` (−220):** 9 prod файлов (MainUserForm + Gender.affiliation + User sync helpers + DayActivity/DayActivityTraining computed + 3 сервиса `isReadOnlyMode` + 2 screens `WelcomeScreen`/`MoreScreen`) + 3 preview-fixup в `JournalScreen.swift`. **80 call-sites `isReadOnlyMode`** в 26 файлах синхронно обновлены.
- [x] **B `3e928f6f` (−13 prod, ~+30 test):** 3 протокола Review — `ReviewAttemptStoring`/`WorkoutCompletionsCounting`/`ReviewContext`. Scope 8 файлов/~25 call-сайтов (план оценил 2). `MockWorkoutCompletionsCounter` rewrite потребовал `ModelContainer` setup + 16 `try` keyword'ов в `ReviewManagerTests`. **B-fix `220375cc` (+4):** guard reversed range в SwiftData seed/append.
- [x] **C `4655820` (−189):** 4 dead метода `DateFormatterService` (`stringFromFullDate`/`dateFromIsoString`/`days(from:to:)` String overload + cascade Date overload) + 13 тестов + 2 explicit `: Bool` для ambiguous require. Net −40 prod (план занизил в 2.5×).

### Исключены (NOT dead / NOT safe без product-decision)

| Файл/свойство | Почему исключено |
|---|---|
| `PreviewContent/User+.swift`/`Progress+.swift` | Активно используются preview-callers (7 в `ProgressScreen`/`ProgressGridView`, 13+ `User.preview`). План изначально ошибочно отмечал User+ как 0-caller — это [ошибка Periphery 2](#ошибки-плана-periphery-2) |
| `MockWatchSession.delegate`/`MockWCSession.delegate` (iOS) | Protocol conformance required: `WatchSessionProtocol` декларирует `var delegate: WCSessionDelegate? { get set }`. На практике мёртвое (cast returns `nil`), но неудаляемо без изменения протокола → Plan D. iOS-файл удалён целиком (A1) |
| `StatusManager.State.isSynchronizingData`/`.error`/`.isLoading`/`.isSyncing` | Periphery прав — все 4 dead (never assigned/read). План блокирует: «`StatusManager` god object, делать только при следующем касании» (раздел 5). Plan D |
| `MainUserForm` deletion без preview-fixup | Каскадит на 3 preview в `JournalScreen.swift:215,225,235` → preview-fixup учтён в A2 |
| Sync-флаги (`isSynced`/`shouldDelete`/`lastModified`) | План пересмотрен 2026-08-01: помечаются `// OBSOLETE: ...` комментариями **без миграции** (решение продукта, раздел 9) |
| Firebase Analytics + Crashlytics | План блокирует: «оставляем 100%» (раздел 5) |

### False positives Periphery 2 (отброшены)

`WCSessionProtocol.delegate` / `WatchAuthServiceProtocol.updateAuthStatus` / `WatchConnectivityServiceProtocol.onCurrentActivityChanged` / `onWorkoutDataReceived` — protocol requirements; `PreviewWatchAuthService.init(isAuthorized:)` — used in `HomeView.swift:67,78`; `WorkoutPreviewViewModel.DataSnapshot` 6 properties (× 2 файла) — `Equatable` synthesis; `RootScreen.tab` — used in `TabView(selection: $tab)` (line 13); `InfopostDetailScreen.showError` — used in `.alert(isPresented:)` + `HTMLContentView` (lines 27, 31); `ReviewRequestTriggerID.pendingRequest` + `scenePhase` — `Hashable` synthesis.

### Прогноз контроля качества (ретроспектива)

Прогноз −860 LOC оказался точным (факт −1029 net — большая часть из-за test-mock rewrites, не regression'ов). См. финальный «Контроль качества».

## 9. [NEW] Анализ офлайн-only Auth модели (2026-08-01, после уточнения пользовательского сценария)

**Контекст:** сервер закрыт навсегда. App различает existing authorized user (сразу RootScreen, локальные данные) vs new offline-only user (Welcome → OfflineLoginView → Root). **Инвариант:** данные existing authorized users НЕ должны теряться при обновлении; после явного logout ОБЯЗАНЫ удаляться (см. Tier 1). Решение 2026-08-01: **схема SwiftData не меняется** (нет миграции), obsolete-поля помечаются `@available(*, deprecated)` без удаления (см. Sync/server fields).

**`AuthHelper` (62 стр. → 46 стр. после Tier 2):** `@MainActor @Observable final class AuthHelperImp` — UserDefaults-backed `isAuthorized`, методы `performOfflineLogin()`/`triggerLogout()`. Не трогает SwiftData. Используется в `OfflineLoginView` (sentinel `id: -1`, `userName == "offline-user"`) + `MoreScreen.triggerLogout()` + `SwiftUI_SotkaAppApp.body` (ветвление Welcome ↔ Root по `isAuthorized`).

**Offline user sentinel-protection:** `User(offlineWithGenderCode:)` → `id: -1`. `OfflineLoginView` удаляет User с `id == -1` (если есть), вставляет новый. **Существующие User с `id != -1` не затрагиваются** → данные existing authorized users защищены.

**Logout-flow регрессия (`ed82f6e9`):** pre-commit `processAuthStatus` делал `didLogout()` + `try context.delete(model: User.self)`; `ed82f6e9` удалил метод + всю `StatusManagerTests/` (22 файла, ~6000 LOC). Восстановлен в Tier 1: `.onChange(of: authHelper.isAuthorized)` → `appSettings.didLogout()` + `reviewManager.reset()` + `statusManager.didLogout()` + `try statusManager.modelContainer.mainContext.delete(model: User.self)`. **Деталь:** `CalendarExtensionRecord.user: User?` — plain optional без `@Relationship`/`deleteRule`; нужен `didLogout()` (внутри `clearExtensionDates()` удаляет `CalendarExtensionRecord`). Одну половину восстанавливать нельзя.

### Sync/server-related поля (выполнено: помечены `@available`, не удалять)

**На `User` модели (8 deprecated полей в `fd5f845`):** `fullName`/`email`/`imageStringURL`/`cityId`/`countryId`/`birthDateIsoString` — server profile (0 prod-readers); `unsyncedReadInfopostDaysString` — sync field, 1 prod-reader (`StatusManager.extendCalendar():742`).

**На других `@Model` (5 deprecated + 6 живых):**

| Поле | Статус |
|---|---|
| `isSynced` (CustomExercise/DayActivity/UserProgress/CalendarExtensionRecord) | deprecated (sync flag) |
| `UserProgress.lastModified` | deprecated (sync timestamp) |
| `shouldDelete` (все 4 модели) | жив (soft-delete filter) |
| `createDate`/`modifyDate` (CustomExercise/DayActivity) | живые (audit/sort) |
| `CalendarExtensionRecord.lastModified` | жив (sort comparator в `StatusManager.swift:1008-1009`) |

**Аннотация:** `@available(*, deprecated, message: "...")` (русский текст, `24ebd8d`). **Не удалять** — нет миграции, по решению продукта 2026-08-01.

### Упрощения (Tiers)

- [x] **Tier 1 — restore logout (`de6d535`+`69fce28a`, +211 net LOC):** `de6d535` восстановил `.onChange` body + `MockStatusManager.create()` + `StatusManagerLogoutTests` (5 адаптированных тестов, без `MockStatusClient` — протокол удалён в `ed82f6e9`). `69fce28a` follow-up: `@Environment(\.modelContext)` → `statusManager.modelContainer.mainContext` (App-struct не получает контейнер через env) + `getStatus()` автостарт дня 1 + 2 теста (`auto-start`/`keeps-existing`). Pre-commit `StatusManager.didLogout()` теперь нужен (call-site из `.onChange`). **Не literal restoration:** адаптация −164 LOC vs ~250 LOC мёртвого prod-кода при дословном. **Scope discovery:** план говорил «только `StatusManagerLogoutTests` (153 LOC)», реально `ed82f6e9` удалил всю `StatusManagerTests/` (22 файла, ~6000 LOC). Восстановлено **LogoutTests + 2 теста из GetStatusTests** = 7 тестов минимального риска. Остальные 20 — Tier 2+ итерации.
- [x] **Tier 2 — AuthHelper simplify (`6b28f00`, −19 LOC):** `AuthHelper.isOfflineOnly` (UserDefaults дубль с `User.isOfflineOnly` computed `userName == "offline-user"`) удалён — Constants −2, AuthHelper −16, SwiftUI_SotkaAppApp −1. `User.isOfflineOnly` остался source of truth.
- [x] **Tier 2 — deprecated markers (`fd5f845`+`24ebd8d`, +24 LOC):** 12 `@available(*, deprecated, ...)` аннотаций (7 server-полей User + 1 sync-поле `unsyncedReadInfopostDaysString` + 4 sync-флага `isSynced` + 1 timestamp `UserProgress.lastModified`) + русский текст 12 deprecated-сообщений.

### Tier 3 — НЕ рекомендуется

- Полное удаление `AuthHelper`: gain −62 стр., но смешивает auth-state с UI + риск сломать logout flow + потеря данных existing authorized users. **Не делать.**
- Удаление obsolete полей User / sync-флагов: требует SwiftData migration (manual + test migration scenarios), риск потери данных. **Не делать в этой итерации.**

### Итог §9

- **Сохранение данных existing authorized users** обеспечено: schema не меняется, OfflineLoginView не трогает User с `id != -1` (sentinel-protection). Logout удаляет данные (Tier 1 выполнен).
- **Tier 1+2+deprecated выполнены** (`de6d535`+`69fce28a`+`6b28f00`+`fd5f845`+`24ebd8d`).
- **Не делать:** Tier 3, sync-flag удаления (решение продукта).

## 10. [NEW] Следующая волна аудита (после current HEAD, 2026-08-01)

Все находки верифицированы субагентами (`explore`) + ручная проверка `TrainingRowAction` через `project.pbxproj:107` (в `membershipExceptions` для Watch target). **Выполнено** в 5 коммитах (`3648fc2`+`a3c7f8f`+`af6a5bd`+`381ee78`+`fc5efb0`), −1118 строк. Подробные per-group таблицы — см. коммиты; здесь сводка.

### Группы D/E/F/G/H (выполнено)

- [x] **D `fc5efb0` (−493: −183 prod, −310 tests):** 9 Watch VM dead members (`shouldShowExercisesReminder`/`getStepState(for:)`/`getCycleSteps()`/`getExerciseSteps(for:)` в `WorkoutViewModel`; `canRemoveExercise`/`updatePlannedCount(id:action:)`/`updateTrainingCount(at:amount:)`/`removeTraining(at:)` private cascade в `WorkoutPreviewViewModel`; `startWorkout` в `HomeViewModel`). Живые альтернативы: `updatePlannedCount(for: Int)` + `updateTrainingCount(for:newValue:)` (`WorkoutPreviewView.swift:143,162`); локальный `canRemoveExercise` в `WorkoutEditView.swift:33-35`. **Safety check `TrainingRowAction`:** файл остаётся живым в iOS — 3 iOS-ссылки (`WorkoutPreviewViewModel.swift:277` + `TrainingRowView.swift:9,17`) сохраняются после удаления watch-ссылки.
- [x] **E `3648fc2` (−198):** транзитивно мёртвые после `ddcb1d52` (A1: `ItemListScreen`): `SectionView.swift` (122) + `SectionHeaderView.swift` (76, содержит `SectionSupplementaryView`). Pure delete.
- [x] **F `381ee78` (−173: −67 prod, −106 tests):** 4 test-only метода `ImageAssetManager` (`getImageURL(for:)`/`getAllAvailableImages()`/`imageExists(_:)`/`getImageSize(_:)`) + 12 тестов. Оставлен `copyImageToTemp(...)` — prod chain через `HTMLContentView.swift:251` → `InfopostResourceManager.copyResources` → `copyImagesFromAssets` → `ImageAssetManager.copyImageToTemp`.
- [x] **G `af6a5bd` (−248: −40 prod, −208 tests):** `Date.rawValue`+`init?(rawValue:)` (Date+rawValue.swift:12), `String.trueCount`/`withoutSpaces` (String+.swift:10), `Double+.swift` целиком (18). `Float+.swift` жив — используется в `UserProgress.swift:179` + `TempMetricsModel.swift:28,48` + `String+.swift:27`. **План занизил test-savings в 7×:** `DoubleExtensionTests.swift` (151 LOC) содержал больше тестов, чем казалось (все `Double.formattedForUI`/`fromUIString` тесты — удалены вместе с prod-кодом).
- [x] **H `a3c7f8f` (−6: −5 prod, −1 line):** write-only `ReadOnlyModeKey.swift` (`@Entry var isReadOnlyMode: Bool = AppConfiguration.isReadOnlyMode`, iOS 17+ Entry macro) + строка `.environment(\.isReadOnlyMode, isReadOnlyMode)` в `SwiftUI_SotkaAppApp.swift:142`. Read sites: 0. Сервисы получают флаг через init-параметр, не через environment. Аналог `9cb2646` (NetworkStatus).

### Итог новой волны

| Группа | LOC prod (план/факт) | Тесты (план/факт) |
|---|---|---|
| D (Watch VM) | ~174 / 183 | ~9 / 310 |
| E (Section) | 198 / 198 | 0 / 0 |
| F (ImageAsset) | ~63 / 67 | ~12 / 106 |
| G (SWUtils) | ~30 / 40 | 3 файла / 208 |
| H (ReadOnlyModeKey) | 5 / 6 | 0 / 0 |
| **Итого** | **~470 / −494** | **~12 / −624** |

**Σ: −1118 строк** (494 prod + 624 tests). Контроль качества: SwiftUI-SotkaApp build ✓, SotkaWatch Watch App build ✓, 829 iOS unit tests ✓, 155 Watch unit tests ✓ (−14 от Группы D). **Зависимости: 0.**

### Не вошло (пограничные случаи)

| Файл/член | Причина |
|---|---|
| `SWTextField.swift` (248 LOC) | Caller (`EditProgressScreen.swift:322`) использует ~95 LOC ядра. `errorState`/`isSecure`/`lineLimit` — неиспользуемые параметры public API с дефолтами, не dead code (Periphery не считает). Мёртвого нет, есть ~95 LOC preview (`SWTextField.swift:152-247`). Удаление целиком потеряет единую стилизацию дизайн-системы — урезать preview, не удалять |

## Итог

### Фактический результат коммитов (хронология)

| Commit | Файлы | Net | Что |
|---|---|---|---|
| `ed82f6e9` (delete) | 162 | −30 290 | 4 сетевых сервиса, 9 экранов, 4 SyncJournal, 9 протоколов, 10 DTO, 6 preview, 9 моков, StatusManager 1559→1107, 5 sync-гейтов, 3 sync-сервиса, 30 тестов, WatchWorkoutService, AuthHelper −41 |
| `22dace92` (FIX) | 5 | +313 | [restore] SwiftDataMigrationTests +269 (5 тестов); [FIX] ScreenshotDemoData +121, Client+.swift −74 |
| `19081bad`+`2555914a`+`c2e906a3` (delete-2) | 46 | −2575 | 4 [NEW] модели, SWFileManager, DateFormatterService.readableDate/makeFormat, ImageProcessor, InfopostAvailabilityManager, SWNetwork −1388, SWKeychain −230, SWAlert −128. Пакеты убраны из репо + `.xcodeproj` |
| `9cb2646` (NetworkStatus) | 1 | −46 | Write-only NetworkStatus (0 references к `@Environment(\.isNetworkConnected)`) |
| `bc0a76f` (Review A) | 6 | −14 | yagni/shrink 3 файла (ReviewAttemptRules, ReviewSkipReason, ReviewStorageKeys) |
| `d7f7682c` (delete-3) | 16 | −647 | KeyedDecodingContainer+тесты, MediaFile+UIImage, InfopostHTMLProcessor→inline, InfopostsService+FilenameManager→inline, HomeDayCountModel→inline, AppLanguage.makeCurrentValue→inline |
| `21608712` (fix) | 1 | ~0 | ProgressServiceTests fix (ModelContext dealloc) |
| `6753c89` (Tier 1) | 4 | −119 | VibrationService 70→12 (CHHapticEngine→AudioServicesPlaySystemSound), Date+ −26, ContentInSheet −56→inline. **Пропущено из ponytail:** RestTimeComponents (false positive), InfopostParser/YouTubeVideoService (gain < трудозатрат), CachedAsyncImage (keep), 4 протокола (2-3 импл, не yagni) |
| `8452aa0` (Tier 2 Periphery) | 12 | −140 | 18 Periphery warnings (UserProgress dead methods, MainUserForm.isReadyToSave, Constants, DayCalculator, City, MockWatchConnectivityService, 4× public→internal). **Сознательные отклонения:** isReadyToRegister −9 (бонус), ItemListScreen.init оставлен (2 previews), shouldDeletePhoto/DELETED_DATA оставлены (state-машина жива) |
| A1 `ddcb1d52` | 10 | −533 | `git rm` 8 dead-файлов (ListRowView, ItemListScreen, CheckmarkRowView, LocationFeedback, ActivitySnapshot, MockResult, MockWCSession, MockStatusManager) + 2 cascade props |
| A2 `b8761560` | 32 | −220 | 9 prod (MainUserForm, Gender, User sync helpers, DayActivity/DayActivityTraining computed, 3 сервиса isReadOnlyMode, 2 screens) + 3 preview-fixup + ~80 call-sites |
| B `3e928f6f` | 12 | −13 | 3 протокола delete (ReviewContext, ReviewAttemptStoring, WorkoutCompletionsCounting) + 2 mock rewrite (16 call-sites в `ReviewManagerTests` + 3 inline). `makeSUT` стал `throws` + 4-tuple |
| B-fix `220375cc` | 1 | +4 | Guard reversed range в `seedActivities`/`appendActivities` (Swift 6.3 trap). **НЕ та же проблема, что в `21608712`** — здесь range precondition, не ModelContext dealloc |
| C `4655820` | 3 | −189 | 4 dead метода `DateFormatterService` + 13 тестов + 2 explicit `: Bool` для ambiguous require |
| `de6d535` (Tier 1) | 3 | +164 | [restore] logout flow: `.onChange(of: isAuthorized)` body + `MockStatusManager.create()` + `StatusManagerLogoutTests` (5 адаптированных тестов). Детали — §9 Tier 1 |
| `69fce28a` (Tier 1 follow-up) | 3 | +47 | [FIX] `@Environment(\.modelContext)` → `try statusManager.modelContainer.mainContext.delete(...)` (App-struct не получает контейнер через env). [restore] `StatusManager.getStatus()` автостарт дня 1 + `StatusManagerGetStatusTests` (2 теста: auto-start/keeps-existing) |
| `6b28f00` (Tier 2) | 3 | −19 | Удалён `AuthHelper.isOfflineOnly` (UserDefaults дубль `User.isOfflineOnly`). 1 reader в `SwiftUI_SotkaAppApp.showLoadingOverlay` упрощён. `User.isOfflineOnly` остался source of truth |
| `fd5f845` (deprecated markers) | 5 | +12 | 12 `@available(*, deprecated, ...)` аннотаций: 7 server-полей User + 1 sync-поле + 4 sync-флага `isSynced` + 1 timestamp `UserProgress.lastModified`. Живые sync-связанные поля (shouldDelete/createDate/modifyDate/CalendarExtensionRecord.lastModified) оставлены без аннотации |
| `24ebd8d` (i18n) | 5 | ±12 | Русский текст 12 deprecated-сообщений в `@available` (Server profile → Поле профиля сервера; Sync flag → Sync-флаг; Sync field → Sync-поле; Sync timestamp → Sync-timestamp) |
| `3648fc2` (Группа E) | 2 | −198 | Транзитивно мёртвые после A1 (`ItemListScreen`): `SectionView.swift` (122) + `SectionHeaderView.swift` (76, содержит `SectionSupplementaryView`). Pure delete |
| `a3c7f8f` (Группа H) | 2 | −6 | Write-only `ReadOnlyModeKey.swift` (`@Entry var isReadOnlyMode: Bool = ...`) + строка `.environment(\.isReadOnlyMode, isReadOnlyMode)` в `SwiftUI_SotkaAppApp.swift:142`. Аналог `9cb2646` (NetworkStatus) |
| `af6a5bd` (Группа G) | 6 | −248 | `Date.rawValue`+`init?(rawValue:)` + `String.trueCount`/`withoutSpaces` + `Double+.swift` целиком (prod) + `DateRawRepresentableTests` + `DoubleExtensionTests` + часть `SWUtilsTests` (tests). `Float+.swift` жив (UserProgress/TempMetricsModel) |
| `381ee78` (Группа F) | 2 | −173 | 4 test-only метода `ImageAssetManager` (`getImageURL(for:)`/`getAllAvailableImages()`/`imageExists(_:)`/`getImageSize(_:)`) + 12 тестов. Оставлен `copyImageToTemp(...)` (prod chain) |
| `fc5efb0` (Группа D) | 8 | −493 | 9 Watch VM dead members (`shouldShowExercisesReminder`/`getStepState(for:)`/`getCycleSteps()`/`getExerciseSteps(for:)` + 4 в `WorkoutPreviewViewModel` + `HomeViewModel.startWorkout`) + 14 watch-тестов |

**Σ всех волн:** ~−33 500 net LOC production до Periphery re-run #2, −1029 Periphery re-run #2, ±211 Tier 1+2+deprecated, −1118 волна §10. **Тестов:** ~85 до Periphery re-run #2, 14 Periphery re-run #2, +9 Tier 1, −38 §10 (24 iOS + 14 watch). Все `[ ]` пункты плана закрыты (`6b28f00`+`fd5f845`+`24ebd8d`+`3648fc2`+`a3c7f8f`+`af6a5bd`+`381ee78`+`fc5efb0`). **Активных [ ] пунктов нет** — все находки реализованы или заблокированы решением продукта (Tier 3, sync-flag миграция — см. §9).

### Контроль качества

- iOS build: ✅ (iPhone 11 / iOS 26.5 / xcodebuild-mcp). Pre-existing `AppIcon` asset error в watch-таргете — не связан с правками аудита (подтверждено через `git stash` до/после). **SotkaWatch Watch App build: ✅** (Apple Watch Ultra 3 49mm / xcodebuild-mcp, 51 pre-existing warning про `isSynced`/`lastModified` deprecated).
- Unit tests: **iOS 829 + Watch 155 = 984 passed**, 1 iOS skipped. История: 1833 → 977 (`ed82f6e9` −856) → 869 (после Tier 1+2+deprecated) → **855** (`916e0194`+`ef400e6e`+`7cc61231`/`3648fc2`/`a3c7f8f`: 0 test changes) → **845** (`af6a5bd` Группа G: −12 SWUtils) → **833** (`381ee78` Группа F: −12 ImageAsset) → **833 iOS + 155 Watch** (`fc5efb0` Группа D: −14 watch). **Σ §10: −24 iOS + −14 watch = −38 tests.**
- UI-тесты: ✅ (8 скриншотов, `testMakeScreenshots`)
- Watch ↔ iPhone sync: не сломана (`WatchConnectivityService`/`WCSession`/`WorkoutDataResponse`)

### Супротив прошлого аудита (2026-07-21)

Добавлены `SyncStartDateScreen`/`HelpScreen`/`ChangePasswordScreen`/`EditProfileScreen`/`SyncResultBadge`/`SyncDateComparisonPolicy` + тесты (~+2000 строк); добавлены sync-методы в активных сервисах + 4 мёртвых протокола (+~1100 строк production, +136 строк тестов); удалены в `1c890e2` Periphery-чистки (учтены в новых счётчиках). `MockSWClient` — warning, использовался в 14 unit-тестах; `ed82f6e9` выбрал вариант (b): MockSWClient + тесты удалены целиком. `ProgressServiceTests` перенесён в keep.

**Periphery 2026-07-26 #1 (re-run после `e75e49db`):** 46 warnings → 18 false-positives → 18 подтверждённых dead code в 6 production-файлах + 1 тест-мок + 4 `public→internal` (`SWDesignSystem`). `1c890e2` (2026-05-01) удалил ~1937 строк — новая волна ≈122 LOC + 4 keyword'а. Выполнено в `8452aa0`.

**Periphery 2026-07-26 #2 (re-run на HEAD после `8452aa0`, пост-ревью):** подтверждённый dead code ≈605 LOC (Группа A) + Review Фаза B scope (8 файлов вместо 2) + `DateFormatterService` dead methods (−20 LOC). Выполнено в `ddcb1d52`+`b8761560`+`3e928f6f`+`220375cc`+`4655820` (net ~−1029 LOC, 14 тестов).

### Ошибки аудита (исправлены в `22dace92`)

1. `Client+.swift` = UI-инфра, не мёртвый код — см. раздел 7.
2. `SwiftDataMigrationTests` = критичный регресс — 5 тестов восстановлены (269 стр.), см. раздел 4 [restore].

### Ошибки плана Periphery 2

1. **`PreviewContent/User+.swift` ошибочно помечен как 0-caller.** Активно используется: 7 preview-callers в `ProgressScreen.swift:3` + `ProgressGridView.swift:4`; `User.preview` — 13+ preview-callers + `ProgressCalculatorTests.swift`. Реальный статус: alive.
2. **`PreviewContent/Progress+.swift` ошибочно помечен как чистый dead code.** Транзитивно жив: `UserProgress.previewDay1/49/100` используются только внутри `User+.swift` (12 internal calls). Удаление требует рефакторинга `User+.swift` — выходит за скоуп.
3. **`User.init(fromMainUserForm:id:)` помечен как «0 readers»** — на самом деле 3 preview-caller'а в `JournalScreen.swift:215,225,235`. Preview-fixup учтён в Группе A2.
4. **Net-savings `DateFormatterService` занижены в 2.5×** (заявлено −15, реально −40): план не учёл, что 3 метода (`stringFromFullDate`/`dateFromIsoString`/`days(from:to:)` String overload) полностью мертвы после удаления `MainUserForm` (A2).
5. **Scope `ReviewContext` undercount'нут**: план говорил «2 внешних caller'а», реально 8 файлов (~25 call-сайтов).
6. **`StatusManager.State` 4 мёртвых члена ошибочно отнесены к false positives** в исходном отчёте Periphery 2. Periphery прав: `.isSynchronizingData`/`.error` never assigned, `.isLoading`/`.isSyncing` never read. План блокирует (god object, раздел 5) → Plan D.
7. **LOC-план `MockWorkoutCompletionsCounter` занижен**: исходный отчёт говорил «тривиально, ~5 LOC нового кода в тестах». Реально ~30-40 LOC изменений в `ReviewManagerTests.swift` — `ModelContainer` setup + имитация `completedWorkoutCount` через вставку `DayActivity` в SwiftData.

CachedAsyncImage остаётся: `AsyncImage` + `URLCache` не решает мерцание при перерисовках ячеек, а кастомный `ImageLoader`/`ImageCache` даёт стабильное изображение без фаз загрузки. Удаление sync-флагов и Firebase в эту цифму не входят: флаги — вторая итерация с миграцией, Firebase — оставляем 100%.
