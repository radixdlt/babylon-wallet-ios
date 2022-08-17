import ComposableArchitecture
@testable import CreateAccount
import XCTest

final class CreateAccountFeatureTests: XCTestCase {
	func testTrivial() throws {
		XCTAssertEqual(CreateAccount.State(), CreateAccount.State())
	}
}
