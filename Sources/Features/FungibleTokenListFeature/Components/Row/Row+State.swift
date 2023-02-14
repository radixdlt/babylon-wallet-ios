import FeaturePrelude

// MARK: - FungibleTokenList.Row.State
extension FungibleTokenList.Row {
	// MARK: State
	public struct State: Sendable, Hashable {
		public var container: FungibleTokenContainer

		// MARK: - AppSettings properties
		public let currency: FiatCurrency
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
