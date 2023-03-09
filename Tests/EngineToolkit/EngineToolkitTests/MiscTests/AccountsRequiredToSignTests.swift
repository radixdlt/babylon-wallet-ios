@testable import EngineToolkit
import Prelude

final class AccountsRequiredToSignTests: TestCase {
	override func setUp() {
		debugPrint = true
		super.setUp()
	}

	func test_setMetaData() throws {
		let transactionManifest = TransactionManifest {
			SetMetadata(
				entityAddress: .componentAddress("account_sim1q0egd2wpyslhkd28yuwpzq0qdg4aq73kl4urcnc3qsxsk6kug3"),
				key: "name",
				value: "Radix Dashboard"
			)

			SetMetadata(
				entityAddress: .componentAddress("component_sim1qgehpqdhhr62xh76wh6gppnyn88a0uau68epljprvj3sxknsqr"),
				key: "name",
				value: "Radix Dashboard"
			)
		}
		let networkID: NetworkID = .simulator
		let accountsRequiredToSign = try transactionManifest.accountsRequiredToSign(networkId: networkID)
		let expected: Set<ComponentAddress> = Set(["account_sim1q0egd2wpyslhkd28yuwpzq0qdg4aq73kl4urcnc3qsxsk6kug3"])
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
			    ComponentAddress("account_tdx_22_1pz8jpmse7hv0uueppwcksp2h60hkcdsfefm40cye9f3qlqau64")
			    "deposit_batch"
			    Expression("ENTIRE_WORKTOP");
			"""
		))
		let networkID: NetworkID = .hammunet

		let accountsRequiredToSign = try transactionManifest.accountsRequiredToSign(networkId: networkID)
		XCTAssertNoDifference(Set(), accountsRequiredToSign, "We expect the 'accountsRequiredToSign' to be empty, but not the 'accountsSuitableToPayTXFee'")

		let accountsSuitableToPayTXFee = try transactionManifest.accountsSuitableToPayTXFee(networkId: networkID)
		XCTAssertNoDifference(accountsSuitableToPayTXFee, ["account_tdx_22_1pz8jpmse7hv0uueppwcksp2h60hkcdsfefm40cye9f3qlqau64"])
	}
}
