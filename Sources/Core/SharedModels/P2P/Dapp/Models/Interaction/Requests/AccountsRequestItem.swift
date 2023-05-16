import Prelude

extension P2P.Dapp.Request {
	public struct AccountsRequestItem: Sendable, Hashable, Decodable {
		public let numberOfAccounts: NumberOfAccounts
		public let challenge: P2P.Dapp.Request.AuthChallengeNonce?

		public init(
			numberOfAccounts: NumberOfAccounts,
			challenge: P2P.Dapp.Request.AuthChallengeNonce?
		) {
			self.numberOfAccounts = numberOfAccounts
			self.challenge = challenge
		}
	}
}
