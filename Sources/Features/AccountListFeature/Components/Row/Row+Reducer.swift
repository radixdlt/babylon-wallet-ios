import AccountPortfoliosClient
import EngineKit
import FactorSourcesClient
import FeaturePrelude

// MARK: - AccountList.Row
extension AccountList {
	public struct Row: Sendable, FeatureReducer {
		public struct State: Sendable, Hashable, Identifiable {
			public var id: AccountAddress { account.address }

			public let account: Profile.Network.Account

			public var portfolio: Loadable<AccountPortfolio>

			public let isLegacyAccount: Bool
			public let isLedgerAccount: Bool
			public var isDappDefinitionAccount: Bool = false
			public var needToBackupMnemonicForThisAccount = false
			public var needToImportMnemonicForThisAccount = false

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
					}
				}()
			}
		}

		public enum ViewAction: Sendable, Equatable {
			case tapped
			case task
			case backUpMnemonic
			case importMnemonic
		}

		public enum InternalAction: Sendable, Equatable {
			case accountPortfolioUpdate(AccountPortfolio)
			case needToBackupMnemonicForThisAccount
		}

		public enum DelegateAction: Sendable, Equatable {
			case tapped(Profile.Network.Account)
			case backUpMnemonic(controlling: Profile.Network.Account)
			case importMnemonics(Profile.Network.Account)
		}

		@Dependency(\.cacheClient) var cacheClient
		@Dependency(\.gatewayAPIClient) var gatewayAPIClient
		@Dependency(\.accountPortfoliosClient) var accountPortfoliosClient
		@Dependency(\.factorSourcesClient) var factorSourcesClient
		@Dependency(\.userDefaultsClient) var userDefaultsClient

		public func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
			switch viewAction {
			case .task:
				let accountAddress = state.account.address
				state.portfolio = .loading
				let accounts = userDefaultsClient.getAddressesOfAccountsThatNeedRecovery()
				state.needToBackupMnemonicForThisAccount = accounts.contains(where: { $0 == accountAddress })

				return .run { send in
					for try await accountPortfolio in await accountPortfoliosClient.portfolioForAccount(accountAddress) {
						guard !Task.isCancelled else {
							return
						}
						await send(.internal(.accountPortfolioUpdate(accountPortfolio.nonEmptyVaults)))
					}
				}
			case .backUpMnemonic:
				return .send(.delegate(.backUpMnemonic(controlling: state.account)))

			case .importMnemonic:
				return .send(.delegate(.importMnemonics(state.account)))

			case .tapped:
				return .send(.delegate(.tapped(state.account)))
			}
		}

		public func reduce(into state: inout State, internalAction: InternalAction) -> EffectTask<Action> {
			switch internalAction {
			case .needToBackupMnemonicForThisAccount:
				state.needToBackupMnemonicForThisAccount = true
				return .none
			case let .accountPortfolioUpdate(portfolio):
				state.isDappDefinitionAccount = portfolio.isDappDefintionAccountType
				assert(portfolio.owner == state.account.address)
				state.portfolio = .success(portfolio)

				guard let xrdResource = portfolio.fungibleResources.xrdResource, xrdResource.amount > .zero else {
					state.needToBackupMnemonicForThisAccount = false
					return .none
				}

				switch state.account.securityState {
				case let .unsecured(unsecuredEntityControl):
					if unsecuredEntityControl.transactionSigning.factorSourceID.kind == .device {
						return .send(.internal(.needToBackupMnemonicForThisAccount))
					} else {
						return .none
					}
				}
			}
		}
	}
}
