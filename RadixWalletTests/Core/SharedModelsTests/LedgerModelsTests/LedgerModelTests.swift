@testable import SharedModels
import TestingPrelude

final class LedgerModelTests: TestCase {
	func test_decode_error_response() throws {
		let json: JSON = [
			"error": [
				"message": "6e38",
				"code": 1,
			],
			"interactionId": "59052FDF-4211-4ED1-871A-C5EFC642677F",
			"discriminator": "signTransaction",
		]

		let expected = P2P.ConnectorExtension.Response.LedgerHardwareWallet(
			interactionID: "59052FDF-4211-4ED1-871A-C5EFC642677F",
			discriminator: .signTransaction,
			response: .failure(.init(
				code: .blindSigningNotEnabledButRequired,
				message: "6e38"
			))
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

	func test_decode_deriveAndDisplayAddress() throws {
		let json: JSON = [
			"success": [
				"address": "account_tdx_e_128gdgkz846vyznldh6n6xcg3lpsx6r9g7j3rhrxuqa4q7kp52435zx",
				"derivedKey": [
					"curve": "curve25519",
					"publicKey": "59faefda7f27792630f54711a79b63de5fa55c45f7e701992d13f4a662954df8",
					"derivationPath": "m/44H/1022H/14H/525H/1460H/3H",
				],
			],
			"interactionId": "010F97C0-1542-4690-A044-0406C2E6F157",
			"discriminator": "deriveAndDisplayAddress",
		]

		let expected = P2P.ConnectorExtension.Response.LedgerHardwareWallet(
			interactionID: "010F97C0-1542-4690-A044-0406C2E6F157",
			discriminator: .deriveAndDisplayAddress,
			response: .success(
				.deriveAndDisplayAddress(
					.init(
						derivedKey: .init(
							curve: "curve25519",
							derivationPath: "m/44H/1022H/14H/525H/1460H/3H",
							publicKey: "59faefda7f27792630f54711a79b63de5fa55c45f7e701992d13f4a662954df8"
						),
						address: "account_tdx_e_128gdgkz846vyznldh6n6xcg3lpsx6r9g7j3rhrxuqa4q7kp52435zx"
					)
				)
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
