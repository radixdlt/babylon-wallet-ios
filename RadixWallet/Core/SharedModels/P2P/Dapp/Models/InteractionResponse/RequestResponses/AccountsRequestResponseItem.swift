
extension P2P.Dapp.Response.WalletInteractionSuccessResponse {
	public struct AccountsRequestResponseItem: Sendable, Hashable, Encodable {
		public let accounts: [P2P.Dapp.Response.WalletAccount]

		public let challenge: P2P.Dapp.Request.AuthChallengeNonce?
		public let proofs: [P2P.Dapp.Response.AccountProof]?

		public init(
			accounts: P2P.Dapp.Response.Accounts
		) {
			switch accounts {
			case let .withProofOfOwnership(challenge, accountsWithProof):
				self.accounts = accountsWithProof.map(\.account)
				self.challenge = challenge
				self.proofs = accountsWithProof.map(P2P.Dapp.Response.AccountProof.init(accountWithProof:))
			case let .withoutProofOfOwnership(account):
				self.accounts = account.map(P2P.Dapp.Response.WalletAccount.init(account:))
				self.challenge = nil
				self.proofs = nil
			}
		}

		/// for tests
		private init(withoutProofOfOwnership accounts: [P2P.Dapp.Response.WalletAccount]) {
			self.accounts = accounts
			self.challenge = nil
			self.proofs = nil
		}

		/// for tests
		static func withoutProofOfOwnership(accounts: [P2P.Dapp.Response.WalletAccount]) -> Self {
			Self(withoutProofOfOwnership: accounts)
		}
	}
}
