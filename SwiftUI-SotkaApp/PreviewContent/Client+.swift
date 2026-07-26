#if DEBUG
import Foundation
import SWUtils

struct MockLoginClient {
    let result: MockResult
    let instantResponse: Bool

    init(result: MockResult, instantResponse: Bool = false) {
        self.result = result
        self.instantResponse = instantResponse
    }
}

struct MockExerciseClient {
    let result: MockResult
    let instantResponse: Bool

    init(result: MockResult, instantResponse: Bool = false) {
        self.result = result
        self.instantResponse = instantResponse
    }
}

struct MockProgressClient {
    let result: MockResult
    let instantResponse: Bool

    init(result: MockResult, instantResponse: Bool = false) {
        self.result = result
        self.instantResponse = instantResponse
    }
}

struct MockInfopostsClient {
    let result: MockResult
    let instantResponse: Bool

    init(result: MockResult, instantResponse: Bool = false) {
        self.result = result
        self.instantResponse = instantResponse
    }
}

struct MockDaysClient {
    let result: MockResult
    let instantResponse: Bool

    init(result: MockResult, instantResponse: Bool = false) {
        self.result = result
        self.instantResponse = instantResponse
    }
}

struct MockProfileClient {
    let result: MockResult
    let instantResponse: Bool

    init(result: MockResult, instantResponse: Bool = false) {
        self.result = result
        self.instantResponse = instantResponse
    }
}

struct MockCountriesClient {
    let result: MockResult
    let instantResponse: Bool

    init(result: MockResult, instantResponse: Bool = false) {
        self.result = result
        self.instantResponse = instantResponse
    }
}
#endif
