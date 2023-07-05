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
			public let isLegacyAccount: Bool
			public let isLedgerAccount: Bool
			public var isDappDefinitionAccount: Bool = false

			public init(
				account: Profile.Network.Account
			) {
				self.account = account
				self.portfolio = .loading
				self.isLegacyAccount = account.isOlympiaAccount

				self.isLedgerAccount = {
					switch account.securityState {
					case let .unsecured(unsecuredEntityControl):
						return unsecuredEntityControl.transactionSigning.factorInstance.factorSourceID.kind == .ledgerHQHardwareWallet
					case let .securified(securified):
						let adminFactors = securified.transactionSigningStructure.primaryRole.superAdminFactors
						let thresholdFactors = securified.transactionSigningStructure.primaryRole.thresholdFactors
						return adminFactors.count == 1 && adminFactors.first?.factorSourceKind == .ledgerHQHardwareWallet || thresholdFactors.count == 1 && thresholdFactors.first?.factorSourceKind == .ledgerHQHardwareWallet
					}
				}()
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

		@Dependency(\.cacheClient) var cacheClient
		@Dependency(\.gatewayAPIClient) var gatewayAPIClient
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
						await send(.internal(.accountPortfolioUpdate(accountPortfolio.nonEmptyVaults)))
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
				state.isDappDefinitionAccount = portfolio.isDappDefintionAccountType
				assert(portfolio.owner == state.account.address)
				state.portfolio = .success(portfolio)

				guard let xrdResource = portfolio.fungibleResources.xrdResource, xrdResource.amount > .zero else {
					state.shouldShowSecurityPrompt = false
					return .none
				}

				switch state.account.securityState {
				case let .unsecured(unsecuredEntityControl):
					if unsecuredEntityControl.transactionSigning.factorSourceID.kind == .device {
						return .send(.internal(.displaySecurityPrompting))
					} else {
						return .none
					}
				case .securified:
					return .none
				}
			}
		}
	}
}
