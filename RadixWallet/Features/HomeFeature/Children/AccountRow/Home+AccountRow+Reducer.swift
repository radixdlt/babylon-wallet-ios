import ComposableArchitecture
import SwiftUI

// MARK: - Home.AccountRow
extension Home {
	public struct AccountRow: Sendable, FeatureReducer {
		public struct State: Sendable, Hashable, Identifiable, AccountWithInfoHolder {
			public var id: AccountAddress { account.address }
			public var accountWithInfo: AccountWithInfo

			public var portfolio: Loadable<AccountPortfoliosClient.AccountPortfolio>
			public var totalFiatWorth: Loadable<FiatWorth>

			public init(
				account: Profile.Network.Account
			) {
				self.accountWithInfo = .init(account: account)
				self.portfolio = .loading
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
			case accountPortfolioUpdate(AccountPortfoliosClient.AccountPortfolio)
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
				if state.portfolio.wrappedValue == nil {
					state.portfolio = .loading
				}

				self.checkAccountAccessToMnemonic(state: &state)

				return .run { send in
					for try await accountPortfolio in await accountPortfoliosClient.portfolioForAccount(accountAddress) {
						guard !Task.isCancelled else {
							return
						}
						await send(.internal(.accountPortfolioUpdate(accountPortfolio)))
					}
				}
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
			case let .accountPortfolioUpdate(portfolio):
				print("Portfolio update called \(portfolio.account.address)")
				state.isDappDefinitionAccount = portfolio.account.metadata.accountType == .dappDefinition

				assert(portfolio.account.address == state.account.address)

				state.portfolio = .success(portfolio)
				state.totalFiatWorth.refresh(from: portfolio.totalFiatWorth)
				return .send(.internal(.checkAccountAccessToMnemonic))

			case .checkAccountAccessToMnemonic:
				checkAccountAccessToMnemonic(state: &state)
				return .none
			}
		}

		private func checkAccountAccessToMnemonic(state: inout State) {
			state.checkAccountAccessToMnemonic(portfolio: state.portfolio.account.wrappedValue)
		}
	}
}
