import ComposableArchitecture
import SwiftUI

// MARK: - SubmitTransaction
public struct SubmitTransaction: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		public enum TXStatus: Sendable, Hashable {
			case notYetSubmitted
			case submitting
			case submittedPending
			case submittedUnknown
			case committedSuccessfully
			case committedFailure
			case rejected
			case failedToGetStatus
		}

		public let notarizedTX: NotarizeTransactionResponse
		public var status: TXStatus
		public var hasDelegatedThatTXHasBeenSubmitted = false
		public let inProgressDismissalDisabled: Bool

		@PresentationState
		var dismissTransactionAlert: AlertState<ViewAction.DismissAlertAction>?

		public init(
			notarizedTX: NotarizeTransactionResponse,
			status: TXStatus = .notYetSubmitted,
			inProgressDismissalDisabled: Bool = false
		) {
			self.notarizedTX = notarizedTX
			self.status = status
			self.inProgressDismissalDisabled = inProgressDismissalDisabled
		}
	}

	public enum InternalAction: Sendable, Equatable {
		case submitTXResult(TaskResult<TXID>)
		case statusUpdate(Result<GatewayAPI.TransactionStatus, TransactionPollingFailure>)
	}

	public enum ViewAction: Sendable, Equatable {
		case appeared
		case closeButtonTapped
		case dismissTransactionAlert(PresentationAction<DismissAlertAction>)

		public enum DismissAlertAction: Sendable, Equatable {
			case cancel
			case confirm
		}
	}

	public enum DelegateAction: Sendable, Equatable {
		case failedToSubmit
		case submittedButNotCompleted(TXID)
		case committedSuccessfully(TXID)
		case manuallyDismiss
	}

	@Dependency(\.submitTXClient) var submitTXClient
	@Dependency(\.errorQueue) var errorQueue

	public init() {}

	public var body: some ReducerOf<Self> {
		Reduce(core)
			.ifLet(\.$dismissTransactionAlert, action: /Action.view .. ViewAction.dismissTransactionAlert)
	}

	public func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .appeared:
			return .run { [txID = state.notarizedTX.txID, notarized = state.notarizedTX.notarized] send in
				await send(.internal(.submitTXResult(
					TaskResult {
						try await submitTXClient.submitTransaction(.init(
							txID: txID,
							compiledNotarizedTXIntent: notarized
						))
					}
				)))
			}
		case .closeButtonTapped:
			if state.status.isInProgress {
				if state.inProgressDismissalDisabled {
					state.dismissTransactionAlert = .init(
						title: .init("Dismiss"), // FIXME: Strings
						message: .init("This transaction requires to be completed") // FIXME: Strings
					)
				} else {
					state.dismissTransactionAlert = .init(
						title: .init(""),
						message: TextState(L10n.Transaction.Status.Dismiss.Dialog.message),
						primaryButton: .destructive(.init(L10n.Common.confirm), action: .send(.confirm)),
						secondaryButton: .cancel(.init(L10n.Common.cancel), action: .send(.cancel))
					)
				}
				return .none
			}

			return .send(.delegate(.manuallyDismiss))

		case .dismissTransactionAlert(.presented(.confirm)):
			return .send(.delegate(.manuallyDismiss))
		case .dismissTransactionAlert(.presented(.cancel)):
			return .none
		case .dismissTransactionAlert(.dismiss):
			return .none
		}
	}

	public func reduce(into state: inout State, internalAction: InternalAction) -> Effect<Action> {
		switch internalAction {
		case let .submitTXResult(.failure(error)):
			errorQueue.schedule(error)
			loggerGlobal.error("Failed to submit TX, error \(error)")
			return .send(.delegate(.failedToSubmit))

		case let .submitTXResult(.success(txID)):
			state.status = .submitting
			let pollStrategy = PollStrategy.default
			return .run { send in
				for try await update in try await submitTXClient.transactionStatusUpdates(txID, pollStrategy) {
					guard update.txID == txID else {
						loggerGlobal.warning("Received update for wrong txID, incorrect impl of `submitTXClient`?")
						continue
					}
					await send(.internal(.statusUpdate(update.result)))
				}
			} catch: { error, send in
				loggerGlobal.error("Failed to receive TX status update, error \(error)")
				await send(.internal(.statusUpdate(.failure(.failedToGetTransactionStatus(txID: txID, error: .init(pollAttempts: pollStrategy.maxPollTries))))))
			}

		case let .statusUpdate(update):
			switch update {
			case let .success(status):
				let stateStatus = status.stateStatus
				state.status = stateStatus
				if stateStatus.isCompletedSuccessfully {
					return .send(.delegate(.committedSuccessfully(state.notarizedTX.txID)))
				} else if stateStatus.isSubmitted {
					if !state.hasDelegatedThatTXHasBeenSubmitted {
						defer { state.hasDelegatedThatTXHasBeenSubmitted = true }
						return .send(.delegate(.submittedButNotCompleted(state.notarizedTX.txID)))
					}
				}
				return .none
			case .failure:
				/// Need to show failure
				state.status = .failedToGetStatus
				return .none
			}
		}
	}
}

extension GatewayAPI.TransactionStatus {
	var stateStatus: SubmitTransaction.State.TXStatus {
		switch self {
		case .committedFailure: .committedFailure
		case .committedSuccess: .committedSuccessfully
		case .pending: .submittedPending
		case .rejected: .rejected
		case .unknown: .submittedUnknown
		}
	}
}

extension SubmitTransaction.State.TXStatus {
	var isComplete: Bool {
		isCompletedWithFailure || isCompletedSuccessfully
	}

	var isSubmitted: Bool {
		switch self {
		case .failedToGetStatus, .rejected, .committedFailure, .submittedUnknown, .submittedPending, .committedSuccessfully: true
		case .submitting, .notYetSubmitted: false
		}
	}

	var isCompletedWithFailure: Bool {
		switch self {
		case .rejected, .committedFailure: true
		case .failedToGetStatus, .notYetSubmitted, .submittedUnknown, .submittedPending, .committedSuccessfully, .submitting: false
		}
	}

	var isCompletedSuccessfully: Bool {
		guard case .committedSuccessfully = self else {
			return false
		}
		return true
	}

	var isInProgress: Bool {
		switch self {
		case .notYetSubmitted, .submitting, .submittedUnknown, .submittedPending: true
		case .committedFailure, .committedSuccessfully, .rejected, .failedToGetStatus: false
		}
	}

	var failed: Bool {
		switch self {
		case .rejected, .committedFailure, .failedToGetStatus: true
		case .notYetSubmitted, .submittedUnknown, .submittedPending, .committedSuccessfully, .submitting: false
		}
	}
}
