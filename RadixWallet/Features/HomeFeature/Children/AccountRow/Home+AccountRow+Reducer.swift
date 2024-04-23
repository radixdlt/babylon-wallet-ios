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

			public init(
				account: Account
			) {
				self.accountWithInfo = .init(account: account)
				self.accountWithResources = .loading
				self.totalFiatWorth = .loading
			}
		}

		public enum ViewAction: Sendable, Equatable {
			case tapped
			case task
			case importMnemonicButtonTapped
			case exportMnemonicButtonTapped
		}

		public enum InternalAction: Sendable, Equatable {
			case accountUpdated(OnLedgerEntity.OnLedgerAccount)
			case fiatWorthUpdated(Loadable<FiatWorth>)
			case checkAccountAccessToMnemonic
		}

		public enum DelegateAction: Sendable, Equatable {
			case openDetails
			case exportMnemonic
			case importMnemonics
		}

		@Dependency(\.accountPortfoliosClient) var accountPortfoliosClient
		@Dependency(\.secureStorageClient) var secureStorageClient
		@Dependency(\.userDefaults) var userDefaults

		public func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
			switch viewAction {
			case .task:
				self.checkAccountAccessToMnemonic(state: &state)

				return .none

			case .exportMnemonicButtonTapped:
				return .send(.delegate(.exportMnemonic))

			case .importMnemonicButtonTapped:
				return .send(.delegate(.importMnemonics))

			case .tapped:
				return .send(.delegate(.openDetails))
			}
		}

		public func reduce(into state: inout State, internalAction: InternalAction) -> Effect<Action> {
			switch internalAction {
			case let .accountUpdated(account):
				assert(account.address == state.account.address)

				state.isDappDefinitionAccount = account.metadata.accountType == .dappDefinition
				state.accountWithResources.refresh(from: .success(account))

				return .send(.internal(.checkAccountAccessToMnemonic))

			case .checkAccountAccessToMnemonic:
				checkAccountAccessToMnemonic(state: &state)
				return .none

			case let .fiatWorthUpdated(fiatWorth):
				state.totalFiatWorth.refresh(from: fiatWorth)
				return .none
			}
		}

		private func checkAccountAccessToMnemonic(state: inout State) {
			state.checkAccountAccessToMnemonic(portfolio: state.accountWithResources.wrappedValue)
		}
	}
}
