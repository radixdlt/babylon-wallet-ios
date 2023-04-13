import Prelude

// MARK: - P2P.Dapp.Request.OngoingAccountsRequestItem
extension P2P.Dapp.Request {
	public struct OngoingAccountsRequestItem: Sendable, Hashable, Decodable {
		public let numberOfAccounts: NumberOfAccounts
		public let requiresProofOfOwnership: Bool

		public init(
			numberOfAccounts: NumberOfAccounts,
			requiresProofOfOwnership: Bool
		) {
			self.numberOfAccounts = numberOfAccounts
			self.requiresProofOfOwnership = requiresProofOfOwnership
		}
	}
}
