import Common
import Foundation
import Profile

// MARK: - AggregatedValue
/// Namespace for AggregatedValueFeature
public enum AggregatedValue {}

// MARK: AggregatedValue.State
public extension AggregatedValue {
	// MARK: State
	struct State: Equatable {
		public var value: Float?

		// MARK: - AppSettings properties
		public var currency: FiatCurrency
		public var isCurrencyAmountVisible: Bool

		public init(
			value: Float? = nil,
			currency: FiatCurrency = .usd,
			isCurrencyAmountVisible: Bool = false
		) {
			self.value = value
			self.currency = currency
			self.isCurrencyAmountVisible = isCurrencyAmountVisible
		}
	}
}

#if DEBUG
public extension AggregatedValue.State {
	static let placeholder = AggregatedValue.State(
		value: 1_000_000,
		currency: .usd
	)
}
#endif
