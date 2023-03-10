@testable import EngineToolkit
import TestingPrelude

// MARK: - ConvertManifestTests

final class AnalyzeManifestWithPreviewContextTests: TestCase {
	override func setUp() {
		debugPrint = true
		super.setUp()
	}

	func test_analyzeManifestWithPreviewContext_succeeds() throws {
		// Arrange
		let request = try AnalyzeManifestWithPreviewContextRequest(
			networkId: 0xF2,
			manifest: .init(instructions: .string("""
			CALL_METHOD
			    Address("account_sim1qdxvh9gnntrm0dykk9jmsxsey00rhle9hw9mxfqfac2s9qycrs")
			    "lock_fee"
			    Decimal("10");
			CALL_METHOD
			    Address("account_sim1qdxvh9gnntrm0dykk9jmsxsey00rhle9hw9mxfqfac2s9qycrs")
			    "withdraw"
			    Address("resource_sim1qqn3f3vuy2682psu65px47ds8z7hagzkkn65g460pjnq6jvzuy")
			    Decimal("2000");
			TAKE_FROM_WORKTOP
			    Address("resource_sim1qqn3f3vuy2682psu65px47ds8z7hagzkkn65g460pjnq6jvzuy")
			    Bucket("bucket1");
			CALL_METHOD
			    Address("component_sim1qg5qj2m7ahsr98ag6jmd4rqwe5tvz76vxmtatqtsugeqn75yn8")
			    "swap"
			    Bucket("bucket1");
			CALL_METHOD
			    Address("account_sim1qdxvh9gnntrm0dykk9jmsxsey00rhle9hw9mxfqfac2s9qycrs")
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
