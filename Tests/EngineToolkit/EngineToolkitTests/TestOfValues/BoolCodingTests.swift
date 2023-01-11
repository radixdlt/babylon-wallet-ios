@testable import EngineToolkit
import Prelude

final class BoolCodingTests: TestCase {
	func test_json_encode() throws {
		let encoder = JSONEncoder()
		let json = try encoder.encode(Value_.boolean(true))
		let expected = """
		{
		  "type" : "Bool",
		  "value" : true
		}
		"""
		XCTAssertNoDifference(
			expected,
			json.prettyPrintedJSONString?.trimmingCharacters(in: .whitespaces)
		)
	}

	func test_json_decode() throws {
		let decoder = JSONDecoder()
		let json = """
		{
		  "type" : "Bool",
		  "value" : true
		}
		""".data(using: .utf8)!
		let value = try decoder.decode(Value_.self, from: json)
		XCTAssertNoDifference(value, Value_.boolean(true))
	}
}
