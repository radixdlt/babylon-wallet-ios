import ComposableArchitecture
import SwiftUI

// MARK: - DeleteAccountCoordinator
struct DeleteAccountCoordinator: Sendable, FeatureReducer {
	// MARK: - State

	struct State: Sendable, Hashable {
		var account: Account
		var deleteConfirmation: DeleteAccountConfirmation.State

		@PresentationState
		var destination: Destination.State? = nil

		init(account: Account) {
			self.account = account
			self.deleteConfirmation = .init(account: account)
		}
	}

	// MARK: - Action

	@CasePathable
	enum ViewAction: Sendable, Equatable {
		case goHomeButtonTapped
	}

	@CasePathable
	enum InternalAction: Sendable, Equatable {
		case accountDeletedSuccessfully
		case accountDeletionFailed
		case accountDeletionFailedDueTooManyAssets
	}

	@CasePathable
	enum ChildAction: Sendable, Equatable {
		case deleteConfirmation(DeleteAccountConfirmation.Action)
	}

	@CasePathable
	enum DelegateAction: Sendable, Equatable {
		case goHomeAfterAccountDeleted
		case canceled
	}

	// MARK: - Destination

	struct Destination: DestinationReducer {
		@CasePathable
		enum State: Hashable, Sendable {
			case chooseReceivingAccount(ChooseReceivingAccountOnDelete.State)
			case accountDeleted
		}

		@CasePathable
		enum Action: Equatable, Sendable {
			case chooseReceivingAccount(ChooseReceivingAccountOnDelete.Action)
			case accountDeleted
		}

		var body: some ReducerOf<Self> {
			Scope(state: \.chooseReceivingAccount, action: \.chooseReceivingAccount) {
				ChooseReceivingAccountOnDelete()
			}
		}
	}

	// MARK: - Reducer

	@Dependency(\.dappInteractionClient) var dappInteractionClient
	@Dependency(\.submitTXClient) var submitTXClient
	@Dependency(\.errorQueue) var errorQueue

	init() {}

	var body: some ReducerOf<Self> {
		Scope(state: \.deleteConfirmation, action: \.child.deleteConfirmation) {
			DeleteAccountConfirmation()
		}
		Reduce(core)
			.ifLet(\.$destination, action: \.destination) {
				Destination()
			}
	}

	func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .goHomeButtonTapped:
			.send(.delegate(.goHomeAfterAccountDeleted))
		}
	}

	func reduce(into state: inout State, internalAction: InternalAction) -> Effect<Action> {
		switch internalAction {
		case .accountDeletedSuccessfully:
			state.destination = .accountDeleted
			return .none

		case .accountDeletionFailed:
			updateChooseAccountControlState(state: &state, footerControlState: .enabled)
			return .none

		case .accountDeletionFailedDueTooManyAssets:
			guard case var .chooseReceivingAccount(childState) = state.destination else { return .none }

			childState.footerControlState = .enabled
			childState.destination = .tooManyAssetsAlert(.tooManyAssets)
			state.destination = .chooseReceivingAccount(childState)

			return .none
		}
	}

	func reduce(into state: inout State, childAction: ChildAction) -> Effect<Action> {
		switch childAction {
		case .deleteConfirmation(.delegate(.canceled)):
			return .send(.delegate(.canceled))

		case .deleteConfirmation(.delegate(.deleteAccount)):
			return deleteAccount(
				accountAddress: state.account.address,
				recipientAccountAddress: nil
			)

		case .deleteConfirmation(.delegate(.chooseRecipientAccount)):
			state.destination = .chooseReceivingAccount(.init(
				chooseAccounts: .init(
					context: .accountDeletion,
					filteredAccounts: [state.account.accountAddress],
					canCreateNewAccount: false
				)
			))
			return .none

		default:
			return .none
		}
	}

	func reduce(into state: inout State, presentedAction: Destination.Action) -> Effect<Action> {
		switch presentedAction {
		case let .chooseReceivingAccount(.delegate(.finished(recipientAccountAddress))):
			updateChooseAccountControlState(
				state: &state,
				footerControlState: .loading(.local)
			)

			return deleteAccount(
				accountAddress: state.account.address,
				recipientAccountAddress: recipientAccountAddress
			)

		default:
			return .none
		}
	}

	private func updateChooseAccountControlState(state: inout State, footerControlState: ControlState) {
		guard case var .chooseReceivingAccount(childState) = state.destination else { return }

		childState.footerControlState = footerControlState
		state.destination = .chooseReceivingAccount(childState)
	}

	private func deleteAccount(
		accountAddress: AccountAddress,
		recipientAccountAddress: AccountAddress? = nil
	) -> Effect<Action> {
		.run { send in
			do {
				let manifest = try await SargonOs.shared.createDeleteAccountManifest(
					accountAddress: accountAddress,
					recipientAccountAddress: recipientAccountAddress
				)

				/// Wait for user to complete the interaction with Transaction Review
				let result = await dappInteractionClient.addWalletInteraction(
					.transaction(.init(send: .init(transactionManifest: manifest))),
					.accountDelete
				)

				switch result {
				case let .dapp(.success(success)):
					if case let .transaction(tx) = success.items {
						/// Wait for the transaction to be committed
						let txID = tx.send.transactionIntentHash
						if try await submitTXClient.hasTXBeenCommittedSuccessfully(txID) {
							await send(.internal(.accountDeletedSuccessfully))
						}
						return
					}

					assertionFailure("Not a transaction Response?")
				case .dapp(.failure), .none:
					/// Either user did dismiss the TransctionReview, or there was a failure.
					/// Any failure message will be displayed in Transaction Review
					await send(.internal(.accountDeletionFailed))
				}
			} catch {
				switch error as? CommonError {
				case .MaxTransfersPerTransactionReached:
					await send(.internal(.accountDeletionFailedDueTooManyAssets))
				default:
					errorQueue.schedule(error)
					await send(.internal(.accountDeletionFailed))
				}
			}
		}
	}
}
