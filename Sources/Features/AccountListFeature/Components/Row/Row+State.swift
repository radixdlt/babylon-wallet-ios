import AccountPortfolio
import Asset
import Common
import Foundation
import Profile

// MARK: - AccountList.Row.State
public extension AccountList.Row {
	// MARK: State
	struct State: Equatable {
		public let account: OnNetwork.Account
		public var aggregatedValue: Float?
		public var portfolio: OwnedAssets

		// MARK: - AppSettings properties
		public var currency: FiatCurrency
		public var isCurrencyAmountVisible: Bool

		public init(
			account: OnNetwork.Account,
			aggregatedValue: Float?,
			portfolio: OwnedAssets,
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
public extension AccountList.Row.State {
	init(account: OnNetwork.Account) {
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
import ProfileClient
public extension AccountList.Row.State {
	static let placeholder = Self(account: .placeholder0)
}
#endif
