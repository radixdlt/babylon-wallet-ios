import Foundation
import NonEmpty

// MARK: - P2P.ToDapp.OneTimeAccountAddressesResponse
public extension P2P.ToDapp {
	/// Response to Dapp from wallet, info about a users accounts.
	///
	/// [cap]: https://radixdlt.atlassian.net/wiki/spaces/AT/pages/2712895489/CAP-21+Message+format+between+dApp+and+wallet#Wallet-SDK-%E2%86%94%EF%B8%8F-Wallet-messages
	///
	enum OneTimeAccountAddressesResponse: Sendable, Hashable, Encodable {
		case withoutProof(OneTimeAccountAddressesWithoutProofOfOwnershipResponse)
		case withProof(OneTimeAccountAddressesWithProofOfOwnershipResponse)
	}
}

public extension P2P.ToDapp.OneTimeAccountAddressesResponse {
	func encode(to encoder: Encoder) throws {
		switch self {
		case let .withProof(response):
			try response.encode(to: encoder)
		case let .withoutProof(response):
			try response.encode(to: encoder)
		}
	}
}

public extension P2P.ToDapp.OneTimeAccountAddressesResponse {
	struct OneTimeAccountAddressesWithoutProofOfOwnershipResponse: Sendable, Hashable, Encodable {
		public let accountAddresses: [P2P.ToDapp.WalletAccount]
		public init(accountAddresses: NonEmpty<[P2P.ToDapp.WalletAccount]>) {
			self.accountAddresses = accountAddresses.rawValue
		}
	}

	struct OneTimeAccountAddressesWithProofOfOwnershipResponse: Sendable, Hashable, Encodable {
		public let accountAddresses: [P2P.ToDapp.WalletAccountWithProof]
		public init(accountAddresses: NonEmpty<[P2P.ToDapp.WalletAccountWithProof]>) {
			self.accountAddresses = accountAddresses.rawValue
		}
	}
}
