@testable import Prelude
import XCTest

final class BiteTests: XCTestCase {
	let deadbeef = Data([0xDE, 0xAD, 0xBE, 0xEF])

	func test_deadbeef_from_hex_string_lowercase_leading_0x() throws {
		XCTAssertEqual(
			try Data(hex: "0xdeadbeef"),
			deadbeef
		)
	}

	func test_deadbeef_from_hex_string_uppercase_leading_0x() throws {
		XCTAssertEqual(
			try Data(hex: "0xDEADBEEF"),
			deadbeef
		)
	}

	func test_deadbeef_from_hex_string_mixed_case_leading_0x() throws {
		XCTAssertEqual(
			try Data(hex: "0xDeaDbEEf"),
			deadbeef
		)
	}

	func test_deadbeef_from_hex_string_lowercase_leading() throws {
		XCTAssertEqual(
			try Data(hex: "deadbeef"),
			deadbeef
		)
	}

	func test_deadbeef_from_hex_string_uppercase_leading() throws {
		XCTAssertEqual(
			try Data(hex: "DEADBEEF"),
			deadbeef
		)
	}

	func test_deadbeef_from_hex_string_lowercase_leading_0x_trimmed() throws {
		XCTAssertEqual(
			try Data(hex: "0 x d ea db eef"),
			deadbeef
		)
	}

	func test_deadbeef_from_hex_string_uppercase_leading_0x_trimmed() throws {
		XCTAssertEqual(
			try Data(hex: "  0 xD EADBEE F "),
			deadbeef
		)
	}

	func test_deadbeef_from_hex_string_lowercase_leading_trimmed() throws {
		XCTAssertEqual(
			try Data(hex: " d e a d b eef "),
			deadbeef
		)
	}

	func test_deadbeef_from_hex_string_uppercase_leading_trimmed() throws {
		XCTAssertEqual(
			try Data(hex: " DE AD BEE F"),
			deadbeef
		)
	}

	func test_deadbeef_from_hex_string_mixedcase_leading_0x_trimmed() throws {
		XCTAssertEqual(
			try Data(hex: "  0 xD EaDBeE f "),
			deadbeef
		)
	}

	func test_hexcodable() throws {
		let data: Data = "deadbeef"
		let encoder = JSONEncoder()
		let hexCodable = HexCodable(data: data)
		let jsonFromData = try encoder.encode(data)
		let jsonFromHexCodable = try encoder.encode(hexCodable)
		XCTAssertNotEqual(jsonFromData, jsonFromHexCodable)
		let decoder = JSONDecoder()
		let decoded = try decoder.decode(HexCodable.self, from: jsonFromHexCodable)
		XCTAssertEqual(decoded, hexCodable)
		XCTAssertEqual(data, decoded.data)
	}
}
