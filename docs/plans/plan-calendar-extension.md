# План реализации: Продление календаря (Calendar Extension)

## Концепция

Функционал позволяет пользователю продолжать программу после 100-го дня, добавляя блоки по 100 дней.
В SwiftUI-приложении это бесплатное действие: пользователь нажимает кнопку и получает +100 дней.
Для авторизованного пользователя продления синхронизируются с сервером (по модели старого приложения, но без платёжного UI), для `offline-only` пользователя продления остаются только локальными.

---

## Цели и ограничения

- Продление доступно только на граничных днях: 100, 200, 300...
- Если продление нажато ровно на граничном дне (100/200/300...), `currentDay` не должен сдвигаться в тот же момент.
- Перед внедрением продления нужно защитить синхронизацию: если сервер присылает дни `>100`, приложение не падает, хранит все дни локально, но без продлений в UI показывает только диапазон 1...100.
- Логика офлайн-first: локальное сохранение первым шагом, sync асинхронный и не блокирует UI.
- Режимы должны сохраняться:
  - авторизованный пользователь (логин/пароль): синхронизация с сервером включена;
  - `offline-only` пользователь: сетевой синк (включая покупки продлений) не выполняется.
- После logout/reset данные продлений очищаются.
- Поддержка watchOS обязательна: часы продолжают отображать только текущий номер дня (`День X`).

### Продуктовые решения (зафиксировано)

- Семантика продления в этом приложении отличается от старого ObjC: мы не «перезапускаем» отсчёт от даты покупки продления.
- Если пользователь нажал продление позже граничного дня (например, на «застывшем» 100-м экране через 30 дней), `currentDay` после продления пересчитывается по формуле `min(daysBetween + 1, totalDays)` и может вырасти сразу.
- Для авторизованного пользователя используем серверные покупки календаря (`GET/POST`), чтобы подтягивать старые продления и отправлять новые.
- Количество синхронизированных продлений в UI отдельно не показываем (влияет только на `totalDays` и доступные дни журнала).
- Для `offline-only` пользователя серверные покупки недоступны: работаем только с локальными продлениями.
- Инфопосты остаются только для диапазона `1...100`; при `currentDay > 100` они скрываются осознанно.

### Актуализация после релизов 4.5.0 и 4.6.0

- Journal уже переписан (новая навигация + исправления падений): актуальная база — `JournalScreen` / `JournalListView` / `JournalGridView` в текущем виде.
- `StatusManager` уже содержит контекст офлайн-режима (`isOfflineOnly`) и новую сигнатуру init с `reviewEventReporter`.
- `ProgressCalculator` уже реализует 100-дневные KPI; в этом плане для него фокус только на регрессионных тестах для `currentDay > 100`.
- В текущем SwiftUI-приложении ещё нет серверной синхронизации покупок календаря — её добавляем в рамках Этапа 2.

---

## Базовая математика (единый контракт)

```swift
let maxExtensionCount = 100
let normalizedExtensionCount = min(extensionCount, maxExtensionCount)

let totalDays = 100 + normalizedExtensionCount * 100
let currentDay = min(daysBetween + 1, totalDays)
let daysLeft = totalDays - currentDay

let shouldShowExtensionButton =
    currentDay > 0 &&
    currentDay % 100 == 0 &&
    normalizedExtensionCount < currentDay / 100 &&
    normalizedExtensionCount < maxExtensionCount

let isOver = currentDay >= totalDays
let shouldShowInfopost = currentDay <= 100
```

Источник `extensionCount` в этом плане:

- авторизованный пользователь: `union(serverDates, localDates)` после дедупликации по нормализованной дате;
- `offline-only` пользователь: только локальные даты продлений.

Пояснение UX на 100-м дне после продления:

- до нажатия: `currentDay=100`, `totalDays=100`, `isOver=true`
- после нажатия: `currentDay=100`, `totalDays=200`, `isOver=false`, `daysLeft=100`

Пояснение UX при отложенном нажатии (например, через 30 дней после достижения 100):

- до нажатия: `currentDay=100`, `totalDays=100`
- после нажатия: `currentDay=130`, `totalDays=200`

### Контракт синхронизации покупок (зафиксировано по ObjC + серверу)

- API-эндпоинты:
  - `GET /100/purchases` -> возвращает объект покупок (`custom_editor`, `calendars`)
  - `POST /100/purchases/calendars` -> принимает параметр `date`, возвращает тот же объект покупок
  - в серверных `url_rules` это маршруты `GET v3/100/purchases` и `POST v3/100/purchases/calendars` (префикс версии закрывается базовым URL клиента)
