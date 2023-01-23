import Prelude

// MARK: - P2P.ToDapp.OneTimeAccountsResponseItem
public extension P2P.ToDapp {
	/// Response to Dapp from wallet, info about a users accounts.
	///
	/// [cap]: https://radixdlt.atlassian.net/wiki/spaces/AT/pages/2712895489/CAP-21+Message+format+between+dApp+and+wallet#Wallet-SDK-%E2%86%94%EF%B8%8F-Wallet-messages
	///
	enum OneTimeAccountsResponseItem: Sendable, Hashable, Encodable {
		case withoutProof(OneTimeAccountsWithoutProofOfOwnershipResponseItem)
		case withProof(OneTimeAccountsWithProofOfOwnershipResponseItem)
	}
}

public extension P2P.ToDapp.OneTimeAccountsResponseItem {
	func encode(to encoder: Encoder) throws {
		switch self {
		case let .withProof(response):
			try response.encode(to: encoder)
		case let .withoutProof(response):
			try response.encode(to: encoder)
		}
	}
}

public extension P2P.ToDapp.OneTimeAccountsResponseItem {
	struct OneTimeAccountsWithoutProofOfOwnershipResponseItem: Sendable, Hashable, Encodable {
		public let accounts: [P2P.ToDapp.WalletAccount]
		public init(accounts: NonEmpty<[P2P.ToDapp.WalletAccount]>) {
			self.accounts = accounts.rawValue
		}
	}

	struct OneTimeAccountsWithProofOfOwnershipResponseItem: Sendable, Hashable, Encodable {
		public let accounts: [P2P.ToDapp.WalletAccountWithProof]
		public init(accounts: NonEmpty<[P2P.ToDapp.WalletAccountWithProof]>) {
			self.accounts = accounts.rawValue
		}
	}
}
