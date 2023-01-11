@testable import EngineToolkit
import Prelude

final class OptionalCodingTests: TestCase {
	func test_json_encode() throws {
		let encoder = JSONEncoder()
		let json = try encoder.encode(Value_.option(.some(.string("hey"))))
		let expected = """
		{
		  "type" : "Option",
		  "variant" : "Some",
		  "field" : {
		    "type" : "String",
		    "value" : "hey"
		  }
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
		  "type" : "Option",
		  "variant" : "Some",
		  "field" : {
		    "type" : "String",
		    "value" : "hey"
		  }
		}
		""".data(using: .utf8)!
		let value = try decoder.decode(Value_.self, from: json)
		XCTAssertNoDifference(value, Value_.option(.some(.string("hey"))))
	}
}
