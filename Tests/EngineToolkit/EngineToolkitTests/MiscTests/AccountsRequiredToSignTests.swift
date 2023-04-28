@testable import EngineToolkit
import Prelude

final class AccountsRequiredToSignTests: TestCase {
	override func setUp() {
		debugPrint = false
		super.setUp()
	}

	func test_setMetaData() throws {
		let transactionManifest = TransactionManifest {
			SetMetadata(
				entityAddress: "account_sim1ql02qtc2tm73h5dyl8grh2p8xfncgrfltagjm7adlg3edr0ejjmpvt",
				key: "name",
				value: Enum(
					.u8(0),
					fields: [
						.enum(.init(.u8(0), fields: [.string("Radix Dashboard")])),
					]
				)
			)
		}
		let networkID: NetworkID = .simulator
		let accountsRequiredToSign = try transactionManifest.accountsRequiredToSign(networkId: networkID)
		let expected: Set<AccountAddress_> = ["account_sim1ql02qtc2tm73h5dyl8grh2p8xfncgrfltagjm7adlg3edr0ejjmpvt"]
		let result = sut.decodeAddressRequest(request: .init(address: "account_tdx_21_1pdphpkkaafrzzuywsp49cwahuxx05k3ul9suawvmpxylelec3d9ytf"))
		XCTAssertNoDifference(expected, accountsRequiredToSign)

		// Accounts suitable to pay TX fee is ought to be a superset of accountsRequiredToSign
		let accountsSuitableToPayTXFee = try transactionManifest.accountsSuitableToPayTXFee(networkId: networkID)

		// Assert
		XCTAssertNoDifference(expected, accountsSuitableToPayTXFee)
	}

	func test_accountsSuitableToPayTXFee_CREATE_FUNGIBLE_RESOURCE_then_deposit_batch() throws {
		let transactionManifest = TransactionManifest(instructions: .string(
			"""
			CREATE_FUNGIBLE_RESOURCE
			    18u8
			    Map<String, String>(
			        "name", "OwlToken",
			        "symbol", "OWL",
			        "description", "My Own Token if you smart - buy. If youre very smart, buy & keep"
			    )
			    Map<Enum, Tuple>(

			        Enum("ResourceMethodAuthKey::Withdraw"), Tuple(Enum("AccessRule::AllowAll"), Enum("AccessRule::DenyAll")),
			        Enum("ResourceMethodAuthKey::Deposit"), Tuple(Enum("AccessRule::AllowAll"), Enum("AccessRule::DenyAll"))
			    );


			CALL_METHOD
			    Address("account_sim1ql02qtc2tm73h5dyl8grh2p8xfncgrfltagjm7adlg3edr0ejjmpvt")
			    "deposit_batch"
			    Expression("ENTIRE_WORKTOP");
			"""
		))
		let networkID: NetworkID = .simulator

		let accountsRequiredToSign = try transactionManifest.accountsRequiredToSign(networkId: networkID)
		XCTAssertNoDifference([], accountsRequiredToSign, "We expect the 'accountsRequiredToSign' to be empty, but not the 'accountsSuitableToPayTXFee'")

		let accountsSuitableToPayTXFee = try transactionManifest.accountsSuitableToPayTXFee(networkId: networkID)
		XCTAssertNoDifference(accountsSuitableToPayTXFee, ["account_sim1ql02qtc2tm73h5dyl8grh2p8xfncgrfltagjm7adlg3edr0ejjmpvt"])
	}

	func test_faucet() throws {
		let transactionManifest = TransactionManifest(instructions: .string(
			"""
			CALL_METHOD
				Address("component_sim1pyqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqdxh44")
				"lock_fee"
				Decimal("10");

			CALL_METHOD
				Address("component_sim1pyqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqdxh44")
				"free";

			CALL_METHOD
				Address("account_sim1ql02qtc2tm73h5dyl8grh2p8xfncgrfltagjm7adlg3edr0ejjmpvt")
				"deposit_batch"
				Expression("ENTIRE_WORKTOP");
			"""
		))
		let networkID: NetworkID = .simulator

		let accountsRequiredToSign = try transactionManifest.accountsRequiredToSign(networkId: networkID)
		XCTAssertNoDifference(Set(), accountsRequiredToSign, "We expect the 'accountsRequiredToSign' to be empty")
	}
}
