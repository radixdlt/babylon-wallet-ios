@testable import Cryptography
import TestingPrelude

final class EncryptionTests: TestCase {
	func test_version1_is_default() {
		XCTAssertEqual(EncryptionScheme.default.version, .version1)
	}

	func test_json_encoding() throws {
		try XCTAssertJSONEncoding(EncryptionScheme.version1, [
			"version": 1,
			"description": "AESGCM-256",
		])
	}

	func test_json_decoding() throws {
		try XCTAssertJSONDecoding([
			"version": 1,
			"description": "AESGCM-256",
		], EncryptionScheme.version1)
	}

	func test_decryption_version1() throws {
		func doTest(cipherHex: String, decryptionKeyHex: String, expectedPlainTextHex: String) throws {
			let decryptionKey = try SymmetricKey(data: Data(hex: decryptionKeyHex))
			guard decryptionKey.data.count == 32 else {
				XCTFail("Expected 32 bytes key")
				return
			}
			let encrypted = try Data(hex: cipherHex)
			let decrypted = try EncryptionScheme.Version1.decrypt(data: encrypted, decryptionKey: decryptionKey)
			XCTAssertEqual(decrypted.hex, expectedPlainTextHex)
		}

		try doTest(
			cipherHex: "4c2266de48fd17a4bb52d5883751d054258755ce004154ea204a73a4c35e",
			decryptionKeyHex: "deadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeef",
			expectedPlainTextHex: "abba"
		)
	}

	func test_roundtrip_version1() throws {
		try doTestRoundtrip(of: .version1)
	}

	func doTestRoundtrip(of scheme: EncryptionScheme) throws {
		let key = SymmetricKey(size: .bits256)
		let plaintext = Data("Radix Rocks!".utf8)
		let encrypted = try scheme.encrypt(data: plaintext, encryptionKey: key)
		let decrypted = try scheme.decrypt(data: encrypted, decryptionKey: key)
		XCTAssertEqual(decrypted, plaintext)
	}
}
