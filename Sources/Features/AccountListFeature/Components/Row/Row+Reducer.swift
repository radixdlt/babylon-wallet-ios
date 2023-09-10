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

			public struct DeviceFactorSourceControlled: Sendable, Hashable {
				public var needToBackupMnemonicForThisAccount = false
				public var needToImportMnemonicForThisAccount = false
			}

			public var deviceFactorSourceControlled: DeviceFactorSourceControlled?

			public var hasValue: Bool = false

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

				switch account.securityState {
				case let .unsecured(unsecuredEntityControl):
					if unsecuredEntityControl.transactionSigning.factorSourceID.kind == .device {
						self.deviceFactorSourceControlled = .init()
					}
				}
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
		}

		public enum DelegateAction: Sendable, Equatable {
			case tapped(
				Profile.Network.Account,
				needToBackupMnemonicForThisAccount: Bool,
				needToImportMnemonicForThisAccount: Bool
			)
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

				checkIfCallActionIsNeeded(state: &state)

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
				return .send(.delegate(.tapped(
					state.account,
					needToBackupMnemonicForThisAccount: state.deviceFactorSourceControlled?.needToBackupMnemonicForThisAccount ?? false,
					needToImportMnemonicForThisAccount: state.deviceFactorSourceControlled?.needToImportMnemonicForThisAccount ?? false
				)))
			}
		}

		public func reduce(into state: inout State, internalAction: InternalAction) -> EffectTask<Action> {
			switch internalAction {
			case let .accountPortfolioUpdate(portfolio):

				// FIXME: Refactor account security prompts to share logic between this reducer and AccountDetails

				state.isDappDefinitionAccount = portfolio.isDappDefintionAccountType
				assert(portfolio.owner == state.account.address)
				state.portfolio = .success(portfolio)

				if let xrdResource = portfolio.fungibleResources.xrdResource {
					state.hasValue = xrdResource.amount > 0
				} else {
					state.hasValue = false
				}

				// FIXME: This is lazy code... we "piggyback" on the fact that `accountPortfolioUpdate` happens frequently.. as a means to update state.
				checkIfCallActionIsNeeded(state: &state)

				return .none
			}
		}

		// FIXME: Refactor account security prompts to share logic between this reducer and AccountDetails
		private func checkIfCallActionIsNeeded(state: inout State) {
			guard state.deviceFactorSourceControlled != nil else { return }

			let isRecoveryOfMnemonicNeeded = userDefaultsClient
				.getAddressesOfAccountsThatNeedRecovery()
				.contains(where: { $0 == state.account.address })

			state.deviceFactorSourceControlled?.needToImportMnemonicForThisAccount = isRecoveryOfMnemonicNeeded

			switch state.account.securityState {
			case let .unsecured(unsecuredEntityControl):
				let hasAlreadyBackedUpMnemonic = userDefaultsClient.getFactorSourceIDOfBackedUpMnemonics().contains(unsecuredEntityControl.transactionSigning.factorSourceID)

				state.deviceFactorSourceControlled?.needToBackupMnemonicForThisAccount = !hasAlreadyBackedUpMnemonic && state.hasValue
			}
		}
	}
}
