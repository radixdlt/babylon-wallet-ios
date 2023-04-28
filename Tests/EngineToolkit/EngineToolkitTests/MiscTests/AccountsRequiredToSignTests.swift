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
		let networkID: NetworkID = .simulator
		let accountsRequiredToSign = try transactionManifest.accountsRequiredToSign(networkId: networkID)
		let expected: Set<ComponentAddress> = ["account_sim1qspjlnwx4gdcazhral74rjgzgysrslf8ngrfmprecrrss3p9md"]
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
			    Address("account_tdx_22_1pz8jpmse7hv0uueppwcksp2h60hkcdsfefm40cye9f3qlqau64")
			    "deposit_batch"
			    Expression("ENTIRE_WORKTOP");
			"""
		))
		let networkID: NetworkID = .hammunet

		let accountsRequiredToSign = try transactionManifest.accountsRequiredToSign(networkId: networkID)
		XCTAssertNoDifference([], accountsRequiredToSign, "We expect the 'accountsRequiredToSign' to be empty, but not the 'accountsSuitableToPayTXFee'")

		let accountsSuitableToPayTXFee = try transactionManifest.accountsSuitableToPayTXFee(networkId: networkID)
		XCTAssertNoDifference(accountsSuitableToPayTXFee, ["account_tdx_22_1pz8jpmse7hv0uueppwcksp2h60hkcdsfefm40cye9f3qlqau64"])
	}

	func test_faucet() throws {
		let transactionManifest = TransactionManifest(instructions: .string(
			"""
			CALL_METHOD
				Address("component_sim1q0kryz5scup945usk39qjc2yjh6l5zsyuh8t7v5pk0tshjs68x")
				"lock_fee"
				Decimal("10");

			CALL_METHOD
				Address("component_sim1q0kryz5scup945usk39qjc2yjh6l5zsyuh8t7v5pk0tshjs68x")
				"free";

			CALL_METHOD
				Address("account_sim1qspjlnwx4gdcazhral74rjgzgysrslf8ngrfmprecrrss3p9md")
				"deposit_batch"
				Expression("ENTIRE_WORKTOP");
			"""
		))
		let networkID: NetworkID = .simulator

		let accountsRequiredToSign = try transactionManifest.accountsRequiredToSign(networkId: networkID)
		XCTAssertNoDifference(Set(), accountsRequiredToSign, "We expect the 'accountsRequiredToSign' to be empty")
	}

	func test_lockFee_account() throws {
		let transactionManifest = TransactionManifest(instructions: .string(
			"""
			CALL_METHOD
			    Address("account_sim1qspjlnwx4gdcazhral74rjgzgysrslf8ngrfmprecrrss3p9md")
			    "lock_fee"
			    Decimal("10");
			"""
		))
		let networkID: NetworkID = .simulator

		let accountsRequiredToSign = try transactionManifest.accountsRequiredToSign(networkId: networkID)
		XCTAssertNoDifference(Set(["account_sim1qspjlnwx4gdcazhral74rjgzgysrslf8ngrfmprecrrss3p9md"]), accountsRequiredToSign, "We expect the 'accountsRequiredToSign' to be contain the fee payer")
	}
}
