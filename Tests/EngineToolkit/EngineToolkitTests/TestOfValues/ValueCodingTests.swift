import Cryptography
@testable import EngineToolkit
import TestingPrelude

final class ValueEncodingTests: TestCase {
	override func setUp() {
		debugPrint = false
		super.setUp()
		continueAfterFailure = false
	}

	func test_value_encoding_and_decoding() throws {
		// load all manifests
		let decoder = JSONDecoder()
		let encoder = JSONEncoder()
		let testValues = try decoder.decode(
			[ManifestASTValue].self,
			from: resource(named: "ManifestAstValue", extension: "json")
		)

		// roundtrip encode/decode
		let encoded = try encoder.encode(testValues)
		let decoded = try decoder.decode([ManifestASTValue].self, from: encoded)

		XCTAssertEqual(testValues, decoded)
	}
}
