# Аудит over-engineering: весь репозиторий

Дата аудита: 2026-07-25. Применено 36 коммитов 2026-07-25..2026-08-01, хронология (подробности — разделы 1-8 + Итог): `ed82f6e9` (delete, −30 489/+199) → `22dace92` (FIX+restore, +393/−80) → delete-2 (`19081bad`/`2555914a`/`c2e906a3`/`56726fe2`, net −2575) → `9cb2646` (NetworkStatus) → 4 docs (`f10157a`/`f1065ca`/`65d39dc`/`606f7b2`) → `68e4bca` (правка плана Review) → `bc0a76f` (Review Фаза A) → `095af10` (move shouldAttemptMilestone) → 2 update-plan (`f7f6a61`/`af3cf6b`) → `d7f7682c` (delete-3 ponytail, −647) → `21608712` (fix ProgressServiceTests) → `c6f9d9e7` (compress) → `6753c89` (Tier 1 ponytail, −119) → `e75e49db` (compress) → `fbb689fb` (Periphery findings) → `8452aa0` (Tier 2 Periphery, −140) → Periphery re-run #2: `ddcb1d52`/`b8761560`/`3e928f6f`/`220375cc`/`4655820` (5 коммитов, ~−1029, раздел 8) → пост-чистки: `a63ef811` (Tier 2 inline: DividerIfNeededModifier + withDivider, −35 LOC) → `738e24d8` (docs) → `fd040669` (docs compress) → `1f051228` (SWDivider rm + doc drift, −13 LOC) → `fff7e885` (Watch schemes cosmetic, xcodebuild artifact) → `9a1fc327` (план update+compress) → `97c75839` (план: исправлены 8 фактических ошибок) → `8dfdf312` (план compress) → `de6d535` (restore logout flow, +164, см. §9 Tier 1) → `69fce28a` (Tier 1 follow-up: modelContainer.mainContext + getStatus автостарт, +47, см. §9 Tier 1) → **`6b28f00` (Tier 2: AuthHelper.isOfflineOnly −19 LOC, см. §9 Tier 2)** → **`fd5f845` (deprecated-аннотации @available: 12 полей User + sync-флагов, +12 LOC, см. §9 Sync/server fields)** → **`24ebd8d` (i18n: перевод deprecated-сообщений на русский, 12 строк)**.
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
| `SwiftUI-SotkaAppTests/Mocks/MockStatusManager.swift` | 66 | 0 callers `MockStatusManager.create()` на момент `ddcb1d52`. `StatusManagerLogoutTests` (где он использовался) удалены в `ed82f6e9`. **[2026-08-01] Восстановлен в `de6d535` (Tier 1)** вместе с logout flow |

**Subtotal: 505 LOC чистого dead code.** Build + tests в каждом коммите.

### Группа A2 — малые правки (~150 LOC, 9 prod файлов + 3 preview-fixup)

Все кандидаты — `let`/`var` properties (assign-only или computed), init-параметры или computed, которые никто не читает. Чистые удаления + 3 preview-fixup в `JournalScreen.swift`.

| Файл | Что удалено | Заметка |
|---|---|---|
| `Models/SWSharedModels/Gender.swift:32` | `var affiliation: String` | 0 readers (cascade на мёртвый `MainUserForm.genderString`) |
| `Models/SWSharedModels/MainUserForm.swift` (122) + `Models/User.swift:68` `init(fromMainUserForm:id:)` | Файл целиком + init | 0 prod-usage'ов. 3 preview-callers в `JournalScreen.swift:215,225,235` → заменены на `User.preview`. Каскад: `image`/`genderString`/`isReadyToSave`/`Placeholder`/`requestParameters`/`shouldUpdateOnAppear` тоже dead |
| `Models/User.swift:221,230` | `addUnsyncedReadInfopostDay` + `removeUnsyncedReadInfopostDay` | 0 callers (sync-флаги, мёртвы с `ed82f6e9`) |
| `Models/Workout/DayActivity.swift:94,110` | `var trainingType` + `var activitySnapshot` (computed) | 0 readers. Cascade для A1 `ActivitySnapshot.swift` |
| `Models/Workout/DayActivityTraining.swift:38,60` | `var exerciseType` + `var trainingSnapshot` (computed) | 0 readers (cascade после A1) |
| `Services/CustomExercisesService.swift:14` | `let isReadOnlyMode` | assign-only |
| `Services/DailyActivitiesService.swift:14,99` | `let isReadOnlyMode` (assign-only) + `markDailyActivityAsModified` (0 callers) | 2 dead члена |
| `Services/Infoposts/InfopostsService.swift:16` | `let isReadOnlyMode` | assign-only |
| `Screens/Login/WelcomeScreen.swift:4,7` | `import SWUtils` + `isReadOnlyMode` env-property | 0 references (cascade убирает `SWUtils` import) |
| `Screens/More/MoreScreen.swift:12,16` | `isReadOnlyMode` env + `isOfflineUser` computed | cascade: 0 readers → drop both |

