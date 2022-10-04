import AccountPortfolio
import Address
import Asset
import Common
import Foundation
import Profile

// MARK: - AccountList.Row
/// Namespace for Row
public extension AccountList {
	enum Row {}
}

// MARK: - AccountList.Row.State
public extension AccountList.Row {
	// MARK: State
	struct State: Equatable {
		public let account: Profile.Account
		public let name: String
		public let address: Address
		public var aggregatedValue: Float?
		public var portfolio: AccountPortfolio

		// MARK: - AppSettings properties
		public var currency: FiatCurrency
		public var isCurrencyAmountVisible: Bool

		public init(
			account: Profile.Account,
			name: String,
			address: String,
			aggregatedValue: Float?,
			portfolio: AccountPortfolio,
			currency: FiatCurrency,
			isCurrencyAmountVisible: Bool
		) {
			self.account = account
			self.name = name
			self.address = address
			self.aggregatedValue = aggregatedValue
			self.portfolio = portfolio
			self.currency = currency
			self.isCurrencyAmountVisible = isCurrencyAmountVisible
		}
	}
}

// MARK: - Convenience
public extension AccountList.Row.State {
	init(account: Profile.Account) {
		self.init(
			account: account,
			name: account.name,
			address: account.address,
			aggregatedValue: nil,
			portfolio: .empty,
			currency: .usd,
			isCurrencyAmountVisible: false
		)
	}
}

// MARK: - AccountList.Row.State + Identifiable
extension AccountList.Row.State: Identifiable {
	public typealias ID = Address
	public var id: Address { address }
}

#if DEBUG
public extension AccountList.Row.State {
	static let placeholder: Self = .init(
		account: .init(address: Address(),
		               name: "My account")
	)
}
#endif
