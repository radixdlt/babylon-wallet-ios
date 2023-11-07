import ComposableArchitecture
import SwiftUI

// MARK: - Home.AccountRow
extension Home {
	public struct AccountRow: Sendable, FeatureReducer {
		public struct State: Sendable, Hashable, Identifiable, AccountWithInfoHolder {
			public var id: AccountAddress { account.address }
			public var accountWithInfo: AccountWithInfo

			public var portfolio: Loadable<OnLedgerEntity.Account>

			public init(
				account: Profile.Network.Account
			) {
				self.accountWithInfo = .init(account: account)
				self.portfolio = .loading
			}
		}

		public enum ViewAction: Sendable, Equatable {
			case tapped
			case task
			case exportMnemonic
			case importMnemonic
		}

		public enum InternalAction: Sendable, Equatable {
			case accountPortfolioUpdate(OnLedgerEntity.Account)
			case checkAccountAccessToMnemonic
		}

		public enum DelegateAction: Sendable, Equatable {
			case openDetails
			case exportMnemonic
			case importMnemonics
		}

		@Dependency(\.accountPortfoliosClient) var accountPortfoliosClient
		@Dependency(\.secureStorageClient) var secureStorageClient
		@Dependency(\.userDefaultsClient) var userDefaultsClient

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
						loggerGlobal.critical("🔮 \(Self.self) account portfolio updated, address: \(accountAddress)")
						await send(.internal(.accountPortfolioUpdate(accountPortfolio.nonEmptyVaults)))
					}
				}
			case .exportMnemonic:
				return .send(.delegate(.exportMnemonic))

			case .importMnemonic:
				return .send(.delegate(.importMnemonics))

			case .tapped:
				return .send(.delegate(.openDetails))
			}
		}

		public func reduce(into state: inout State, internalAction: InternalAction) -> Effect<Action> {
			switch internalAction {
			case let .accountPortfolioUpdate(portfolio):
				state.isDappDefinitionAccount = portfolio.metadata.accountType == .dappDefinition

				assert(portfolio.address == state.account.address)

				state.portfolio = .success(portfolio)
				return .send(.internal(.checkAccountAccessToMnemonic))

			case .checkAccountAccessToMnemonic:
				checkAccountAccessToMnemonic(state: &state)
				return .none
			}
		}

		private func checkAccountAccessToMnemonic(state: inout State) {
			state.checkAccountAccessToMnemonic(portfolio: state.portfolio.wrappedValue)
		}
	}
}
