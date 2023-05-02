import Prelude

// MARK: - P2P.Dapp.Response.WalletInteractionSuccessResponse.OngoingAccountsRequestResponseItem
extension P2P.Dapp.Response.WalletInteractionSuccessResponse {
	public enum OngoingAccountsRequestResponseItem: Sendable, Hashable, Encodable {
		case withoutProof(OngoingAccountsWithoutProofOfOwnershipRequestResponseItem)
		case withProof(OngoingAccountsWithProofOfOwnershipRequestResponseItem)

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
	public struct OngoingAccountsWithoutProofOfOwnershipRequestResponseItem: Sendable, Hashable, Encodable {
		public let accounts: [P2P.Dapp.Response.WalletAccount]

		public init(accounts: [P2P.Dapp.Response.WalletAccount]) {
			self.accounts = accounts
		}
	}

	public struct OngoingAccountsWithProofOfOwnershipRequestResponseItem: Sendable, Hashable, Encodable {
		public let accounts: [P2P.Dapp.Response.WalletAccountWithProof]

		public init(accounts: [P2P.Dapp.Response.WalletAccountWithProof]) {
			self.accounts = accounts
		}
	}
}
