# План реализации экрана таймера отдыха

## Общая информация

Экран таймера отдыха отображается между подходами/кругами в процессе тренировки. Пользователь видит обратный отсчет времени с визуальным индикатором прогресса и может завершить отдых досрочно.

## Структура файлов

```
Screens/
└── Workout/
    ├── RestTimerScreen.swift          # Основной экран таймера (вся логика внутри)
    └── Views/
        └── CircularTimerView.swift    # Компонент кругового прогресс-бара с таймером
```

## Компоненты экрана

### 1. RestTimerScreen

**Основной экран таймера отдыха со всей логикой внутри**

#### Параметры:
- `duration: Int` - длительность таймера в секундах

#### Состояние (@State):
- `remainingSeconds: Int` - оставшееся время в секундах (для обновления UI)

#### Структура экрана:
```swift
import SwiftUI
import Combine

struct RestTimerScreen: View {
    let duration: Int
    @State private var remainingSeconds: Int
    @Environment(\.dismiss) private var dismiss
    
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    init(duration: Int) {
        self.duration = duration
        _remainingSeconds = State(initialValue: duration)
    }
    
    var body: some View {
        VStack {
            // Верхняя часть - заголовок
            Text("TimerScreen.Title")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(.top)
            
            Spacer()
            
            // Центральная часть - круговой таймер
            CircularTimerView(
                remainingSeconds: remainingSeconds,
                totalSeconds: duration
            )
            
            Spacer()
            
            // Нижняя часть - кнопка завершения
            Button("TimerScreen.FinishButton") {
                finishTimer()
            }
            .buttonStyle(SWButtonStyle(mode: .tinted, size: .large))
            .padding(.horizontal)
            .padding(.bottom)
        }
        .background(Color.swBackground)
        .onReceive(timer) { _ in
            if remainingSeconds > 0 {
                remainingSeconds -= 1
            } else {
                finishTimer()
            }
        }
        .onDisappear {
            timer.upstream.connect().cancel()
        }
    }
}
```

#### Логика работы:

**Завершение таймера (`finishTimer()`):**
```swift
private func finishTimer() {
    timer.upstream.connect().cancel()
    dismiss()
}
```

**Примечание:** 
- Используется `Timer.publish` с `autoconnect()` для автоматического подключения таймера при первом подписчике
- Таймер автоматически отключается при отсутствии подписчиков (например, при закрытии View)
- В `onDisappear` и `finishTimer()` вызывается `timer.upstream.connect().cancel()` для явной отмены таймера
- Это более SwiftUI-идиоматичный подход, чем `Timer.scheduledTimer`

### 2. CircularTimerView

**Компонент кругового прогресс-бара с отображением времени**

#### Параметры:
- `remainingSeconds: Int` - оставшееся время в секундах
- `totalSeconds: Int` - общая длительность таймера в секундах

#### Структура компонента:
```
ZStack {
    // Фоновый круг (незаполненная часть)
    Circle()
        .stroke(Color.gray.opacity(0.3), lineWidth: 8)
    
    // Прогресс-бар (заполненная часть)
    Circle()
        .trim(from: 0, to: progress)
        .stroke(
            Color.swAccent,
            style: StrokeStyle(lineWidth: 8, lineCap: .round)
        )
        .rotationEffect(.degrees(-90)) // Начинаем сверху
        .animation(.linear(duration: 1.0), value: remainingSeconds)
    
    // Текст времени в центре
    VStack(spacing: 4) {
        Text(timeString)
            .font(.system(size: 48, weight: .bold))
            .monospacedDigit() // Для предотвращения "прыжков" цифр
    }
}
.frame(width: 200, height: 200)
```

#### Вычисляемые свойства:
- `progress: CGFloat` - прогресс от 0.0 до 1.0
  ```swift
  let progress = CGFloat(totalSeconds - remainingSeconds) / CGFloat(totalSeconds)
  ```
- `timeString: String` - форматированная строка времени (используется локализованная строка `.minSec`, как в `SyncJournalEntryDetailsScreen`)
  ```swift
  let minutes = remainingSeconds / 60
  let seconds = remainingSeconds % 60
  return String(localized: .minSec(minutes, seconds))
  ```
  
  **Примечание:** Для формата MM:SS (как на скриншотах) можно использовать `String(format: "%02d:%02d", minutes, seconds)`, но предпочтительнее использовать локализованную строку `.minSec` для консистентности с остальным приложением.

## Локализация

### Ключи локализации:
- `"TimerScreen.Title"` - "Отдых"
- `"TimerScreen.FinishButton"` - "Завершить отдых"

### Добавление в Localizable.xcstrings:
```json
{
  "TimerScreen.Title" : {
    "extractionState" : "manual",
    "localizations" : {
      "ru" : {
        "state" : "needs_review",
        "stringUnit" : {
          "state" : "translated",
          "value" : "Отдых"
        }
      }
    }
  },
  "TimerScreen.FinishButton" : {
    "extractionState" : "manual",
    "localizations" : {
      "ru" : {
        "state" : "needs_review",
        "stringUnit" : {
          "state" : "translated",
          "value" : "Завершить отдых"
        }
      }
    }
  }
}
```

