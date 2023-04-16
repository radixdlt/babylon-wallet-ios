@testable import SharedModels
import TestingPrelude

final class LedgerModelTests: TestCase {
	func test_decode_derivePublicKey() throws {
		let json: JSON = [
			"success": [
				"publicKey": "03e6e5f34b265cca342ac711e68b5df9d839bc722e0b004f471539867d179d57c8",
			],
			"interactionId": "32b94cc3-2418-4964-9877-b3cd1d66a007",
			"discriminator": "derivePublicKey",
		]
		try XCTAssertJSONDecoding(
			json,
			P2P.ConnectorExtension.Response.ledgerHardwareWallet(.init(
				interactionID: "32b94cc3-2418-4964-9877-b3cd1d66a007",
				discriminator: .derivePublicKey,
				response: .success(
					.derivePublicKey(.init(
						publicKey: "03e6e5f34b265cca342ac711e68b5df9d839bc722e0b004f471539867d179d57c8")
					)
				)
			))
		)
	}
}
