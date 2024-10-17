import ComposableArchitecture
import SwiftUI

let epochDurationInMinutes = 5

// MARK: - SubmitTransaction
struct SubmitTransaction: Sendable, FeatureReducer {
	private enum CancellableId: Hashable {
		case transactionStatus
	}

	struct State: Sendable, Hashable {
		enum TXStatus: Sendable, Hashable {
			case notYetSubmitted
			case submitting
			case submitted
			case committedSuccessfully
			case temporarilyRejected(remainingProcessingTime: Int)
			case permanentlyRejected(TransactionStatusReason)
			case failed(TransactionStatusReason)
		}

		let notarizedTX: NotarizeTransactionResponse
		var status: TXStatus
		let inProgressDismissalDisabled: Bool
		let route: P2P.Route

		@PresentationState
		var dismissTransactionAlert: AlertState<ViewAction.DismissAlertAction>?

		init(
			notarizedTX: NotarizeTransactionResponse,
			status: TXStatus = .notYetSubmitted,
			inProgressDismissalDisabled: Bool = false,
			route: P2P.Route
		) {
			self.notarizedTX = notarizedTX
			self.status = status
			self.inProgressDismissalDisabled = inProgressDismissalDisabled
			self.route = route
		}
	}

	enum InternalAction: Sendable, Equatable {
		case submitTXResult(TaskResult<IntentHash>)
		case statusUpdate(State.TXStatus)
	}

	enum ViewAction: Sendable, Equatable {
		case appeared
		case closeButtonTapped
		case dismissTransactionAlert(PresentationAction<DismissAlertAction>)

		enum DismissAlertAction: Sendable, Equatable {
			case cancel
			case confirm
		}
	}

	enum DelegateAction: Sendable, Equatable {
		case failedToSubmit
		case submittedButNotCompleted(IntentHash)
		case committedSuccessfully(IntentHash)
		case manuallyDismiss
	}

	@Dependency(\.submitTXClient) var submitTXClient
	@Dependency(\.errorQueue) var errorQueue
	@Dependency(\.accountPortfoliosClient) var accountPortfoliosClient
	@Dependency(\.accountLockersClient) var accountLockersClient

	init() {}

	var body: some ReducerOf<Self> {
		Reduce(core)
			.ifLet(\.$dismissTransactionAlert, action: /Action.view .. ViewAction.dismissTransactionAlert)
	}

	func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .appeared:
			state.status = .submitting
			return .run { [notarized = state.notarizedTX.notarized] send in
				await send(.internal(.submitTXResult(
					TaskResult {
						try await submitTXClient.submitTransaction(notarized)
					}
				)))
			}
		case .closeButtonTapped:
			if state.status.isInProgress {
				if state.inProgressDismissalDisabled {
					state.dismissTransactionAlert = .init(
						title: .init(L10n.TransactionStatus.DismissalDisabledDialog.title),
						message: .init(L10n.TransactionStatus.DismissalDisabledDialog.text)
					)
				} else {
					state.dismissTransactionAlert = .init(
						title: .init(""),
						message: TextState(L10n.TransactionStatus.DismissDialog.message),
						primaryButton: .destructive(.init(L10n.Common.confirm), action: .send(.confirm)),
						secondaryButton: .cancel(.init(L10n.Common.cancel), action: .send(.cancel))
					)
				}
				return .none
			}

			return .send(.delegate(.manuallyDismiss))
		case .dismissTransactionAlert(.presented(.confirm)):
			return .concatenate(.cancel(id: CancellableId.transactionStatus), .send(.delegate(.manuallyDismiss)))
		case .dismissTransactionAlert(.presented(.cancel)):
			return .none
		case .dismissTransactionAlert(.dismiss):
			return .none
		}
	}

	func reduce(into state: inout State, internalAction: InternalAction) -> Effect<Action> {
		switch internalAction {
		case let .submitTXResult(.failure(error)):
			errorQueue.schedule(error)
			loggerGlobal.error("Failed to submit TX, error \(error)")
			return .send(.delegate(.failedToSubmit))

		case let .submitTXResult(.success(txID)):
			state.status = .submitted
			return .run { [endEpoch = state.notarizedTX.intent.header.endEpochExclusive] send in
				let status = try await submitTXClient.pollTransactionStatus(txID)
				switch status {
				case .success:
					await send(.internal(.statusUpdate(.committedSuccessfully)))
				case let .permanentlyRejected(reason):
					await send(.internal(.statusUpdate(.permanentlyRejected(reason))))
				case let .temporarilyRejected(epoch):
					await send(.internal(.statusUpdate(
						.temporarilyRejected(
							remainingProcessingTime: Int(endEpoch - epoch) * epochDurationInMinutes
						)
					)))
				case let .failed(reason):
					await send(.internal(.statusUpdate(.failed(reason))))
				}
			}
			.cancellable(id: CancellableId.transactionStatus, cancelInFlight: true)
			.merge(with: .send(.delegate(.submittedButNotCompleted(state.notarizedTX.txID))))

		case let .statusUpdate(status):
			state.status = status
			if status == .committedSuccessfully {
				return transactionCommittedSuccesfully(state)
			} else {
				return .none
			}
		}
	}

	private func transactionCommittedSuccesfully(_ state: State) -> Effect<Action> {
		// TODO: Could probably be moved in other place. TransactionClient? AccountPortfolio?
		accountPortfoliosClient.updateAfterCommittedTransaction(state.notarizedTX.intent)
		return .send(.delegate(.committedSuccessfully(state.notarizedTX.txID)))
	}
}

extension SubmitTransaction.State.TXStatus {
	var isInProgress: Bool {
		switch self {
		case .notYetSubmitted, .submitting, .submitted: true
		case .temporarilyRejected, .failed, .permanentlyRejected, .committedSuccessfully: false
		}
	}

	var failed: Bool {
		switch self {
		case .failed, .permanentlyRejected, .temporarilyRejected: true
		case .notYetSubmitted, .submitting, .submitted, .committedSuccessfully: false
		}
	}
}
