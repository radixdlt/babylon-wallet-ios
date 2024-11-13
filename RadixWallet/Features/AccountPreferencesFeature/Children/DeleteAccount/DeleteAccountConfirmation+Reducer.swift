import ComposableArchitecture
import Sargon
import SwiftUI

struct DeleteAccountConfirmation: Sendable, FeatureReducer {
	struct State: Sendable, Hashable {
		let account: Account
		var continueButtonState: ControlState = .enabled

		@PresentationState
		var destination: Destination.State? = nil

		init(account: Account) {
			self.account = account
		}
	}

	@CasePathable
	enum ViewAction: Sendable, Equatable {
		case continueButtonTapped
		case cancelButtonTapped
	}

	@CasePathable
	enum InternalAction: Sendable, Equatable {
		case confirmedDeletionResult(TaskResult<OnLedgerEntity.OnLedgerAccount>)
	}

	@CasePathable
	enum DelegateAction: Sendable, Equatable {
		case cancel
	}

	// MARK: - Destination
	struct Destination: DestinationReducer {
		@CasePathable
		enum State: Hashable, Sendable {
			case chooseReceivingAccount(ChooseReceivingAccountOnDelete.State)
		}

		@CasePathable
		enum Action: Equatable, Sendable {
			case chooseReceivingAccount(ChooseReceivingAccountOnDelete.Action)
		}

		var body: some ReducerOf<Self> {
			Scope(state: \.chooseReceivingAccount, action: \.chooseReceivingAccount) {
				ChooseReceivingAccountOnDelete()
			}
		}
	}

	@Dependency(\.accountPortfoliosClient) var accountPortfoliosClient
	@Dependency(\.errorQueue) var errorQueue

	init() {}

	var body: some ReducerOf<Self> {
		Reduce(core)
			.ifLet(\.$destination, action: \.destination) {
				Destination()
			}
	}

	func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .continueButtonTapped:
			state.continueButtonState = .loading(.local)
			return .run { [address = state.account.address] send in
				let result = await TaskResult {
					try await accountPortfoliosClient.fetchAccountPortfolio(address, true).account
				}
				await send(.internal(.confirmedDeletionResult(result)))
			}
		case .cancelButtonTapped:
			return .send(.delegate(.cancel))
		}
	}

	func reduce(into state: inout State, internalAction: InternalAction) -> Effect<Action> {
		switch internalAction {
		case let .confirmedDeletionResult(.success(account)):
			state.continueButtonState = .enabled

			if account.containsAnyAssets {
				state.destination = .chooseReceivingAccount(.init(
					accountToDelete: state.account,
					chooseAccounts: .init(
						context: .accountDeletion,
						filteredAccounts: [state.account.accountAddress],
						canCreateNewAccount: false
					)
				))
			} else {
				// TODO: skip account selection and review transaction
			}
			return .none

		case let .confirmedDeletionResult(.failure(error)):
			state.continueButtonState = .enabled
			errorQueue.schedule(error)
			return .none
		}
	}
}
