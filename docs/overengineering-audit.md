# Аудит over-engineering: весь репозиторий

Дата аудита: 2026-07-25. Применено 16 коммитов 2026-07-25..26: `ed82f6e9` (delete) → `22dace92` (FIX+restore) → `19081bad`/`2555914a`/`c2e906a3`/`56726fe2` (delete-2: 4 [NEW] модели + SWFileManager + DateFormatter + String + ImageProcessor + Infopost + SWNetwork + SWKeychain + SWAlert + ScreenshotDemoData) → `9cb2646` (NetworkStatus) → `f10157a`/`f1065ca`/`65d39dc`/`606f7b2` (4 docs-этапа) → `68e4bca` (правка плана Review) → `bc0a76f` (Review Фаза A) → `095af10` (move shouldAttemptMilestone) → `f7f6a61`/`af3cf6b` (update-plan × 2) → `d7f7682c` (delete-3: ponytail audit — KeyedDecodingContainer+/MediaFile/InfopostHTMLProcessor/FilenameManager/HomeDayCountModel/AppLanguage, −647 LOC) → `21608712` (fix: ProgressServiceTests ModelContext crash).
Скоуп: только избыточная сложность (не корректность, не безопасность, не производительность).

Контекст: `AppConfiguration.isReadOnlyMode = true` на постоянной основе — серверные API закрыты, поэтому весь сетевой слой (синхронизация прогресса, авторизация на сервере, разрешение конфликтов дат, серверный профиль/смена пароля) — мёртвый код и подлежит удалению. UI-тесты и mock-bootstrap по-прежнему передают `isReadOnlyMode: false`, чтобы симулировать нормальное поведение для скриншот-тестов.

**ВАЖНО (`22dace92`):** моки серверных протоколов в `Client+.swift` (~685 стр.) — UI-тестовая инфраструктура, не мёртвый код. Заменены прямым SwiftData-seed'ом в `ScreenshotDemoData.seedDemoData()`. Подробности — раздел 7.

Предыдущий аудит 2026-07-21 валиден. С тех пор: `1c890e2` (Periphery, 2026-05-01, ~1937 строк); добавлены находки (SyncStartDateScreen/ChangePasswordScreen/EditProfileScreen/StatusManagerLogoutTests/sync-методы в 3 сервисах + 4 мёртвых протокола); обновлены счётчики и обоснования (`StatusManager` — 5 независимых гейтов, `MockSWClient` — warning из-за 14 живых unit-тестов).

Теги: `delete` — мёртвый код; `stdlib` — велосипед вместо стандартной библиотеки; `native` — то, что платформа делает сама; `yagni` — абстракция с одной реализацией; `shrink` — та же логика короче.

Статусы: `[x]` выполнено в коммитах `ed82f6e9`/`22dace92`/`19081bad`/`2555914a`/`c2e906a3`/`56726fe2`/`9cb2646`/`f10157a`/`f1065ca`/`65d39dc`/`606f7b2`/`bc0a76f`/`095af10`/`f7f6a61`/`d7f7682c`/`21608712`, `[ ]` не выполнено (см. причину), `[NEW]` — новая находка, появившаяся после удаления мёртвого кода, `[FIX]`/`[restore]` — исправление критических побочных эффектов (коммит `22dace92`).

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

- [x] yagni `ReviewAttemptRules.swift` (10 стр.) → `func ReviewMilestone.isNotYetAttempted(in:)` (3 стр.) + `ReviewManager.shouldAttemptMilestone` удалён (7 стр.). 0 external callers вне `Services/Review/`. `ReviewAttemptRulesTests.swift` (16 стр., 2 теста) — 2 вызова переподключены на `ReviewMilestone.X.isNotYetAttempted(in: [...])`. **`nonisolated` workaround снят:** метод на обычном enum'е, MainActor-изоляция не наследуется. Diff: `ReviewManager` −10 строк (100 → 90), `ReviewMilestone` +4 (17 → 21), тесты −10.
- [x] shrink `ReviewSkipReason.swift` (9 стр.) → nested `enum ReviewManager.ReviewSkipReason` (5 cases). Отдельных тестов нет.
- [x] yagni `ReviewStorageKeys.swift` (8 стр.) → 3 `static let` в `ReviewStorage` (private namespace `"review."` + 2 ключа). `ReviewStorageKeysTests.swift` (17 стр., 2 теста) — 3 вызова переподключены на `ReviewStorage.attemptedMilestones` / `ReviewStorage.lastReviewRequestAttemptDate`.

