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
			networkId: 0xF2,
			manifest: .init(instructions: .string("""
			CALL_METHOD
				Address("account_sim1qw84yeyhh755eq66z9kc72v8l0h4jpg40zw3wlz3qj6qx6lf6m")
				"lock_fee"
				Decimal("10");
			CALL_METHOD
				Address("account_sim1qw84yeyhh755eq66z9kc72v8l0h4jpg40zw3wlz3qj6qx6lf6m")
				"withdraw"
				Address("resource_sim1qpmu3e3xeqshv0072kt43wnsg7sy6c7unpfysujnzjjqzp3sl9")
			Decimal("2000");
				TAKE_FROM_WORKTOP
				Address("resource_sim1qpmu3e3xeqshv0072kt43wnsg7sy6c7unpfysujnzjjqzp3sl9")
				Bucket("bucket1");
			CALL_METHOD
				Address("component_sim1qt4srls7qvvunpdxughqp0ha9qw39ksqdecx3sk2prysthsj3g")
				"swap"
				Bucket("bucket1");
			CALL_METHOD
				Address("account_sim1qw84yeyhh755eq66z9kc72v8l0h4jpg40zw3wlz3qj6qx6lf6m")
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
