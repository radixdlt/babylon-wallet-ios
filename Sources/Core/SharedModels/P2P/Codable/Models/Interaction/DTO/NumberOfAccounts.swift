import Prelude

public extension P2P.FromDapp.WalletInteraction {
	struct NumberOfAccounts: Sendable, Hashable, Decodable {
		public enum Quantifier: String, Sendable, Hashable, Decodable {
			case exactly
			case atLeast
		}

		public let quantifier: Quantifier
		public let quantity: Int

		public static func exactly(_ quantity: Int) -> Self {
			.init(quantifier: .exactly, quantity: quantity)
		}

		public static func atLeast(_ quantity: Int) -> Self {
			.init(quantifier: .atLeast, quantity: quantity)
		}
	}
}