**Фактический net (вместо планировавшегося −27): −14 стр. production, −10 стр. tests.** 3 файла → 0; код инкапсулирован в 1 класс + 1 struct + 1 enum-метод. Удалённые 27 строк частично возвращаются в inline-код (≈+13 в файлы-хозяева).

### Фаза B — переписывание тестов (доп. net −18, дополнительный −18 стр.)

- [ ] yagni `ReviewAttemptStoring.swift` (8 стр.) → удалить протокол, использовать `ReviewStorage` напрямую. `MockReviewAttemptStore` в `ReviewManagerTests:222` заменить на `ReviewStorage` + `MockUserDefaults`.
- [ ] yagni `WorkoutCompletionsCounting.swift` (5 стр.) → удалить протокол, использовать `WorkoutCompletionsCounter` напрямую. `MockWorkoutCompletionsCounter` в `ReviewManagerTests:253` заменить на `WorkoutCompletionsCounter` + in-memory SwiftData container.
- [ ] yagni `ReviewContext.swift` (5 стр.) → убрать обёртку, передавать `hadRecentError: Bool` напрямую в `workoutCompletedSuccessfully(hadRecentError:)`. Затронуты 2 внешних файла: `StatusManager.swift:571`, `WorkoutPreviewViewModel.swift:238`.

### keep — расширен, не трогаем остальное

- [x] keep `ReviewEventReporting.swift` (5 стр.) — **живой, не тронут.**
- [x] `ReviewMilestone.swift` (21 стр.) — расширен `func isNotYetAttempted(in: [ReviewMilestone]) -> Bool` (3 стр., тестируется в `ReviewAttemptRulesTests`, 2 теста). Других правок нет: `ReviewMilestoneTests.swift` (90 стр., ~10 тестов) тестирует статические методы `milestone(forCompletedWorkoutCount:)` / `isMilestoneWorkoutCount(_:)`. Гнездование в `ReviewManager` не требуется: enum остаётся публичным для тестов.
- [x] keep `ReviewRequestHost.swift` (55 стр.) — SwiftUI-интеграция StoreKit `requestReview()`: `ReviewRequestTriggerID` (4-7) для `.task(id:)`, `ReviewRequestModifier` (9-49) private, `View.reviewRequestHandling(requestDelay:)` (51-55) public. Подавляет запрос при `-FASTLANE_SNAPSHOT`/`UITest`. **Живой, не тронут.** Тесты: `ReviewRequestTriggerIDTests.swift` (34 стр.).
- [x] keep `WorkoutCompletionsCounter.swift` (31 стр.) — concrete class для подсчёта завершённых тренировок из SwiftData. **Живой, не тронут** (Фаза B заменит протокол `WorkoutCompletionsCounting` этим конкретным типом, см. ниже). Тесты: `WorkoutCompletionsCounterTests.swift` (134 стр.).

### Итог Review-слоя (Фаза A выполнена, Фаза B [ ])

`ReviewManager` 85 → 90, `ReviewStorage` 31 → 36, `ReviewMilestone` 17 → 21. Production 270 → 256 (net −14). Tests 636 без изменений (2 теста в `ReviewAttemptRulesTests` 26 → 16). Фаза B (план) доведёт до 256 → 244.

## 4. Другие мёртвые/yagni находки в приложении

### Watch-приложение

- [x] **Удалены `WatchWorkoutService.swift` + тесты (~285 стр.).** Реальная workout-логика — `WorkoutViewModel`. Watch ↔ iPhone синхронизация через `WatchConnectivityService`/`WCSession`/`WorkoutDataResponse` — не затронута.

### Прочее

