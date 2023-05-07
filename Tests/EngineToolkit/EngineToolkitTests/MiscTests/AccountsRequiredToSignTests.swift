@testable import EngineToolkit
import Prelude

final class AccountsRequiredToSignTests: TestCase {
	override func setUp() {
		debugPrint = false
		super.setUp()
	}

	func analyze(manifest: TransactionManifest, networkID: NetworkID = .simulator) throws -> AnalyzeManifestResponse {
		try EngineToolkit().analyzeManifest(request: .init(manifest: manifest, networkId: networkID)).get()
	}

	func test_setMetaData() throws {
		let transactionManifest = TransactionManifest {
			SetMetadata(
				entityAddress: "account_sim1qspjlnwx4gdcazhral74rjgzgysrslf8ngrfmprecrrss3p9md",
				key: "name",
				value: Enum(.string("Radix Dashboard"))
			)

			SetMetadata(
				entityAddress: "component_sim1q0kryz5scup945usk39qjc2yjh6l5zsyuh8t7v5pk0tshjs68x",
				key: "name",
				value: Enum(.string("Radix Dashboard"))
			)
		}
		let analyzed = try analyze(manifest: transactionManifest)
		let expected: [ComponentAddress] = ["account_sim1qspjlnwx4gdcazhral74rjgzgysrslf8ngrfmprecrrss3p9md"]
		XCTAssertNoDifference(expected, analyzed.entitiesRequiringAuth)
		XCTAssertNoDifference(expected, analyzed.accountAddresses)
	}
}
