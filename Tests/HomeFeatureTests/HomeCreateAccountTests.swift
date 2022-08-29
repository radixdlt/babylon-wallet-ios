import ComposableArchitecture
@testable import HomeFeature
import TestUtils
import XCTest

final class CreateAccountFeatureTests: TestCase {
	func testTrivial() throws {
		XCTAssertEqual(Home.CreateAccount.State(), Home.CreateAccount.State())
	}
}
