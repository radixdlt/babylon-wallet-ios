@testable import Cryptography
import CryptoKit
import Foundation
import TestingPrelude

final class EdgeCasesTests: XCTestCase {
	/// This test was found by: https://github.com/radixdlt/GenerateSLIP10Vectors
	/// in group with id `1`.
	func testIncorrectKeySize() throws {
		let pathString = "m/3H/4H/2147483647H"
		let seedHex = "47bd31d9dc7e582335c2548e8ab7477b80d37b714c2d162e34dff18c3df0e8ac6e5ceadb2174c54e0351457107bf45bdefc97e3280151d907c25d75bdae9c39c"
		let root = try HD.Root(seed: Data(hex: seedHex))
		let path = try HD.Path.Full(string: pathString)
		do {
			let childKey = try root.derivePrivateKey(path: path, curve: Curve25519.self)

			let expectedChainCodeHex = "e7d3c7078139462b8520318ffb6a00aa33ba4f193141d826db3840fc3ca83662"

			XCTAssertEqual(childKey.chainCode.chainCode.hex(), expectedChainCodeHex)
			let expectedPrivateKeyHex = "0046c267d5f13262155b6d33b7aff4ef1dfc64c3f5ea2f1d72c46db50dca382d"
			XCTAssertEqual(childKey.privateKey!.rawRepresentation.hex(), expectedPrivateKeyHex)
		} catch {
			XCTFail("Got error: \(error.localizedDescription)")
		}
	}
}
