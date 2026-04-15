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

- [x] Заменить `case profile` на `case journal` и `case progress` в enum `Tab` (localizedTitle, systemImageName, accessibilityId, порядок: `home`, `journal`, `progress`, `more`)
- [x] Добавить `@Query private var users: [User]` и передавать `user` в `JournalScreen`/`ProgressScreen`
- [x] Перенести построение tab content в `RootScreen.body`/`@ViewBuilder`-хелпер с доступом к `user`
- [x] Обернуть `journal`/`progress` в `NavigationStack` на уровне `RootScreen`
- [x] Обработать отсутствие `user`: `ProgressView` fallback

**Проверка:** 4 таба работают корректно

---

## Этап 2: Изменения на MoreScreen

Файл: `SwiftUI-SotkaApp/Screens/More/MoreScreen.swift`

- [x] Добавить `NavigationLink` на `CustomExercisesScreen` первым элементом в `workoutSettingsGroup` (accessibility id `customExercisesButton`, текст `.customExercises`)
- [x] Добавить `Section(.profile)` первой в List с `NavigationLink(.editProfile)` (только для online) и `logoutButton` с confirmationDialog
- [x] Добавить зависимости: `AuthHelperImp`, `showLogoutDialog`, `ProfileClient`

**Проверка:** `Section(.profile)` первая, EditProfile для online, Logout работает, CustomExercises доступен

---

## Этап 3: Удаление ProfileScreen

- [x] Удалить файл `SwiftUI-SotkaApp/Screens/Profile/ProfileScreen.swift`
- [x] Проверить ссылки, оставить подпапки Journal/Progress/Edit/CustomExercises
- [x] Удалить `case .profile` из `AnalyticsEvent.AppScreen`, проверить компиляцию
- [ ] Проверить внешний аналитический контракт (backend/dashboard/events schema) — если зависимость есть, оставить `case .profile` как legacy

---

## Этап 4: Обновление UI-теста скриншотов

Файл: `SwiftUI-SotkaAppUITests/SwiftUI_SotkaAppUITests.swift`

- [x] Заменить `profileTabButton` на `journalTabButton`/`progressTabButton`, удалить `ProfileJournalButton`/`ProfileProgressButton`
- [x] Переход к CustomExercises: `moreTabButton` -> `workoutSettingsGroup` (раскрыть) -> `CustomExercises`
- [x] Обновить индексы табов для iPhone (4 таба), accessibility id для iPad
- [x] Сохранить порядок: progress -> journal -> more -> CustomExercises
- [x] Проверить локализационные ключи

**Проверка:** `testMakeScreenshots` проходит (зависит от конфигурации scheme/test plan)

---

## Этап 4.5: Рефактор MoreScreen — User через RootScreen

- [x] Изменить сигнатуру `MoreScreen`: `let user: User` вместо `@Query ... users`, обновить `isOfflineUser`
- [x] Убрать костыль `if !isOfflineUser { if let user ... }` -> `if !isOfflineUser { NavigationLink ... EditProfileScreen(user: user, client: client) }`
- [x] В `RootScreen.tabContent` обернуть `MoreScreen` в `if let user { ... } else { ProgressView() }`
- [x] Обновить `#Preview`

**Проверка:** компиляция и тесты проходят (1682/1683, 0 failed)

---

## Этап 5: Финальная валидация

- [x] `make format`
- [x] Сборка (`SwiftUI-SotkaApp`, `SwiftUI-SotkaAppUITests` успешна на iPhone 17)
- [x] Тесты проходят
- [ ] Проверить навигацию на iPhone и iPad симуляторах

## Технический долг и риски

- [ ] Проверить внешний аналитический контракт для `AppScreen.profile`
- [ ] Исправить конфигурацию `xcodebuild-mcp`/схемы UI-тестов: `test_sim` не запускает `testMakeScreenshots`

---

## Затрагиваемые файлы

| Файл | Действие |
|------|----------|
| `SwiftUI-SotkaApp/Screens/Root/RootScreen.swift` | Обновить табы (journal/progress), передача User в JournalScreen/ProgressScreen/MoreScreen |
| `SwiftUI-SotkaApp/Screens/More/MoreScreen.swift` | Добавить `Section(.profile)`, CustomExercises в workoutSettingsGroup, приём User (неопциональный) |
| `SwiftUI-SotkaApp/Screens/Profile/ProfileScreen.swift` | Удалить |
| `SwiftUI-SotkaAppUITests/SwiftUI_SotkaAppUITests.swift` | Обновить тестовый сценарий под новые табы |
