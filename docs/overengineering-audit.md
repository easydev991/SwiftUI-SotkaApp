# Аудит over-engineering: весь репозиторий

Дата аудита: 2026-07-25. Применено 33 коммита 2026-07-25..2026-08-01, хронология (подробности — разделы 1-8 + Итог): `ed82f6e9` (delete, −30 489/+199) → `22dace92` (FIX+restore, +393/−80) → delete-2 (`19081bad`/`2555914a`/`c2e906a3`/`56726fe2`, net −2575) → `9cb2646` (NetworkStatus) → 4 docs (`f10157a`/`f1065ca`/`65d39dc`/`606f7b2`) → `68e4bca` (правка плана Review) → `bc0a76f` (Review Фаза A) → `095af10` (move shouldAttemptMilestone) → 2 update-plan (`f7f6a61`/`af3cf6b`) → `d7f7682c` (delete-3 ponytail, −647) → `21608712` (fix ProgressServiceTests) → `c6f9d9e7` (compress) → `6753c89` (Tier 1 ponytail, −119) → `e75e49db` (compress) → `fbb689fb` (Periphery findings) → `8452aa0` (Tier 2 Periphery, −140) → Periphery re-run #2: `ddcb1d52`/`b8761560`/`3e928f6f`/`220375cc`/`4655820` (5 коммитов, ~−1029, раздел 8) → пост-чистки: `a63ef811` (Tier 2 inline: DividerIfNeededModifier + withDivider, −35 LOC) → `738e24d8` (docs) → `fd040669` (docs compress) → `1f051228` (SWDivider rm + doc drift, −13 LOC) → `fff7e885` (Watch schemes cosmetic, xcodebuild artifact).
Скоуп: только избыточная сложность (не корректность, не безопасность, не производительность).

Контекст: `AppConfiguration.isReadOnlyMode = true` на постоянной основе — серверные API закрыты, поэтому весь сетевой слой (синхронизация прогресса, авторизация на сервере, разрешение конфликтов дат, серверный профиль/смена пароля) — мёртвый код и подлежит удалению. UI-тесты и mock-bootstrap по-прежнему передают `isReadOnlyMode: false`, чтобы симулировать нормальное поведение для скриншот-тестов.

**ВАЖНО (`22dace92`):** моки серверных протоколов в `Client+.swift` (~685 стр.) — UI-тестовая инфраструктура, не мёртвый код. Заменены прямым SwiftData-seed'ом в `ScreenshotDemoData.seedDemoData()`. Подробности — раздел 7.

Предыдущий аудит 2026-07-21 валиден. С тех пор: `1c890e2` (Periphery, 2026-05-01, ~1937 строк); добавлены находки (SyncStartDateScreen/ChangePasswordScreen/EditProfileScreen/StatusManagerLogoutTests/sync-методы в 3 сервисах + 4 мёртвых протокола); обновлены счётчики и обоснования (`StatusManager` — 5 независимых гейтов, `MockSWClient` — warning из-за 14 живых unit-тестов). **Periphery re-run 2026-07-26 #1** (после `e75e49db`): 46 warnings в 17 файлах, 18 false-positives отфильтрованы ручной верификацией (см. раздел 4). Подтверждённый dead code 122 LOC → выполнено в `8452aa0` (−140 net, факт превысил оценку). **Periphery re-run 2026-07-26 #2** (на HEAD после `8452aa0`, пост-ревью): подтверждённый dead code **~605 LOC** в 10 production-файлах + 2 test-моках (Группа A) + Review Фаза B (yagni, 8 файлов, −18 LOC) + 1 safe Tier 2 ponytail item (`DateFormatterService` dead methods, −20 LOC). См. раздел 8 «Пост-`8452aa0` план».

Теги: `delete` — мёртвый код; `stdlib` — велосипед вместо стандартной библиотеки; `native` — то, что платформа делает сама; `yagni` — абстракция с одной реализацией; `shrink` — та же логика короче.

Статусы: `[x]` выполнено (см. раздел Итог), `[ ]` не выполнено (см. причину), `[NEW]` — новая находка после удаления мёртвого кода, `[FIX]`/`[restore]` — исправление критических побочных эффектов (`22dace92`).

