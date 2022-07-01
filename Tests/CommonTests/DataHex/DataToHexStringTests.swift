//
//  File.swift
//  
//
//  Created by Alexander Cyon on 2022-07-01.
//

import TestUtils
import Common

final class DataToHexStringTests: TestCase {

	func testAssertHexFromDataIsLowerCasedByDefault() throws {
		let data = Data([0xde, 0xad, 0xbe, 0xef])
		XCTAssertEqual(data.hex(), "deadbeef")
	}
	func testAssertHexFromDataCanBeUppercased() throws {
		let data = Data([0xde, 0xad, 0xbe, 0xef])
		XCTAssertEqual(data.hex(options: [.upperCase]), "DEADBEEF")
	}
}
