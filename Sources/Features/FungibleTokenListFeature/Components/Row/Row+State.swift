import FeaturePrelude

// MARK: - FungibleTokenList.Row.State
public extension FungibleTokenList.Row {
	// MARK: State
	struct State: Sendable, Equatable {
		public var container: FungibleTokenContainer

		// MARK: - AppSettings properties
		public var currency: FiatCurrency
		public var isCurrencyAmountVisible: Bool

		public init(
			container: FungibleTokenContainer,
			currency: FiatCurrency,
			isCurrencyAmountVisible: Bool
		) {
			self.container = container
			self.currency = currency
			self.isCurrencyAmountVisible = isCurrencyAmountVisible
		}
	}
}

// MARK: - FungibleTokenList.Row.State + Identifiable
extension FungibleTokenList.Row.State: Identifiable {
	public var id: FungibleTokenContainer.ID { container.id }
}