## 1. Сетевой слой / синхронизация / авторизация (read-only mode)

Всё, что обращается к серверу, синхронизирует данные или реализует авторизацию, — **мёртвый код**. Сервер закрыт навсегда.

### Целиком мёртвые сервисы

- [x] Удалены 4 мёртвых сетевых сервиса (~1686 стр.).
- [ ] shrink `AuthHelper.swift` — частично выполнено: удалены серверные методы (`authToken`, `saveAuthData`, `updateAuthData`, `didAuthorize`, импорт `KeychainWrapper`). **Осталось 62 стр.** в виде `AuthHelperImp` с локальной логикой (`isAuthorized`/`isOfflineOnly`/`performOfflineLogin`/`triggerLogout`). Класс **живой** — используется `OfflineLoginView`, `MoreScreen.triggerLogout()`, `RootScreen`, `SwiftUI_SotkaAppApp`. Полное удаление требует переноса `isOfflineOnly` флага в `User` (UserDefaults-бэкап) и inlining `triggerLogout` в `MoreScreen`. **См. раздел 4 «На границе скоупа».**

### Удалено в `ed82f6e9` (delete-этап, ~16 530 стр.)

- [x] Удалены sync-экраны, SyncJournal, протоколы, DTO, моки, тесты, sync-сервисы (~16 530 стр., `ed82f6e9`; подробности — Итог).

### keep (живые, не тронуты)

- [x] `WorkoutDataResponse`, `ProgressServiceTests`, sync-флаги (см. раздел 5).

## 2. Пакеты и native-замены

### Целиком мёртвые пакеты

- [x] **SWNetwork** (~1412 стр.) — удалён в `2555914a` (каталог + пакет из `.xcodeproj`).
- [x] **SWKeychain** (~230 стр.) — удалён в `2555914a` (0 prod-ссылок, 0 тестов).

### Пакеты, которые оставляем

- [x] 3 живых пакета сохранены (CachedAsyncImage, SWDesignSystem, SWUtils).

### Native-замены внутри пакетов

- [x] **Native/delete** (`19081bad`/`c2e906a3`): SWAlert, SWFileManager, DateFormatterService helpers, String.capitalizingFirstLetter.
- [x] [NEW] **NetworkStatus** (~46 стр., `9cb2646`): `NetworkStatus` + `NetworkStatusEnvironmentKey` + `.networkStatus(...)` modifier. Write-only: 0 ссылок на `@Environment(\.isNetworkConnected)`, `NWPathMonitor` запускался впустую.

## 3. Review-слой (yagni — избыточная абстракция)

Система «оценить приложение в App Store» реализована через **9 production-файлов (256 стр. после Фазы A) + 7 тестовых файлов (636 стр.)**. Исходно было 12 production-файлов / 270 стр. — 3 файла (`ReviewAttemptRules`/`ReviewSkipReason`/`ReviewStorageKeys`) удалены в Фазе A. **Вся зачистка этого раздела не выполнена в `ed82f6e9`** (выходит за рамки delete-этапа).

