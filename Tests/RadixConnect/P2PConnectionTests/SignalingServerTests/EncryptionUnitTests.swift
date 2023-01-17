@testable import P2PConnection
import TestingPrelude

final class EncryptionUnitTests: TestCase {
	func testRoundtrip() throws {
		let cryption = try SignalingServerEncryption(
			key: .init(data: .deadbeef32Bytes)
		)
		let encrypted = try cryption.encrypt(
			.init(
				method: .answer,
				source: .mobileWallet,
				connectionId: .placeholder,
				requestId: "",
				unencryptedPayload: Data("hey".utf8)
			)
		)
		let decrypted = try cryption.decrypt(data: encrypted.encryptedPayload.data)
		XCTAssertEqual(String(data: decrypted, encoding: .utf8)!, "hey")
	}
}
