@testable import EngineToolkit
import TestingPrelude

final class DeriveOlympiaAddressFromPublicKeyTests: TestCase {
	func test__derive_olympia_address_from_public_key() throws {
		let request = try DeriveOlympiaAddressFromPublicKeyRequest(
			network: .mainnet,
			publicKey: .init(hex: "026f08db98ef1d0231eb15580da9123db8e25aa1747c8c32e5fd2ec47b8db73d5c")
		)

		let response = try sut.deriveOlympiaAddressFromPublicKeyRequest(request: request).get()

		let expected = DeriveOlympiaAddressFromPublicKeyResponse(
			olympiaAccountAddress: "rdx1qspx7zxmnrh36q33av24srdfzg7m3cj65968erpjuh7ja3rm3kmn6hq4j9842"
		)

		XCTAssertEqual(response, expected)
	}
}
