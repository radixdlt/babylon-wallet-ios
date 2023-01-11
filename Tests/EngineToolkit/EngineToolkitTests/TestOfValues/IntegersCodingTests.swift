@testable import EngineToolkit
import Prelude

final class IntegersCodingTests: TestCase {
	let encoder = JSONEncoder()
	let decoder = JSONDecoder()

	func test_int8_json_encode() throws {
		let json = try encoder.encode(Value_.i8(42))
		let expected = """
		{
		  "type" : "I8",
		  "value" : "42"
		}
		"""
		XCTAssertNoDifference(
			expected,
			json.prettyPrintedJSONString?.trimmingCharacters(in: .whitespaces)
		)
	}

	func test_int8_json_decode() throws {
		let json = """
		{
		  "type" : "I8",
		  "value" : "42"
		}
		""".data(using: .utf8)!
		let value = try decoder.decode(Value_.self, from: json)
		XCTAssertNoDifference(value, Value_.i8(42))
	}

	func test_int16_json_encode() throws {
		let json = try encoder.encode(Value_.i16(32767))
		let expected = """
		{
		  "type" : "I16",
		  "value" : "32767"
		}
		"""
		XCTAssertNoDifference(
			expected,
			json.prettyPrintedJSONString?.trimmingCharacters(in: .whitespaces)
		)
	}

	func test_int16_json_decode() throws {
		let json = """
		{
		  "type" : "I16",
		  "value" : "32767"
		}
		""".data(using: .utf8)!
		let value = try decoder.decode(Value_.self, from: json)
		XCTAssertNoDifference(value, Value_.i16(32767))
	}

	func test_int32_json_encode() throws {
		let json = try encoder.encode(Value_.i32(2_147_483_647))
		let expected = """
		{
		  "type" : "I32",
		  "value" : "2147483647"
		}
		"""
		XCTAssertNoDifference(
			expected,
			json.prettyPrintedJSONString?.trimmingCharacters(in: .whitespaces)
		)
	}

	func test_int32_json_decode() throws {
		let json = """
		{
		  "type" : "I32",
		  "value" : "2147483647"
		}
		""".data(using: .utf8)!
		let value = try decoder.decode(Value_.self, from: json)
		XCTAssertNoDifference(value, Value_.i32(2_147_483_647))
	}

	func test_int64_json_encode() throws {
		let json = try encoder.encode(Value_.i64(9_223_372_036_854_775_807))
		let expected = """
		{
		  "type" : "I64",
		  "value" : "9223372036854775807"
		}
		"""
		XCTAssertNoDifference(
			expected,
			json.prettyPrintedJSONString?.trimmingCharacters(in: .whitespaces)
		)
	}

	func test_int64_json_decode() throws {
		let json = """
		{
		  "type" : "I64",
		  "value" : "9223372036854775807"
		}
		""".data(using: .utf8)!
		let value = try decoder.decode(Value_.self, from: json)
		XCTAssertNoDifference(value, Value_.i64(9_223_372_036_854_775_807))
	}

	func test_uint8_json_encode() throws {
		let json = try encoder.encode(Value_.u8(255))
		let expected = """
		{
		  "type" : "U8",
		  "value" : "255"
		}
		"""
		XCTAssertNoDifference(
			expected,
			json.prettyPrintedJSONString?.trimmingCharacters(in: .whitespaces)
		)
	}

	func test_uint8_json_decode() throws {
		let json = """
		{
		  "type" : "U8",
		  "value" : "255"
		}
		""".data(using: .utf8)!
		let value = try decoder.decode(Value_.self, from: json)
		XCTAssertNoDifference(value, Value_.u8(255))
	}

	func test_uint16_json_encode() throws {
		let json = try encoder.encode(Value_.u16(65535))
		let expected = """
		{
		  "type" : "U16",
		  "value" : "65535"
		}
		"""
		XCTAssertNoDifference(
			expected,
			json.prettyPrintedJSONString?.trimmingCharacters(in: .whitespaces)
		)
	}

	func test_uint16_json_decode() throws {
		let json = """
		{
		  "type" : "U16",
		  "value" : "65535"
		}
		""".data(using: .utf8)!
		let value = try decoder.decode(Value_.self, from: json)
		XCTAssertNoDifference(value, Value_.u16(65535))
	}

	func test_uint32_json_encode() throws {
		let json = try encoder.encode(Value_.u32(4_294_967_295))
		let expected = """
		{
		  "type" : "U32",
		  "value" : "4294967295"
		}
		"""
		XCTAssertNoDifference(
			expected,
			json.prettyPrintedJSONString?.trimmingCharacters(in: .whitespaces)
		)
	}

	func test_uint32_json_decode() throws {
		let json = """
		{
		  "type" : "U32",
		  "value" : "4294967295"
		}
		""".data(using: .utf8)!
		let value = try decoder.decode(Value_.self, from: json)
		XCTAssertNoDifference(value, Value_.u32(4_294_967_295))
	}

	func test_uint64_json_encode() throws {
		let json = try encoder.encode(Value_.u64(18_446_744_073_709_551_615))
		let expected = """
		{
		  "type" : "U64",
		  "value" : "18446744073709551615"
		}
		"""
		XCTAssertNoDifference(
			expected,
			json.prettyPrintedJSONString?.trimmingCharacters(in: .whitespaces)
		)
	}

	func test_uint64_json_decode() throws {
		let json = """
		{
		  "type" : "U64",
		  "value" : "18446744073709551615"
		}
		""".data(using: .utf8)!
		let value = try decoder.decode(Value_.self, from: json)
		XCTAssertNoDifference(value, Value_.u64(18_446_744_073_709_551_615))
	}
}
