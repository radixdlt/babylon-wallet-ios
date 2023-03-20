import struct AccountPortfolioFetcherClient.AccountPortfolio // TODO: move to some new model package
import FeaturePrelude

// MARK: - AccountList.Row
extension AccountList {
	public struct Row: Sendable, FeatureReducer {
		public struct State: Sendable, Hashable, Identifiable {
			public var id: AccountAddress { account.address }

			public let account: Profile.Network.Account
			public var aggregatedValue: BigDecimal?
			public var portfolio: AccountPortfolio

			// MARK: - AppSettings properties
			public var currency: FiatCurrency
			public var isCurrencyAmountVisible: Bool

			public init(
				account: Profile.Network.Account,
				aggregatedValue: BigDecimal?,
				portfolio: AccountPortfolio,
				currency: FiatCurrency,
				isCurrencyAmountVisible: Bool
			) {
				precondition(account.address == portfolio.owner)
				self.account = account
				self.aggregatedValue = aggregatedValue
				self.portfolio = portfolio
				self.currency = currency
				self.isCurrencyAmountVisible = isCurrencyAmountVisible
			}

			public init(account: Profile.Network.Account) {
				self.init(
					account: account,
					aggregatedValue: nil,
					portfolio: .empty(owner: account.address),
					currency: .usd,
					isCurrencyAmountVisible: false
				)
			}
		}

		public enum ViewAction: Sendable, Equatable {
			case copyAddressButtonTapped
			case tapped
		}

		public init() {}
	}
}
