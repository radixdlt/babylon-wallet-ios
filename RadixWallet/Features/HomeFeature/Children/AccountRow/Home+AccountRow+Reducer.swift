import ComposableArchitecture
import SwiftUI

// MARK: - Home.AccountRow
extension Home {
	public struct AccountRow: Sendable, FeatureReducer {
		public struct State: Sendable, Hashable, Identifiable, AccountWithInfoHolder {
			public var id: AccountAddress { account.address }
			public var accountWithInfo: AccountWithInfo

			public var accountWithResources: Loadable<OnLedgerEntity.Account>
			public var showFiatWorth: Bool = true
			public var totalFiatWorth: Loadable<FiatWorth>

			public init(
				account: Profile.Network.Account
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
			case accountUpdated(OnLedgerEntity.Account)
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
				let accountAddress = state.account.address
				self.checkAccountAccessToMnemonic(state: &state)

				return .run { send in
					for try await accountPortfolio in await accountPortfoliosClient.portfolioForAccount(accountAddress).map(\.account).removeDuplicates() {
						guard !Task.isCancelled else {
							return
						}
						// if portfolio != .success(accountPortfolio) {
						await send(.internal(.accountUpdated(accountPortfolio)))
						//  }
					}
				}
				.merge(with: .run { send in
					for try await fiatWorth in await accountPortfoliosClient.portfolioForAccount(accountAddress).map(\.totalFiatWorth).removeDuplicates() {
						guard !Task.isCancelled else {
							return
						}
						// if portfolio != .success(accountPortfolio) {
						await send(.internal(.fiatWorthUpdated(fiatWorth)))
						//  }
					}
				})
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