- Формат поля `calendars`: массив ISO-дат (серверный `ApiPurchases.calendars`, старый iOS парсил через `NSISO8601DateFormatter`).
- Формат `POST` параметра: `date=<ISO8601>` (в старом iOS использовался form-urlencoded); в новом клиенте допускается любой формат запроса, который эквивалентно отправляет поле `date`.
- Серверная дедупликация: сравнение дат после нормализации в UTC, точность до секунд (`compareDateTime` в серверном `Profile`).
- Merge-правило в приложении:
  - дедуп по ключу нормализованной даты (UTC, точность до секунд);
  - итоговый `extensionCount` = количество уникальных дат, а не `max(local, server)`;
  - если unsynced локальная дата уже есть на сервере, локальная запись помечается `isSynced=true`, дубль не создаётся.
- Референсы:
  - старый iOS: `SOTKA-OBJc/WorkOut100Days/Library/API/Purchases+Network.m`, `.../Library/Singletons/WODSyncManager.m`
  - сервер: `StreetWorkoutSU/api/controllers/PurchasesController.php`, `.../api/models/ApiPurchases.php`, `.../common/models/Users/Profile.php`

### Уточнения по открытым вопросам ревью (зафиксировано)

1. `DayCalculator.isOver` меняется в Этапе 1: старое `currentDay == 100` заменяется на `isOver = currentDay >= totalDays`, чтобы корректно работать на границах 100/200/300... и на верхнем лимите продлений (`10100`).
2. Хардкод `100` в `DayCalculator.init` убирается в Этапе 1: расчёт идёт через `totalDays`, то есть `currentDay = min(daysBetween + 1, totalDays)`.
3. В Этапе 0 очистка продлений не делается: `clearExtensionDates()` вводится в Этапе 2, а вызовы из `resetProgram()`/`didLogout()` и регрессии проверяются в Этапе 8.
4. `JournalSection` создаётся с нуля в Этапе 4 (новый файл): `id`, `title`, `days`.
5. `PurchasesClient` — именно новый protocol в `Services/Protocols/`, а `SWClient` — его concrete реализация.
6. DTO покупок фиксируем без двусмысленности: response содержит `custom_editor` и `calendars: [String]`; поле `date` относится только к request DTO для `POST`.
7. `shouldShowExtensionButton` и `normalizedExtensionCount` считаются в `DayCalculator` (единый источник математики), `StatusManager/HomeScreen` их только потребляют.
8. `setCurrentDayForDebug(_ day: Int, extensionCount: Int? = nil)` подтверждён: при `nil` extension считается автоматически, при явном значении используется как есть (включая edge-case с `extensionCount = 0`).
9. Watch-файлы в текущем проекте существуют и остаются целевыми для регрессии: `SotkaWatch Watch App/Services/WatchConnectivityService.swift`, `.../ViewModels/HomeViewModel.swift`, `.../Views/DayActivityView.swift`.
10. Retry unsynced выполняется в двух местах через единый helper: `getStatus()` и `syncJournalAndProgress()`. Последовательность: fetch purchases -> merge -> retry unsynced POST -> refresh/merge -> rebuild calculator.
11. `JournalScreen` получает `totalDays` из `StatusManager.currentDayCalculator` через `@Environment(StatusManager.self)` и пробрасывает в list/grid как входной параметр.
12. Формула grid для `page > 0` подтверждена: `day = page * 100 + rowIndex + 1`, поэтому `page = 1`, `rowIndex = 0` => день `101`.
13. При `extensionCount > maxExtensionCount` применяем `normalizedExtensionCount = min(rawCount, 100)` для расчётов UI/калькулятора; сырые записи сохраняются в БД и участвуют в sync/audit.
14. `HomeScreen.Model` берёт состояние дня из `StatusManager.currentDayCalculator` (single source of truth), не содержит собственной математики дней/продлений.

---

## Этап 0: Защитная синхронизация при днях > 100 (до продлений)

### Red: пишем тесты (ожидаем падений)

- [x] Добавлены защитные тесты (`offline-only` включён)

### Green: минимальная реализация

- [x] Подтверждено: дни `>100` хранятся, UI без продлений ограничен `1...100`

### Refactor

- [x] Проверено разделение UI/хранения, выполнен `make format`

---

## Этап 1: DayCalculator

### Red: пишем тесты (ожидаем падений)

- [x] Расширены `DayCalculatorTests`

Примечание: модель дня начинается с 1, сценарий `currentDay=0` не используется.

### Green: минимальная реализация

- [x] Реализована математика продлений в `DayCalculator` (включая future-start)

### Refactor

- [x] Вынесены константы, выполнен `make format`

---

## Этап 2: Хранение, синхронизация покупок и бизнес-логика в StatusManager

