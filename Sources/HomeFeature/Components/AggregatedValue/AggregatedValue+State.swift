import Foundation
import Profile

// MARK: - AggregatedValue
/// Namespace for AggregatedValueFeature
public extension Home {
	enum AggregatedValue {}
}

public extension Home.AggregatedValue {
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
