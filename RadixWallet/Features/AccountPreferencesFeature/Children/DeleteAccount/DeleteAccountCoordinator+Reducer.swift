import ComposableArchitecture
import Sargon
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
		case accountDeletionFailedDueToManyAssets
	}

	@CasePathable
	enum ChildAction: Sendable, Equatable {
		case deleteConfirmation(DeleteAccountConfirmation.Action)
	}

	@CasePathable
	enum DelegateAction: Sendable, Equatable {
		case goHomeAfterAccountDeleted
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
	@Dependency(\.overlayWindowClient) var overlayWindowClient
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

		case .accountDeletionFailedDueToManyAssets:
			guard case var .chooseReceivingAccount(childState) = state.destination else { return .none }

			childState.footerControlState = .enabled
			childState.destination = .tooManyAssetsAlert(.tooManyAssets)
			state.destination = .chooseReceivingAccount(childState)

			return .none
		}
	}

	func reduce(into state: inout State, childAction: ChildAction) -> Effect<Action> {
		switch childAction {
		case .deleteConfirmation(.delegate(.deleteAccount)):
			return deleteAccount(
				accountAddress: state.account.address,
				recipientAccountAddress: nil
			)

		case let .deleteConfirmation(.delegate(.chooseReceivingAccount(accounts, disabledAccounts))):
			let filteredAccounts = [state.account.accountAddress]
			let availableAccounts = accounts.filter { !filteredAccounts.contains($0.account.address) }
			let hasAccountsWithEnoughXRD = availableAccounts.contains(where: \.hasEnoughXRD)

			state.destination = .chooseReceivingAccount(.init(
				chooseAccounts: .init(
					context: .assetTransfer,
					filteredAccounts: filteredAccounts,
					disabledAccounts: disabledAccounts,
					availableAccounts: availableAccounts.map(\.account).asIdentified(),
					canCreateNewAccount: false
				),
				hasAccountsWithEnoughXRD: hasAccountsWithEnoughXRD
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
				let manifestOutcome = try await SargonOs.shared.createDeleteAccountManifest(
					accountAddress: accountAddress,
					recipientAccountAddress: recipientAccountAddress
				)

				/// Check for non-transferable resources
				if !manifestOutcome.nonTransferableResources.isEmpty {
					let action = await overlayWindowClient.scheduleAlert(.nonTransferableAssets)
					switch action {
					case .primaryButtonTapped:
						/// Continue account deletion
						break
					default:
						await send(.internal(.accountDeletionFailed))
						return
					}
				}

				/// Wait for user to complete the interaction with Transaction Review
				let result = await dappInteractionClient.addWalletInteraction(
					.transaction(.init(send: .init(transactionManifest: manifestOutcome.manifest))),
					.accountDelete
				)

				switch result {
				case let .dapp(.success(success)):
					if case let .transaction(tx) = success.items {
						/// Wait for the transaction to be committed
						let txID = tx.send.transactionIntentHash
						if try await submitTXClient.hasTXBeenCommittedSuccessfully(txID) {
							try await SargonOs.shared.markAccountAsTombstoned(accountAddress: accountAddress)
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
					await send(.internal(.accountDeletionFailedDueToManyAssets))
				default:
					errorQueue.schedule(error)
					await send(.internal(.accountDeletionFailed))
				}
			}
		}
	}
}

extension OverlayWindowClient.Item.AlertState {
	fileprivate static var nonTransferableAssets: Self {
		Self(
			title: { TextState(L10n.AccountSettings.NonTransferableAssetsWarning.title) },
			actions: {
				ButtonState(role: .cancel, action: .dismissed) {
					TextState(L10n.Common.cancel)
				}
				ButtonState(role: .destructive, action: .primaryButtonTapped) {
					TextState(L10n.Common.continue)
				}
			},
			message: { TextState(L10n.AccountSettings.NonTransferableAssetsWarning.message) }
		)
	}
}
