# UI-тесты и скриншоты

Документ описывает запуск UI-тестов и генерацию скриншотов в проекте `SwiftUI-SotkaApp`.

## Оглавление

- [Команды](#команды)
- [Что делает preflight симулятора](#что-делает-preflight-симулятора)
- [Чек-лист для скриншотов](#чек-лист-для-скриншотов)
- [Скриншоты (fastlane)](#скриншоты-fastlane)
- [Troubleshooting](#troubleshooting)
- [Обновление fastlane](#обновление-fastlane)

## Команды

- UI-тесты:

```shell
make test_ui
```

- Скриншоты iPhone/iPad:

```shell
make screenshots
```

- Скриншоты Apple Watch:

```shell
make watch_screenshots
```

## Что делает preflight симулятора

Команды `make test_ui` и `make screenshots` автоматически выполняют preflight через:

- [scripts/simulator_ui_preflight.sh](/Users/Oleg991/Documents/GitHub/SwiftUI-SotkaApp/scripts/simulator_ui_preflight.sh)

Preflight:

1. Находит нужный симулятор по `destination`/`device`.
2. Загружает (boot) симулятор и дожидается готовности.
3. Выдаёт обязательные privacy-разрешения для `com.oleg991.SwiftUI-SotkaApp` через `xcrun simctl privacy grant`.
4. Останавливает запуск с понятной ошибкой, если симулятор или permission недоступны.

Текущий набор permissions по умолчанию задаётся в `Makefile` переменной `UI_PREFLIGHT_PERMISSIONS`.

## Чек-лист для скриншотов

Перед запуском `make screenshots`:

1. Убедитесь, что нужные iOS-системы и устройства установлены в Xcode (`Settings -> Platforms`).
2. Не запускайте приложение вручную на целевых симуляторах в момент прогона.
3. Запускайте только `make screenshots` без дополнительных ручных действий в Simulator.
4. Если симулятор был очищен (`Erase All Content and Settings`), это допустимо: preflight сам выставит permissions.

## Скриншоты (fastlane)

- Основная команда: `make screenshots`.
- Внутри вызывается `fastlane screenshots`.
- Настройки устройств и языков для snapshot находятся в:
  - [fastlane/Snapfile](/Users/Oleg991/Documents/GitHub/SwiftUI-SotkaApp/fastlane/Snapfile)
  - [fastlane/Fastfile](/Users/Oleg991/Documents/GitHub/SwiftUI-SotkaApp/fastlane/Fastfile)
- Результаты сохраняются в:
  - [fastlane/screenshots](/Users/Oleg991/Documents/GitHub/SwiftUI-SotkaApp/fastlane/screenshots)

## Troubleshooting

1. Ошибка `не найден доступный симулятор ...`:
   - проверьте, что нужное устройство и runtime установлены в Xcode (`Settings -> Platforms`);
   - при необходимости переопределите `IOS_SIM_DEST` (для `test_ui`) или `SNAPSHOT_IOS_DEVICE_1/2` (для `screenshots`).
2. Ошибка `не удалось выдать permission ...`:
   - проверьте, что permission поддерживается `xcrun simctl privacy`;
   - обновите Xcode/runtime или пересоздайте симулятор.
3. После `Erase All Content and Settings`:
   - просто повторите `make test_ui` или `make screenshots` — preflight выставит разрешения заново.

## Обновление fastlane

Для обновления fastlane используйте:

```shell
bundle update fastlane
```

Проверка установленной версии:

```shell
bundle exec fastlane --version
```
