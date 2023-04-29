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
		}

		public let notarizedTX: NotarizeTransactionResponse
		public var status: TXStatus
		public var hasDelegatedThatTXHasBeenSubmitted = false

		public init(
			notarizedTX: NotarizeTransactionResponse,
			status: TXStatus = .notYetSubmitted
		) {
			self.notarizedTX = notarizedTX
			self.status = status
		}
	}

	public enum InternalAction: Sendable, Equatable {
		case submitTXResult(TaskResult<TXID>)
		case statusUpdate(GatewayAPI.TransactionStatus)
	}

	public enum ViewAction: Sendable, Equatable {
		case appeared
	}

	public enum DelegateAction: Sendable, Equatable {
		case failedToSubmit
		case failedToReceiveStatusUpdate
		case submittedButNotCompleted(TXID)
		case submittedTransactionFailed
		case committedSuccessfully(TXID)
	}

	@Dependency(\.submitTXClient) var submitTXClient
	@Dependency(\.errorQueue) var errorQueue

	public init() {}

	public func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
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
		}
	}

	public func reduce(into state: inout State, internalAction: InternalAction) -> EffectTask<Action> {
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
					try await send(.internal(.statusUpdate(update.result.get())))
				}
			} catch: { error, send in
				errorQueue.schedule(error)
				loggerGlobal.error("Failed to receive TX status update, error \(error)")
				await send(.delegate(.failedToReceiveStatusUpdate))
			}

		case let .statusUpdate(update):
			let status = update.stateStatus
			loggerGlobal.debug("Got TX status update: \(String(describing: status))")
			state.status = status
			if status.isCompletedSuccessfully {
				return .send(.delegate(.committedSuccessfully(state.notarizedTX.txID)))
			} else if status.isCompletedWithFailure {
				return .send(.delegate(.submittedTransactionFailed))
			} else if status.isSubmitted {
				if !state.hasDelegatedThatTXHasBeenSubmitted {
					defer { state.hasDelegatedThatTXHasBeenSubmitted = true }
					return .send(.delegate(.submittedButNotCompleted(state.notarizedTX.txID)))
				}
			}
			return .none
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
		case .rejected, .committedFailure, .submittedUnknown, .submittedPending, .committedSuccessfully: return true
		case .submitting, .notYetSubmitted: return false
		}
	}

	var isCompletedWithFailure: Bool {
		switch self {
		case .rejected, .committedFailure: return true
		case .notYetSubmitted, .submittedUnknown, .submittedPending, .committedSuccessfully, .submitting: return false
		}
	}

	var isCompletedSuccessfully: Bool {
		guard case .committedSuccessfully = self else {
			return false
		}
		return true
	}
}
