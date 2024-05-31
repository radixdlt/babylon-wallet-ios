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
			public var entitySecurityProblems: EntitySecurityProblems.State

			public init(
				account: Account
			) {
				self.accountWithInfo = .init(account: account)
				self.accountWithResources = .loading
				self.totalFiatWorth = .loading
				self.entitySecurityProblems = .init(kind: .account(account.address))
			}
		}

		public enum ViewAction: Sendable, Equatable {
			case tapped
		}

		public enum InternalAction: Sendable, Equatable {
			case accountUpdated(OnLedgerEntity.OnLedgerAccount)
			case fiatWorthUpdated(Loadable<FiatWorth>)
		}

		public enum DelegateAction: Sendable, Equatable {
			case openDetails
			case openSecurityCenter
		}

		@CasePathable
		public enum ChildAction: Sendable, Equatable {
			case entitySecurityProblems(EntitySecurityProblems.Action)
		}

		@Dependency(\.accountPortfoliosClient) var accountPortfoliosClient
		@Dependency(\.secureStorageClient) var secureStorageClient
		@Dependency(\.userDefaults) var userDefaults

		public var body: some ReducerOf<Self> {
			Scope(state: \.entitySecurityProblems, action: \.child.entitySecurityProblems) {
				EntitySecurityProblems()
			}
			Reduce(core)
		}

		public func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
			switch viewAction {
			case .tapped:
				.send(.delegate(.openDetails))
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

		public func reduce(into state: inout State, childAction: ChildAction) -> Effect<Action> {
			switch childAction {
			case .entitySecurityProblems(.delegate(.openSecurityCenter)):
				.send(.delegate(.openSecurityCenter))
			default:
				.none
			}
		}
	}
}
