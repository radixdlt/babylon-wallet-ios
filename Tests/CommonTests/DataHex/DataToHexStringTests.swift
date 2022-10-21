import Common
import TestUtils

final class DataToHexStringTests: TestCase {
	func testAssertHexFromDataIsLowerCasedByDefault() throws {
		let data = Data([0xDE, 0xAD, 0xBE, 0xEF])
		XCTAssertEqual(data.hexEncodedString(), "deadbeef")
	}

	func testAssertHexFromDataCanBeUppercased() throws {
		let data = Data([0xDE, 0xAD, 0xBE, 0xEF])
		XCTAssertEqual(data.hexEncodedString(options: [.upperCase]), "DEADBEEF")
	}
}
