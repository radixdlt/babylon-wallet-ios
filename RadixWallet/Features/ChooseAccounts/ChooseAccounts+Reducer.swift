import ComposableArchitecture
import SwiftUI

// MARK: - _ChooseAccounts
public struct ChooseAccounts: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		public let selectionRequirement: SelectionRequirement
		public let filteredAccounts: [AccountAddress]
		public var availableAccounts: IdentifiedArrayOf<Account>
		public var selectedAccounts: [ChooseAccountsRow.State]?
		public var canCreateNewAccount: Bool

		@PresentationState
		var destination: Destination.State? = nil

		public init(
			selectionRequirement: SelectionRequirement,
			filteredAccounts: [AccountAddress] = [],
			availableAccounts: IdentifiedArrayOf<Account> = [],
			selectedAccounts: [ChooseAccountsRow.State]? = nil,
			canCreateNewAccount: Bool = true
		) {
			self.selectionRequirement = selectionRequirement
			self.filteredAccounts = filteredAccounts
			self.availableAccounts = availableAccounts
			self.selectedAccounts = selectedAccounts
			self.canCreateNewAccount = canCreateNewAccount
		}
	}

	public enum ViewAction: Sendable, Equatable {
		case appeared
		case createAccountButtonTapped
		case selectedAccountsChanged([ChooseAccountsRow.State]?)
	}

	public enum InternalAction: Sendable, Equatable {
		case loadAccountsResult(TaskResult<IdentifiedArrayOf<Account>>)
	}

	public struct Destination: DestinationReducer {
		public enum State: Sendable, Hashable {
			case createAccount(CreateAccountCoordinator.State)
		}

		public enum Action: Sendable, Equatable {
			case createAccount(CreateAccountCoordinator.Action)
		}

		public var body: some ReducerOf<Self> {
			Scope(state: /State.createAccount, action: /Action.createAccount) {
				CreateAccountCoordinator()
			}
		}
	}

	@Dependency(\.errorQueue) var errorQueue
	@Dependency(\.accountsClient) var accountsClient

	public init() {}

	public var body: some ReducerOf<Self> {
		Reduce(core)
			.ifLet(destinationPath, action: /Action.destination) {
				Destination()
			}
	}

	private let destinationPath: WritableKeyPath<State, PresentationState<Destination.State>> = \.$destination

	public func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
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

	public func reduce(into state: inout State, internalAction: InternalAction) -> Effect<Action> {
		switch internalAction {
		case let .loadAccountsResult(.success(accounts)):
			// Uniqueness is guaranteed as per `Accounts`
			state.availableAccounts = accounts.filter {
				!state.filteredAccounts.contains($0.address)
			}.asIdentified()
			return .none

		case let .loadAccountsResult(.failure(error)):
			errorQueue.schedule(error)
			return .none
		}
	}

	public func reduce(into state: inout State, presentedAction: Destination.Action) -> Effect<Action> {
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
