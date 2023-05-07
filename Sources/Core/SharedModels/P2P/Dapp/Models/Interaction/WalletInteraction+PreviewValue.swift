import Prelude

#if DEBUG

extension TransactionManifest {
	public static let previewValue = Self(instructions: .string(complexManifestString))
}

private let complexManifestString = """
# Withdraw XRD from account
CALL_METHOD ComponentAddress("account_sim1q02r73u7nv47h80e30pc3q6ylsj7mgvparm3pnsm780qgsy064") "withdraw_by_amount" Decimal("5.0") ResourceAddress("resource_sim1qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqzqu57yag");

# Buy GUM with XRD
TAKE_FROM_WORKTOP_BY_AMOUNT Decimal("2.0") ResourceAddress("resource_sim1qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqzqu57yag") Bucket("xrd");
CALL_METHOD ComponentAddress("component_sim1q2f9vmyrmeladvz0ejfttcztqv3genlsgpu9vue83mcs835hum") "buy_gumball" Bucket("xrd");
ASSERT_WORKTOP_CONTAINS_BY_AMOUNT Decimal("3.0") ResourceAddress("resource_sim1qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqzqu57yag");
ASSERT_WORKTOP_CONTAINS ResourceAddress("resource_sim1qzhdk7tq68u8msj38r6v6yqa5myc64ejx3ud20zlh9gseqtux6");

# Create a proof from bucket, clone it and drop both
TAKE_FROM_WORKTOP ResourceAddress("resource_sim1qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqzqu57yag") Bucket("some_xrd");
CREATE_PROOF_FROM_BUCKET Bucket("some_xrd") Proof("proof1");
CLONE_PROOF Proof("proof1") Proof("proof2");
DROP_PROOF Proof("proof1");
DROP_PROOF Proof("proof2");

# Create a proof from account and drop it
CALL_METHOD ComponentAddress("account_sim1q02r73u7nv47h80e30pc3q6ylsj7mgvparm3pnsm780qgsy064") "create_proof_by_amount" Decimal("5.0") ResourceAddress("resource_sim1qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqzqu57yag");
POP_FROM_AUTH_ZONE Proof("proof3");
DROP_PROOF Proof("proof3");

# Return a bucket to worktop
RETURN_TO_WORKTOP Bucket("some_xrd");
TAKE_FROM_WORKTOP_BY_IDS Set<NonFungibleLocalId>(NonFungibleLocalId("0905000000"), NonFungibleLocalId("0907000000")) ResourceAddress("resource_sim1qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqzqu57yag") Bucket("nfts");

# Create a new fungible resource
CREATE_RESOURCE Enum("Fungible", 0u8) Map<String, String>() Map<Enum, Tuple>() Some(Enum("Fungible", Decimal("1.0")));

# Cancel all buckets and move resources to account
CALL_METHOD ComponentAddress("account_sim1q02r73u7nv47h80e30pc3q6ylsj7mgvparm3pnsm780qgsy064") "deposit_batch" Expression("ENTIRE_WORKTOP");

# Drop all proofs
DROP_ALL_PROOFS;

# Complicated method that takes all of the number types
CALL_METHOD ComponentAddress("component_sim1q2f9vmyrmeladvz0ejfttcztqv3genlsgpu9vue83mcs835hum") "complicated_method" Decimal("1") PreciseDecimal("2");
"""

extension P2P.Dapp.Request.OneTimeAccountsRequestItem {
	public static let previewValue: Self = .init(
		numberOfAccounts: .exactly(1),
		requiresProofOfOwnership: false
	)
}

extension P2P.Dapp.Request.OneTimePersonaDataRequestItem {
	public static let previewValue: Self = .init(
		fields: [.givenName, .familyName, .emailAddress]
	)
}

extension P2P.Dapp.Request.SendTransactionItem {
	public static let previewValue: Self = .init(version: .default, transactionManifest: .previewValue, message: nil)
}

extension P2P.Dapp.Request.ID {
	public static let previewValue = Self.previewValue0
	public static let previewValue0: Self = "E621E1F8-C36C-495A-93FC-0C247A3E6E5F"
	public static let previewValue1: Self = "D621E1F8-C36C-495A-93FC-0C247A3E6E5F"
	public static let previewValue2: Self = "C621E1F8-C36C-495A-93FC-0C247A3E6E5F"
	public static let previewValue3: Self = "B621E1F8-C36C-495A-93FC-0C247A3E6E5F"
	public static let previewValue4: Self = "A621E1F8-C36C-495A-93FC-0C247A3E6E5F"
}

extension P2P.Dapp.Request.Metadata {
	public static let previewValue = Self(
		networkId: .simulator,
		origin: "Placeholder",
		dAppDefinitionAddress: try! .init(address: "account_tdx_b_1p8ahenyznrqy2w0tyg00r82rwuxys6z8kmrhh37c7maqpydx7p")
	)
}

extension P2P.Dapp.Request {
	public static func previewValueAllRequests(auth: P2P.Dapp.Request.AuthRequestItem) -> Self {
		.init(
			id: .previewValue0,
			items: .request(.authorized(.init(
				auth: auth,
				reset: nil,
				ongoingAccounts: .init(
					numberOfAccounts: .atLeast(2),
					requiresProofOfOwnership: false
				),
				ongoingPersonaData: .init(
					fields: [.givenName, .familyName, .emailAddress]
				),
				oneTimeAccounts: .previewValue,
				oneTimePersonaData: .previewValue
			))),
			metadata: .previewValue
		)
	}

	public static let previewValueOneTimeAccount: Self = .previewValueOneTimeAccount()
	public static func previewValueOneTimeAccount(
		id: ID = .previewValue0
	) -> Self {
		.init(
			id: id,
			items: .request(
				.unauthorized(.init(
					oneTimeAccounts: .previewValue,
					oneTimePersonaData: .previewValue
				))
			),
			metadata: .previewValue
		)
	}

	public static let previewValueSignTX: Self = .previewValueSignTX()

	public static func previewValueSignTX(
		id: ID = .previewValue0
	) -> Self {
		.init(
			id: id,
			items: .transaction(.init(
				send: .previewValue
			)),
			metadata: .previewValue
		)
	}

	public static let previewValueNoRequestItems = Self(
		id: .previewValue,
		items: .request(.unauthorized(.init(
			oneTimeAccounts: nil,
			oneTimePersonaData: nil
		))),
		metadata: .previewValue
	)
}
#endif // DEBUG
