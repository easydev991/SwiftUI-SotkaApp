import SwiftUI

struct HomeView: View {
    @State private var authState = AuthState.idle
    let isAuthorized: Bool
    private let dayNumber = 1 // TODO: заглушка, заменить реальными данными

    var body: some View {
        ZStack {
            if isAuthorized {
                DayActivityView(
                    onSelect: { activity in
                        print("Выбрали активность \(activity)")
                    },
                    dayNumber: dayNumber,
                    selectedActivity: nil // TODO: передать реальную выбранную активность для текущего дня
                )
            } else {
                AuthRequiredView(
                    checkAuthAction: {
                        print("TODO: проверить статус авторизации")
                        authState = .loading
                    },
                    state: authState
                )
            }
        }
        .animation(.default, value: isAuthorized)
    }
}

#Preview("Неавторизован") {
    HomeView(isAuthorized: false)
}

#Preview("Авторизован") {
    HomeView(isAuthorized: true)
}
