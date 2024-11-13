import ComposableArchitecture
import SwiftUI

// MARK: - ChooseAccounts
struct ChooseAccounts: Sendable, FeatureReducer {
	struct State: Sendable, Hashable {
		let context: Context
		let filteredAccounts: [AccountAddress]
		var selectedAccounts: [ChooseAccountsRow.State]?
		var availableAccounts: Loadable<IdentifiedArrayOf<AccountType>>
		var canCreateNewAccount: Bool

		@PresentationState
		var destination: Destination.State? = nil

		var selectionRequirement: SelectionRequirement {
			switch context {
			case .assetTransfer, .accountDeletion:
				.exactly(1)
			case let .permission(selectionRequirement):
				selectionRequirement
			}
		}

		init(
			context: Context,
			filteredAccounts: [AccountAddress] = [],
			selectedAccounts: [ChooseAccountsRow.State]? = nil,
			availableAccounts: Loadable<IdentifiedArrayOf<AccountType>> = .idle,
			canCreateNewAccount: Bool = true
		) {
			self.context = context
			self.filteredAccounts = filteredAccounts
			self.availableAccounts = availableAccounts
			self.selectedAccounts = selectedAccounts
			self.canCreateNewAccount = canCreateNewAccount
		}
	}

	enum ViewAction: Sendable, Equatable {
		case appeared
		case createAccountButtonTapped
		case selectedAccountsChanged([ChooseAccountsRow.State]?)
	}

	enum InternalAction: Sendable, Equatable {
		case loadAccountsResult(TaskResult<IdentifiedArrayOf<State.AccountType>>)
	}

	struct Destination: DestinationReducer {
		enum State: Sendable, Hashable {
			case createAccount(CreateAccountCoordinator.State)
		}

		enum Action: Sendable, Equatable {
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
	@Dependency(\.onLedgerEntitiesClient) var onLedgerEntitiesClient

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
			if state.availableAccounts == .idle {
				state.availableAccounts = .loading
			}
			return loadAccounts(context: state.context)

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
			state.availableAccounts = .success(
				accounts.filter {
					!state.filteredAccounts.contains($0.account.address)
				}.asIdentified()
			)
			return .none

		case let .loadAccountsResult(.failure(error)):
			errorQueue.schedule(error)
			return .none
		}
	}

	func reduce(into state: inout State, presentedAction: Destination.Action) -> Effect<Action> {
		switch presentedAction {
		case .createAccount(.delegate(.completed)):
			loadAccounts(context: state.context)

		default:
			.none
		}
	}

	private func loadAccounts(context: State.Context) -> Effect<Action> {
		.run { send in
			let result = await TaskResult {
				switch context {
				case .assetTransfer, .permission:
					return try await accountsClient.getAccountsOnCurrentNetwork()
						.map { State.AccountType.general($0) }
						.asIdentified()

				case .accountDeletion:
					let accounts = try await accountsClient.getAccountsOnCurrentNetwork()
					let entities = try await onLedgerEntitiesClient.getAccounts(accounts.map(\.address), cachingStrategy: .forceUpdate)
					let receivingAccounts = accounts.compactMap { account -> State.ReceivingAccountCandidate? in
						guard let entity = entities.first(where: { $0.address == account.address }) else {
							assertionFailure("Failed to find account, this should never happen.")
							return nil
						}

						let xrdBalance = entity.fungibleResources.xrdResource?.amount.exactAmount?.nominalAmount ?? 0
						let hasEnoughXRD = xrdBalance >= 1

						return .init(account: account, hasEnoughXRD: hasEnoughXRD)
					}
					return receivingAccounts
						.sorted { $0.hasEnoughXRD && !$1.hasEnoughXRD }
						.map { State.AccountType.receiving($0) }
						.asIdentified()
				}
			}
			await send(.internal(.loadAccountsResult(result)))
		}
	}
}

// MARK: - ChooseAccounts.State.Context
extension ChooseAccounts.State {
	enum Context: Sendable, Hashable {
		case assetTransfer
		case permission(SelectionRequirement)
		case accountDeletion
	}

	enum AccountType: Sendable, Hashable, Identifiable {
		case general(Account)
		case receiving(ReceivingAccountCandidate)

		var id: Self { self }

		var account: Account {
			switch self {
			case let .general(account):
				account
			case let .receiving(receivingAccount):
				receivingAccount.account
			}
		}

		var hasEnoughXRD: Bool? {
			switch self {
			case .general:
				nil
			case let .receiving(receivingAccount):
				receivingAccount.hasEnoughXRD
			}
		}
	}

	struct ReceivingAccountCandidate: Sendable, Hashable, Identifiable {
		typealias ID = Account.ID
		var id: ID { account.id }

		let account: Account
		let hasEnoughXRD: Bool
	}
}
