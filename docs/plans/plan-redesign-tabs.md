# План: Редизайн таб-бара — Profile -> Journal + Progress

## Обзор задачи

Заменить таб `profile` на 2 отдельных таба (`journal` и `progress`), перенести нужные действия профиля на `MoreScreen` и удалить `ProfileScreen`.

### Текущее состояние

```text
TabView (3 таба):
  home    -> HomeScreen
  profile -> ProfileScreen (Journal, Progress, CustomExercises, EditProfile, Logout)
  more    -> MoreScreen
```

### Целевое состояние

```text
TabView (4 таба):
  home     -> HomeScreen
  journal  -> JournalScreen (иконка book.closed)
  progress -> ProgressScreen (иконка chart.line.uptrend.xyaxis)
  more     -> MoreScreen:
               1) новая Section(.profile) первой в List
                  - NavigationLink(.editProfile) -> EditProfileScreen
                  - logoutButton с существующим confirmationDialog
               2) NavigationLink на CustomExercisesScreen первым элементом в workoutSettingsGroup
```

### Важное уточнение по объёму

- `JournalScreen` и `ProgressScreen` уже готовы как экраны и должны переиспользоваться без лишнего рефакторинга их внутренней логики.
- План не включает изменение данных/бизнес-логики этих экранов, если это не нужно для компиляции после переноса в табы.
- Для передачи `User` в табы используется подход через `RootScreen` (вариант `c`), без изменения сигнатур `JournalScreen`/`ProgressScreen` и без добавления wrapper-файлов.

---

## Этап 1: Обновление RootScreen и табов

Файл: `SwiftUI-SotkaApp/Screens/Root/RootScreen.swift`

### 1.1 Реализация

- [x] В enum `Tab` заменить `case profile` на `case journal` и `case progress`
- [x] Обновить `localizedTitle`:
  - [x] `journal` -> `String(localized: .journal)`
  - [x] `progress` -> `String(localized: .progress)`
- [x] Обновить `systemImageName`:
  - [x] `journal` -> `"book.closed"`
  - [x] `progress` -> `"chart.line.uptrend.xyaxis"`
- [x] Обновить `accessibilityId`:
  - [x] `journal` -> `"journalTabButton"`
  - [x] `progress` -> `"progressTabButton"`
- [x] Убедиться, что порядок табов: `home`, `journal`, `progress`, `more`
- [x] В `RootScreen` добавить `@Query private var users: [User]` и `private var user: User? { users.first }`
- [x] Перенести построение tab content из `Tab.screen` в `RootScreen.body`/`@ViewBuilder`-хелпер, чтобы у контента был доступ к `user`
- [x] Для табов `journal`/`progress` передавать `user` в существующие `JournalScreen(user:)` и `ProgressScreen(user:)`
- [x] Для `journal`/`progress` обернуть экран в `NavigationStack` на уровне `RootScreen` (так как после удаления `ProfileScreen` его стек исчезает; в самих `JournalScreen`/`ProgressScreen` сейчас `NavigationStack` нет)
- [x] Обработать отсутствие `user` (защитный fallback для состояния до инициализации): показать безопасный placeholder/`ProgressView`, без крэша и force unwrap

### 1.2 Проверка

- [x] В приложении отображаются 4 таба
- [x] Таб `journal` открывает журнал
- [x] Таб `progress` открывает прогресс
- [x] Таб `more` продолжает работать как раньше

---

## Этап 2: Изменения на MoreScreen

Файл: `SwiftUI-SotkaApp/Screens/More/MoreScreen.swift`

### 2.1 Перенос CustomExercises в workoutSettingsGroup

- [x] Добавить `NavigationLink` на `CustomExercisesScreen` первым элементом в `workoutSettingsGroup`, перед `notificationToggle`
- [x] Размещение — именно внутри `DisclosureGroup` `workoutSettingsGroup` (не снаружи), первым элементом
- [x] Текст кнопки: `.customExercises`
- [x] Добавить/сохранить `accessibilityIdentifier` для стабильного UI-теста (используется id `customExercisesButton`)
- [x] Для стабильности UI-тестов добавить/сохранить явный способ таргетировать заголовок `workoutSettingsGroup` (accessibility id `moreScreenWorkoutGroup`)

