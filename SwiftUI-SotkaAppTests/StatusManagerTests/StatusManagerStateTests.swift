import Foundation
@testable import SwiftUI_SotkaApp
import Testing

extension StatusManagerTests {
    @Suite("Тесты для State")
    struct StateTests {
        @Test("isLoading возвращает true для состояний загрузки", arguments: [
            StatusManager.State.isLoadingInitialData,
            StatusManager.State.isSynchronizingData
        ])
        func isLoadingReturnsTrueForLoadingStates(state: StatusManager.State) {
            #expect(state.isLoading)
        }

        @Test("isLoading возвращает false для состояний без загрузки", arguments: [
            StatusManager.State.idle,
            StatusManager.State.error("Test error")
        ])
        func isLoadingReturnsFalseForNonLoadingStates(state: StatusManager.State) {
            #expect(!state.isLoading)
        }

        @Test("isLoadingInitialData возвращает true для .isLoadingInitialData")
        func isLoadingInitialDataReturnsTrueForLoadingInitialData() {
            let state = StatusManager.State.isLoadingInitialData
            #expect(state.isLoadingInitialData)
        }

        @Test("isLoadingInitialData возвращает false для других состояний", arguments: [
            StatusManager.State.idle,
            StatusManager.State.isSynchronizingData,
            StatusManager.State.error("Test")
        ])
        func isLoadingInitialDataReturnsFalseForOtherStates(state: StatusManager.State) {
            #expect(!state.isLoadingInitialData)
        }

        @Test("isSyncing возвращает true для .isSynchronizingData")
        func isSyncingReturnsTrueForSynchronizingData() {
            let state = StatusManager.State.isSynchronizingData
            #expect(state.isSyncing)
        }

        @Test("isSyncing возвращает false для других состояний", arguments: [
            StatusManager.State.idle,
            StatusManager.State.isLoadingInitialData,
            StatusManager.State.error("Test")
        ])
        func isSyncingReturnsFalseForOtherStates(state: StatusManager.State) {
            #expect(!state.isSyncing)
        }

        @Test("init(didLoadInitialData:) возвращает .isLoadingInitialData, если didLoadInitialData == false")
        func initReturnsLoadingInitialDataWhenFalse() {
            let state = StatusManager.State(didLoadInitialData: false)
            #expect(state.isLoadingInitialData)
        }

        @Test("init(didLoadInitialData:) возвращает .isSynchronizingData, если didLoadInitialData == true")
        func initReturnsSynchronizingDataWhenTrue() {
            let state = StatusManager.State(didLoadInitialData: true)
            #expect(state.isSyncing)
        }
    }
}
