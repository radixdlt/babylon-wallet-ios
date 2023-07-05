import Cryptography
@testable import EngineToolkit
import TestingPrelude

final class InstructionEncodingTests: TestCase {
	override func setUp() {
		debugPrint = false
		super.setUp()
		continueAfterFailure = false
	}

	func test_value_encoding_and_decoding() throws {
		let decoder = JSONDecoder()
		let encoder = JSONEncoder()

		let raw = try resource(named: "Instructions", extension: "json")
		let instructions = try decoder.decode([Instruction].self, from: raw)

		// round trip encode/decoded
		let encoded = try encoder.encode(instructions)
		let decoded = try decoder.decode([Instruction].self, from: encoded)

		XCTAssertEqual(instructions, decoded)
	}
}
