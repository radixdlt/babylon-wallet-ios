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
		public var value: Float?
		public var isVisible: Bool

		public init(
			value: Float? = nil,
			isVisible: Bool = false
		) {
			self.value = value
			self.isVisible = isVisible
		}
	}
}

#if DEBUG
public extension Home.AggregatedValue.State {
	static let placeholder = Home.AggregatedValue.State(
		value: 1_000_000,
		isVisible: false
	)
}
#endif
