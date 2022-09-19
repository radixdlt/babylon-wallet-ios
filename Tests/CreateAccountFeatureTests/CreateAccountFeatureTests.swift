import ComposableArchitecture
@testable import CreateAccountFeature
import TestUtils

final class CreateAccountFeatureTests: TestCase {
	func testTrivial() throws {
		XCTAssertEqual(CreateAccount.State(), CreateAccount.State())
	}
}