**Subtotal: ~150 LOC prod + 3 preview-fixup в `JournalScreen.swift`.**

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

| Протокол | Реальный scope |
|---|---|
| `ReviewAttemptStoring` (8 LOC) | 2 prod файла + `MockReviewAttemptStore` → `ReviewStorage(userDefaults:)` + `MockUserDefaults`. Mechanical |
| `WorkoutCompletionsCounting` (5 LOC) | 2 prod файла + `MockWorkoutCompletionsCounter` → реальный `WorkoutCompletionsCounter` + in-memory `ModelContainer`. `makeSUT` стал `throws` + 4-tuple, добавлен `makeContainer()`, цикл вставки `completedWorkoutCount` `DayActivity` в SwiftData, 16 tests обновлено с `try`. ~30-40 LOC изменений в `ReviewManagerTests` |
| `ReviewContext` (5 LOC) | 8 файлов, ~25 call-сайтов: `StatusManager` + `WorkoutPreviewViewModel` + `ReviewEventReporting` + `MockReviewEventReporter` + `ReviewManager` + 16 call-сайтов в `ReviewManagerTests` + `WorkoutPreviewViewModelReviewEventTests`. `ReviewContext(hadRecentError: X)` → `X` (Bool). План `8452aa0` говорил «2 файла», реально 8 |

