@testable import Radix_Wallet_Dev
import XCTest

final class LocalAuthenticationClientTests: TestCase {
	let sut = LocalAuthenticationClient.liveValue

	func testTrivial() async throws {
		let config = try await sut.queryConfig()
		XCTAssertTrue(config.isPasscodeSetUp)
	}
}
