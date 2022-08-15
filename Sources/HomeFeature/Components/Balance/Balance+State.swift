import Foundation
import Profile

// MARK: - Balance
/// Namespace for BalanceFeature
public extension Home {
	enum Balance {}
}

public extension Home.Balance {
	// MARK: State
	struct State: Equatable {
		public var isVisible: Bool
		public var account: Account

		public init(
			isVisible: Bool = false,
			account: Account = .default
		) {
			self.isVisible = isVisible
			self.account = account
		}
	}
}