### Red: пишем тесты (ожидаем падений)

- [x] Добавлены тесты продлений и миграции

### Green: минимальная реализация

#### 2.1 Хранение продлений

- [x] Добавлены `CalendarExtensionRecord`, DTO и merge `extensionCount`

#### 2.1.1 Безопасная эволюция схемы SwiftData (реализовано)

- [x] Реализован runtime-переход на явную `Schema([...])` с проверкой legacy-store

#### 2.2 API StatusManager

- [x] Реализованы API продлений и `rebuildCurrentDayCalculator(now:)`

#### 2.3 Серверная синхронизация покупок (online-only)

- [x] Реализована server-sync покупок (протокол, `SWClient`, `GET/POST`, merge/dedup/retry), прогнан `SwiftUI-SotkaAppTests`

### Refactor

- [x] Стабилизированы `extendCalendar`/`rebuildCurrentDayCalculator`, выполнен `make format`

Техдолг после Этапа 2:

- [ ] Вернуться к отдельной задаче по `VersionedSchema/SchemaMigrationPlan` после стабилизации Apple-совместимого сценария без крэша на реальных legacy-хранилищах.

---

## Этап 3: HomeScreen

### Red: пишем тесты (ожидаем падений)

- [x] Обновлены Home/Analytics тесты
- [x] Red-фаза зафиксирована

### Green: минимальная реализация

#### 3.1 Кнопка продления

- [x] Добавлен `HomeCalendarExtensionView`

#### 3.2 Активности на Home

- [x] Обновлены `showActivitySection` и `showProgressSection`

#### 3.3 DayCount / finished state

- [x] `HomeDayCountView` обновлён: формат 3+ цифр, `HomeDayCountModel`, разделение `finishedView` (100) и `extendedFinishedView` (200+)

#### 3.4 Инфопост на Home

- [x] Инфопост на Home переведён на `calculator.shouldShowInfopost`

#### 3.5 Аналитика кнопки продления

- [x] Добавлены `extendCalendar(targetTotalDays:)` и tap-логирование
- [x] Поведение аналитики подтверждено unit-тестами без UI-тестов

- [x] Тесты этапа пройдены

### Refactor

- [x] Выполнен рефактор `HomeCalendarExtensionView`, `make format`

---

## Этап 4: Journal (iOS)

### 4.0 Архитектурная правка

После релизов 4.5.0/4.6.0 Journal уже работает как:

- list/grid рендерят секции через `InfopostSection.journalSections`
- grid — это `ScrollView + LazyVGrid` (без вложенного `TabView(.page)`)

Проблема теперь не в удалении `TabView`, а в масштабировании: при `totalDays > 100` единый скролл на 200+ дней становится неюзабельным.
Для этого этапа нужно:

- сохранить текущую архитектуру экрана,
- добавить пагинацию/сегментацию по 100 дней,
- отвязать источник journal-секций от жёсткой модели `InfopostSection` (которая сейчас фиксирована на дни 1...100).

Архитектурное решение этого этапа:

- `InfopostSection` остаётся только для инфопостов и базовых блоков 1...100.
- Для журнала вводится отдельная модель, например `JournalSection` (`id`, `title`, `days`).
- Секции журнала формируются через отдельный builder/helper (например, `JournalSectionsBuilder.make(totalDays:sortOrder:)`), а не внутри View.

### Red: пишем тесты (ожидаем падений)

- [x] Добавлены/расширены тесты Journal (`JournalListViewTests`, `JournalGridViewTests`, `JournalSectionBuilderTests`)
- [x] Red-фаза зафиксирована

### Green: минимальная реализация

#### 4.1 List mode

- [x] В list-mode реализованы `1...totalDays`

#### 4.2 Grid mode (пагинация)

- [x] Реализована grid-пагинация по 100 дней (`controls` только при `totalDays > 100`)
- [x] Целевые тесты этапа проходят

### Refactor

- [x] Секции и пагинация вынесены в модели (`JournalSection`, `JournalSectionsBuilder`, `JournalGridPagination`)
- [x] Починены Journal preview, выполнен `make format`

---

## Этап 5: ProgressCalculator

`ProgressCalculator` уже реализован в релизах 4.5.0/4.6.0 и соответствует целевому поведению (100-дневные KPI). В этом этапе меняем только тесты.

### Red: пишем регрессионные тесты (ожидаем прохождения)

- [x] Обновлены `ProgressCalculatorTests`

### Green: подтверждение текущего поведения

- [x] Подтверждена 100-дневная модель KPI

### Refactor

- [x] Зафиксировано ограничение прогресса 100 днями, выполнен `make format`

---

## Этап 6: Уведомления (границы 100/200/...)

