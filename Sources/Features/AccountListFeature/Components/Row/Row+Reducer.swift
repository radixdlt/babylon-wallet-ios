import AccountPortfoliosClient
import FeaturePrelude

// MARK: - AccountList.Row
extension AccountList {
	public struct Row: Sendable, FeatureReducer {
		public struct State: Sendable, Hashable, Identifiable {
			public var id: AccountAddress { account.address }

			public let account: Profile.Network.Account

			public var portfolio: Loadable<AccountPortfolio>

			public init(
				account: Profile.Network.Account
			) {
				self.account = account
				self.portfolio = .loading
			}
		}

		public enum ViewAction: Sendable, Equatable {
			case copyAddressButtonTapped
			case tapped
			case task
			case securityPromptTapped
		}

		public enum InternalAction: Sendable, Equatable {
			case accountPortfolioUpdate(AccountPortfolio)
		}

		public enum DelegateAction: Sendable, Equatable {
			case copyAddressButtonTapped(Profile.Network.Account)
			case tapped(Profile.Network.Account)
			case securityPrompTaped(Profile.Network.Account)
		}

		public init() {}

		@Dependency(\.accountPortfoliosClient) var accountPortfoliosClient

		public func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
			switch viewAction {
			case .task:
				let accountAddress = state.account.address
				state.portfolio = .loading
				return .run { send in
					for try await accountPortfolio in await accountPortfoliosClient.portfolioForAccount(accountAddress) {
						guard !Task.isCancelled else {
							return
						}
						await send(.internal(.accountPortfolioUpdate(accountPortfolio)))
					}
				}
			case .copyAddressButtonTapped:
				return .send(.delegate(.copyAddressButtonTapped(state.account)))
			case .securityPromptTapped:
				return .send(.delegate(.securityPrompTaped(state.account)))
			case .tapped:
				return .send(.delegate(.tapped(state.account)))
			}
		}

		public func reduce(into state: inout State, internalAction: InternalAction) -> EffectTask<Action> {
			switch internalAction {
			case let .accountPortfolioUpdate(portfolio):
				state.portfolio = .success(portfolio)
				return .none
			}
		}
	}
}
