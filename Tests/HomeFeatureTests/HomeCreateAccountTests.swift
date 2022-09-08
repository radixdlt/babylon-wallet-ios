import ComposableArchitecture
@testable import HomeFeature
import TestUtils

final class CreateAccountFeatureTests: TestCase {
	func testTrivial() throws {
		XCTAssertEqual(Home.CreateAccount.State(), Home.CreateAccount.State())
	}
}
