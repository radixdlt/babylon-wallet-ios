import ComposableArchitecture
import Sargon
import SwiftUI

// MARK: - Home.AccountRow
extension Home {
	struct AccountRow: Sendable, FeatureReducer {
		struct State: Sendable, Hashable, Identifiable, AccountWithInfoHolder {
			var id: AccountAddress { account.address }
			var accountWithInfo: AccountWithInfo

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
		}

		@Dependency(\.accountPortfoliosClient) var accountPortfoliosClient
		@Dependency(\.secureStorageClient) var secureStorageClient
		@Dependency(\.userDefaults) var userDefaults
		@Dependency(\.accountLockersClient) var accountLockersClient

		func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
			switch viewAction {
			case .tapped:
				.send(.delegate(.openDetails))
			case .securityProblemsTapped:
				.send(.delegate(.openSecurityCenter))
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
	}
}
