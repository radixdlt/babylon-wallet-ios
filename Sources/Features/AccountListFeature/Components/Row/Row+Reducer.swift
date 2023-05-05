import AccountPortfoliosClient
import FactorSourcesClient
import FeaturePrelude

// MARK: - AccountList.Row
extension AccountList {
	public struct Row: Sendable, FeatureReducer {
		public struct State: Sendable, Hashable, Identifiable {
			public var id: AccountAddress { account.address }

			public let account: Profile.Network.Account

			public var portfolio: Loadable<AccountPortfolio>

			public var shouldShowSecurityPrompt = false

			public init(
				account: Profile.Network.Account
			) {
				self.account = account
				self.portfolio = .loading
			}
		}

		public enum ViewAction: Sendable, Equatable {
			case tapped
			case task
			case securityPromptTapped
		}

		public enum InternalAction: Sendable, Equatable {
			case accountPortfolioUpdate(AccountPortfolio)
			case displaySecurityPrompting
		}

		public enum DelegateAction: Sendable, Equatable {
			case tapped(Profile.Network.Account)
			case securityPromptTapped(Profile.Network.Account)
		}

		public init() {}

		@Dependency(\.accountPortfoliosClient) var accountPortfoliosClient
		@Dependency(\.factorSourcesClient) var factorSourcesClient

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
			case .securityPromptTapped:
				return .send(.delegate(.securityPromptTapped(state.account)))
			case .tapped:
				return .send(.delegate(.tapped(state.account)))
			}
		}

		public func reduce(into state: inout State, internalAction: InternalAction) -> EffectTask<Action> {
			switch internalAction {
			case .displaySecurityPrompting:
				state.shouldShowSecurityPrompt = true
				return .none
			case let .accountPortfolioUpdate(portfolio):
				assert(portfolio.owner == state.account.address)
				state.portfolio = .success(portfolio)

				guard let xrdResource = portfolio.fungibleResources.xrdResource, xrdResource.amount > .zero else {
					state.shouldShowSecurityPrompt = false
					return .none
				}

				return checkIfDeviceFactorSourceControls(factorInstance: state.account.factorInstance)
			}
		}

		private func checkIfDeviceFactorSourceControls(factorInstance: FactorInstance) -> EffectTask<Action> {
			.run { send in
				guard
					let factorSource = try await factorSourcesClient.getFactorSource(of: factorInstance)
				else {
					loggerGlobal.warning("Did not find factor source for factor instance.")
					return
				}
				guard factorSource.kind == .device else {
					// probably ledger account
					return
				}
				await send(.internal(.displaySecurityPrompting))
			}
		}
	}
}
