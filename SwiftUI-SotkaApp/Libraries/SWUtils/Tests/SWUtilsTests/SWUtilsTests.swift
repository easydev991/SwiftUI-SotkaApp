import Foundation
@testable import SWUtils
import Testing

struct SWUtilsTests {
    @Test
    func queryAllowedURL() {
        let urlString: String? = "https://workout.su/uploads/userfiles/св3.jpg"
        let resultURL = urlString.queryAllowedURL
        #expect(resultURL == URL(string: "https://workout.su/uploads/userfiles/%D1%81%D0%B23.jpg"))
    }
}
