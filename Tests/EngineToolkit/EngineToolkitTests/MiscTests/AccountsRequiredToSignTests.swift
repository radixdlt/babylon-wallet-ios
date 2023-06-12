@testable import EngineToolkit
import Prelude

final class AccountsRequiredToSignTests: TestCase {
	let account = try! AccountAddress(validatingAddress: "account_sim1qspjlnwx4gdcazhral74rjgzgysrslf8ngrfmprecrrss3p9md")
	let genericAddress = try! Address(validatingAddress: "component_sim1q0kryz5scup945usk39qjc2yjh6l5zsyuh8t7v5pk0tshjs68x")

	override func setUp() {
		debugPrint = false
		super.setUp()
	}

	func analyze(manifest: TransactionManifest, networkID: NetworkID = .simulator) throws -> ExtractAddressesFromManifestResponse {
		try RadixEngine.instance.extractAddressesFromManifest(request: .init(manifest: manifest, networkId: networkID)).get()
	}

	func test_setMetaData() throws {
		let transactionManifest = TransactionManifest {
			SetMetadata(
				accountAddress: account,
				key: "name",
				value: Enum(.string("Radix Dashboard"))
			)

			SetMetadata(
				entityAddress: genericAddress,
				key: "name",
				value: Enum(.string("Radix Dashboard"))
			)
		}
		let analyzed = try analyze(manifest: transactionManifest)
		let expected: [AccountAddress] = [account]
		XCTAssertNoDifference(expected, analyzed.accountsRequiringAuth)
		XCTAssertNoDifference(expected, analyzed.accountAddresses)
	}
}
