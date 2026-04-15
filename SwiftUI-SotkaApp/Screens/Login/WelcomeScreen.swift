import SWDesignSystem
import SwiftData
import SwiftUI
import SWKeychain
import SWUtils

struct WelcomeScreen: View {
    @Environment(\.modelContext) private var modelContext
    @State private var destination = NavigationDestination.welcome
    let client: LoginClient & StatusClient

    var body: some View {
        NavigationStack {
            ZStack {
                switch destination {
                case .welcome:
                    welcomeView
                case .online:
                    OnlineLoginView(
                        client: client,
                        closeAction: { destination = .welcome }
                    )
                case .offline:
                    OfflineLoginView(closeAction: { destination = .welcome })
                }
            }
            .animation(.spring, value: destination)
            .padding()
            .background(Color.swBackground)
        }
        .trackScreen(.login)
    }
}

private extension WelcomeScreen {
    enum NavigationDestination: Equatable {
        case welcome
        case online
        case offline
    }

    var welcomeView: some View {
        VStack(spacing: 32) {
            Image(.launcherLogo)
            onlineSection
            offlineSection
        }
        .transition(.scale(2).combined(with: .opacity))
    }

    var onlineSection: some View {
        VStack(spacing: 8) {
            Button(.loginScreenAuthorizeButtonTitle) {
                destination = .online
            }
            .buttonStyle(SWButtonStyle(mode: .filled, size: .large))
            Text(.loginScreenRegistrationInfoText)
                .font(.footnote.weight(.medium))
                .multilineTextAlignment(.center)
                .foregroundStyle(Color.swMainText)
        }
    }

    var offlineSection: some View {
        VStack(spacing: 8) {
            Button(.loginScreenSkipButton) {
                destination = .offline
            }
            .buttonStyle(SWButtonStyle(mode: .tinted, size: .large))
            Text(.loginScreenOfflineHint)
                .font(.footnote.weight(.medium))
                .multilineTextAlignment(.center)
                .foregroundStyle(Color.swMainText)
        }
    }
}

#if DEBUG
#Preview("Успех") {
    WelcomeScreen(client: MockLoginClient(result: .success))
        .environment(AuthHelperImp())
}

#Preview("Ошибка") {
    WelcomeScreen(client: MockLoginClient(result: .failure()))
        .environment(AuthHelperImp())
}
#endif
