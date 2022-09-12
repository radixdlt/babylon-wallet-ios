import AccountWorthFetcher
import Common
import Foundation

// MARK: - AssetRow
/// Namespace for AssetRowFeature
public extension Home {
	enum AssetRow {}
}

public extension Home.AssetRow {
	// MARK: State
	struct State: Equatable, Identifiable {
		public var id: UUID
		public var tokenContainer: TokenWorthContainer

		// MARK: - AppSettings properties
		public var currency: FiatCurrency
		public var isCurrencyAmountVisible: Bool

		public init(
			id: UUID,
			tokenContainer: TokenWorthContainer,
			currency: FiatCurrency,
			isCurrencyAmountVisible: Bool
		) {
			self.id = id
			self.tokenContainer = tokenContainer
			self.currency = currency
			self.isCurrencyAmountVisible = isCurrencyAmountVisible
		}
	}
}
