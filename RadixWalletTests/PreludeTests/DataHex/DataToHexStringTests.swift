import Foundation
@testable import Radix_Wallet_Dev
import Sargon
import XCTest

final class DataToHexStringTests: TestCase {
	func testAssertHexFromDataIsLowerCasedByDefault() {
		let data = Data([0xDE, 0xAD, 0xBE, 0xEF])
		XCTAssertEqual(data.hex(), "deadbeef")
	}

	func testAssertHexFromDataCanBeUppercased() {
		let data = Data([0xDE, 0xAD, 0xBE, 0xEF])
		XCTAssertEqual(data.hex(options: [.upperCase]), "DEADBEEF")
	}
}
