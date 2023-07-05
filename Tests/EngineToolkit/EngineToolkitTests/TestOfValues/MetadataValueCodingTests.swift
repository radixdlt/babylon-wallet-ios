import Cryptography
@testable import EngineToolkit
import TestingPrelude

final class MetadataValueCodingTests: TestCase {
	override func setUp() {
		debugPrint = false
		super.setUp()
		continueAfterFailure = false
	}

	func test_value_encoding_and_decoding() throws {
		// load all manifests
		let decoder = JSONDecoder()
		let encoder = JSONEncoder()
		let testValues = try decoder.decode([MetadataValue].self, from: resource(named: "MetadataValue", extension: "json"))

		let decodedKinds = Set(testValues.map(\.kind))
		let definedKinds = Set(MetadataValueKind.allCases)
		XCTAssertEqual(decodedKinds, definedKinds)

		// roundtrip encode/decode
		let encoded = try encoder.encode(testValues)
		let str = String(data: encoded, encoding: .utf8)
		let decoded = try decoder.decode([MetadataValue].self, from: encoded)

		XCTAssertEqual(testValues, decoded)
	}
}
