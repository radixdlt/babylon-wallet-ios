import Common
import TestUtils

final class HexStringToDataTests: TestCase {
	func testAssertDataFromHexStringWithOddLengthThrows() throws {
		XCTAssertThrowsError(try Data(hexString: "deadbee"))
	}

	func testAssertDataFromEmptyHexStringThrows() throws {
		XCTAssertThrowsError(try Data(hexString: ""))
	}

	func testAssertDataFromHexStringOfEvenLengthWithNonHexCharsThrows() throws {
		XCTAssertThrowsError(try Data(hexString: "nonhex"))
	}

	func testAssertDataFromValidHexStringHasCorrectValue() throws {
		let data = try Data(hexString: "deadbeef")
		XCTAssertEqual(data, Data([0xDE, 0xAD, 0xBE, 0xEF]))
	}

	func testAssertThatHexStringCanBePrefixWithBaseIdentifier() throws {
		let data = try Data(hexString: "0xdeadbeef")
		XCTAssertEqual(data, Data([0xDE, 0xAD, 0xBE, 0xEF]))
	}
}