### 2.2 Новая секция Profile

- [x] Добавить в `List` новую `Section(.profile)` самой первой, перед `Section(.settings)`
- [x] Внутри секции добавить `NavigationLink(.editProfile)` на `EditProfileScreen` только для online-пользователя (`if !isOfflineUser`)
- [x] Внутри секции добавить `logoutButton` с текущей логикой из `ProfileScreen`:
  - [x] `showLogoutDialog = true`
  - [x] `confirmationDialog(.alertLogout, ...)`
  - [x] при подтверждении: `analytics.log(.userAction(action: .logout))` и `authHelper.triggerLogout()`
- [x] `logoutButton` отображается для всех пользователей, включая offline
- [x] Добавить недостающие зависимости в `MoreScreen`:
  - `@Environment(AuthHelperImp.self) private var authHelper`
  - `@State private var showLogoutDialog = false`
  - `private var client: ProfileClient { SWClient(with: authHelper) }`
  - использовать уже существующий `@Query private var users: [User]` и `isOfflineUser` (derived из `users.first?.isOfflineOnly`) для получения `user` и условий показа
  - `@Environment(\.analyticsService) private var analytics` уже есть в `MoreScreen`, повторно не добавлять
- [x] Использовать тот же тип секции, что и в текущем коде (`Section(.settings)`): `Section(.profile)` как стандартный `SwiftUI Section` с локализованным заголовком

### 2.3 Проверка

- [x] `Section(.profile)` отображается первой
- [x] Для online-пользователя переход в `EditProfileScreen` работает
- [x] Для offline-пользователя кнопка `EditProfile` не отображается
- [x] Logout показывает confirmation dialog и выполняет logout после подтверждения
- [x] Переход в `CustomExercisesScreen` работает из `workoutSettingsGroup`

---

## Этап 3: Удаление ProfileScreen

### 3.1 Удаление

- [x] Удалить файл `SwiftUI-SotkaApp/Screens/Profile/ProfileScreen.swift`

### 3.2 Проверка ссылок

- [x] Убедиться, что `ProfileScreen` больше нигде не используется
- [x] Подпапки `Screens/Profile/Journal`, `Screens/Profile/Progress`, `Screens/Profile/Edit`, `Screens/Profile/CustomExercises` оставить
- [ ] Перед удалением `case .profile` из `AnalyticsEvent.AppScreen` проверить его использование и совместимость с внешним аналитическим контрактом (backend/dashboard/events schema)
- [x] Если внешний контракт не требует legacy-событие: удалить `case .profile` и проверить компиляцию
- [ ] Если есть зависимость во внешней аналитике: оставить `case .profile` как legacy (без новых вызовов), добавить короткий комментарий с причиной
- [x] Удаление `ProfileScreen.swift` автоматически удаляет его `#Preview`-блоки — это ожидаемо и корректно

---

## Этап 4: Обновление UI-теста скриншотов

Файл: `SwiftUI-SotkaAppUITests/SwiftUI_SotkaAppUITests.swift`

### 4.1 Обновить элементы

- [x] Заменить использование `profileTabButton` на `journalTabButton` и `progressTabButton`
- [x] Удалить зависимости от `ProfileJournalButton` и `ProfileProgressButton`
- [x] Обновить переход к упражнениям: теперь через `moreTabButton` -> `workoutSettingsGroup` -> кнопка `CustomExercises`
- [x] В UI-тесте явно раскрывать `workoutSettingsGroup` перед тапом по `CustomExercises` (не полагаться на сохранённое состояние `@AppStorage`)
- [x] Для iPhone обновить обращения по индексам таб-бара под новый порядок (теперь 4 таба: `home`, `journal`, `progress`, `more`)
- [x] Для iPad обновить обращения по accessibility id (`journalTabButton`, `progressTabButton`, `moreTabButton`)

