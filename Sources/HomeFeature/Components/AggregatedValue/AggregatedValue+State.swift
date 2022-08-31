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
		public var currency: FiatCurrency // FIXME: this should be currency, since it can be any currency

		public init(
			value: Float? = nil,
			currency: FiatCurrency = .usd // FIXME: do not use default parameter
		) {
			self.value = value
			self.currency = currency
		}
	}
}

#if DEBUG
public extension Home.AggregatedValue.State {
	static let placeholder = Home.AggregatedValue.State(
		value: 1_000_000,
		currency: .usd
	)
}
#endif
