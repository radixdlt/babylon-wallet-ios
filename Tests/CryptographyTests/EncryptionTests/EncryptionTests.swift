@testable import Cryptography
import TestingPrelude

final class EncryptionTests: TestCase {
	func test_version1_is_default() {
		XCTAssertEqual(EncryptionScheme.default.version, .version1)
	}
}