**Важно (обнаружено 2026-07-26):** утверждение «тесты не ломаются» из исходного аудита — ложное для 2 протоколов. В `SwiftUI-SotkaAppTests/Services/Review/ReviewManagerTests.swift:222/253` определены `private final class MockReviewAttemptStore: ReviewAttemptStoring` и `private final class MockWorkoutCompletionsCounter: WorkoutCompletionsCounting`, оба используются в `makeSUT()` (строки 11-13) во всех тестах `ReviewManager`. Удаление этих двух протоколов = переписывание тестов. `ReviewContext` — **используется вне `Review/`** (внешние caller'ы: `StatusManager.swift:571`, `WorkoutPreviewViewModel.swift:238`), инлайн потребует изменения их вызовов.

### Фаза A — безопасная консолидация (выполнена в `bc0a76f` + move в текущем коммите, net −14, без переписывания тестов)

Только файлы без fileprivate-моков в `ReviewManagerTests` и без внешних caller'ов:

- [x] yagni/shrink 3 файла (ReviewAttemptRules 10→3, ReviewSkipReason 9→5, ReviewStorageKeys 8→0). 2 тест-файла переподключены. Net: −14 prod, −10 tests.

### Фаза B — переписывание тестов (доп. net −18, дополнительный −18 стр.)

- [x] yagni `ReviewAttemptStoring.swift` (8 стр.) — выполнено в `3e928f6f`. `MockReviewAttemptStore` заменён на `ReviewStorage` + `MockUserDefaults`.
- [x] yagni `WorkoutCompletionsCounting.swift` (5 стр.) — выполнено в `3e928f6f`. `MockWorkoutCompletionsCounter` заменён на `WorkoutCompletionsCounter` + in-memory `ModelContainer` (`makeContainer` helper).
- [x] yagni `ReviewContext.swift` (5 стр.) — выполнено в `3e928f6f`. `hadRecentError: Bool` теперь передаётся напрямую в 8 файлах (~25 call-сайтов).

### keep — расширен, не трогаем остальное

- [x] keep 4 файла: `ReviewEventReporting` (5 стр.), `ReviewMilestone` (21 стр., +`isNotYetAttempted`), `ReviewRequestHost` (55 стр.), `WorkoutCompletionsCounter` (31 стр.). Тесты `ReviewMilestoneTests`/`ReviewRequestTriggerIDTests`/`WorkoutCompletionsCounterTests` — живые.

### Итог Review-слоя (Фазы A и B выполнены в `3e928f6f`)

`ReviewManager` 85→90, `ReviewStorage` 31→36, `ReviewMilestone` 17→21. Production 270→256 (net −14). Tests 636 без изменений. Фаза B доведёт до 244.

## 4. Другие мёртвые/yagni находки в приложении

### Watch-приложение

- [x] Удалены `WatchWorkoutService.swift` + тесты (~285 стр.). Watch ↔ iPhone sync через `WatchConnectivityService`/`WCSession`/`WorkoutDataResponse` — не затронута.

### Прочее

- [x] Удалены мелкие мёртвые члены: `ImageProcessor.createThumbnail`, `InfopostAvailabilityManager.getAvailablePostsBySection`, `Client+.swift` (→ `ScreenshotDemoData.seedDemoData`, см. раздел 7), `ScreenshotDemoData.readInfopostDays`.

### Новые мёртвые находки после `ed82f6e9` (не были в исходном аудите) [NEW]

- [x] Удалены 4 мёртвые модели (все 0 ссылок в проде).

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
| `Libraries/SWDesignSystem/.../SWDivider.swift` | `struct` + `init` + `var body` | 13 LOC | **Стал entirely dead 2026-07-26** (пользователь удалил `DividerIfNeededModifier.swift` + `withDivider` extension — единственный consumer). 0 production-callers, 1 reference в собственном `#Preview`. Periphery-описание «redundant public» было неточным: `public` на struct'е уже не было в HEAD, файл всегда был `internal`. **`git rm` в `1f051228`** |
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

### Прогноз контроля качества

См. финальный «Контроль качества» в конце документа (actual: 862 passed, build ✅, Watch sync не сломана). Прогноз −860 LOC оказался точным (факт −1029 net — большая часть из-за test-mock rewrites, не regression'ов).

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

### Не выполнено (оставлено на следующие итерации)

Все запланированные Periphery re-run #2 чистки (Группа A1/A2/B/C, раздел 8) и пост-чистки (Tier 2 inline + SWDivider) выполнены — см. «Фактический результат Periphery re-run #2» в Итоге. Осталось единственное:

| Категория | Объём | Причина |
|---|---|---|
| `AuthHelper` shrink ([ ]) | 62 стр. production | Требует переноса `isOfflineOnly` в `User` (UserDefaults-бэкап) + inlining `triggerLogout` в `MoreScreen`. Снижение читаемости. Решение за продуктом |

### Контроль качества

- iOS build: ✅ (iPhone 11 / iOS 26.5 / xcodebuild-mcp)
- Unit tests: 862 passed, 1 skipped. История: 1833 → 977 (`ed82f6e9` −856) → 868 (после `8452aa0`) → 862 (Periphery re-run #2: −6 `DateFormatterServiceTests` в SWUtils target, 16 `ReviewManagerTests` не сломаны, 0 regressions в iOS)
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
