@testable import EngineToolkit
import Prelude

final class AccountsRequiredToSignTests: TestCase {
	let account = try! AccountAddress(validatingAddress: "account_sim1cyvgx33089ukm2pl97pv4max0x40ruvfy4lt60yvya744cve475w0q")
	let genericAddress = try! Address(validatingAddress: "component_sim1cqvgx33089ukm2pl97pv4max0x40ruvfy4lt60yvya744cvemygpmu")

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
				value: .init(.option_Some)
			)

			SetMetadata(
				entityAddress: genericAddress,
				key: "name",
				value: .init(.option_Some)
			)
		}
		let analyzed = try analyze(manifest: transactionManifest)
		let expected: [AccountAddress] = [account]
		XCTAssertNoDifference(expected, analyzed.accountsRequiringAuth)
		XCTAssertNoDifference(expected, analyzed.accountAddresses)
	}
}
