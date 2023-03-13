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
			let hex = "0279be667ef9dcbbac55a06295ce870b07029bfcdb2dce28d959f2815b16f81798"
			try roundtripTest(Engine.ECPrimitive(hex: hex), .string(hex))
		}

		private func roundtripTest(_ value: some Codable & Equatable, _ json: JSON, file: StaticString = #file, line: UInt = #line) throws {
			try XCTAssertJSONEncoding(value, json, file: file, line: line)
			try XCTAssertJSONDecoding(json, value, file: file, line: line)
		}
	}
}
