import ComposableArchitecture
import Sargon
import SwiftUI

// MARK: - Home.AccountRow
extension Home {
	public struct AccountRow: Sendable, FeatureReducer {
		public struct State: Sendable, Hashable, Identifiable, AccountWithInfoHolder {
			public var id: AccountAddress { account.address }
			public var accountWithInfo: AccountWithInfo

			public var accountWithResources: Loadable<OnLedgerEntity.OnLedgerAccount>
			public var showFiatWorth: Bool = true
			public var totalFiatWorth: Loadable<FiatWorth>
			public var securityProblemsConfig: EntitySecurityProblemsView.Config
			public var accountLockerClaims: [AccountLockerClaimDetails] = []

			public init(
				account: Account,
				problems: [SecurityProblem]
			) {
				self.accountWithInfo = .init(account: account)
				self.accountWithResources = .loading
				self.totalFiatWorth = .loading
				self.securityProblemsConfig = .init(kind: .account(account.address), problems: problems)
			}
		}

		public enum ViewAction: Sendable, Equatable {
			case tapped
			case securityProblemsTapped
			case accountLockerClaimTapped(AccountLockerClaimDetails)
		}

		public enum InternalAction: Sendable, Equatable {
			case accountUpdated(OnLedgerEntity.OnLedgerAccount)
			case fiatWorthUpdated(Loadable<FiatWorth>)
		}

		public enum DelegateAction: Sendable, Equatable {
			case openDetails
			case openSecurityCenter
		}

		@Dependency(\.accountPortfoliosClient) var accountPortfoliosClient
		@Dependency(\.secureStorageClient) var secureStorageClient
		@Dependency(\.userDefaults) var userDefaults
		@Dependency(\.accountLockersClient) var accountLockersClient

		public func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
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

		public func reduce(into state: inout State, internalAction: InternalAction) -> Effect<Action> {
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
