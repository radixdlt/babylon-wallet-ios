@testable import Cryptography
import TestingPrelude

final class PasswordBasedKeyDerivationTests: TestCase {
	func test_version1_is_default() {
		XCTAssertEqual(PasswordBasedKeyDerivationScheme.default.version, .version1)
	}

	func test_json_encoding() throws {
		try XCTAssertJSONEncoding(PasswordBasedKeyDerivationScheme.version1, [
			"version": 1,
			"description": "HKDFSHA256-with-UTF8-encoding-of-password-no-salt-no-info",
		])
	}

	func test_json_decoding() throws {
		try XCTAssertJSONDecoding([
			"version": 1,
			"description": "HKDFSHA256-with-UTF8-encoding-of-password-no-salt-no-info",
		], PasswordBasedKeyDerivationScheme.version1)
	}

	func test_version1() throws {
		func doTest(password: String, expected: String) {
			let key = PasswordBasedKeyDerivationScheme.version1.kdf(password: password)
			XCTAssertEqual(key.hex, expected)
		}

		doTest(password: "Radix Rules!", expected: "042f5ea1b7b384432fc6f8b8fdf413d59efbb30489c0e01aa0267e9c04aceee7")

		// RFC 5869 test case 3: https://datatracker.ietf.org/doc/html/rfc5869#appendix-A.3
		try doTest(password: String(data: Data(hex: "0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b"), encoding: .utf8)!, expected: String("8da4e775a563c18f715f802a063c5a31b8a11f5c5ee1879ec3454e5f3c738d2d9d201395faa4b61a96c8".prefix(64)))

		// We probably wont allow empty password in UI, but here is a unit test for it anyway...
		doTest(password: "", expected: "eb70f01dede9afafa449eee1b1286504e1f62388b3f7dd4f956697b0e828fe18")
	}
}
