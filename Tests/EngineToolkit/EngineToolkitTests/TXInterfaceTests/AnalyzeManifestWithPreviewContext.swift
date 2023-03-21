@testable import EngineToolkit
import TestingPrelude

// MARK: - ConvertManifestTests

final class AnalyzeManifestWithPreviewContextTests: TestCase {
	override func setUp() {
		debugPrint = false
		super.setUp()
	}

	func test_analyzeManifestWithPreviewContext_succeeds() throws {
		// Arrange
		let request = try AnalyzeManifestWithPreviewContextRequest(
			networkId: .simulator,
			manifest: .init(instructions: .string("""
			CALL_METHOD
				Address("account_sim1qnm629yc2jzkff5aql6xaldyxzvh3dt4zxrxzrfuakvsv7w7ue")
				"lock_fee"
				Decimal("10");
			CALL_METHOD
				Address("account_sim1qnm629yc2jzkff5aql6xaldyxzvh3dt4zxrxzrfuakvsv7w7ue")
				"withdraw"
				Address("resource_sim1q9qprrnqrjqd9m8ukah02v8hanhyh2gg5sjxtqadccgqqtvdrj")
				Decimal("2000");
			TAKE_FROM_WORKTOP
				Address("resource_sim1q9qprrnqrjqd9m8ukah02v8hanhyh2gg5sjxtqadccgqqtvdrj")
				Bucket("bucket1");
			CALL_METHOD
				Address("component_sim1qvrw4q2rn9npn5y08e6ltx4g0vqhu8dxuptl42apdeyq4t8dg2")
				"swap"
				Bucket("bucket1");
			CALL_METHOD
				Address("account_sim1qnm629yc2jzkff5aql6xaldyxzvh3dt4zxrxzrfuakvsv7w7ue")
				"deposit_batch"
				Expression("ENTIRE_WORKTOP");
			""")),
			transactionReceipt: [UInt8](resource(named: "file", extension: "blob"))
		)

		// Act
		let response = EngineToolkit().analyzeManifestWithPreviewContext(request: request)

		// Assert
		XCTAssertNoThrow(try response.get())
	}
}