### Red: пишем регрессионные тесты (ожидаем прохождения)

- [x] Обновлены тесты уведомлений

### Green: подтверждение текущего поведения

- [x] Подтверждено: уведомления не зависят от продления

### Refactor

- [x] Проверено отсутствие зависимостей от `totalDays/currentDay`

---

## Этап 7: Watch (iOS + watchOS)

Целевые файлы watchOS в текущей кодовой базе существуют и валидируются в этом этапе:

- `SotkaWatch Watch App/Services/WatchConnectivityService.swift`
- `SotkaWatch Watch App/ViewModels/HomeViewModel.swift`
- `SotkaWatch Watch App/Views/DayActivityView.swift`

### Red: пишем регрессионные тесты (ожидаем прохождения)

- [x] Обновлены watch-тесты

### Green: подтверждение текущего поведения

- [x] Подтверждён watch-контракт: только `currentDay`

### Refactor

- [x] Подтверждён payload `WatchStatusMessage` без скрытых полей

---

## Этап 8: Reset / Logout

### Red: пишем регрессионные тесты (ожидаем прохождения)

- [x] Обновлены `StatusManagerResetLogoutTests`, `StatusManagerTests` проходит без регрессий

### Green: подтверждение текущего поведения

- [x] Подтверждена очистка продлений в `didLogout()/resetProgram()`

### Refactor

- [x] Проверены cleanup-путь и стабильность пересоздания состояния

---

## Этап 9: Debug / Preview / совместимость

### Red: пишем тесты (ожидаем падений)

- [x] Обновлены `StatusManagerSetCurrentDayForDebugTests` и `WorkoutProgramCreatorTests` (`101+`)
- [x] Red-фаза зафиксирована

### Green: минимальная реализация

#### 9.1 Debug API

- [x] Реализован `setCurrentDayForDebug(_ day: Int, extensionCount: Int? = nil)` и обновлён preview для дней `>100`
- [x] Debug-picker в `MoreScreen` переведён на `StatusManager.debugPickerMaxDay`

#### 9.2 WorkoutProgramCreator fallback для 101+

- [x] Зафиксирован и протестирован fallback для дней `>100`

### Refactor

- [x] Убрано дублирование `extensionCount`, обновлены preview `101+` (Home/Journal)
- [x] Проверена стабильность preview, выполнен `make format`

---

## Этап 10: Финальное тестирование

### Red: запускаем полный набор тестов

- [x] Все прогоны выполняются последовательно
- [x] Пройдены unit iOS/watchOS, UI-тесты и watch-regression
- [x] Добавлен `make test_ui`; исключена зависимость от runtime-взаимодействия с `SpringBoard`
- [x] Пройдены сценарии online/offline-only и тесты этапов 0-9

### Green: фиксим регрессии

- [x] Регрессии закрыты минимальными правками, unit/UI тесты проходят

### Refactor

- [x] Выполнены `make format`, финальный review и актуализация `docs/`
- [x] Проверен coverage новых модулей (`xccov`)

### Актуальный остаток после этапа 10

- [x] Добраны отложенные тесты этапов 3/4

---

## Этап 11: Стабилизация UI-автотестов и скриншотов (simulator permissions + fastlane)

Цель: убрать зависимость от ручного закрытия системных alert-ов и обеспечить одинаково стабильный запуск `make screenshots` и `make test_ui` на чистом/сброшенном симуляторе.
Текущее состояние: `make test_ui` уже стабилизирован (без прямого обращения к `SpringBoard`), но preflight-настройка разрешений симулятора и стабилизация `make screenshots` ещё не внедрены.

### Red: пишем проверки и фиксируем текущий риск

- [ ] Добавить/обновить smoke-проверку preflight для UI-run:
  - проверяет, что все обязательные privacy-permissions заранее выставлены в симуляторе;
  - при отсутствии прав завершает запуск с понятной ошибкой и подсказкой.
- [x] Зафиксировано: сценарии не опираются на runtime tap по `SpringBoard` alert-ам
- [ ] Добавить check-list в план выполнения скриншотов: запуск на чистом симуляторе без ручных действий.

### Green: минимальная реализация

#### 11.1 Преднастройка симулятора для `make test_ui`

- [ ] Вынести preflight-шаг в Makefile-пайплайн UI-тестов:
  - загрузка/проверка booted simulator;
  - выдача нужных privacy-разрешений через `xcrun simctl privacy ... grant ...` для app bundle id;
  - запуск тестов только после успешной pre-configuration.
- [x] Подтверждено: `make test_ui` не зависит от системного alert-а и `SpringBoard`

#### 11.2 Преднастройка симулятора для `make screenshots`

