import Prelude

// MARK: - P2P.FromDapp.WalletInteraction.OneTimeAccountsRequestItem
public extension P2P.FromDapp.WalletInteraction {
	struct OneTimeAccountsRequestItem: Sendable, Hashable, Decodable {
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

// MARK: - P2P.FromDapp.WalletInteraction.NumberOfAccounts
public extension P2P.FromDapp.WalletInteraction {
	struct NumberOfAccounts: Sendable, Hashable, Decodable {
		public enum Quantifier: String, Sendable, Hashable, Decodable {
			case exactly
			case atLeast
		}

		public let quantifier: Quantifier
		public let quantity: Int
	}
}
