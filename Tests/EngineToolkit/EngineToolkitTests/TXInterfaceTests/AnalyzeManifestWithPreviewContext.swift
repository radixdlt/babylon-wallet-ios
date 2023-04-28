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
				Address("account_sim1quft09whj3nzlsd80n28fasr92pup8z4hkflrkqtagelu3g4ywxhjl")
				"lock_fee"
				Decimal("10");
			CALL_METHOD
				Address("account_sim1quft09whj3nzlsd80n28fasr92pup8z4hkflrkqtagelu3g4ywxhjl")
				"withdraw"
				Address("resource_sim1q2k2fa4x7rjy9e57wff58dr3uydvypdgf2m3kvec2uv5uxwhjta2dm")
				Decimal("2000");
			TAKE_FROM_WORKTOP
				Address("resource_sim1q2k2fa4x7rjy9e57wff58dr3uydvypdgf2m3kvec2uv5uxwhjta2dm")
				Bucket("bucket1");
			CALL_METHOD
				Address("component_sim1pyakxvzls3cwkfp25xz7dufp9jnw6wzxe3cxaku2ju7tlyuvusk6y9")
				"swap"
				Bucket("bucket1");
			CALL_METHOD
				Address("account_sim1quft09whj3nzlsd80n28fasr92pup8z4hkflrkqtagelu3g4ywxhjl")
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
