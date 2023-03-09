@testable import EngineToolkit
import Prelude

final class AccountsRequiredToSignTests: TestCase {
    override func setUp() {
        debugPrint = true
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
            Array<NonFungibleLocalId>();

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
            Array<NonFungibleLocalId>();

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
            Array<NonFungibleLocalId>();

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
            Array<NonFungibleLocalId>();

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
            Array<NonFungibleLocalId>();

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
            Array<NonFungibleLocalId>();
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
        var expectedAccountsSuitableToPayFee = expectedAccountsRequiredToSign
        expectedAccountsSuitableToPayFee.insert("account_sim1qd3gq5m2lnfc8ahau2td5mprqf44nucsgxagmllnsjyqj426ly")
        expectedAccountsSuitableToPayFee.insert("account_sim1qdv0uj0zs7qrcyl6qee0csu6prdssuz9r7uldsz3sqhqvw24hw")

        // Act
        let accountsRequiredToSign = try transactionManifest.accountsRequiredToSign(networkId: 0xF2)

        // Assert
        XCTAssertNoDifference(
            expectedAccountsRequiredToSign,
            accountsRequiredToSign
        )

        // Accounts suitable to pay TX fee is ought to be a superset of accountsRequiredToSign
        let accountsSuitableToPayTXFee = try transactionManifest.accountsSuitableToPayTXFee(networkId: 0xF2)

        // Assert
        XCTAssertNoDifference(
            expectedAccountsSuitableToPayFee,
            accountsSuitableToPayTXFee
        )
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
