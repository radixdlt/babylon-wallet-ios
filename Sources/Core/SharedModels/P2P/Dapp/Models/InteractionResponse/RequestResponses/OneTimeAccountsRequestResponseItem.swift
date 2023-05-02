import Prelude

// MARK: - P2P.Dapp.Response.WalletInteractionSuccessResponse.OneTimeAccountsRequestResponseItem
extension P2P.Dapp.Response.WalletInteractionSuccessResponse {
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

extension P2P.Dapp.Response.WalletInteractionSuccessResponse {
	public struct OneTimeAccountsWithoutProofOfOwnershipRequestResponseItem: Sendable, Hashable, Encodable {
		public let accounts: [P2P.Dapp.Response.WalletAccount]

		public init(accounts: [P2P.Dapp.Response.WalletAccount]) {
			self.accounts = accounts
		}
	}

	public struct OneTimeAccountsWithProofOfOwnershipRequestResponseItem: Sendable, Hashable, Encodable {
		public let accounts: [P2P.Dapp.Response.WalletAccountWithProof]

		public init(accounts: [P2P.Dapp.Response.WalletAccountWithProof]) {
			self.accounts = accounts
		}
	}
}
