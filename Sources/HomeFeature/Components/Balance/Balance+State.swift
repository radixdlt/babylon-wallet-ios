import Foundation

// MARK: - Balance
/// Namespace for BalanceFeature
public extension Home {
	enum Balance {}
}

public extension Home.Balance {
	// MARK: State
	struct State: Equatable {
		var isVisible: Bool

		public init(
			isVisible: Bool = false
		) {
			self.isVisible = isVisible
		}
	}
}
