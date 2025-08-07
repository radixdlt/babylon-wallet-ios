import ComposableArchitecture
import Sargon
import SwiftUI

// MARK: - Home.AccountRow
extension Home {
	struct AccountRow: Sendable, FeatureReducer {
		struct State: Sendable, Hashable, Identifiable, AccountWithInfoHolder {
			var id: AccountAddress { account.address }
			var accountWithInfo: AccountWithInfo
			var factorSource: FactorSource?

			var accountWithResources: Loadable<OnLedgerEntity.OnLedgerAccount>
			var showFiatWorth: Bool = true
			var totalFiatWorth: Loadable<FiatWorth>
			var securityProblemsConfig: EntitySecurityProblemsView.Config
			var accountLockerClaims: [AccountLockerClaimDetails] = []

			init(
				account: Account,
				problems: [SecurityProblem]
			) {
				self.accountWithInfo = .init(account: account)
				self.accountWithResources = .loading
				self.totalFiatWorth = .loading
				self.securityProblemsConfig = .init(kind: .account(account.address), problems: problems)
			}
		}

		enum ViewAction: Sendable, Equatable {
			case tapped
			case securityProblemsTapped
			case accountLockerClaimTapped(AccountLockerClaimDetails)
		}

		enum InternalAction: Sendable, Equatable {
			case accountUpdated(OnLedgerEntity.OnLedgerAccount)
			case fiatWorthUpdated(Loadable<FiatWorth>)
		}

		enum DelegateAction: Sendable, Equatable {
			case openDetails
			case openSecurityCenter
			case displayMnemonic(DisplayMnemonic.State)
			case enterMnemonic(ImportMnemonicForFactorSource.State)
		}

		@Dependency(\.accountPortfoliosClient) var accountPortfoliosClient
		@Dependency(\.secureStorageClient) var secureStorageClient
		@Dependency(\.userDefaults) var userDefaults
		@Dependency(\.accountLockersClient) var accountLockersClient
		@Dependency(\.factorSourcesClient) var factorSourcesClient

		func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
			switch viewAction {
			case .tapped:
				.send(.delegate(.openDetails))
			case .securityProblemsTapped:
				handleSecurityProblems(state)
			case let .accountLockerClaimTapped(details):
				.run { _ in
					try await accountLockersClient.claimContent(details)
				} catch: { error, _ in
					loggerGlobal.error("Account locker claim failed, error: \(error)")
				}
			}
		}

		func reduce(into state: inout State, internalAction: InternalAction) -> Effect<Action> {
			switch internalAction {
			case let .accountUpdated(account):
				assert(account.address == state.account.address)

				state.isDappDefinitionAccount = account.metadata.accountType == .dappDefinition
				state.accountWithResources.refresh(from: .success(account))

				return .none

			case let .fiatWorthUpdated(fiatWorth):
				state.totalFiatWorth.refresh(from: fiatWorth)
				return .none
			}
		}

		private func handleSecurityProblems(_ state: State) -> Effect<Action> {
			let problems = state.securityProblemsConfig.problems
			let accountAddress = state.account.address

			// Find the specific security problem for this account
			for problem in problems {
				switch problem {
				case let .problem3(addresses) where accountHasProblem(accountAddress, in: addresses):
					return handleProblem3ForAccount(state.account)

				case let .problem9(addresses) where accountHasProblem(accountAddress, in: addresses):
					return handleProblem9ForAccount(state.account)

				default:
					continue
				}
			}

			return .send(.delegate(.openSecurityCenter))
		}

		private func accountHasProblem(_ accountAddress: AccountAddress, in addresses: AddressesOfEntitiesInBadState) -> Bool {
			addresses.accounts.contains(accountAddress) || addresses.hiddenAccounts.contains(accountAddress)
		}

		private func handleProblem3ForAccount(_ account: Account) -> Effect<Action> {
			guard let factorInstance = account.unsecuredControllingFactorInstance?.factorInstance else {
				return .send(.delegate(.openSecurityCenter))
			}

			return .run { send in
				do {
					if let factorSource = try await factorSourcesClient.getFactorSource(of: factorInstance) {
						let integrity = try await SargonOS.shared.factorSourceIntegrity(factorSource: factorSource)
						if let factorSourceId = integrity.factorSourceIdOfMnemonicToExport,
						   let mnemonicWithPassphrase = try secureStorageClient.loadMnemonic(
						   	factorSourceID: factorSourceId,
						   	notifyIfMissing: true
						   )
						{
							await send(.delegate(.displayMnemonic(.init(
								mnemonic: mnemonicWithPassphrase.mnemonic,
								factorSourceID: factorSourceId
							))))
							return
						}
					}
					await send(.delegate(.openSecurityCenter))
				} catch {
					loggerGlobal.error("Failed to handle problem3: \(error), falling back to SecurityCenter")
					await send(.delegate(.openSecurityCenter))
				}
			}
		}

		private func handleProblem9ForAccount(_ account: Account) -> Effect<Action> {
			guard let factorInstance = account.unsecuredControllingFactorInstance?.factorInstance else {
				return .send(.delegate(.openSecurityCenter))
			}

			return .run { send in
				do {
					if let factorSource = try await factorSourcesClient.getFactorSource(of: factorInstance),
					   let deviceFactorSource = factorSource.asDevice
					{
						await send(.delegate(.enterMnemonic(.init(
							deviceFactorSource: deviceFactorSource,
							profileToCheck: .current
						))))
					} else {
						await send(.delegate(.openSecurityCenter))
					}
				} catch {
					loggerGlobal.error("Failed to handle problem9: \(error), falling back to SecurityCenter")
					await send(.delegate(.openSecurityCenter))
				}
			}
		}
	}
}