- [x] Удалены `ImageProcessor.createThumbnail` (5 стр. + 2 теста), `InfopostAvailabilityManager.getAvailablePostsBySection` (4 стр. + 1 тест), `Client+.swift` (74 стр., демо-данные → `ScreenshotDemoData.seedDemoData()`, см. раздел 7), `ScreenshotDemoData.readInfopostDays` (1 константа, 0 вызовов).

### Новые мёртвые находки после `ed82f6e9` (не были в исходном аудите) [NEW]

- [x] [NEW] **Удалены 4 модели, ставшие мёртвыми после удаления sync/DTO:** `ConflictingStartDate`, `CalendarPurchasesResponse`, `LoginCredentials`, `ProgressSnapshot`. Все 0 ссылок в проде.

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

- [x] **Все 11 doc-файлов + `AGENTS.md` обработаны** (`f10157a`/`f1065ca`/`65d39dc`/`606f7b2`): удалены целиком `testing-mocks.md`, `ui-test-mock-client.md`, `sync-journal.md`, `crash-swiftdata-invalid-future-backing-data.md`; отредактированы `daily-activities.md`, `custom-exercises.md`, `infoposts.md`, `progress-screen.md`, `calendar-extension.md`, `data-migration.md`, `AGENTS.md` (строка 75 — убран термин `SyncJournalEntry`).

## 7. UI-тестовая инфраструктура: демо-данные (ошибка аудита) [FIX]

`Client+.swift` (~685 стр.) с мок-клиентами `MockDaysClient`/`MockProgressClient`/`MockExerciseClient`/`MockInfopostsClient` — не мёртвый код, а UI-тестовая инфраструктура (fixture-данные для скриншотов). До `ed82f6e9` `SwiftUI_SotkaAppApp.init()` при `UITest` через `createMockServices()` подставлял 12 дней тренировок / прогресс дня 1 / 3 демо-упражнения / 10 прочитанных инфопостов. После удаления UI-тесты `testMakeScreenshots` падали. Аудит должен был пометить `Client+.swift` как `adapt`, не `delete`.

- [x] [FIX] `22dace92`: `ScreenshotDemoData.seedDemoData(context:user:)` создаёт 11 `DayActivity` (8 тренировок + 2 отдыха + 1 растяжка), `UserProgress` дня 1, 3 `CustomExercise`, `Country`. День 12 пуст — для кнопок выбора типа в `HomeActivitySectionView`. `createMockServices()` дополнен `performOfflineLogin()` + `Tips.resetDatastore()` + `UIView.setAnimationsEnabled(false)`. `Client+.swift` удалён (−74 стр.).

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

### Фактический результат коммита `d7f7682c` (delete-этап-3: ponytail audit)

**16 файлов изменено, 48 вставлено / 695 удалено (net −647).** Выполнение находок ponytail-аудита:

| Категория | Изменение |
|---|---|
| `KeyedDecodingContainer+` + тесты | −364 стр. (47 prod + 317 tests). 0 prod-вызовов, только свои 21 тест. Сервер мёртв → flexible Int/Float-from-string не нужен |
| `MediaFile` + `UIImage+toMediaFile` + `MainUserForm.image` | −34 стр. (15 + 14 + 5 в MainUserForm). Image-upload модель, помечена «для отправки на сервер». Поле `image: MediaFile?` никогда не заполнялось в read-only |
| `InfopostHTMLProcessor` → инлайн в `HTMLContentView` | −29 стр. (64 удалено, 29 вставлено в call site). Single-use struct, 1 caller |
| `InfopostsService+FilenameManager` + тесты → инлайн в `InfopostsService` | −166 стр. (74 prod + 92 tests, 16 вставлено в call site). 4 private метода + Logger, 1 caller |
| `HomeDayCountModel` + тесты → инлайн в `HomeDayCountView` | −44 стр. (16 prod + 28 tests, 15 вставлено в call site). 2 computed property + 1 static formatter |
| `AppLanguage.makeCurrentValue` → инлайн в `MoreScreen` | −5 стр. Static factory удалена, логика в `MoreScreen.swift:90` |
| `.xcodeproj/project.pbxproj` | −2 стр. |

