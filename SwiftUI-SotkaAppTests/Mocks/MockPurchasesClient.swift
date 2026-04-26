import Foundation
@testable import SwiftUI_SotkaApp

final class MockPurchasesClient: PurchasesClient, @unchecked Sendable {
    enum Call: Equatable {
        case getPurchases
        case postCalendarPurchase
    }

    enum MockError: Error {
        case demoError
    }

    var getPurchasesResult: Result<CalendarPurchasesResponse, Error> = .success(
        CalendarPurchasesResponse(customEditor: false, calendars: [])
    )
    var postResultsQueue: [Result<CalendarPurchasesResponse, Error>] = []

    var getPurchasesCallCount = 0
    var postCalendarPurchaseCallCount = 0
    var postedDates: [Date] = []
    var callHistory: [Call] = []

    func getPurchases() async throws -> CalendarPurchasesResponse {
        getPurchasesCallCount += 1
        callHistory.append(.getPurchases)
        switch getPurchasesResult {
        case let .success(response):
            return response
        case let .failure(error):
            throw error
        }
    }

    func postCalendarPurchase(date: Date) async throws -> CalendarPurchasesResponse {
        postCalendarPurchaseCallCount += 1
        postedDates.append(date)
        callHistory.append(.postCalendarPurchase)

        if !postResultsQueue.isEmpty {
            let result = postResultsQueue.removeFirst()
            switch result {
            case let .success(response):
                return response
            case let .failure(error):
                throw error
            }
        }

        switch getPurchasesResult {
        case let .success(response):
            return response
        case let .failure(error):
            throw error
        }
    }
}
