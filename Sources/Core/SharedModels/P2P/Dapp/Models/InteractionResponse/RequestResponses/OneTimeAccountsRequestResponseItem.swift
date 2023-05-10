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
		public let discriminator = "oneTimeAccountsWithoutProofOfOwnership"
		public let accounts: [P2P.Dapp.Response.WalletAccount]

		public init(accounts: [P2P.Dapp.Response.WalletAccount]) {
			self.accounts = accounts
		}
	}

	public struct OneTimeAccountsWithProofOfOwnershipRequestResponseItem: Sendable, Hashable, Encodable {
		public let discriminator = "oneTimeAccountsWithProofOfOwnership"
		public let accounts: [P2P.Dapp.Response.WalletAccountWithProof]
		public let challenge: P2P.Dapp.AuthChallengeNonce

		public init(
			challenge: P2P.Dapp.AuthChallengeNonce,
			accounts: [P2P.Dapp.Response.WalletAccountWithProof]
		) {
			self.challenge = challenge
			self.accounts = accounts
		}
	}
}

// MARK: - InvalidProofFoundAmongstAccounts
struct InvalidProofFoundAmongstAccounts: Swift.Error {}
