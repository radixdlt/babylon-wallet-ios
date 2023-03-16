import Cryptography
@testable import EngineToolkit
import TestingPrelude

final class CurveEncodingTests: TestCase {
	override func setUp() {
		debugPrint = false
		super.setUp()
		continueAfterFailure = false
	}

	final class CurveEncodingTests: TestCase {
		func test_curve_encoding_and_decoding() throws {
			let hex0 = "0279be667ef9dcbbac55a06295ce870b07029bfcdb2dce28d959f2815b16f81798"
			try roundtripTest(Engine.EcdsaSecp256k1PublicKey(hex: hex0), .string(hex0))

			let hex1 = "4cb5abf6ad79fbf5abbccafcc269d85cd2651ed4b885b5869f241aedf0a5ba29"
			try roundtripTest(Engine.EddsaEd25519PublicKey(hex: hex1), .string(hex1))

			let hex2 = "0079224ea514206706298d8d620f660828f7987068d6d02757e6f3cbbf4a51ab133395db69db1bc9b2726dd99e34efc252d8258dcb003ebaba42be349f50f7765e"
			try roundtripTest(Engine.EcdsaSecp256k1Signature(hex: hex2), .string(hex2))

			let hex3 = "ce993adc51111309a041faa65cbcf1154d21ed0ecdc2d54070bc90b9deb744aa8605b3f686fa178fba21070b4a4678e54eee3486a881e0e328251cd37966de09"
			try roundtripTest(Engine.EddsaEd25519Signature(hex: hex3), .string(hex3))
		}

		private func roundtripTest(_ value: some Codable & Equatable, _ json: JSON, file: StaticString = #file, line: UInt = #line) throws {
			try XCTAssertJSONEncoding(value, json, file: file, line: line)
			try XCTAssertJSONDecoding(json, value, file: file, line: line)
		}
	}
}
