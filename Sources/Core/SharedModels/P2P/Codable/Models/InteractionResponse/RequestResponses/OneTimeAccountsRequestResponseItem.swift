import Prelude

// MARK: - P2P.ToDapp.WalletInteractionSuccessResponse.OneTimeAccountsRequestResponseItem
public extension P2P.ToDapp.WalletInteractionSuccessResponse {
	enum OneTimeAccountsRequestResponseItem: Sendable, Hashable, Encodable {
		case withoutProof(OneTimeAccountsWithoutProofOfOwnershipRequestResponseItem)
		case withProof(OneTimeAccountsWithProofOfOwnershipRequestResponseItem)

		public func encode(to encoder: Encoder) throws {
			switch self {
			case let .withProof(response):
				try response.encode(to: encoder)
			case let .withoutProof(response):
				try response.encode(to: encoder)
			}
		}
	}
}

public extension P2P.ToDapp.WalletInteractionSuccessResponse {
	struct OneTimeAccountsWithoutProofOfOwnershipRequestResponseItem: Sendable, Hashable, Encodable {
		public let accounts: [P2P.ToDapp.WalletAccount]

		public init(accounts: NonEmpty<[P2P.ToDapp.WalletAccount]>) {
			self.accounts = accounts.rawValue
		}
	}

	struct OneTimeAccountsWithProofOfOwnershipRequestResponseItem: Sendable, Hashable, Encodable {
		public let accounts: [P2P.ToDapp.WalletAccountWithProof]

		public init(accounts: NonEmpty<[P2P.ToDapp.WalletAccountWithProof]>) {
			self.accounts = accounts.rawValue
		}
	}
}
