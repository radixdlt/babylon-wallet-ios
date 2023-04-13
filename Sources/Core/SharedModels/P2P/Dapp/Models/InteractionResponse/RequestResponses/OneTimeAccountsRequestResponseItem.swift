import Prelude

// MARK: - P2P.ToDapp.WalletInteractionSuccessResponse.OneTimeAccountsRequestResponseItem
extension P2P.ToDapp.WalletInteractionSuccessResponse {
	public enum OneTimeAccountsRequestResponseItem: Sendable, Hashable, Encodable {
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

extension P2P.ToDapp.WalletInteractionSuccessResponse {
	public struct OneTimeAccountsWithoutProofOfOwnershipRequestResponseItem: Sendable, Hashable, Encodable {
		public let accounts: [P2P.ToDapp.WalletAccount]

		public init(accounts: [P2P.ToDapp.WalletAccount]) {
			self.accounts = accounts
		}
	}

	public struct OneTimeAccountsWithProofOfOwnershipRequestResponseItem: Sendable, Hashable, Encodable {
		public let accounts: [P2P.ToDapp.WalletAccountWithProof]

		public init(accounts: [P2P.ToDapp.WalletAccountWithProof]) {
			self.accounts = accounts
		}
	}
}
