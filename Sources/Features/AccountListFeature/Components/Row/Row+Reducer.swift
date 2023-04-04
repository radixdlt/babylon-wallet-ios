import struct AccountPortfolioFetcherClient.AccountPortfolio // TODO: move to some new model package
import AccountsClient
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

			public var needsAccountRecovery: Bool?

			public init(
				account: Profile.Network.Account,
				needsAccountRecovery: Bool? = nil,
				aggregatedValue: BigDecimal?,
				portfolio: AccountPortfolio,
				currency: FiatCurrency,
				isCurrencyAmountVisible: Bool
			) {
				precondition(account.address == portfolio.owner)
				self.account = account
				self.needsAccountRecovery = needsAccountRecovery
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
			case appeared
			case copyAddressButtonTapped
			case tapped
		}

		public enum InternalAction: Sendable, Equatable {
			case needsAccountRecovery(Bool)
		}

		public enum DelegateAction: Sendable, Equatable {
			case copyAddress
			case selected
		}

		@Dependency(\.accountsClient) var accountsClient

		public init() {}

		public var body: some ReducerProtocolOf<Self> {
			Reduce(core)
		}

		public func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
			switch viewAction {
			case .appeared:
				return .run { [account = state.account] send in
					let needsAccountRecovery = await accountsClient.checkIfNeedsAccountRecovery(account)
					await send(.internal(.needsAccountRecovery(needsAccountRecovery)))
				}
			case .copyAddressButtonTapped:
				return .send(.delegate(.copyAddress))
			case .tapped:
				return .send(.delegate(.selected))
			}
		}

		public func reduce(into state: inout State, internalAction: InternalAction) -> EffectTask<Action> {
			switch internalAction {
			case let .needsAccountRecovery(needsAccountRecovery):
				state.needsAccountRecovery = needsAccountRecovery
				return .none
			}
		}
	}
}
