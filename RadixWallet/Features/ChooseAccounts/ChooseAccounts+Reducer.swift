import ComposableArchitecture
import SwiftUI

// MARK: - ChooseAccounts
struct ChooseAccounts: FeatureReducer {
	struct State: Hashable {
		let context: Context
		let filteredAccounts: [AccountAddress]
		let disabledAccounts: [AccountAddress]
		var availableAccounts: IdentifiedArrayOf<Account>
		var selectedAccounts: [ChooseAccountsRow.State]?
		var canCreateNewAccount: Bool
		let showSelectAllAccounts: Bool

		@PresentationState
		var destination: Destination.State? = nil

		var selectionRequirement: SelectionRequirement {
			switch context {
			case .assetTransfer, .applyShield:
				.exactly(1)
			case let .permission(selectionRequirement):
				selectionRequirement
			}
		}

		init(
			context: Context,
			filteredAccounts: [AccountAddress] = [],
			disabledAccounts: [AccountAddress] = [],
			availableAccounts: IdentifiedArrayOf<Account> = [],
			selectedAccounts: [ChooseAccountsRow.State]? = nil,
			canCreateNewAccount: Bool = true,
			showSelectAllAccounts: Bool = false
		) {
			self.context = context
			self.filteredAccounts = filteredAccounts
			self.disabledAccounts = disabledAccounts
			self.availableAccounts = availableAccounts
			self.selectedAccounts = selectedAccounts
			self.canCreateNewAccount = canCreateNewAccount
			self.showSelectAllAccounts = showSelectAllAccounts
		}
	}

	enum ViewAction: Equatable {
		case appeared
		case createAccountButtonTapped
		case selectedAccountsChanged([ChooseAccountsRow.State]?)
	}

	enum InternalAction: Equatable {
		case loadAccountsResult(TaskResult<Accounts>)
	}

	struct Destination: DestinationReducer {
		enum State: Hashable {
			case createAccount(CreateAccountCoordinator.State)
		}

		enum Action: Equatable {
			case createAccount(CreateAccountCoordinator.Action)
		}

		var body: some ReducerOf<Self> {
			Scope(state: /State.createAccount, action: /Action.createAccount) {
				CreateAccountCoordinator()
			}
		}
	}

	@Dependency(\.errorQueue) var errorQueue
	@Dependency(\.accountsClient) var accountsClient

	init() {}

	var body: some ReducerOf<Self> {
		Reduce(core)
			.ifLet(\.$destination, action: \.destination) {
				Destination()
			}
	}

	func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .appeared:
			return loadAccounts()

		case .createAccountButtonTapped:
			state.destination = .createAccount(.init(
				config: .init(purpose: .newAccountDuringDappInteraction)
			))
			return .none

		case let .selectedAccountsChanged(selectedAccounts):
			state.selectedAccounts = selectedAccounts
			return .none
		}
	}

	func reduce(into state: inout State, internalAction: InternalAction) -> Effect<Action> {
		switch internalAction {
		case let .loadAccountsResult(.success(accounts)):
			// Uniqueness is guaranteed as per `Accounts`
			state.availableAccounts = accounts
				.filter {
					!state.filteredAccounts.contains($0.address)
				}
				.sorted {
					!state.disabledAccounts.contains($0.address)
						&& state.disabledAccounts.contains($1.address)
				}
				.asIdentified()

			if state.context == .applyShield {
				state.availableAccounts = state.availableAccounts.filter {
					switch $0.securityState {
					case .unsecured:
						true
					case .securified:
						false
					}
				}
			}
			return .none

		case let .loadAccountsResult(.failure(error)):
			errorQueue.schedule(error)
			return .none
		}
	}

	func reduce(into state: inout State, presentedAction: Destination.Action) -> Effect<Action> {
		switch presentedAction {
		case .createAccount(.delegate(.completed)):
			loadAccounts()

		default:
			.none
		}
	}

	private func loadAccounts() -> Effect<Action> {
		.run { send in
			let result = await TaskResult {
				try await accountsClient.getAccountsOnCurrentNetwork()
			}
			await send(.internal(.loadAccountsResult(result)))
		}
	}
}

// MARK: - ChooseAccounts.State.Context
extension ChooseAccounts.State {
	enum Context: Hashable {
		case assetTransfer
		case permission(SelectionRequirement)
		case applyShield
	}
}
