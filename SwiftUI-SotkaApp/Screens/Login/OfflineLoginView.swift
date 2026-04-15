import SWDesignSystem
import SwiftData
import SwiftUI

struct OfflineLoginView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(AuthHelperImp.self) private var authHelper
    @Environment(\.analyticsService) private var analytics
    @State private var selectedGender: Gender?
    let closeAction: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            subtitleView
            VStack(spacing: 12) {
                ForEach(Gender.allCases, id: \.self) { gender in
                    makeButton(for: gender)
                }
                genderHintView
            }
            .animation(.default, value: selectedGender)
            Spacer()
            bottomView
        }
        .navigationTitle(.offlineMode)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                CloseButton(mode: .xmark, action: closeAction)
            }
        }
        .trackScreen(.offlineLogin)
    }
}

private extension OfflineLoginView {
    var subtitleView: some View {
        VStack(spacing: 8) {
            Group {
                Text("OfflineLogin.Subtitle")
                    .font(.headline)
                Text("OfflineLogin.Subtitle.Hint")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    func makeButton(for gender: Gender) -> some View {
        Button {
            selectedGender = gender
        } label: {
            HStack(spacing: 12) {
                Image(
                    systemName: selectedGender == gender ? "largecircle.fill.circle" : "circle"
                )
                .font(.title3)
                .foregroundStyle(
                    selectedGender == gender ? Color.swAccent : Color.swSmallElements
                )
                Text(gender.description)
                    .font(.body)
                    .foregroundStyle(Color.swMainText)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, 4)
    }

    @ViewBuilder
    var genderHintView: some View {
        if selectedGender == .unspecified {
            Text(.genderNotSpecifiedHint)
                .font(.footnote)
                .foregroundStyle(Color.swSmallElements)
                .frame(maxWidth: .infinity, alignment: .leading)
                .transition(.slide.combined(with: .opacity))
        }
    }

    var bottomView: some View {
        VStack(spacing: 20) {
            Text(.alertOfflineModeNoSync)
                .font(.callout)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
            Button(.beginProgram) {
                if let selectedGender {
                    performOfflineLogin(with: selectedGender)
                }
            }
            .buttonStyle(SWButtonStyle(mode: .filled, size: .large))
            .disabled(selectedGender == nil)
        }
    }

    func performOfflineLogin(with gender: Gender) {
        analytics.log(.userAction(action: .beginOfflineLogin))
        authHelper.performOfflineLogin()
        let fetchDescriptor = FetchDescriptor<User>(predicate: #Predicate { $0.id == -1 })
        if let existingUser = try? modelContext.fetch(fetchDescriptor).first {
            modelContext.delete(existingUser)
        }
        let user = User(offlineWithGenderCode: gender.code)
        modelContext.insert(user)
        try? modelContext.save()
    }
}

#if DEBUG
#Preview {
    NavigationStack {
        OfflineLoginView(
            closeAction: { print("нажали крестик") }
        )
        .padding()
        .environment(AuthHelperImp())
    }
}
#endif
