@testable import ProfileClientLive
import TestingPrelude

final class ProfileClientLiveTests: TestCase {
	func test_loading_profile() async {
		let sut = ProfileClient.liveValue
		let json = """
		{
		    "version": 0
		}
		""".data(using: .utf8)!

		await withDependencies {
			$0.keychainClient.dataForKey = { _, _ in json }
		} operation: {
			let res = await sut.loadProfile()

			switch res {
			case let .failure(.profileVersionOutdated(gotJson, version)):
				XCTAssertEqual(version, 0)
				XCTAssertEqual(json, gotJson)
			default:
				XCTFail("wrong res, got: \(String(describing: res))")
			}
		}
	}
}