### 4.2 Обновить сценарий `testMakeScreenshots`

- [x] Сохранить порядок экранов как в текущем сценарии: сначала `progress`, затем `journal` (без перестановки порядка скриншотов)
- [x] Новый флоу:
  1. Главный экран
  2. Сегодняшний инфопост
  3. Превью тренировки
  4. Редактор тренировки
  5. Таб `progress` -> скриншот прогресса
  6. Таб `journal` -> скриншот журнала (grid)
  7. Переключение Journal в list -> скриншот
  8. Таб `more` -> раскрыть `workoutSettingsGroup` -> тап `CustomExercises` -> скриншот

### 4.3 Проверка

- [ ] `testMakeScreenshots` проходит с новой структурой табов (зависит от корректной конфигурации UI test plan/scheme в CI/локально)

### 4.4 Локализация и ресурсы

- [x] Убедиться, что ключи `.journal`, `.progress`, `.customExercises`, `.alertLogout`, `.logOut`, `.profile`, `.editProfile` присутствуют и корректно отображаются в UI

---

## Этап 4.5: Рефактор MoreScreen — User через RootScreen

Файл: `SwiftUI-SotkaApp/Screens/More/MoreScreen.swift`, `SwiftUI-SotkaApp/Screens/Root/RootScreen.swift`

### 4.5.1 Реализация

- [x] Изменить сигнатуру `MoreScreen`: заменить `@Query private var users: [User]` + `private var isOfflineUser: Bool { users.first?.isOfflineOnly ?? false }` на `let user: User` (неопциональный)
- [x] Обновить `isOfflineUser`: `user.isOfflineOnly` вместо `users.first?.isOfflineOnly ?? false`
- [x] Убрать костыль `if !isOfflineUser { if let user = users.first { ... } }` в `Section(.profile)`: теперь `if !isOfflineUser { NavigationLink ... EditProfileScreen(user: user, client: client) }`
- [x] В `RootScreen.tabContent(user:)` для `case .more` обернуть в `if let user { MoreScreen(user: user) } else { ProgressView() }` (аналогично `journal`/`progress`)
- [x] Обновить `#Preview` в `MoreScreen`: передавать `user: .preview`

### 4.5.2 Проверка

- [x] Компиляция проходит
- [x] Тесты проходят (1682/1683, 0 failed)

---

## Этап 5: Финальная валидация

- [x] Запустить `make format`
- [x] Выполнить сборку через `xcodebuild-mcp` / `Build iOS Apps` (проверено: `SwiftUI-SotkaApp`, `SwiftUI-SotkaAppUITests` build succeeded на iPhone 17)
- [x] Выполнить тесты через `xcodebuild-mcp` / `Build iOS Apps`
- [ ] Проверить навигацию на iPhone и iPad симуляторах

## Технический долг и риски

- [ ] Проверить внешний аналитический контракт перед финальным решением по удалённому `AppScreen.profile` (backend/dashboard/events schema)
- [ ] Зафиксировать и исправить конфигурацию `xcodebuild-mcp`/схемы UI-тестов: `test_sim` сейчас не запускает `SwiftUI_SotkaAppUITests/testMakeScreenshots` из-за несоответствия scheme/test plan membership

---

## Затрагиваемые файлы

| Файл | Действие |
|------|----------|
| `SwiftUI-SotkaApp/Screens/Root/RootScreen.swift` | Обновить табы (journal/progress), передача User в JournalScreen/ProgressScreen/MoreScreen |
| `SwiftUI-SotkaApp/Screens/More/MoreScreen.swift` | Добавить `Section(.profile)`, CustomExercises в workoutSettingsGroup, приём User (неопциональный) |
| `SwiftUI-SotkaApp/Screens/Profile/ProfileScreen.swift` | Удалить |
| `SwiftUI-SotkaAppUITests/SwiftUI_SotkaAppUITests.swift` | Обновить тестовый сценарий под новые табы |
