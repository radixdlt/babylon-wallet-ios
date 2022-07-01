//
//  File.swift
//
//
//  Created by Alexander Cyon on 2022-06-30.
//

import TestUtils
import Common

final class HexStringToDataTests: TestCase {
	func testAssertDataFromHexStringWithOddLengthThrows() throws {
		XCTAssertThrowsError(try Data(hex: "deadbee")) { anError in
			guard let error = anError as? ByteHexEncodingErrors else {
				return XCTFail("Incorrect error type")
			}
			XCTAssertEqual(error, ByteHexEncodingErrors.incorrectString)
		}
	}
	
	func testAssertDataFromEmptyHexStringThrows() throws {
		XCTAssertThrowsError(try Data(hex: "")) { anError in
			guard let error = anError as? ByteHexEncodingErrors else {
				return XCTFail("Incorrect error type")
			}
			XCTAssertEqual(error, ByteHexEncodingErrors.incorrectString)
		}
	}
	
	func testAssertDataFromHexStringOfEvenLengthWithNonHexCharsThrows() throws {
		XCTAssertThrowsError(try Data(hex: "nonhex")) { anError in
			guard let error = anError as? ByteHexEncodingErrors else {
				return XCTFail("Incorrect error type")
			}
			XCTAssertEqual(error, ByteHexEncodingErrors.incorrectHexValue)
		}
	}
	
	func testAssertDataFromValidHexStringHasCorrectValue() throws {
		let data = try Data(hex: "deadbeef")
		XCTAssertEqual(data, Data([0xde, 0xad, 0xbe, 0xef]))
	}
	
	func testAssertThatHexStringCanBePrefixWithBaseIdentifier() throws {
		let data = try Data(hex: "0xdeadbeef")
		XCTAssertEqual(data, Data([0xde, 0xad, 0xbe, 0xef]))
	}
}
