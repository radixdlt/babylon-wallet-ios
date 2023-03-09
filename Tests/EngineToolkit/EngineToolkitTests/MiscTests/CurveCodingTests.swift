import Cryptography
@testable import EngineToolkit
import TestingPrelude

final class CurveEncodingTests: TestCase {
	override func setUp() {
		debugPrint = false
		encoder.outputFormatting = [.withoutEscapingSlashes]
		super.setUp()
		continueAfterFailure = false
	}

	func test_curve_encoding_and_decoding() throws {
		try performTest(value: EcdsaSecp256k1PublicKey(hex: "0279be667ef9dcbbac55a06295ce870b07029bfcdb2dce28d959f2815b16f81798")) {
			#"{"type":"EcdsaSecp256k1PublicKey","public_key":"0279be667ef9dcbbac55a06295ce870b07029bfcdb2dce28d959f2815b16f81798"}"#
		}
		try performTest(value: EddsaEd25519PublicKey(hex: "4cb5abf6ad79fbf5abbccafcc269d85cd2651ed4b885b5869f241aedf0a5ba29")) {
			#"{"type":"EddsaEd25519PublicKey","public_key":"4cb5abf6ad79fbf5abbccafcc269d85cd2651ed4b885b5869f241aedf0a5ba29"}"#
		}
		try performTest(value: EcdsaSecp256k1Signature(hex: "0079224ea514206706298d8d620f660828f7987068d6d02757e6f3cbbf4a51ab133395db69db1bc9b2726dd99e34efc252d8258dcb003ebaba42be349f50f7765e")) {
			#"{"type":"EcdsaSecp256k1Signature","signature":"0079224ea514206706298d8d620f660828f7987068d6d02757e6f3cbbf4a51ab133395db69db1bc9b2726dd99e34efc252d8258dcb003ebaba42be349f50f7765e"}"#
		}
		try performTest(value: EddsaEd25519Signature(hex: "ce993adc51111309a041faa65cbcf1154d21ed0ecdc2d54070bc90b9deb744aa8605b3f686fa178fba21070b4a4678e54eee3486a881e0e328251cd37966de09")) {
			#"{"type":"EddsaEd25519Signature","signature":"ce993adc51111309a041faa65cbcf1154d21ed0ecdc2d54070bc90b9deb744aa8605b3f686fa178fba21070b4a4678e54eee3486a881e0e328251cd37966de09"}"#
		}
	}

	private let encoder = JSONEncoder()
	private let decoder = JSONDecoder()

	private func performTest<T: Codable & Equatable>(value: T, json: () -> String) throws {
		let jsonRepresentation = json()

		// Act
		let string = try XCTUnwrap(String(data: encoder.encode(value), encoding: .utf8))

		// Assert
		XCTAssertNoDifference(string, jsonRepresentation)

		// Act
		let decodedValue = try decoder.decode(T.self, from: jsonRepresentation.data(using: .utf8)!)

		// Assert
		XCTAssertEqual(value, decodedValue)
	}
}
