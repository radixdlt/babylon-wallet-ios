@testable import EngineToolkit
import EngineToolkitModels
import TestingPrelude

final class HashTests: TestCase {
	override func setUp() {
		debugPrint = false
		super.setUp()
	}

	func test_hash() throws {
		let hashed = try hash(hex: "01ba4719c80b6fe911b091a7c05124b64eeece964e09c058ef8f9805daca546b")
		let expected = "7f7611d6f09dbfe5c195057e1f4563b174ec360c837ac9ba5140d0424b2a7489"
		XCTAssertEqual(hashed, expected)
	}

	private func hash(hex hexString: String) throws -> String {
		let request = HashRequest(payload: hexString)
		let result = engineToolkit.hashRequest(request: request)
		return try result.get().value
	}

	private let engineToolkit = EngineToolkit()
}
