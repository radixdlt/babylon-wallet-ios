import KeychainClient
@testable import ProfileLoader
import TestUtils

final class ProfileLoaderTests: TestCase {
	func testTrivial() async {
		let sut = ProfileLoader.liveValue
		let json = """
		{
		    "version": "0.0.0"
		}
		""".data(using: .utf8)!

		KeychainClient.testValue.dataForKey = { @Sendable _, _ in
			json
		}

		let res = await sut.loadProfile()

		switch res {
		case let .profileVersionOutdated(gotJson, version):
			XCTAssertEqual(version, .init(rawValue: .init(0, 0, 0)))
			XCTAssertEqual(json, gotJson)
		default:
			XCTFail("wrong res")
		}
	}
}