## Стилизация

### Фон экрана:
- Использовать стандартный фон системы: `Color.swBackground`
- Адаптируется к светлой/темной теме автоматически

### Кнопка:
- Стиль: `SWButtonStyle(mode: .tinted, size: .large)`
- Аналогична кнопке "Сохранить как выполненную" в `WorkoutPreviewButtonsView`
- Цвет текста: `.swAccent`
- Фон: `.swTintedButton` (прозрачный с акцентным цветом)

### Круговой прогресс-бар:
- Цвет прогресса: `Color.swAccent`
- Цвет фона: `Color.gray.opacity(0.3)`
- Толщина линии: 8pt
- Размер: 200x200pt
- Скругление концов: `.round` (lineCap)

### Текст времени:
- Шрифт: `.system(size: 48, weight: .bold)`
- Модификатор: `.monospacedDigit()` для предотвращения "прыжков" при изменении цифр
- Цвет: стандартный цвет текста системы

## Логика работы таймера

### Принцип работы:
1. **При инициализации экрана (`init`)**:
   - Инициализировать `remainingSeconds = duration`
   - Таймер создается с `autoconnect()`, что означает автоматическое подключение при первом подписчике

2. **При появлении экрана (первый `onReceive`)**:
   - Таймер автоматически подключается и начинает публиковать события каждую секунду

3. **Каждую секунду (в `onReceive(timer)`)**:
   - Уменьшить `remainingSeconds` на 1
   - Если `remainingSeconds == 0`, автоматически вызвать `finishTimer()`

4. **При досрочном завершении (кнопка "Завершить отдых")**:
   - Вызвать `timer.upstream.connect().cancel()` для отмены таймера
   - Закрыть экран через `dismiss()`

5. **При автоматическом завершении (таймер дошел до 0)**:
   - Вызвать `timer.upstream.connect().cancel()` для отмены таймера
   - Закрыть экран через `dismiss()`

6. **При закрытии экрана (`onDisappear`)**:
   - Вызвать `timer.upstream.connect().cancel()` для явной отмены таймера
   - Таймер также автоматически отключится при отсутствии подписчиков

### Преимущества подхода с `Timer.publish`:
- Простота реализации без ViewModel
- Более SwiftUI-идиоматичный подход
- Автоматическая работа с жизненным циклом View через `onReceive`
- Работа в фоне: `Timer.publish` продолжает работать, при возврате в приложение UI обновится с актуальным значением

## Интеграция с экраном тренировки

### Использование:
```swift
// В экране выполнения тренировки
@State private var showRestTimer = false
@Environment(\.restTime) private var restTime

Button("Начать подход") {
    showRestTimer = true
}
.fullScreenCover(isPresented: $showRestTimer) {
    RestTimerScreen(duration: restTime)
} onDismiss: {
    // Обработка закрытия экрана таймера
    // Таймер завершен (досрочно или автоматически)
    // Здесь можно выполнить необходимые действия после завершения отдыха
}
```

## Анимации

### Круговой прогресс-бар:
- Плавная анимация обновления прогресса: `.linear(duration: 1.0)`
- Анимация привязана к изменению `remainingSeconds`

## Тестирование

### Сценарии для тестирования:
1. **Запуск таймера**: Проверить, что таймер запускается автоматически
2. **Обратный отсчет**: Проверить, что время уменьшается каждую секунду
3. **Досрочное завершение**: Нажать кнопку до окончания таймера, проверить закрытие экрана
4. **Автоматическое завершение**: Дождаться окончания таймера, проверить закрытие экрана
5. **Обработка закрытия**: Проверить, что замыкание `onDismiss` вызывается при закрытии экрана
6. **Форматирование времени**: Проверить корректное отображение MM:SS для разных значений
7. **Прогресс-бар**: Проверить, что прогресс-бар заполняется пропорционально времени
8. **Локализация**: Проверить отображение текстов на русском языке

## Звуковые уведомления, вибрация и уведомления

**Примечание:** Логика звуковых уведомлений, вибрации и локальных уведомлений при завершении таймера будет реализована в отдельной `WorkoutViewModel` (которая еще не создана). Эта ViewModel будет:

- Управлять процессом тренировки
- Вычислять время от начала тренировки до окончания
- Запускать вибрацию, звук и уведомления при завершении таймера отдыха
- Использовать флаги из `AppSettings` для включения/выключения звука и вибрации

Экран таймера (`RestTimerScreen`) отвечает только за отображение обратного отсчета и не содержит логику уведомлений.

## Примечания

- Экран должен быть модальным (`fullScreenCover` или `sheet`) для отображения поверх экрана тренировки
- Таймер должен работать корректно при переходе приложения в фоновый режим
- При закрытии экрана таймер должен останавливаться через `onDisappear`
- Значение `remainingSeconds` уменьшается каждую секунду и проверяется на 0 в `onReceive`
- `Timer.publish` автоматически добавляется в текущий RunLoop, что обеспечивает работу в фоне
- Обработка завершения таймера происходит через замыкание `onDismiss` в модификаторе `fullScreenCover`/`sheet` родительского экрана
- Необходимо импортировать `Combine` для использования `Timer.publish` и `autoconnect()`

