import EngineKit
import FeaturePrelude
import GatewayAPI
import SubmitTransactionClient
import struct TransactionClient.NotarizeTransactionResponse

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
		public let dismissalDisabled: Bool

		public init(
			notarizedTX: NotarizeTransactionResponse,
			status: TXStatus = .notYetSubmitted,
			dismissalDisabled: Bool = false
		) {
			self.notarizedTX = notarizedTX
			self.status = status
			self.dismissalDisabled = dismissalDisabled
		}
	}

	public enum InternalAction: Sendable, Equatable {
		case submitTXResult(TaskResult<TXID>)
		case statusUpdate(Result<GatewayAPI.TransactionStatus, TransactionPollingFailure>)
	}

	public enum ViewAction: Sendable, Equatable {
		case appeared
		case closeButtonTapped
	}

	public enum DelegateAction: Sendable, Equatable {
		case failedToSubmit
		case failedToReceiveStatusUpdate
		case submittedButNotCompleted(TXID)
		case submittedTransactionFailed
		case committedSuccessfully(TXID)
		case manuallyDismiss(State.TXStatus)
	}

	@Dependency(\.submitTXClient) var submitTXClient
	@Dependency(\.errorQueue) var errorQueue

	public init() {}

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
			guard !state.dismissalDisabled else { return .none }
			// FIXME: For some reason, the dismiss dependency does not work here
			return .send(.delegate(.manuallyDismiss(state.status)))
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
			return .run { send in
				for try await update in try await submitTXClient.transactionStatusUpdates(txID, PollStrategy.default) {
					guard update.txID == txID else {
						loggerGlobal.warning("Received update for wrong txID, incorrect impl of `submitTXClient`?")
						continue
					}
					await send(.internal(.statusUpdate(update.result)))
				}
			} catch: { error, send in
				loggerGlobal.error("Failed to receive TX status update, error \(error)")
				await send(.internal(.statusUpdate(.failure(.failedToGetTransactionStatus(txID: txID, error: .init(pollAttempts: 0))))))
			}

		case let .statusUpdate(update):
			switch update {
			case let .success(status):
				let stateStatus = status.stateStatus
				state.status = stateStatus
				if stateStatus.isCompletedSuccessfully {
					return .send(.delegate(.committedSuccessfully(state.notarizedTX.txID)))
				} else if stateStatus.isCompletedWithFailure {
					return .send(.delegate(.submittedTransactionFailed))
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
		case .committedFailure: return .committedFailure
		case .committedSuccess: return .committedSuccessfully
		case .pending: return .submittedPending
		case .rejected: return .rejected
		case .unknown: return .submittedUnknown
		}
	}
}

extension SubmitTransaction.State.TXStatus {
	var isComplete: Bool {
		isCompletedWithFailure || isCompletedSuccessfully
	}

	var isSubmitted: Bool {
		switch self {
		case .failedToGetStatus, .rejected, .committedFailure, .submittedUnknown, .submittedPending, .committedSuccessfully: return true
		case .submitting, .notYetSubmitted: return false
		}
	}

	var isCompletedWithFailure: Bool {
		switch self {
		case .rejected, .committedFailure: return true
		case .failedToGetStatus, .notYetSubmitted, .submittedUnknown, .submittedPending, .committedSuccessfully, .submitting: return false
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
		case .notYetSubmitted, .submitting, .submittedUnknown, .submittedPending: return true
		case .committedFailure, .committedSuccessfully, .rejected, .failedToGetStatus: return false
		}
	}
}
