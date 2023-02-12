import AccountPortfolio
import FeaturePrelude

// MARK: - AccountList.Row.State
extension AccountList.Row {
	// MARK: State
	public struct State: Sendable, Equatable {
		public let account: OnNetwork.Account
		public var aggregatedValue: Float?
		public var portfolio: AccountPortfolio

		// MARK: - AppSettings properties
		public var currency: FiatCurrency
		public var isCurrencyAmountVisible: Bool

		public init(
			account: OnNetwork.Account,
			aggregatedValue: Float?,
			portfolio: AccountPortfolio,
			currency: FiatCurrency,
			isCurrencyAmountVisible: Bool
		) {
			self.account = account
			self.aggregatedValue = aggregatedValue
			self.portfolio = portfolio
			self.currency = currency
			self.isCurrencyAmountVisible = isCurrencyAmountVisible
		}
	}
}

// MARK: - Convenience
extension AccountList.Row.State {
	public init(account: OnNetwork.Account) {
		self.init(
			account: account,
			aggregatedValue: nil,
			portfolio: .empty,
			currency: .usd,
			isCurrencyAmountVisible: false
		)
	}
}

// MARK: - AccountList.Row.State + Identifiable
extension AccountList.Row.State: Identifiable {
	public typealias ID = AccountAddress
	public var id: ID { address }
	public var address: AccountAddress {
		account.address
	}
}

#if DEBUG
extension AccountList.Row.State {
	public static let previewValue = Self(account: .previewValue0)
}
#endif
