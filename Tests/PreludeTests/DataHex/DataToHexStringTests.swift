import Prelude
import TestingPrelude

final class DataToHexStringTests: XCTestCase {
	func testAssertHexFromDataIsLowerCasedByDefault() throws {
		let data = Data([0xDE, 0xAD, 0xBE, 0xEF])
		XCTAssertEqual(data.hex(), "deadbeef")
	}

	func testAssertHexFromDataCanBeUppercased() throws {
		let data = Data([0xDE, 0xAD, 0xBE, 0xEF])
		XCTAssertEqual(data.hex(options: [.upperCase]), "DEADBEEF")
	}
}