- [ ] Применить тот же preflight-подход перед snapshot-прогоном (единый механизм для UI test + screenshots).
- [ ] Зафиксировать, что snapshot-поток выполняется без ручных tap по системным alert-ам на новом симуляторе.

#### 11.3 Обновление fastlane

- [ ] Обновить fastlane по рекомендациям инструмента: `bundle update fastlane`.
- [ ] Проверить совместимость после обновления:
  - `bundle exec fastlane --version`;
  - smoke-run lane для скриншотов;
  - отсутствие новых регрессий в `make screenshots`.
- [ ] Зафиксировать версию в `Gemfile.lock` и обновить связанное описание в документации проекта (если меняется команда/параметры).

### Refactor

- [ ] Убрать дублирование preflight-логики между `make screenshots` и `make test_ui` (единая цель/скрипт).
- [ ] Добавить краткий troubleshooting-блок в документацию (что делать при reset simulator, revoked permissions, stale simulator state).
- [ ] Выполнить `make format` и повторный smoke-run:
  - `make test_ui`;
  - `make screenshots` (или эквивалентный dry/smoke шаг lane).

---

## Этап 12: List mode toolbar-пагинация (паритет с grid)

Цель: в `displayMode == .list` показывать тот же toolbar-контрол пагинации, что уже используется в grid, при тех же условиях (`totalDays > 100`), и листать список страницами по 100 дней.

Правила рендера list-страниц:

- страница `0`: текущее поведение списка `1...100` сохраняется (базовые секции);
- страница `1+`: дни `101+` рендерятся как плоский список из 100 последовательных записей без деления на секции;
- toolbar-контролы (`page picker`, `previous`, `next`) видимы только если `JournalGridPagination.shouldShowPaginationControls(totalDays:) == true`.

### Red: пишем тесты (ожидаем падений)

- [x] Добавлены/расширены тесты list-пагинации (`JournalScreen`, `JournalListView`)
- [x] Добавлен регрессионный кейс disabled-состояния дней `> currentDay` для list-страниц `1+`

### Green: минимальная реализация

- [x] `JournalScreen` и `JournalListView` обновлены для list-пагинации при `totalDays > 100`
- [x] Для страниц `101+` применена сортировка `forward/reverse`
- [x] Переиспользована общая математика пагинации, preview проверены

### Refactor

- [x] Вынесен общий toolbar-блок пагинации для grid/list
- [x] Логика list-контента вынесена в `JournalListPagination`
- [x] Удалено дублирование day-range, выполнен `make format`

---

## Этап 13: Персистент выбранной страницы Journal (UserDefaults)

Цель: запоминать последнюю открытую страницу календаря на экране Journal между перезапусками приложения, без риска некорректного восстановления после logout, входа под другим пользователем или `resetProgram()`.

Контракт:

- Персистим только номер страницы (`selectedPage`) в `UserDefaults`.
- Используем единый ключ хранения для всех режимов (offline/authorized).
- При восстановлении страница валидируется в диапазоне `0...(pageCount - 1)` для текущего `totalDays`; невалидное значение сбрасывается в `0`.
- При `didLogout()` и `resetProgram()` сохранённая страница Journal удаляется из `UserDefaults` (после этого экран открывается с `0`).

### Red: пишем тесты (ожидаем падений)

- [x] Добавить/расширить тесты Journal:
  - восстановление `selectedPage` после relaunch в пределах валидного диапазона;
  - clamp в `0`, если сохранённая страница выходит за новый `pageCount`;
  - после `didLogout()` сохранённая страница удаляется и при следующем входе экран стартует с `0`;
  - очистка/сброс после `didLogout()` и `resetProgram()`.
- [x] Добавить unit-тесты для helper/модели персистентного состояния страницы (ключи, валидация, clamp).

### Green: минимальная реализация

- [x] Добавить модель/хелпер для сохранения страницы Journal в `UserDefaults` (без бизнес-логики во View).
- [x] Подключить чтение/запись состояния на уровне `JournalScreen`:
  - чтение при инициализации/появлении экрана;
  - запись при изменении `selectedPage`.
- [x] Добавить reset persisted page в пути `didLogout()` и `resetProgram()`.

### Refactor

- [x] Переиспользовать существующую математику пагинации (`JournalGridPagination`) для валидации диапазона страницы.
- [x] Убрать дублирование ключей/валидации, выполнить `make format`.

---

## Зависимости этапов

```text
Этап 0 -> Этап 1 -> Этап 2 -> Этапы 3,4,5,6,7,8,9 -> Этап 10 -> Этап 12 -> Этап 13
Открытый хвост: Этап 11 (UI-автотесты/скриншоты) + отдельные незавершённые пункты Этапа 3
```

