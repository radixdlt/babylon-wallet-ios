import ComposableArchitecture
import Sargon
import SwiftUI

// MARK: - DeleteAccountConfirmation
struct DeleteAccountConfirmation: Sendable, FeatureReducer {
	struct State: Sendable, Hashable {
		let account: Account
		var footerButtonState: ControlState = .enabled

		@PresentationState
		var destination: Destination.State? = nil
	}

	@CasePathable
	enum ViewAction: Sendable, Equatable {
		case continueButtonTapped
		case cancelButtonTapped
		case goHomeButtonTapped
	}

	@CasePathable
	enum InternalAction: Sendable, Equatable {
		case fetchAccountPortfolioResult(TaskResult<OnLedgerEntity.OnLedgerAccount>)
		case accountDeletedSuccessfully
		case accountDeletionFailed
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

	@Dependency(\.accountPortfoliosClient) var accountPortfoliosClient
	@Dependency(\.dappInteractionClient) var dappInteractionClient
	@Dependency(\.submitTXClient) var submitTXClient
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
			state.footerButtonState = .loading(.local)
			return .run { [address = state.account.address] send in
				let result = await TaskResult {
					try await accountPortfoliosClient.fetchAccountPortfolio(address, true).account
				}
				await send(.internal(.fetchAccountPortfolioResult(result)))
			}
		case .cancelButtonTapped:
			return .send(.delegate(.canceled))

		case .goHomeButtonTapped:
			return .send(.delegate(.goHomeAfterAccountDeleted))
		}
	}

	func reduce(into state: inout State, internalAction: InternalAction) -> Effect<Action> {
		switch internalAction {
		case let .fetchAccountPortfolioResult(.success(account)):
			state.footerButtonState = .enabled

			if account.containsAnyAsset {
				state.destination = .chooseReceivingAccount(.init(
					accountToDelete: state.account,
					chooseAccounts: .init(
						context: .accountDeletion,
						filteredAccounts: [state.account.accountAddress],
						canCreateNewAccount: false
					)
				))
			} else {
				return deleteAccount(
					accountAddress: state.account.address,
					recipientAccountAddress: nil
				)
			}
			return .none

		case let .fetchAccountPortfolioResult(.failure(error)):
			state.footerButtonState = .enabled
			errorQueue.schedule(error)
			return .none

		case .accountDeletedSuccessfully:
			state.destination = .accountDeleted
			return .none

		case .accountDeletionFailed:
			if case var .chooseReceivingAccount(childState) = state.destination {
				childState.footerControlState = .enabled
				state.destination = .chooseReceivingAccount(childState)
			}

			return .none
		}
	}

	func reduce(into state: inout State, presentedAction: Destination.Action) -> Effect<Action> {
		switch presentedAction {
		case let .chooseReceivingAccount(.delegate(.finished(recipientAccountAddress))):
			deleteAccount(
				accountAddress: state.account.address,
				recipientAccountAddress: recipientAccountAddress
			)
		default:
			.none
		}
	}

	private func deleteAccount(
		accountAddress: AccountAddress,
		recipientAccountAddress: AccountAddress?
	) -> Effect<Action> {
		.run { send in
			do {
				let manifest = try await createDeleteAccountManifest(
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
				errorQueue.schedule(error)
				await send(.internal(.accountDeletionFailed))
			}
		}
	}
}

// TODO: Use Sargon
func createDeleteAccountManifest(
	accountAddress: AccountAddress,
	recipientAccountAddress: AccountAddress?
) async throws -> TransactionManifest {
	.sampleOther
}
