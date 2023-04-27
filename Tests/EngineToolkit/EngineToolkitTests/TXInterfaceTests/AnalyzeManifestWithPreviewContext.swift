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
				Address("account_sim1q7qp88kspl8e4ay2jvqxln9r0kq3jy49akm3aue3jcaqnth6t3")
				"lock_fee"
				Decimal("10");
			CALL_METHOD
				Address("account_sim1q7qp88kspl8e4ay2jvqxln9r0kq3jy49akm3aue3jcaqnth6t3")
				"withdraw"
				Address("resource_sim1q88e5v6nynxjnn2hr6pjm4ttvgwfctuall7yhnty7mrq30ccxs")
				Decimal("2000");
			TAKE_FROM_WORKTOP
				Address("resource_sim1q88e5v6nynxjnn2hr6pjm4ttvgwfctuall7yhnty7mrq30ccxs")
				Bucket("bucket1");
			CALL_METHOD
				Address("component_sim1pyh6hkm4emes653c38qgllau47rufnsj0qumeez85zyskzs0y9")
				"swap"
				Bucket("bucket1");
			CALL_METHOD
				Address("account_sim1q7qp88kspl8e4ay2jvqxln9r0kq3jy49akm3aue3jcaqnth6t3")
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
