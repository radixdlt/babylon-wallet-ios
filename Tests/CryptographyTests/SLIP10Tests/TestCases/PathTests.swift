@testable import Cryptography
import Foundation
import TestingPrelude

final class PathTests: XCTestCase {
	func testInvalidPaths() throws {
		let invalidPaths = [
			"44'/2147483648",
			"44'/2147483648'",
			"44'/-1",
			"44'//0",
			"/0'/1/2'",
			"44'/'",
			"44'/'0",
			"44'/0h",
			"44'/0''",
			"44'/0H'",
			"wrong",
		]

		for pathString in invalidPaths {
			XCTAssertThrowsError(try HD.Path.Full(string: pathString), "Expected path: <\(pathString)> to be invalid, but it was not.")
		}
	}
}
