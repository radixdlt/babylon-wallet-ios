@testable import SingleVersion
import XCTest

final class SingleVersionTests: XCTestCase {
	func test_decoding() throws {
		let json0 = """
		{
			"version": 0,
			"id": "88888888-4444-4444-4444-CCCCCCCCCCCC",
			"settings": {
				"isDeveloper": true
			}
		}
		""".data(using: .utf8)!
		let jsonDecoder = JSONDecoder()
		let profile = try jsonDecoder.decode(Profile0.self, from: json0)
		XCTAssertEqual(profile.version, 0)
	}
}
