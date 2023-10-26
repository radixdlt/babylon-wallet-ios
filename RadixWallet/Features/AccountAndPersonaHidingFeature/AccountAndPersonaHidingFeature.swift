import Foundation

// MARK: - AccountAndPersonaHiding
public struct AccountAndPersonaHiding: FeatureReducer {
	@Dependency(\.accountsClient) var accountsClient
	@Dependency(\.personasClient) var personasClient

	public struct State: Hashable, Sendable {
		public var hiddenAccounts: IdentifiedArrayOf<Profile.Network.Account> = []
		public var hiddenPersonas: IdentifiedArrayOf<Profile.Network.Persona> = []
	}

	public enum ViewAction: Hashable, Sendable {
		case task
		case unhideAllTapped
	}

	public enum InternalAction: Hashable, Sendable {
		case hiddenAccountsLoaded(IdentifiedArrayOf<Profile.Network.Account>)
		case hiddenPersonasLoaded([Profile.Network.Persona])
	}

	public func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .task:
			.run { send in
				let hiddenAccounts = await accountsClient.getHiddenAccountsOnAllNetworks()
				await send(.internal(.hiddenAccountsLoaded(hiddenAccounts)))
			}
		case .unhideAllTapped:
			.run { [accounts = state.hiddenAccounts] _ in
				var accounts = accounts
				for account in accounts {
					accounts[id: account.id]?.unhide()
				}
				try await accountsClient.updateAccounts(accounts)
			}
		}
	}

	public func reduce(into state: inout State, internalAction: InternalAction) -> Effect<Action> {
		switch internalAction {
		case let .hiddenAccountsLoaded(array):
			state.hiddenAccounts = array
			return .none
		case let .hiddenPersonasLoaded(array):
			return .none
		}
	}
}

extension AccountAndPersonaHiding.State {
	var viewState: AccountAndPersonaHiding.ViewState {
		.init(numberOfHiddenAccounts: hiddenAccounts.count, numberOfHiddenPersonas: hiddenPersonas.count)
	}
}

extension AccountAndPersonaHiding {
	public struct ViewState: Equatable {
		let numberOfHiddenAccounts: Int
		let numberOfHiddenPersonas: Int
	}

	public struct View: SwiftUI.View {
		public let store: StoreOf<AccountAndPersonaHiding>

		public var body: some SwiftUI.View {
			WithViewStore(store, observe: \.viewState) { viewStore in
				VStack {
					Text("\(viewStore.numberOfHiddenAccounts) hidden Accounts")

					Button("Unhide All") {
						viewStore.send(.view(.unhideAllTapped))
					}
				}
				.task { @MainActor in
					await viewStore.send(.view(.task)).finish()
				}
			}
		}
	}
}
