import AccountWorthFetcher
import Common
import Foundation

// MARK: - AssetRow
/// Namespace for AssetRowFeature
public extension AccountDetails {
	enum AssetRow {}
}

public extension AccountDetails.AssetRow {
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

// MARK: - AccountDetails.AssetRow.State + Identifiable
extension AccountDetails.AssetRow.State: Identifiable {
	public typealias ID = Token.Code

	public var id: Token.Code {
		tokenContainer.token.code
	}
}
