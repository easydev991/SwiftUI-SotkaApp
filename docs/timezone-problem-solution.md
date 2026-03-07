# Решение проблемы с часовыми поясами (БЕЗ изменений на сервере)

## Корневая причина

Сервер (PHP) конвертирует UTC → локальное время (+03:00) при сохранении в БД.

### Цепочка обработки на сервере

```
1. Клиент отправляет: 2026-03-07T14:30:40.000Z (UTC)
2. toDateTimeApi() парсит → DateTime в UTC (14:30:40 UTC)
3. dateTimeToDbStr() вызывает setTimeZone() с локальной таймзоной
4. КОНВЕРТАЦИЯ: 14:30:40 UTC → 17:30:40 +03:00 (Москва)
5. В БД сохраняется: "2026-03-07 17:30:40" (БЕЗ указания таймзоны!)
6. При возврате: "17:30:40" → DateTime(17:30:40, +03:00) → "2026-03-07T17:30:40+03:00"
7. Клиент парсит: 17:30:40+03:00 → 14:30:40 UTC (правильно!)
```

**Но есть проблема:** если клиент отправил локальное время (14:30:40 локальное = 11:30:40 UTC),
сервер сохранит 14:30:40 + 3 часа = 17:30:40, и вернёт 17:30:40+03:00 = 14:30:40 UTC.

Это **добавляет 3 часа** к оригинальному времени!

### Код сервера (Conv.php)

```php
// dateTimeToDbStr - конвертирует в локальную таймзону!
public static function dateTimeToDbStr(\DateTime $datetime = null, ...) {
    self::setTimeZone($datetime, $tz);  // <-- ПРОБЛЕМА: конвертирует время
    return $datetime->format('Y-m-d H:i:s');
}

private static function setTimeZone(\DateTime &$datetime, \DateTimeZone $tz = null) {
    if (!$tz) {
        $tz = new \DateTimeZone(date_default_timezone_get());  // +03:00
    }
    $datetime->setTimezone($tz);  // <-- конвертирует UTC → +03:00
}
```

## Как старое приложение решало проблему

### Ключевой инсайт: старое приложение НЕ использует modifyDate для сортировки

```objc
// Старое приложение сортирует по номеру дня (1..100)
// modifyDate используется ТОЛЬКО для разрешения конфликтов при синхронизации
```

### Отправка дат в старом приложении

```objc
// NSDate+Utilities.m - isoString
- (NSString *) isoString {
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];  // <-- UTC!
    [dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss.SSSXXXXX"];
    return [dateFormatter stringFromDate:self];  // Возвращает "2026-03-07T14:30:40.000Z"
}
```

## Решение для SwiftUI-SotkaApp

### Вариант 1: Сортировка по номеру дня (как в старом приложении) ✅ РЕКОМЕНДУЕТСЯ

Самый надёжный вариант - не использовать modifyDate для сортировки вообще.

```swift
// Вместо сортировки по modifyDate
let sortedDays = days.sorted { $0.modifyDate > $1.modifyDate }

// Использовать сортировку по номеру дня
let sortedDays = days.sorted { $0.day > $1.day }
```

**Плюсы:**

- Не зависит от бага сервера
- Работает как в старом приложении
- Проще логика

### Вариант 2: Миграция повреждённых данных + текущий фикс

Текущий фикс в `updateLocalFromServer` сохраняет локальный modifyDate.
Но старые данные уже "повреждены".

```swift
// Одноразовая миграция при запуске
func fixCorruptedModifyDates() {
    let versionKey = "modifyDateFixVersion"
    let currentVersion = 1.0

    if UserDefaults.standard.double(forKey: versionKey) >= currentVersion {
        return  // Уже исправлено
    }

    let context = persistentContainer.viewContext
    let fetchRequest: NSFetchRequest<DayActivity> = DayActivity.fetchRequest()

    for day in try! context.fetch(fetchRequest) {
        // Если modifyDate значительно позже createDate - сбросить
        if let modifyDate = day.modifyDate,
           let createDate = day.createDate,
           modifyDate.timeIntervalSince(createDate) > 3600 {  // > 1 часа
            day.modifyDate = createDate
            day.isSynced = false
        }
    }

    try! context.save()
    UserDefaults.standard.set(currentVersion, forKey: versionKey)
}
```

### Вариант 3: Игнорировать серверный modifyDate при синхронизации (УЖЕ РЕАЛИЗОВАНО)

```swift
func updateLocalFromServer(_ local: DayActivity, _ server: DayResponse) {
    // НЕ перезаписываем modifyDate серверным значением
    // local.modifyDate = server.modifyDate  <-- УБРАНО

    // Обновляем только данные тренировок
    local.activityType = server.activityType
    local.count = server.count
    // ...
}
```

## Итоговая рекомендация

1. **Сортировать по номеру дня** (как в старом приложении) - это устраняет зависимость от modifyDate
2. **Сохранять локальный modifyDate** при синхронизации (уже реализовано)
3. **Опционально:** добавить миграцию для исправления старых данных

## Код для миграции (добавить в AppDelegate или инициализацию)

```swift
// В DailyActivitiesService или отдельном MigrationService
static func runMigrationsIfNeeded() {
    fixCorruptedModifyDates()
}

private static func fixCorruptedModifyDates() {
    let key = "DidFixModifyDateTimezone_v1"
    guard !UserDefaults.standard.bool(forKey: key) else { return }

    let predicate = NSPredicate(format: "modifyDate > createDate + 3600")
    let context = PersistenceController.shared.container.viewContext

    let request: NSFetchRequest<DayActivity> = DayActivity.fetchRequest()
    request.predicate = predicate

    do {
        let corruptedDays = try context.fetch(request)
        for day in corruptedDays {
            day.modifyDate = day.createDate
            day.isSynced = false
        }
        if !corruptedDays.isEmpty {
            try context.save()
            print("Fixed \(corruptedDays.count) days with corrupted modifyDate")
        }
        UserDefaults.standard.set(true, forKey: key)
    } catch {
        print("Migration error: \(error)")
    }
}
```

## Сравнение с старым приложением

| Аспект | Старое приложение (ObjC) | Новое приложение (Swift) |
|--------|--------------------------|--------------------------|
| Сортировка | По номеру дня (1-100) | По modifyDate |
| Отправка дат | UTC (timeZone = GMT+0) | UTC (с суффиксом Z) |
| Использование modifyDate | Только для конфликтов | Для сортировки (проблема!) |
| Решение | Не зависит от бага | Нужен фикс |
