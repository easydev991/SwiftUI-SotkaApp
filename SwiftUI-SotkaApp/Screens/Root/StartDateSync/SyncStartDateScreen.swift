import SWDesignSystem
import SwiftUI

struct SyncStartDateView: View {
    @Environment(StatusManager.self) private var statusManager
    @Environment(\.modelContext) private var modelContext
    @State private var selectedOption = Selection.none
    @State private var syncTask: Task<Void, Never>?
    let model: ConflictingStartDate

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 32) {
                    Text(.dateSyncDescription)
                    VStack(spacing: 12) {
                        HomeDayCountView(calculator: model.appDayCalculator)
                            .opacity(makeOpacity(model.appDayCalculator))
                        Button(.dateSyncSelectAppDate) {
                            selectedOption = .app(model.appDayCalculator)
                        }
                        .buttonStyle(
                            SWButtonStyle(
                                icon: selectedOption.isAppSelected ? .checkmark : nil,
                                mode: .filled,
                                size: .small
                            )
                        )
                    }
                    SWDivider()
                    VStack(spacing: 12) {
                        HomeDayCountView(calculator: model.siteDayCalculator)
                            .opacity(makeOpacity(model.siteDayCalculator))
                        Button(.dateSyncSelectSiteDate) {
                            selectedOption = .site(model.siteDayCalculator)
                        }
                        .buttonStyle(
                            SWButtonStyle(
                                icon: selectedOption.isSiteSelected ? .checkmark : nil,
                                mode: .filled,
                                size: .small
                            )
                        )
                    }
                }
                .padding()
            }
            .animation(.default, value: selectedOption)
            .scrollBounceBehavior(.basedOnSize)
            .background(Color.swBackground)
            .frame(maxHeight: .infinity, alignment: .top)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    NavigationLink(destination: SyncStartDateHelpScreen()) {
                        Image(systemName: "questionmark.circle")
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(.done, action: applySelection)
                        .disabled(selectedOption == .none)
                }
            }
            .navigationTitle(.dateSyncTitle)
            .navigationBarTitleDisplayMode(.inline)
        }
        .interactiveDismissDisabled()
        .loadingOverlay(if: statusManager.state.isLoading)
    }

    private func makeOpacity(_ model: DayCalculator) -> CGFloat {
        guard let selectedStartDate = selectedOption.startDate else {
            return 1
        }
        return model.startDate == selectedStartDate ? 1 : 0.5
    }

    private func applySelection() {
        switch selectedOption {
        case .none:
            assertionFailure("Дата должна быть выбрана до попытки сохранения")
        case let .app(model):
            syncTask = Task {
                await statusManager.start(
                    appDate: model.startDate,
                    context: modelContext
                )
            }
        case let .site(model):
            syncTask = Task {
                await statusManager.syncWithSiteDate(
                    siteDate: model.startDate,
                    context: modelContext
                )
            }
        }
    }
}

extension SyncStartDateView {
    enum Selection: Equatable {
        case none
        case app(DayCalculator)
        case site(DayCalculator)

        var startDate: Date? {
            switch self {
            case let .app(model), let .site(model): model.startDate
            case .none: nil
            }
        }

        var isAppSelected: Bool {
            if case .app = self { true } else { false }
        }

        var isSiteSelected: Bool {
            if case .site = self { true } else { false }
        }
    }
}

#if DEBUG
#Preview {
    let siteStartDate = Calendar.current.date(byAdding: .day, value: -25, to: .now)!
    let appStartDate = Calendar.current.date(byAdding: .day, value: -12, to: .now)!
    SyncStartDateView(model: .init(appStartDate, siteStartDate))
        .environment(AuthHelperImp())
        .environment(StatusManager.preview)
}
#endif
