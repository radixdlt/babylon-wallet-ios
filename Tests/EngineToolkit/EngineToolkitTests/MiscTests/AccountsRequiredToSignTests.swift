@testable import EngineToolkit
import Prelude

final class AccountsRequiredToSignTests: TestCase {
	override func setUp() {
		debugPrint = false
		super.setUp()
	}

	func test_accountsRequiredToSign_produces_expected_accounts_set() throws {
		// Arrange
		let manifestStringInstructions = """
		# Calls to account components. These should all be picked up and considered as accounts
		# which MUST sign.

		CALL_METHOD
		    ComponentAddress("account_sim1qw9skv0yge0skn4l0twddkwj0dyg94r8e3e3xh789d7sj0cgq7")
		    "lock_fee"
		    Decimal("100");

		CALL_METHOD
		    ComponentAddress("account_sim1q0e6ft8su6e06ex4ydpu3tndxphlj97tf5th2wtxr8lsperj9r")
		    "lock_contingent_fee"
		    Decimal("100");

		CALL_METHOD
		    ComponentAddress("account_sim1q0e6ft8su6e06ex4ydpu3tndxphlj97tf5th2wtxr8lsperj9r")
		    "withdraw"
		    ResourceAddress("resource_sim1qqytpulp0fyyna49y7vemgskcpv5079yekq29k6g2mpqlct2ez");

		CALL_METHOD
		    ComponentAddress("account_sim1qdy37ey867camkm4xmzy7x223fk0qjrakk6t9rwr9masl23tc0")
		    "withdraw_by_amount"
		    Decimal("100")
		    ResourceAddress("resource_sim1qqytpulp0fyyna49y7vemgskcpv5079yekq29k6g2mpqlct2ez");

		CALL_METHOD
		    ComponentAddress("account_sim1qvcqup8crcr07qxcprncvptayz9ustn2wfs0dh5pqagqqxvefg")
		    "withdraw_by_ids"
		    Array<NonFungibleId>();

		CALL_METHOD
		    ComponentAddress("account_sim1qvcqup8crcr07qxcprncvptayz9ustn2wfs0dh5pqagqqxvefg")
		    "lock_fee_and_withdraw"
		    Decimal("100")
		    ResourceAddress("resource_sim1qqytpulp0fyyna49y7vemgskcpv5079yekq29k6g2mpqlct2ez");

		CALL_METHOD
		    ComponentAddress("account_sim1qwhk2vvcjdjqp6l2lvc9cnu8gpjf7q07h7zp3872mpqs4f209p")
		    "lock_fee_and_withdraw_by_amount"
		    Decimal("100")
		    Decimal("100")
		    ResourceAddress("resource_sim1qqytpulp0fyyna49y7vemgskcpv5079yekq29k6g2mpqlct2ez");

		CALL_METHOD
		    ComponentAddress("account_sim1q0g8lr6vnuf4ey70t8ctxjgq6j7r5d6s7288fzr52jssmjs79x")
		    "lock_fee_and_withdraw_by_ids"
		    Decimal("100")
		    Array<NonFungibleId>();

		CALL_METHOD
		    ComponentAddress("account_sim1qw4z7rd4x429796cmgp7ql50j0n8rrlujkwqa9xf3vpqg8crj4")
		    "create_proof"
		    ResourceAddress("resource_sim1qqytpulp0fyyna49y7vemgskcpv5079yekq29k6g2mpqlct2ez");

		CALL_METHOD
		    ComponentAddress("account_sim1q0ewuyq9780mrftmlx706qrlw8n5rk48qj876p3zzrwqj28net")
		    "create_proof_by_amount"
		    Decimal("100")
		    ResourceAddress("resource_sim1qqytpulp0fyyna49y7vemgskcpv5079yekq29k6g2mpqlct2ez");

		CALL_METHOD
		    ComponentAddress("account_sim1q04p2nchcux4x3ppeq98f73ku83zem6yf0f9t2ad0lss5c20ea")
		    "create_proof_by_ids"
		    Array<NonFungibleId>();

		# Calls to account components, but to methods which do not require any signatures

		CALL_METHOD
		    ComponentAddress("account_sim1qdv0uj0zs7qrcyl6qee0csu6prdssuz9r7uldsz3sqhqvw24hw")
		    "balance";

		TAKE_FROM_WORKTOP
		    ResourceAddress("resource_sim1qqytpulp0fyyna49y7vemgskcpv5079yekq29k6g2mpqlct2ez")
		    Bucket("xrd1");
		CALL_METHOD
		    ComponentAddress("account_sim1qd3gq5m2lnfc8ahau2td5mprqf44nucsgxagmllnsjyqj426ly")
		    "deposit"
		    Bucket("xrd1");

		CALL_METHOD
		    ComponentAddress("account_sim1qd3gq5m2lnfc8ahau2td5mprqf44nucsgxagmllnsjyqj426ly")
		    "deposit_batch"
		    Expression("ENTIRE_WORKTOP");

		# Calls to other components but with method names that look identical to that of the
		# account. These should not be picked up

		CALL_METHOD
		    ComponentAddress("component_sim1qftacppvmr9ezmekxqpq58en0nk954x0a7jv2zz0hc7q8utaxr")
		    "lock_fee"
		    Decimal("100");

		CALL_METHOD
		    ComponentAddress("component_sim1qftacppvmr9ezmekxqpq58en0nk954x0a7jv2zz0hc7q8utaxr")
		    "lock_contingent_fee"
		    Decimal("100");

		CALL_METHOD
		    ComponentAddress("component_sim1qftacppvmr9ezmekxqpq58en0nk954x0a7jv2zz0hc7q8utaxr")
		    "withdraw"
		    ResourceAddress("resource_sim1qqytpulp0fyyna49y7vemgskcpv5079yekq29k6g2mpqlct2ez");

		CALL_METHOD
		    ComponentAddress("component_sim1qftacppvmr9ezmekxqpq58en0nk954x0a7jv2zz0hc7q8utaxr")
		    "withdraw_by_amount"
		    Decimal("100")
		    ResourceAddress("resource_sim1qqytpulp0fyyna49y7vemgskcpv5079yekq29k6g2mpqlct2ez");

		CALL_METHOD
		    ComponentAddress("component_sim1qftacppvmr9ezmekxqpq58en0nk954x0a7jv2zz0hc7q8utaxr")
		    "withdraw_by_ids"
		    Array<NonFungibleId>();

		CALL_METHOD
		    ComponentAddress("component_sim1qftacppvmr9ezmekxqpq58en0nk954x0a7jv2zz0hc7q8utaxr")
		    "lock_fee_and_withdraw"
		    Decimal("100")
		    ResourceAddress("resource_sim1qqytpulp0fyyna49y7vemgskcpv5079yekq29k6g2mpqlct2ez");

		CALL_METHOD
		    ComponentAddress("component_sim1qftacppvmr9ezmekxqpq58en0nk954x0a7jv2zz0hc7q8utaxr")
		    "lock_fee_and_withdraw_by_amount"
		    Decimal("100")
		    Decimal("100")
		    ResourceAddress("resource_sim1qqytpulp0fyyna49y7vemgskcpv5079yekq29k6g2mpqlct2ez");

		CALL_METHOD
		    ComponentAddress("component_sim1qftacppvmr9ezmekxqpq58en0nk954x0a7jv2zz0hc7q8utaxr")
		    "lock_fee_and_withdraw_by_ids"
		    Decimal("100")
		    Array<NonFungibleId>();

		CALL_METHOD
		    ComponentAddress("component_sim1qftacppvmr9ezmekxqpq58en0nk954x0a7jv2zz0hc7q8utaxr")
		    "create_proof"
		    ResourceAddress("resource_sim1qqytpulp0fyyna49y7vemgskcpv5079yekq29k6g2mpqlct2ez");

		CALL_METHOD
		    ComponentAddress("component_sim1qftacppvmr9ezmekxqpq58en0nk954x0a7jv2zz0hc7q8utaxr")
		    "create_proof_by_amount"
		    Decimal("100")
		    ResourceAddress("resource_sim1qqytpulp0fyyna49y7vemgskcpv5079yekq29k6g2mpqlct2ez");

		CALL_METHOD
		    ComponentAddress("component_sim1qftacppvmr9ezmekxqpq58en0nk954x0a7jv2zz0hc7q8utaxr")
		    "create_proof_by_ids"
		    Array<NonFungibleId>();
		"""
		let transactionManifest = TransactionManifest(instructions: .string(manifestStringInstructions))

		let expectedAccountsRequiredToSign: Set<ComponentAddress> = [
			"account_sim1qw9skv0yge0skn4l0twddkwj0dyg94r8e3e3xh789d7sj0cgq7",
			"account_sim1q0e6ft8su6e06ex4ydpu3tndxphlj97tf5th2wtxr8lsperj9r",
			"account_sim1qdy37ey867camkm4xmzy7x223fk0qjrakk6t9rwr9masl23tc0",
			"account_sim1qvcqup8crcr07qxcprncvptayz9ustn2wfs0dh5pqagqqxvefg",
			"account_sim1qwhk2vvcjdjqp6l2lvc9cnu8gpjf7q07h7zp3872mpqs4f209p",
			"account_sim1q0g8lr6vnuf4ey70t8ctxjgq6j7r5d6s7288fzr52jssmjs79x",
			"account_sim1qw4z7rd4x429796cmgp7ql50j0n8rrlujkwqa9xf3vpqg8crj4",
			"account_sim1q0ewuyq9780mrftmlx706qrlw8n5rk48qj876p3zzrwqj28net",
			"account_sim1q04p2nchcux4x3ppeq98f73ku83zem6yf0f9t2ad0lss5c20ea",
		]

		// Act
		let accountsRequiredToSign = try transactionManifest.accountsRequiredToSign(networkId: 0xF2)

		// Assert
		XCTAssertNoDifference(
			expectedAccountsRequiredToSign,
			accountsRequiredToSign
		)
	}
}
