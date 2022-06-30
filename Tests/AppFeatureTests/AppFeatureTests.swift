import XCTest
@testable import AppFeature
import ComposableArchitecture

final class AppFeatureTests: XCTestCase {
    func testTrivial() throws {
        XCTAssertEqual(App.State(), App.State())
    }

}