---

## Статус тестовой инфраструктуры (на момент обновления плана)

- Уже существуют и расширяются: `DayCalculatorTests`, `HomeScreenModelTests`, `StatusManagerGetStatusTests`, `StatusManagerSyncJournalTests`, `StatusManagerOfflineTests`, `StatusManagerOfflineIntegrationTests`, `StatusManagerSetCurrentDayForDebugTests`.
- Добавлены: `HomeDayCountViewTests` (проверяет `HomeDayCountModel`), `JournalSectionBuilderTests`, `JournalListViewTests`, `JournalGridViewTests`, `HomeScreenTests`, `HomeScreenAnalyticsTests`, `JournalScreenTests`, `JournalPagePersistenceTests`.

---

## Критерии завершения

1. На этапе защитной синхронизации (до активации продлений в UI) приложение не падает на серверных днях `>100`: в БД сохраняются все дни, а UI остаётся в безопасном диапазоне при `totalDays=100`.
2. Кнопка продления появляется только на 100/200/300... при неактивированном продлении.
3. Лимит продлений работает корректно, кнопка скрыта при достижении лимита.
4. После продления `totalDays += 100`; на граничном дне `currentDay` не прыгает, при отложенном нажатии пересчитывается по фактически прошедшим дням в пределах `totalDays`.
5. Для авторизованного пользователя покупки календаря синхронизируются с сервером (`GET /100/purchases`, `POST /100/purchases/calendars`) в offline-first модели: локально сначала, сеть асинхронно; retry unsynced выполняется в `getStatus()` и `syncJournalAndProgress()`.
6. Для `offline-only` пользователя синхронизация покупок не выполняется, работает только локальная логика.
7. Journal поддерживает `totalDays > 100` в list и grid с пагинацией/сегментацией по 100 дней, включая кейс «старые серверные продления синхронизированы, локально кнопку ещё не нажимали».
8. После активации продлений (локальных и/или синхронизированных с сервера) UI использует актуальный `totalDays` и не ограничивается 100 днями.
9. Секция активностей на Home работает и после 100-го дня.
10. Секция заполнения максимумов (`showProgressSection`) остаётся завязанной только на `isMaximumsFilled`.
11. Счётчик дней корректно отображает 3+ цифр.
12. KPI прогресса остаются 100-дневными; после 100-го дня прогресс не меняется до полного сброса.
13. Уведомления зависят только от флага включения и времени, продление на них не влияет.
14. Watch показывает только `День X`; `totalDays` не передаётся и не отображается.
15. Локальные продления очищаются при logout/reset.
16. Нажатие кнопки продления логируется в аналитику как `extendCalendar` с параметром `targetTotalDays` (по факту tap, независимо от результата продления); при скрытой/недоступной кнопке событие не появляется.
17. Merge продлений выполняется как `union` локальных и серверных дат с дедупликацией по UTC-ключу (точность до секунд), без потери unsynced записей.
18. Безопасное открытие legacy SwiftData-хранилища проверено тестами: существующая БД предыдущей версии открывается без падений, данные сохраняются, `CalendarExtensionRecord` доступна.
19. Все тесты проходят.
20. `make test_ui` и `make screenshots` стабильно выполняются на чистом симуляторе без ручного закрытия системных alert-ов.
21. Fastlane обновлён (`bundle update fastlane`), lanes для скриншотов остаются рабочими.
22. В `displayMode == .list` toolbar-пагинация визуально паритетна с grid при `totalDays > 100`; для страниц `101+` список рендерится плоскими блоками по 100 дней без секций.
23. Номер выбранной страницы Journal сохраняется между перезапусками приложения и безопасно валидируется по текущему `totalDays`.
24. После `didLogout()` и `resetProgram()` persisted-страница Journal не приводит к некорректному восстановлению (экран открывается с валидной страницы, по умолчанию `0`).

---

## Файлы для изменения

