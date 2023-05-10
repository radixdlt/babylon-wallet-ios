import Prelude

extension P2P.Dapp.Response.WalletInteractionSuccessResponse {
	public struct OngoingAccountsWithoutProofOfOwnershipRequestResponseItem: Sendable, Hashable, Encodable {
		public let accounts: [P2P.Dapp.Response.WalletAccount]
		public init(accounts: [P2P.Dapp.Response.WalletAccount]) {
			self.accounts = accounts
		}
	}

	public struct OngoingAccountsWithProofOfOwnershipRequestResponseItem: Sendable, Hashable, Encodable {
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
