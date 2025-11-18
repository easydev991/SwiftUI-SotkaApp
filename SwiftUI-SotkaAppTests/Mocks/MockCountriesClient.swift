import Foundation
@testable import SwiftUI_SotkaApp

final class MockCountriesClient: CountriesClient, @unchecked Sendable {
    var mockedCountries: [CountryResponse] = []
    var shouldThrowError = false
    var errorToThrow: Error = MockCountriesClient.MockError.demoError
    var getCountriesCallCount = 0
    var delay: TimeInterval = 0

    init(mockedCountries: [CountryResponse] = []) {
        self.mockedCountries = mockedCountries
    }

    func getCountries() async throws -> [CountryResponse] {
        getCountriesCallCount += 1
        if delay > 0 {
            try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
        }
        if shouldThrowError {
            throw errorToThrow
        }
        return mockedCountries
    }
}

extension MockCountriesClient {
    /// Ошибка для тестирования
    enum MockError: Error {
        case demoError
    }
}
