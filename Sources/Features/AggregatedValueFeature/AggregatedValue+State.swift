import FeaturePrelude

// MARK: - AggregatedValue.State
extension AggregatedValue {
	// MARK: State
	public struct State: Sendable, Equatable {
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
extension AggregatedValue.State {
	public static let previewValue = AggregatedValue.State(
		value: 1_000_000,
		currency: .usd
	)
}
#endif
