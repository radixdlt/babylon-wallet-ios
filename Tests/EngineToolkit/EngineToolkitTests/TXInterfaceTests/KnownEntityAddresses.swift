@testable import EngineToolkit
import TestingPrelude

// MARK: - KnownEntityAddresses

final class KnownEntityAddresses: TestCase {
	override func setUp() {
		debugPrint = false
		super.setUp()
		continueAfterFailure = false
	}

	func test__knownEntityAddressRequestDoesntFail() throws {
		XCTAssertNoThrow(try sut.knownEntityAddresses(request: KnownEntityAddressesRequest(networkId: 0x02)).get())
	}
}
