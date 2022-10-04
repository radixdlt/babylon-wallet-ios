import AccountWorthFetcher
import Common
import Foundation

// MARK: - AssetList.Row
/// Namespace for Row
public extension AssetList {
	enum Row {}
}

// MARK: - AssetList.Row.State
public extension AssetList.Row {
	// MARK: State
	struct State: Equatable {
		public var tokenContainer: TokenWorthContainer

		// MARK: - AppSettings properties
		public var currency: FiatCurrency
		public var isCurrencyAmountVisible: Bool

		public init(
			tokenContainer: TokenWorthContainer,
			currency: FiatCurrency,
			isCurrencyAmountVisible: Bool
		) {
			self.tokenContainer = tokenContainer
			self.currency = currency
			self.isCurrencyAmountVisible = isCurrencyAmountVisible
		}
	}
}

// MARK: - AssetList.Row.State + Identifiable
extension AssetList.Row.State: Identifiable {
	public typealias ID = Token.Code

	public var id: Token.Code {
		tokenContainer.token.code
	}
}
