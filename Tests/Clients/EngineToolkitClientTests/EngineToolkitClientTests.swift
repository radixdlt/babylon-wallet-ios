import ClientTestingPrelude
@testable import EngineToolkitClient
import K1

// MARK: - EngineToolkitClientTests
final class EngineToolkitClientTests: TestCase {
	func test__derive_olympia_address_from_public_key() throws {
		let sut = EngineToolkitClient.liveValue

		let bytes = try Data(hex: "03f43fba6541031ef2195f5ba96677354d28147e45b40cde4662bec9162c361f55").bytes
		let publicKey = try K1.PublicKey(compressedRepresentation: bytes)
		let result = try sut.deriveOlympiaAdressFromPublicKey(publicKey)

		let expected = "rdx1qsplg0a6v4qsx8hjr904h2txwu6562q50ezmgrx7ge3tajgk9smp74gh88as2"

		XCTAssertEqual(result, expected)
	}
}
