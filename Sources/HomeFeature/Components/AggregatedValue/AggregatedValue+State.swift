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
		public var account: Account
		public var isVisible: Bool

		public init(
			account: Account,
			isVisible: Bool = false
		) {
			self.account = account
			self.isVisible = isVisible
		}
	}
}

#if DEBUG
public extension Home.AggregatedValue.State {
	static let placeholder = Home.AggregatedValue.State(
		account: .placeholder,
		isVisible: true
	)
}
#endif
