import EngineKit
import FeaturePrelude
import GatewayAPI
import SubmitTransactionClient

// MARK: - TransactionStatusPolling
public struct TransactionStatusPolling: Sendable, FeatureReducer {
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

		public let txID: TXID
		public var status: TXStatus
		public var failureMessage: String?
		public var hasDelegatedThatTXHasBeenSubmitted = false
		public let disableInProgressDismissal: Bool

		public init(
			txID: TXID,
			status: TXStatus = .notYetSubmitted,
			disableInProgressDismissal: Bool = false
		) {
			self.txID = txID
			self.status = status
			self.disableInProgressDismissal = disableInProgressDismissal
		}
	}

	public enum InternalAction: Sendable, Equatable {
		case statusUpdate(GatewayAPI.TransactionStatus)
		case faileToReceiveUpdates
	}

	public enum ViewAction: Sendable, Equatable {
		case appeared
		case closeButtonTapped
	}

	public enum DelegateAction: Sendable, Equatable {}

	@Dependency(\.submitTXClient) var submitTXClient
	@Dependency(\.dismiss) var dismiss

	public init() {}

	public func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case .appeared:
			state.status = .submitting
			return .run { [txID = state.txID] send in
				for try await update in try await submitTXClient.transactionStatusUpdates(txID, PollStrategy.default) {
					guard update.txID == txID else {
						loggerGlobal.warning("Received update for wrong txID, incorrect impl of `submitTXClient`?")
						continue
					}
					try await send(.internal(.statusUpdate(update.result.get())))
				}
			} catch: { error, send in
				loggerGlobal.error("Failed to receive TX status update, error \(error)")
				await send(.internal(.faileToReceiveUpdates))
			}

		case .closeButtonTapped:
			return .fireAndForget {
				await dismiss()
			}
		}
	}

	public func reduce(into state: inout State, internalAction: InternalAction) -> EffectTask<Action> {
		switch internalAction {
		case let .statusUpdate(update):
			let status = update.stateStatus
			loggerGlobal.debug("Got TX status update: \(String(describing: status))")
			state.status = status

			return .none
		case .faileToReceiveUpdates:
			state.failureMessage = "Failed to get transaction status"
			return .none
		}
	}
}

extension GatewayAPI.TransactionStatus {
	var stateStatus: TransactionStatusPolling.State.TXStatus {
		switch self {
		case .committedFailure: return .committedFailure
		case .committedSuccess: return .committedSuccessfully
		case .pending: return .submittedPending
		case .rejected: return .rejected
		case .unknown: return .submittedUnknown
		}
	}
}

extension TransactionStatusPolling.State.TXStatus {
	var isComplete: Bool {
		isCompletedWithFailure || isCompletedSuccessfully
	}

	var inProgress: Bool {
		switch self {
		case .notYetSubmitted, .submitting, .submittedPending, .submittedUnknown: return true
		case .committedFailure, .committedSuccessfully, .rejected: return false
		}
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
