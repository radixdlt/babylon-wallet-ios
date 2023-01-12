import Prelude
import XCTest

final class HexStringToDataTests: XCTestCase {
	func testAssertDataFromHexStringWithOddLengthThrows() throws {
		XCTAssertThrowsError(try Data(hex: "deadbee"))
	}

	func testAssertDataFromHexStringOfEvenLengthWithNonHexCharsThrows() throws {
		XCTAssertThrowsError(try Data(hex: "nonhex"))
	}

	func testAssertDataFromValidHexStringHasCorrectValue() throws {
		let data = try Data(hex: "deadbeef")
		XCTAssertEqual(data, Data([0xDE, 0xAD, 0xBE, 0xEF]))
	}
}
