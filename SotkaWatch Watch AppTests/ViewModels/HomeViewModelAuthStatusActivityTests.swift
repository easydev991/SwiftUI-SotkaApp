@testable import SotkaWatch_Watch_App
import Testing

/// Регрессионные тесты нотификации currentActivity через PHONE_COMMAND_AUTH_STATUS (Этап 9)
@MainActor
struct HomeViewModelAuthStatusActivityTests {
    /// Repro Этапа 9: при удалении активности iPhone пушит AUTH_STATUS без ключа currentActivity.
    /// Сервис должен сбросить currentActivity в nil, иначе протухшее значение блокирует
    /// didSet-уведомление при следующем push с тем же значением — и HomeViewModel не узнаёт
    /// о сохранённой тренировке (home-экран показывает «активность не выбрана»).
    @Test("AUTH_STATUS без ключа currentActivity сбрасывает активность в HomeViewModel")
    func authStatusWithoutActivityKeyResetsCurrentActivity() {
        let service = WatchConnectivityService(authService: WatchAuthService())
        let viewModel = HomeViewModel(authService: WatchAuthService(), connectivityService: service)

        let authStatusCommand = Constants.WatchCommand.authStatus.rawValue

        // 1. Тренировка сохранена → iPhone пушит AUTH_STATUS с currentActivity=workout
        service.testHandleReceivedMessage([
            "command": authStatusCommand,
            "isAuthorized": true,
            "currentDay": 1,
            "currentActivity": DayActivityType.workout.rawValue
        ])
        #expect(service.currentActivity == .workout)
        #expect(viewModel.currentActivity == .workout)

        // 2. Активность удалена → AUTH_STATUS без ключа currentActivity (nil опускается при кодировании)
        service.testHandleReceivedMessage([
            "command": authStatusCommand,
            "isAuthorized": true,
            "currentDay": 1
        ])
        #expect(service.currentActivity == nil)
        #expect(viewModel.currentActivity == nil)

        // 3. Тренировка снова сохранена → push того же значения должен дойти до HomeViewModel
        service.testHandleReceivedMessage([
            "command": authStatusCommand,
            "isAuthorized": true,
            "currentDay": 1,
            "currentActivity": DayActivityType.workout.rawValue
        ])
        #expect(viewModel.currentActivity == .workout)
    }
}
