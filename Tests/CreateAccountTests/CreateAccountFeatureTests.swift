@testable import AppFeature
import ComposableArchitecture
import XCTest

final class AppFeatureTests: XCTestCase {
	func testTrivial() throws {
		XCTAssertEqual(App.State(), App.State())
	}
}
