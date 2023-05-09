import Prelude

// MARK: - P2P.Dapp.Request.OneTimeAccountsRequestItem
extension P2P.Dapp.Request {
	public struct OneTimeAccountsRequestItem: Sendable, Hashable, Decodable {
		public let numberOfAccounts: NumberOfAccounts
		public let challenge: P2P.Dapp.AuthChallengeNonce?

		public init(
			numberOfAccounts: NumberOfAccounts,
			challenge: P2P.Dapp.AuthChallengeNonce?
		) {
			self.numberOfAccounts = numberOfAccounts
			self.challenge = challenge
		}
	}
}
