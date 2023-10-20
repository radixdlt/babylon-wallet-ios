@testable import Radix_Wallet_Dev
import XCTest

final class LocalAuthenticationClientTests: TestCase {
	let sut = LocalAuthenticationClient.liveValue

	func testTrivial() throws {
		let config = try sut.queryConfig()
		XCTAssertTrue(config.isPasscodeSetUp)
	}
}
