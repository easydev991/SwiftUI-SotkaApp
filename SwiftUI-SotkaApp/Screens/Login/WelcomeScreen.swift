import SWDesignSystem
import SwiftData
import SwiftUI
import SWUtils

struct WelcomeScreen: View {
    @Environment(\.isReadOnlyMode) private var isReadOnlyMode
    @State private var destination = NavigationDestination.welcome

    var body: some View {
        NavigationStack {
            ZStack {
                switch destination {
                case .welcome:
                    welcomeView
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
        case offline
    }

    var welcomeView: some View {
        VStack(spacing: 32) {
            Image(.launcherLogo)
            offlineSection
        }
        .transition(.scale(2).combined(with: .opacity))
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
