@testable import SharedModels
import TestingPrelude

final class LedgerModelTests: TestCase {
	func test_decode_derivePublicKeys() throws {
		let json: JSON = [
			"success": [
				[
					"curve": "curve25519",
					"derivationPath": "testPath",
					"publicKey": "03e6e5f34b265cca342ac711e68b5df9d839bc722e0b004f471539867d179d57c8",
				],
			],
			"interactionId": "32b94cc3-2418-4964-9877-b3cd1d66a007",
			"discriminator": "derivePublicKeys",
		]

		let expected = P2P.ConnectorExtension.Response.LedgerHardwareWallet(
			interactionID: "32b94cc3-2418-4964-9877-b3cd1d66a007",
			discriminator: .derivePublicKeys,
			response: .success(
				.derivePublicKeys([.init(curve: "curve25519", derivationPath: "testPath", publicKey: "03e6e5f34b265cca342ac711e68b5df9d839bc722e0b004f471539867d179d57c8")])
			)
		)

		// Decode assocated value
		try XCTAssertJSONDecoding(
			json,
			expected
		)

		// Decode enum
		try XCTAssertJSONDecoding(
			json,
			P2P.ConnectorExtension.Response.ledgerHardwareWallet(expected)
		)
	}

	func test_decode_getDeviceInfo() throws {
		let json: JSON = [
			"success": [
				"id": "41ac202687326a4fc6cb677e9fd92d08b91ce46c669950d58790d4d5e583adc0",
				"model": "nanoS",
			],
			"interactionId": "5B2803A9-0EBC-4056-A724-4A0F95C8827C",
			"discriminator": "getDeviceInfo",
		]

		let expected = try P2P.ConnectorExtension.Response.LedgerHardwareWallet(
			interactionID: "5B2803A9-0EBC-4056-A724-4A0F95C8827C",
			discriminator: .getDeviceInfo,
			response: .success(
				.getDeviceInfo(.init(
					id: .init(hex: "41ac202687326a4fc6cb677e9fd92d08b91ce46c669950d58790d4d5e583adc0"),
					model: .nanoS
				))
			)
		)

		// Decode assocated value
		try XCTAssertJSONDecoding(
			json,
			expected
		)

		// Decode enum
		try XCTAssertJSONDecoding(
			json,
			P2P.ConnectorExtension.Response.ledgerHardwareWallet(expected)
		)
	}
}
