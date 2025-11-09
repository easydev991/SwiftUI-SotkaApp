import Foundation
@testable import SwiftUI_SotkaApp

final class MockCountryClient: CountryClient, @unchecked Sendable {
    var mockedCountries: [CountryResponse] = []
    var shouldThrowError = false
    var errorToThrow: Error = NSError(
        domain: "TestError",
        code: 1,
        userInfo: [NSLocalizedDescriptionKey: "Test error"]
    )
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
