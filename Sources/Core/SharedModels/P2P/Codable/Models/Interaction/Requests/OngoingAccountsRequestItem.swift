import Prelude

// MARK: - P2P.FromDapp.WalletInteraction.OngoingAccountsRequestItem
public extension P2P.FromDapp.WalletInteraction {
	struct OngoingAccountsRequestItem: Sendable, Hashable, Decodable {
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
