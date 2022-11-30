import EngineToolkit
import Foundation
import Tagged

// MARK: - P2P.FromDapp.Request
public extension P2P.FromDapp {
	/// Called `WalletRequest` in [CAP21][cap]
	///
	/// [cap]: https://radixdlt.atlassian.net/wiki/spaces/AT/pages/2712895489/CAP-21+Message+format+between+dApp+and+wallet#Wallet-SDK-%E2%86%94%EF%B8%8F-Wallet-messages
	///
	struct Request: Sendable, Hashable, Decodable, Identifiable {
		public let id: ID

		public let items: [WalletRequestItem]

		public let metadata: Metadata

		public init(
			id: ID,
			metadata: Metadata,
			items: [WalletRequestItem]
		) {
			self.id = id
			self.metadata = metadata
			self.items = items
		}
	}
}

public extension P2P.FromDapp.Request {
	enum IDTag: Hashable {}
	typealias ID = Tagged<IDTag, String>
}

// MARK: - P2P.FromDapp.Request.Metadata
public extension P2P.FromDapp.Request {
	struct Metadata: Sendable, Hashable, Decodable {
		public let networkId: NetworkID
		public let origin: Origin
		public let dAppId: DAppID

		public init(networkId: NetworkID, origin: Origin, dAppId: DAppID) {
			self.networkId = networkId
			self.origin = origin
			self.dAppId = dAppId
		}
	}
}

public extension P2P.FromDapp.Request.Metadata {
	enum OriginTag: Hashable {}
	typealias Origin = Tagged<OriginTag, String>
	enum DappIDTag: Hashable {}
	typealias DAppID = Tagged<DappIDTag, String>
}

public extension P2P.FromDapp.Request {
	private enum CodingKeys: String, CodingKey {
		case id = "requestId"
		case items
		case metadata
	}

	init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		try self.init(
			id: container.decode(ID.self, forKey: .id),
			metadata: container.decode(Metadata.self, forKey: .metadata),
			items: container.decode([P2P.FromDapp.WalletRequestItem].self, forKey: .items)
		)
	}
}

#if DEBUG

public extension TransactionManifest {
	static let placeholder = Self(instructions: .string(complexManifestString))
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
TAKE_FROM_WORKTOP_BY_IDS Set<NonFungibleId>(NonFungibleId("0905000000"), NonFungibleId("0907000000")) ResourceAddress("resource_sim1qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqzqu57yag") Bucket("nfts");

# Create a new fungible resource
CREATE_RESOURCE Enum("Fungible", 0u8) Map<String, String>() Map<Enum, Tuple>() Some(Enum("Fungible", Decimal("1.0")));

# Cancel all buckets and move resources to account
CALL_METHOD ComponentAddress("account_sim1q02r73u7nv47h80e30pc3q6ylsj7mgvparm3pnsm780qgsy064") "deposit_batch" Expression("ENTIRE_WORKTOP");

# Drop all proofs
DROP_ALL_PROOFS;

# Complicated method that takes all of the number types
CALL_METHOD ComponentAddress("component_sim1q2f9vmyrmeladvz0ejfttcztqv3genlsgpu9vue83mcs835hum") "complicated_method" Decimal("1") PreciseDecimal("2");
"""

public extension P2P.FromDapp.OneTimeAccountsReadRequestItem {
	static let placeholder: Self = .init(
		numberOfAddresses: 1,
		isRequiringOwnershipProof: false
	)
}

public extension P2P.FromDapp.SendTransactionWriteRequestItem {
	static let placeholder: Self = .init(transactionManifest: .placeholder, version: .default, message: nil)
}

public extension P2P.FromDapp.Request.ID {
	static let placeholder = Self.placeholder0
	static let placeholder0 = Self("E621E1F8-C36C-495A-93FC-0C247A3E6E5F")
	static let placeholder1 = Self("D621E1F8-C36C-495A-93FC-0C247A3E6E5F")
	static let placeholder2 = Self("C621E1F8-C36C-495A-93FC-0C247A3E6E5F")
	static let placeholder3 = Self("B621E1F8-C36C-495A-93FC-0C247A3E6E5F")
	static let placeholder4 = Self("A621E1F8-C36C-495A-93FC-0C247A3E6E5F")
}

public extension P2P.FromDapp.Request.Metadata {
	static let placeholder = Self(
		networkId: .primary,
		origin: "Placeholder",
		dAppId: "Placeholder"
	)
}

public extension P2P.FromDapp.Request {
	static let placeholderOneTimeAccount: Self = .placeholderOneTimeAccount()
	static func placeholderOneTimeAccount(
		id: ID = .placeholder0
	) -> Self {
		.init(
			id: id,
			metadata: .placeholder,
			items: [
				.oneTimeAccounts(.placeholder),
			]
		)
	}

	static let placeholderSignTX: Self = .placeholderSignTX()

	static func placeholderSignTX(
		id: ID = .placeholder0
	) -> Self {
		.init(
			id: id,
			metadata: .placeholder,
			items: [
				.sendTransaction(.placeholder),
			]
		)
	}
}
#endif // DEBUG