| Файл | Изменения |
|------|-----------|
| `SwiftUI-SotkaApp/Models/DayCalculator.swift` | `maxExtensionCount`, `normalizedExtensionCount`, `totalDays`, `shouldShowExtensionButton`, `nextExtensionTotalDays`, future-start branch, уточнённый `id` на базе `currentDay` + `daysLeft` |
| `SwiftUI-SotkaApp/Services/StatusManager.swift` | хранение/очистка продлений в SwiftData, merge локальных/серверных покупок, retry unsynced, `extendCalendar()`, `rebuildCurrentDayCalculator(now:)`, snapshot продлений, debug range |
| `SwiftUI-SotkaApp/Models/CalendarExtensionRecord.swift` | новая SwiftData-сущность продления с флагами `isSynced`/`shouldDelete`/`lastModified` и связью с `User` |
| `SwiftUI-SotkaApp/SwiftUI_SotkaAppApp.swift` | создание `ModelContainer` через явную текущую `Schema([...])` с `CalendarExtensionRecord` и безопасным открытием legacy-store |
| `SwiftUI-SotkaApp/Services/SWClient.swift` | добавить `GET /100/purchases` и `POST /100/purchases/calendars` |
| `SwiftUI-SotkaApp/Services/Protocols/PurchasesClient.swift` | новый клиентский протокол покупок календаря (`getPurchases`, `postCalendarPurchase`) |
| `SwiftUI-SotkaApp/Models/SWSharedModels/CalendarPurchasesResponse.swift` | DTO серверного ответа (`custom_editor`, `calendars`) и request DTO для `date` |
| `SwiftUI-SotkaApp/Screens/Home/HomeScreen.swift` | `showActivitySection` для дней > 100, `showProgressSection` без дневного лимита, интеграция `HomeCalendarExtensionView`, infopost |
| `SwiftUI-SotkaApp/Screens/Home/Views/HomeDayCountView.swift` | `finishedView` без захардкоженного 100, copy для повторных границ, 3-значный формат |
| `SwiftUI-SotkaApp/Models/HomeDayCountModel.swift` | отдельная модель для форматирования номера дня и правила первого завершения программы (100-й день) |
| `SwiftUI-SotkaAppTests/Screens/Home/HomeScreenTests.swift` | unit-кейсы видимости кнопки продления и базовых состояний Home (новый файл) |
| `SwiftUI-SotkaAppTests/Models/HomeScreenModelTests.swift` | кейсы `showActivitySection`/`showProgressSection` и видимости кнопки продления на Home |
| `SwiftUI-SotkaAppTests/Models/HomeDayCountViewTests.swift` | кейсы `HomeDayCountModel`: формат 3+ значного счётчика и правило первого завершения (100 vs 200/300+) |
| `SwiftUI-SotkaAppTests/Screens/Home/HomeScreenAnalyticsTests.swift` | unit-кейсы `extendCalendar(targetTotalDays:)` и расчёта целевого `totalDays` (новый файл) |
| `SwiftUI-SotkaApp/Models/AnalyticsEvent.swift` | добавить `extendCalendar(targetTotalDays:)` в `UserAction` |
| `SwiftUI-SotkaApp/Services/Analytics/FirebaseAnalyticsProvider.swift` | при необходимости обновить маппинг `target_total_days` для `extendCalendar` (если провайдер не делает это автоматически через общий маппинг) |
| `SwiftUI-SotkaAppTests/Services/AnalyticsServiceTests.swift` | добавить кейсы: логирование `extendCalendar`, отсутствие события при скрытой/недоступной кнопке |
| `SwiftUI-SotkaAppTests/StatusManagerTests/StatusManagerGetStatusTests.swift` | защитные кейсы синхронизации, когда сервер возвращает дни `>100` |
| `SwiftUI-SotkaAppTests/StatusManagerTests/StatusManagerSyncJournalTests.swift` | проверка сохранения всех серверных дней в БД и отсутствия падений |
| `SwiftUI-SotkaAppTests/StatusManagerTests/StatusManagerCalendarExtensionTests.swift` | unit/integration кейсы продлений, merge, retry и online/offline-only поведения (новый файл) |
| `SwiftUI-SotkaAppTests/Persistence/SwiftDataMigrationTests.swift` | регрессионные тесты открытия старой БД и успешной миграции на новую схему (новый файл) |
| `SwiftUI-SotkaAppTests/StatusManagerTests/StatusManagerOfflineTests.swift` | подтверждение: `offline-only` не вызывает sync покупок |
| `SwiftUI-SotkaAppTests/StatusManagerTests/StatusManagerOfflineIntegrationTests.swift` | интеграционные кейсы online/offline-only для покупок календаря |
| `SwiftUI-SotkaApp/Screens/Journal/JournalScreen.swift` | прокидывание `totalDays` в list/grid, `selectedPage` для grid-пагинации |
| `SwiftUI-SotkaApp/Models/Journal/JournalPagePersistence.swift` | модель/хелпер хранения `selectedPage` в `UserDefaults` (единый ключ, clamp/валидация, удаление при logout/reset) |
| `SwiftUI-SotkaApp/Screens/More/MoreScreen.swift` | debug-picker использует динамический диапазон дней через `StatusManager.debugPickerMaxDay` |
| `SwiftUI-SotkaApp/Screens/Journal/JournalListView.swift` | дни до `totalDays`, list-пагинация и плоский рендер страниц `101+` без секций |
| `SwiftUI-SotkaApp/Models/Journal/JournalListPagination.swift` | отдельная модель/билдер контента list-режима (`sections`/`flatDays`/`shouldRenderFlatPage`) |
| `SwiftUI-SotkaApp/Screens/Journal/JournalGridView.swift` | рендер выбранной страницы в scroll-based grid; без возврата вложенного `TabView` |
| `SwiftUI-SotkaApp/Models/Journal/JournalGridPagination.swift` | общий helper пагинации (`pageCount/pageRange/pageTitle/prev-next`) и единая проверка доступности дня (`isDayEnabled`) для list/grid |
| `SwiftUI-SotkaApp/Models/Journal/JournalSection.swift` | новая модель journal-секций (`id`, `title`, `days`) и builder/helper для `totalDays` |
| `SwiftUI-SotkaApp/Models/Infoposts/InfopostSection.swift` | оставить ответственность за инфопосты и базовые секции 1...100 |
| `SwiftUI-SotkaAppTests/Screens/Journal/JournalListViewTests.swift` | кейсы `JournalListPagination` (list-пагинация, плоский рендер `101+`, сортировка `forward/reverse`, отображение дней по синхронизированным продлениям) |
| `SwiftUI-SotkaAppTests/Screens/Journal/JournalGridViewTests.swift` | кейсы page count/day mapping при `totalDays > 100` (новый файл) |
| `SwiftUI-SotkaAppTests/Screens/Journal/JournalScreenTests.swift` | кейсы toolbar-пагинации для `displayMode == .list` (новый файл или расширение существующего) |
| `SwiftUI-SotkaAppTests/Screens/Journal/JournalPagePersistenceTests.swift` | кейсы восстановления/валидации persisted-page и cleanup при logout/reset (новый файл) |
| `SwiftUI-SotkaApp/Screens/Progress/ProgressCalculator.swift` | без изменений в логике (только проверка соответствия 100-дневным KPI) |
| `SwiftUI-SotkaAppTests/ProgressTests/ProgressCalculatorTests.swift` | добавить регрессионные кейсы для `currentDay > 100` |
| `SwiftUI-SotkaApp/PreviewContent/DayCalculator+.swift` | корректные preview для дней > 100 |
| `SwiftUI-SotkaApp/PreviewContent/StatusManager+.swift` | preview-сценарий с продлением календаря для экранов, зависящих от `currentDayCalculator.totalDays` |
| `SwiftUI-SotkaApp/Services/WorkoutProgramCreator.swift` | проверка/адаптация поведения для дней > 100 |
| `SwiftUI-SotkaAppTests/StatusManagerTests/StatusManagerSetCurrentDayForDebugTests.swift` | расширение диапазона и новые кейсы |
| `SwiftUI-SotkaAppTests/WorkoutProgramCreatorTests/` | регрессионные кейсы для дней 101/150/1000 (в существующих файлах набора тестов `WorkoutProgramCreator`) |
| `SwiftUI-SotkaApp/Services/AppSettings.swift` | только регрессионная валидация: уведомления независимы от продления |
| `SwiftUI-SotkaApp/Services/WatchStatusMessage.swift` | только регрессионная валидация: payload без `totalDays` |
| `SotkaWatch Watch App/Services/WatchConnectivityService.swift` | только регрессионная валидация: принимается `currentDay` без `totalDays` |
| `SotkaWatch Watch App/ViewModels/HomeViewModel.swift` | только регрессионная валидация: UI использует только `currentDay` |
| `SotkaWatch Watch App/Views/DayActivityView.swift` | подтверждение формата `День X` без изменений |
| `Makefile` | добавить/унифицировать preflight-шаги simulator permissions для `make test_ui` и `make screenshots` |
| `Gemfile.lock` | фиксация обновлённой версии fastlane после `bundle update fastlane` |
| `fastlane/Fastfile` и/или `fastlane/Snapfile` | при необходимости адаптация snapshot lane под новый preflight и совместимость после обновления fastlane |

---

## Что сознательно не делаем в этом плане

- Не возвращаем IAP-логику старого приложения.
- Не добавляем отдельный `CalendarExtensionService` (логика остаётся в `StatusManager`).
- Не добавляем UI «отменить продление» в V1 (только внутренний rollback-метод).
- Не добавляем отдельный UI для количества/истории синхронизированных покупок.
- Не добавляем серверное удаление исторических покупок при `resetProgram` (очищаем только локальное состояние; серверная история остаётся источником для будущего sync).
- Не меняем 100-дневную модель KPI прогресса.
- Не меняем контракт watch на `totalDays` (часы показывают только текущий день).
- Не связываем ежедневные уведомления с продлением календаря.