**Subtotal: −18 LOC prod + ~30-40 LOC test changes в `ReviewManagerTests` (`makeSUT` throws + `makeContainer` + вставка activities + 16 `try` keyword'ов).** План оценил Фазу B в 12, реально 18.

### Группа C — Tier 2 minimum (1 safe item, −20 LOC, 1 prod файл + 1 test file)

Минимальный безопасный ponytail: удалить 3 мёртвых метода `DateFormatterService` **после** удаления `MainUserForm` (A2): `stringFromFullDate` (0 prod-callers после A2), `dateFromIsoString` (только в `SWUtilsTests/DateFormatterServiceTests.swift`), `days(from:to:)` String overload (только в тестах) + cascade `days(from:to:)` Date overload.

Удаление методов + соответствующих тестов (~8 тестов в `SWUtilsTests/DateFormatterServiceTests.swift`) → −20 LOC prod + сокращение test file.

### Исключены из этого плана (NOT dead / NOT safe без product-decision)

| Файл/свойство | Почему исключено |
|---|---|
| `PreviewContent/User+.swift` (68 LOC) | **Активно используется**: `.previewWithDay1Progress`/`.previewWithDay49Progress`/`.previewWithDay100Progress` — 7 preview-callers в `ProgressScreen.swift:3` + `ProgressGridView.swift:4`. `User.preview` — 13+ preview-callers + `ProgressCalculatorTests.swift`. **Файл живой, не трогать** (план изначально ошибочно отмечал как 0-caller) |
| `PreviewContent/Progress+.swift` (38 LOC) | Транзитивно жив: `UserProgress.previewDay1/49/100` используются только внутри `User+.swift` (12 internal calls). Можно удалить только вместе с рефакторингом `User+.swift` — выходит за скоуп dead code |
| `MockWatchSession.delegate` (Watch, `SotkaWatch Watch App/PreviewContent/MockWatchSession.swift:9`) | Protocol conformance required: `WatchSessionProtocol` декларирует `var delegate: WCSessionDelegate? { get set }`. На практике **мёртвое**: `WatchConnectivityService` делает `sessionProtocol as? WCSession` (line ~21) — для `MockWatchSession` cast returns `nil`, поэтому `session.delegate = self` (line 366) никогда не вызывается на моке. **Неудаляемо** без изменения протокола → Plan D |
| `MockWCSession.delegate` (iOS, `SwiftUI-SotkaAppTests/Mocks/MockWCSession.swift:9`) | Same: protocol required. The whole `MockWCSession.swift` сам мёртв (см. A1, 0 iOS-usage'ов), поэтому это становится moot при удалении файла |
| `StatusManager.State.isSynchronizingData` / `.error(String)` / `.isLoading` (computed) / `.isSyncing` (computed) | **Periphery прав — все 4 члена реально dead**: `.isSynchronizingData`/`.error` never assigned, `.isLoading`/`.isSyncing` never read (единственный reader `.isLoading` в `AuthRequiredView:state.isLoading` — это **другой** `State`, не `StatusManager.State`). План блокирует: «`StatusManager` god object, делать только при следующем касании» (раздел 5, строка 127). **Plan D** |
| `MainUserForm` deletion без preview-fixup | Удаление `MainUserForm.swift` каскадит на 3 preview в `JournalScreen.swift:215,225,235`. Не блокер, но preview-fixup обязателен — учтено в A2 |
| Sync-флаги (`isSynced`/`shouldDelete`/`lastModified`) | План пересмотрен 2026-08-01: помечаются `// OBSOLETE: ...` комментариями **без миграции** (по решению продукта, раздел 9) |
| Firebase Analytics + Crashlytics | План блокирует: «оставляем 100%» (раздел 5, строка 126) |

### False positives Periphery 2 (отброшены ручной верификацией)

- `WCSessionProtocol.delegate` / `WatchAuthServiceProtocol.updateAuthStatus` / `WatchConnectivityServiceProtocol.onCurrentActivityChanged` / `onWorkoutDataReceived` — protocol requirements
- `MockWCSession.delegate` (iOS) / `MockWatchSession.delegate` (Watch) — protocol conformance (см. таблицу исключений)
- `PreviewWatchAuthService.init(isAuthorized:)` — used in `HomeView.swift:67,78`
- `WorkoutPreviewViewModel.DataSnapshot` 6 properties (× 2 файла) — `Equatable` synthesis
- `RootScreen.tab` — used in `TabView(selection: $tab)` (line 13)
- `InfopostDetailScreen.showError` — used in `.alert(isPresented:)` + `HTMLContentView` (lines 27, 31)
- `ReviewRequestTriggerID.pendingRequest` + `scenePhase` — `Hashable` synthesis (для `task(id:)` идентификации)

### Прогноз контроля качества (ретроспектива)

Прогноз −860 LOC оказался точным (факт −1029 net — большая часть из-за test-mock rewrites, не regression'ов). См. финальный «Контроль качества».

## 9. [NEW] Анализ офлайн-only Auth модели (2026-08-01, после уточнения пользовательского сценария)

**Контекст:** сервер закрыт навсегда. App должно различать:

- **Existing authorized user** (установил до отключения сервера): сразу RootScreen, данные локальны.
- **New offline-only user** (установил после отключения): WelcomeScreen → OfflineLoginView (gender) → RootScreen.

**Сохранение данных existing authorized users при обновлении приложения** — критичный инвариант: после обновления приложения данные должны оставаться на устройстве (после явного logout данные ОБЯЗАНЫ удаляться — см. §9 Tier 1). Решение 2026-08-01: **схема SwiftData не меняется** (нет миграции), obsolete-поля помечаются комментариями.

### Исходное состояние (до `de6d535`+`69fce28a`)

**`AuthHelper` (62 стр. → 46 стр. после Tier 2):** `@MainActor @Observable final class AuthHelperImp: AuthHelper` — UserDefaults-backed флаг `isAuthorized` (после Tier 2: `isOfflineOnly` удалён, см. Tier 2), методы `performOfflineLogin()` / `triggerLogout()`. Не трогает SwiftData.

**Двойное хранение `isOfflineOnly` (smell, решён в `6b28f00`):** `AuthHelper.isOfflineOnly` (UserDefaults, 1 reader) vs `User.isOfflineOnly` (computed `userName == "offline-user"`, 2 reader'а). Удалён `AuthHelper.isOfflineOnly` — `User.isOfflineOnly` остался source of truth.

**Logout-flow регрессия (`ed82f6e9`):** pre-commit `processAuthStatus` (line 292 в `ed82f6e9~1`) делал `didLogout()` + `try context.delete(model: User.self)`. `ed82f6e9` удалил метод + call-site + всю `StatusManagerTests/` (22 файла, ~6000 LOC). Текущий `.onChange` (после `69fce28a`): `appSettings.didLogout()` + `reviewManager.reset()` + `statusManager.didLogout()` + `try statusManager.modelContainer.mainContext.delete(model: User.self)` (errors → `logger.error`).

**Деталь без cascade:** `CalendarExtensionRecord.user: User?` — plain optional без `@Relationship`/`deleteRule`. Удаление User НЕ зацепит extension records → нужен `didLogout()` (внутри `clearExtensionDates()` удаляет `CalendarExtensionRecord`). Одну половину восстанавливать нельзя.

**Offline user sentinel:** `User(offlineWithGenderCode:)` создаёт User с `id: -1`, `userName: "offline-user"`. `OfflineLoginView` сначала вызывает `authHelper.performOfflineLogin()` (UserDefaults), затем удаляет существующий User с `id == -1` (если есть) и вставляет новый. **Существующие User с `id != -1` НЕ затрагиваются** → данные existing authorized users защищены.

### Sync/server-related поля (выполнено: помечены @available, не удалять)

**На `User` модели (8 deprecated полей в `fd5f845`):** `fullName`, `email`, `imageStringURL`, `cityId`, `countryId`, `birthDateIsoString` — server profile (0 prod-readers); `unsyncedReadInfopostDaysString` (private) — sync field, 1 prod-reader (`StatusManager.extendCalendar():742` → `setUnsyncedReadInfopostDays([])`). Internal `@available` warning при use site допустим.

**На других `@Model` (5 deprecated + 6 живых):**

| Поле | Статус |
|---|---|
| `isSynced` (CustomExercise/DayActivity/UserProgress/CalendarExtensionRecord) | deprecated (sync flag) |
| `UserProgress.lastModified` | deprecated (sync timestamp) |
| `shouldDelete` (все 4 модели) | жив (soft-delete filter) |
| `createDate`/`modifyDate` (CustomExercise/DayActivity) | живые (audit/sort) |
| `CalendarExtensionRecord.lastModified` | жив (sort comparator в `StatusManager.swift:1008-1009`) |

**Аннотация:** `@available(*, deprecated, message: "...")` (русский текст, `24ebd8d`). **Не удалять** — нет миграции, несколько лишних nullable полей не критичны (по решению продукта 2026-08-01).

### Упрощения (Tiers)

**Tier 1 — восстановить logout-флоу (0 риск, исправление регрессии `ed82f6e9`):**

- [x] [2026-08-01] **`de6d535` (+164 LOC, 3 файла):** восстановлен logout flow (`.onChange` body + `MockStatusManager.create()` + `StatusManagerLogoutTests`, 5 адаптированных тестов вместо дословного восстановления — без `MockStatusClient`, протокол удалён в `ed82f6e9`).
- [x] [2026-08-01] **`69fce28a` (+47 net, 3 файла):** follow-up Tier 1 — `@Environment(\.modelContext)` → `statusManager.modelContainer.mainContext` (App-struct не получает контейнер через env); восстановлен `getStatus()` автостарт дня 1; +2 теста (`auto-start`/`keeps-existing`).
- [x] [2026-08-01] Pre-commit `StatusManager.didLogout()` сохранён — теперь нужен (call-site из `.onChange`), не dead code.
- **Не literal restoration:** дословное восстановление тестов потребовало бы ~250 LOC мёртвого prod-кода (`StatusClient` + `MockStatusClient` с 0 prod-ссылок). Адаптация: −164 LOC с тем же coverage.
- **Scope discovery:** план говорил «только `StatusManagerLogoutTests` (153 LOC)». Реально `ed82f6e9` удалил всю `StatusManagerTests/` (22 файла, ~6000 LOC). Восстановлено **LogoutTests + 2 теста из GetStatusTests** = 7 тестов минимального риска. Остальные 20 — Tier 2+ итерации.

**Tier 2 — опциональное упрощение AuthHelper (низкий риск):**

- [x] [2026-08-01] **`6b28f00` (−19 LOC, 3 файла):** `AuthHelper.isOfflineOnly` удалён (Constants −2, AuthHelper −16, SwiftUI_SotkaAppApp −1). Протокол AuthHelper: `isAuthorized` + `triggerLogout()` + `performOfflineLogin()`. `User.isOfflineOnly` остался source of truth. Migration нюанс не возник — `showLoadingOverlay` в test-mode под `isAuthorized = true`, в read-only prod-mode guard уже под `isReadOnlyMode`.

**Tier 3 — НЕ рекомендуется:**

- Полное удаление `AuthHelper`: gain −62 стр., но смешивает auth-state с UI + риск сломать logout flow + потеря данных existing authorized users. **Не делать.**
- Удаление obsolete полей User / sync-флагов: требует SwiftData migration (manual + test migration scenarios), риск потери данных. **Не делать в этой итерации.**

### Итог

- **Сохранение данных existing authorized users** обеспечено: schema не меняется, OfflineLoginView не трогает User с `id != -1` (sentinel-protection). Logout удаляет данные (Tier 1 выполнен).
- **Tier 1+2+deprecated выполнены** (`de6d535`+`69fce28a`+`6b28f00`+`fd5f845`+`24ebd8d`).
- **Не делать:** Tier 3, sync-flag удаления (решение продукта).

## 10. [NEW] Следующая волна аудита (после current HEAD, 2026-08-01)

Все находки верифицированы субагентами (`explore`) + ручная проверка `TrainingRowAction` через `project.pbxproj:107` (в `membershipExceptions` для Watch target). **Выполнено** в 4 коммитах (`3648fc2`+`a3c7f8f`+`af6a5bd`+`381ee78`+`fc5efb0`).

### Группа D — Watch VM dead members (9 членов, ~174 LOC prod + ~9 watch-тестов) [x]

| Член | VM | Prod refs (watch) | Test refs (watch) |
|---|---|---|---|
| `shouldShowExercisesReminder` | WorkoutViewModel | 0 | 2 (SetupTests:150,172) |
| `getStepState(for:)` | WorkoutViewModel | 0 | 2 (StepManagementTests:153,156) |
| `getCycleSteps()` | WorkoutViewModel | 0 | 1 (StepManagementTests:179) |
| `getExerciseSteps(for:)` | WorkoutViewModel | 0 | 2 (StepManagementTests:214, SetsTests:325) |
| `canRemoveExercise` | WorkoutPreviewViewModel | 0 | 2 (EditMethodsTests:21,35) |
| `updatePlannedCount(id:action:)` | WorkoutPreviewViewModel | 0 | 2 (EditMethodsTests:191,209) |
| `updateTrainingCount(at:amount:)` | WorkoutPreviewViewModel | 0 | 3 (EditMethodsTests:87,103,120) |
| `removeTraining(at:)` | WorkoutPreviewViewModel | 0 (private, cascade) | 0 |
| `startWorkout` | HomeViewModel | 0 | 1 (HomeViewModelTests:204) |

Живые перегрузки/альтернативы:

- `updatePlannedCount(for: Int)` (WorkoutPreviewViewModel:239) — caller: `WorkoutPreviewView.swift:162`
- `updateTrainingCount(for:newValue:)` (WorkoutPreviewViewModel:253) — caller: `WorkoutPreviewView.swift:143`
- `WorkoutEditView.swift:33-35` имеет свой локальный `canRemoveExercise` (не VM)
- Кнопки `startWorkout` в watch нет: `HomeView` → `fullScreenCover` `WorkoutPreviewView` → `loadData(day:)` (HomeView:13-14, 42-46)

**Safety check `TrainingRowAction`:** файл `Models/Workout/TrainingRowAction.swift` (iOS-only, в `membershipExceptions` для Watch target: `project.pbxproj:107`) **остаётся живым** в iOS. Живые ссылки: `WorkoutPreviewViewModel.swift:277` (`updatePlannedCount(id:action:)` — iOS-метод, вызывается из `WorkoutPreviewScreen.swift:148,160`) + `TrainingRowView.swift:9,17` (тип параметра `onAction` в живой iOS-view). После удаления 9 watch-членов исчезает единственная watch-ссылка (`SotkaWatch/.../WorkoutPreviewViewModel.swift:196`); 3 iOS-ссылки сохраняются. Файл `TrainingRowAction.swift` удалять не нужно.

**Subtotal: ~174 LOC prod + ~9 watch-тестов (SetupTests:132-172, StepManagementTests, SetsTests:302-325, EditMethodsTests, HomeViewModelTests:204).** [x] Реальный LOC: −180 prod (HomeViewModel.swift:27, WorkoutPreviewViewModel.swift:85, WorkoutViewModel.swift:71) + −313 tests = 493 удалений в коммите `fc5efb0`.

### Группа E — SWDesignSystem dead files (2 файла, 198 LOC) [x]

`ItemListScreen` удалён в `ddcb1d52` → транзитивно мёртвыми стали:

| Файл | LOC | Содержимое |
|---|---|---|
| `Libraries/SWDesignSystem/Public/SectionView.swift` | 122 | `SectionView` struct + 3 init'а + `Mode` + extension |
| `Libraries/SWDesignSystem/Internal/SectionHeaderView.swift` | 76 | `SectionSupplementaryView` + `#Preview` |

**Уточнение:** `SectionSupplementaryView.swift` как отдельный файл **не существует** — тип живёт внутри `SectionHeaderView.swift`. Ранее Periphery (line 104) отмечал только redundant `public` модификатор — после удаления `ItemListScreen` (транзитивный caller) оба файла полностью мёртвые.

**Subtotal: 198 LOC pure delete.** [x] Реальный LOC: −198 в коммите `3648fc2`.

### Группа F — ImageAssetManager test-only methods (4 метода, ~63 LOC) [x]

| Метод | Prod refs | Test refs |
|---|---|---|
| `getImageURL(for:)` | 0 (внутр. caller — `imageExists`, тоже dead) | 13 (ImageAssetManagerTests) |
| `getAllAvailableImages()` | 0 | 2 |
| `imageExists(_:)` | 0 | 2 |
| `getImageSize(_:)` | 0 | 2 |

**Оставить:** `copyImageToTemp(...)` — prod chain: `HTMLContentView.swift:251` → `resourceManager.copyResources` (`InfopostResourceManager.swift:54`) → `copyImagesFromAssets` (line 64) → `ImageAssetManager.copyImageToTemp` (line 130).

Тестовые вызовы для очистки: ~12 мест в `ImageAssetManagerTests` (строки 13, 20, 27, 34, 41-42, 113, 120, 129, 138, 146, 158, 170).

**Subtotal: ~63 LOC prod + ~12 тестовых вызовов.** [x] Реальный LOC: −67 prod + −106 tests = −173 в коммите `381ee78`.

### Группа G — SWUtils dead extensions (4 члена + бонус, ~30 LOC) [x]

| Член | Файл | LOC |
|---|---|---|
| `Date.rawValue` + `init?(rawValue:)` | `Extensions/Date+rawValue.swift` | 12 |
| `String.trueCount` | `Extensions/String+.swift:5-7` | 4 |
| `String.withoutSpaces` | `Extensions/String+.swift:10-12` | 4 (cascade) |
| `Double.formattedForUI` | `Extensions/Double+.swift:7-9` | 6 |

**Бонус:** `Double.fromUIString` (`Double+.swift:14-17`, 4 LOC) тоже dead. Опционально — удалить `Double+.swift` целиком (10 LOC).

Тестовые файлы: `DateRawRepresentableTests.swift` (38 строк), часть `SWUtilsTests.swift` (lines 7-21), `DoubleExtensionTests.swift` (17 вхождений).

**Subtotal: ~30 LOC prod (или ~36 с `Double+.swift` целиком) + 3 тестовых файла/части.** [x] Реальный LOC: −218 prod (`Date+rawValue.swift:12` + `String+.swift:10` (trueCount+withoutSpaces) + `Double+.swift:18` целиком) + −30 tests (`DateRawRepresentableTests.swift:38` + часть `SWUtilsTests.swift:19` + `DoubleExtensionTests.swift:151`) = −248 в коммите `af6a5bd`. `Float+.swift` (Float.fromUIString + .formattedForUI + .stringFromFloat) жив — используется в `UserProgress.swift:179`, `TempMetricsModel.swift:28,48`, `String+.swift:27`.

### Группа H — ReadOnlyModeKey write-only env key (5 LOC) [x]

| Файл | LOC | Verdict |
|---|---|---|
| `Services/ReadOnlyModeKey.swift` | 5 | DEAD (write-only, 0 readers). Удалён в `a3c7f8f` (−5 prod + −1 строка `SwiftUI_SotkaAppApp.swift:142`) |

Содержимое: `@Entry var isReadOnlyMode: Bool = AppConfiguration.isReadOnlyMode` (iOS 17+ Entry macro, не legacy `EnvironmentKey`). Write site: `SwiftUI_SotkaAppApp.swift:142`. **Read sites: 0** во всём проекте. Сервисы получают флаг через init-параметр, не через environment.

Аналог `9cb2646` (NetworkStatus, удалён по той же причине).

### Итог новой волны

| Группа | LOC prod | Тесты |
|---|---|---|
| D (Watch VM) | ~174 | ~9 watch-тестов |
| E (Section) | 198 | 0 |
| F (ImageAsset) | ~63 | ~12 вызовов |
| G (SWUtils) | ~30 (+6 опц.) | 3 файла/части |
| H (ReadOnlyModeKey) | 5 | 0 |
| **Итого (план)** | **~470** | **~12** |
|---|---|---|
| **Итого (факт)** | **−488** | **−419** |

**Реальный итог в 5 коммитах:**

- `3648fc2` (Группа E): −198 prod
- `a3c7f8f` (Группа H): −6 (5 prod + 1 line)
- `af6a5bd` (Группа G): −248 (218 prod + 30 tests)
- `381ee78` (Группа F): −173 (67 prod + 106 tests)
- `fc5efb0` (Группа D): −493 (180 prod + 313 tests)
- **Σ: −1118 строк** (488 prod + 419 tests + прочее)

**Контроль качества:** SwiftUI-SotkaApp build ✓, SotkaWatch Watch App build ✓, 829 iOS unit tests ✓, 169 Watch unit tests ✓.

**Зависимости: 0.**

### Не вошло (пограничные случаи)

| Файл/член | Причина |
|---|---|
| `SWTextField.swift` (248 LOC) | Caller (`EditProgressScreen.swift:322`) использует ~95 LOC ядра (стили + валидация + focus). `errorState`/`isSecure`/`lineLimit` — **неиспользуемые параметры public API с дефолтами**, не dead code: используются в `body`/`textField`/`borderColor`/`errorMessageViewIfNeeded`; Periphery их НЕ считает мёртвыми. Мёртвого нет, есть ~95 LOC preview (`SWTextField.swift:152-247`). Удаление целиком потеряет единую стилизацию дизайн-системы. Разумный путь — урезать preview, не удалять |

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
| `de6d535` (Tier 1) | 3 | +164 | [restore] logout flow: `.onChange(of: isAuthorized)` body + `MockStatusManager.create()` + `StatusManagerLogoutTests` (5 адаптированных тестов). Детали — §9 Tier 1 |
| `69fce28a` (Tier 1 follow-up) | 3 | +47 | [FIX] `@Environment(\.modelContext)` не содержит контейнер в App-struct → `try statusManager.modelContainer.mainContext.delete(...)` (тот же путь, что в докоммитном `processAuthStatus`). [restore] `StatusManager.getStatus()` автостарт дня 1 (`if startDate == nil { startDate = now }`). + `StatusManagerGetStatusTests` (2 теста: auto-start/keeps-existing) |
| `6b28f00` (Tier 2) | 3 | −19 | Удалён `AuthHelper.isOfflineOnly` (UserDefaults `"isOfflineOnly"` key + property + assignments в `performOfflineLogin()`/`triggerLogout()`). 1 reader в `SwiftUI_SotkaAppApp.showLoadingOverlay` упрощён. `User.isOfflineOnly` остался source of truth. Детали — §9 Tier 2 |
| `fd5f845` (deprecated markers) | 5 | +12 | 12 `@available(*, deprecated, ...)` аннотаций: 7 server-полей User + 1 sync-поле + 4 sync-флага (`isSynced` в CustomExercise/DayActivity/UserProgress/CalendarExtensionRecord) + 1 timestamp (`UserProgress.lastModified`). Живые sync-связанные поля оставлены без аннотации (soft-delete filter / sort / audit). См. §9 Sync/server fields |
| `24ebd8d` (i18n) | 5 | ±12 | Русский текст 12 deprecated-сообщений в `@available` (Server profile → Поле профиля сервера; Sync flag → Sync-флаг; Sync field → Sync-поле; Sync timestamp → Sync-timestamp) |

**Итого до Periphery re-run #2: ~−33 500 net LOC production, ~85 тестов удалено/переписано.**

### Фактический результат Periphery re-run #2 (5 коммитов)

| Commit | Файлы | Net | Что |
|---|---|---|---|
| A1 `ddcb1d52` | 10 | −533 | `git rm` 8 dead-файлов (ListRowView, ItemListScreen, CheckmarkRowView, LocationFeedback, ActivitySnapshot, MockResult, MockWCSession, MockStatusManager) + 2 cascade props |
| A2 `b8761560` | 32 | −220 | 9 prod (MainUserForm, Gender, User sync helpers, DayActivity/DayActivityTraining computed, 3 сервиса isReadOnlyMode, 2 screens) + 3 preview-fixup + ~80 call-sites. Доп. — `createMockServices` (1 site) исправлен preventively |
| B `3e928f6f` | 12 | −13 | 3 протокола delete (ReviewContext, ReviewAttemptStoring, WorkoutCompletionsCounting) + 2 mock rewrite (16 call-sites в `ReviewManagerTests` + 3 inline). `makeSUT` стал `throws` + 4-tuple |
| B-fix `220375cc` | 1 | +4 | Guard reversed range в `seedActivities`/`appendActivities` (Swift 6.3 trap). **НЕ та же проблема, что в `21608712`** — здесь range precondition, не ModelContext dealloc |
| C `4655820` | 3 | −189 | 4 dead метода `DateFormatterService` + 13 тестов + 2 explicit `: Bool` для ambiguous require |

**Итого Periphery re-run #2: ~−1029 net LOC production, 14 тестов удалено/переписано.** Подробный план (A1/A2/B/C группы) — раздел 8.

### Финал 2026-08-01: Tier 2 + deprecated markers

Все `[ ]` пункты плана закрыты (`6b28f00`+`fd5f845`+`24ebd8d`, суммарно −19 net LOC + 24 LOC аннотаций/i18n). Подробности — §9 Tier 2 + Sync/server fields.

### Не выполнено (оставлено на следующие итерации)

Все запланированные Periphery re-run #2 чистки (Группа A1/A2/B/C, раздел 8), пост-чистки (Tier 2 inline + SWDivider), восстановление logout-flow (Tier 1, `de6d535`+`69fce28a`), Tier 2 (`AuthHelper.isOfflineOnly` `6b28f00`) и deprecated-аннотации User/sync полей (`fd5f845`+`24ebd8d`) **выполнены** — см. «Фактический результат Periphery re-run #2» и §9 в Итоге.

**Активных [ ] пунктов нет.** Все находки аудита либо реализованы, либо явно заблокированы решением продукта (Tier 3, sync-flag миграция — см. §9 Итог). Волна §10 выполнена в 5 коммитах (`3648fc2`/`a3c7f8f`/`af6a5bd`/`381ee78`/`fc5efb0`), −1118 строк, без новых сетевых/auth зависимостей.

### Контроль качества

- iOS build: ✅ (iPhone 11 / iOS 26.5 / xcodebuild-mcp). Pre-existing `AppIcon` asset error в watch-таргете (`SotkaWatch Watch App` Assets.xcassets) — не связан с правками аудита (подтверждено через `git stash` до/после).
- Unit tests: 869 passed, 1 skipped. История: 1833 → 977 (`ed82f6e9` −856) → 868 (после `8452aa0`) → 862 (Periphery re-run #2: −6 `DateFormatterServiceTests` в SWUtils target, 16 `ReviewManagerTests` не сломаны, 0 regressions в iOS) → **867 (`de6d535` Tier 1: +5 logout-тестов)** → **869 (`69fce28a` Tier 1 follow-up: +2 getStatus-теста)** → **869 (`6b28f00`+`fd5f845`+`24ebd8d`: no test changes, удаление флага + deprecation-аннотации не требуют новых тестов — YAGNI)**
- UI-тесты: ✅ (8 скриншотов, `testMakeScreenshots`)
- Watch ↔ iPhone sync: не сломана (`WatchConnectivityService`/`WCSession`/`WorkoutDataResponse`)

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