**Результат:** −647 стр. net, 28 тестов удалено (`KeyedDecodingContainer` 21 + `FilenameManager` 4 + `HomeDayCountModel` 3). 0 переписывания тестов, 0 внешних зависимостей — чистый delete + inline.

**Пропущено из ponytail-аудита (не выполнено в `d7f7682c`):** `RestTimeComponents` (false positive: 12-строчный `localizedString` с 4 i18n-кейсами + 3 production-вызова); shrink-оценки (InfopostParser, YouTubeVideoService, VibrationService — реальная экономия меньше трудозатрат); `CachedAsyncImage` (план keep'ит, решение за продуктом); 4 протокола (`WCSession`/`WatchAuth`/`WatchConnectivity`/`ReviewEventReporting` — 2-3 импл каждый, не yagni).

### Не выполнено в `ed82f6e9` + `22dace92` + `19081bad` + `2555914a` + `c2e906a3` + `56726fe2` + `d7f7682c` (оставлено на следующие итерации)

| Категория | Объём | Причина |
|---|---|---|
| Review Фаза B ([ ]) | −12 стр. production (256 → 244) | Фаза A выполнена (`bc0a76f`+move, −14 стр.). Phase B blocked: 2 fileprivate-мока в `ReviewManagerTests:222/253` + 2 внешних caller'а `StatusManager:571` + `WorkoutPreviewViewModel:238`. Реальный net Фазы A = −14 (не −27): inline + move добавляют 13 стр. в файлы-хозяева |
| `AuthHelper` shrink ([ ]) | 62 стр. production | Требует переноса `isOfflineOnly` в `User` (UserDefaults-бэкап) + inlining `triggerLogout` в `MoreScreen`. Снижение читаемости. Решение за продуктом |

### Контроль качества после `ed82f6e9` + `22dace92` + `19081bad` + `2555914a` + `c2e906a3` + `56726fe2` + `d7f7682c`

- iOS build: ✅ SUCCEEDED (iPhone 17 / iOS 27)
- Unit tests на iPhone 11 (iOS 26.5): ✅ **875 passed, 0 failed, 1 skipped** (было 1833 → −856 мёртвых тестов в `ed82f6e9`; +5 миграционных после `22dace92` = 982; −79 тестов после `19081bad`/`2555914a`/`c2e906a3` = 903; −28 тестов после `d7f7682c` = 875)
- UI-тесты (скриншоты): ✅ **все проходят** (`testMakeScreenshots`, 8 скриншотов)
- Watch app ↔ iPhone sync через `WatchConnectivityService`/`WCSession`/`WorkoutDataResponse` — не сломана

### Супротив прошлого аудита (2026-07-21)

Добавлены `SyncStartDateScreen`/`HelpScreen`/`ChangePasswordScreen`/`EditProfileScreen`/`SyncResultBadge`/`SyncDateComparisonPolicy` + соответствующие тесты (~+2000 строк); добавлены sync-методы в активных сервисах (DailyActivities/CustomExercises/Infoposts) + 4 мёртвых протокола (+~1100 строк production, +136 строк тестов); удалены в `1c890e2` Periphery-чистки (учтены в новых счётчиках). `MockSWClient` помечен как **warning** — использовался в 14 unit-тестах `CustomExercisesServiceTests`. В `ed82f6e9` выбран **вариант (b)**: `MockSWClient` + тесты удалены целиком. `ProgressServiceTests` перенесён в keep (тестирует живой локальный `ProgressService`).

### Ошибки аудита (исправлены в `22dace92`)

1. `Client+.swift` = UI-инфра, не мёртвый код — см. раздел 7.
2. `SwiftDataMigrationTests` = критичный регресс — 5 тестов восстановлены (269 стр.), см. раздел 4 [restore].

CachedAsyncImage остаётся: `AsyncImage` + `URLCache` не решает мерцание при перерисовках ячеек, а кастомный `ImageLoader`/`ImageCache` даёт стабильное изображение без фаз загрузки. Удаление sync-флагов и Firebase в эту цифму не входят: флаги — вторая итерация с миграцией, Firebase — оставляем 100%.
