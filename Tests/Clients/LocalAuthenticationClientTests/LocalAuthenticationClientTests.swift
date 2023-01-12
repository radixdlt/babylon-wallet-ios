import ClientPrelude
@testable import LocalAuthenticationClient
import TestingPrelude

final class LocalAuthenticationClientTests: TestCase {
	let sut = LocalAuthenticationClient.liveValue

	func testTrivial() async throws {
		let config = try await sut.queryConfig()
		XCTAssertTrue(config.isPasscodeSetUp)
	}
}
