import ComposableArchitecture
import SwiftUI

// MARK: - SubmitTransaction
public struct SubmitTransaction: Sendable, FeatureReducer {
	private enum CancellableId: Hashable {
		case transactionStatus
	}

	static let epochDurationInMinutes = 5

	public struct State: Sendable, Hashable {
		public enum TXStatus: Sendable, Hashable {
			case notYetSubmitted
			case submitting
			case submitted
			case committedSuccessfully
			case temporarilyRejected(remainingProcessingTime: Int)
			case permanentlyRejected
			case failed
		}

		public let notarizedTX: NotarizeTransactionResponse
		public var status: TXStatus
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
		case statusUpdate(State.TXStatus)
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
			state.status = .submitting
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
			return .concatenate(.cancel(id: CancellableId.transactionStatus), .send(.delegate(.manuallyDismiss)))
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
			state.status = .submitted
			return .run { [endEpoch = state.notarizedTX.intent.header().endEpochExclusive] send in
				do {
					try await submitTXClient.hasTXBeenCommittedSuccessfully(txID)
					await send(.internal(.statusUpdate(.committedSuccessfully)))
				} catch let error as TXFailureStatus {
					// Error is always TXFailureStatus, just that it is erased to generic Error
					switch error {
					case .permanentlyRejected:
						await send(.internal(.statusUpdate(.permanentlyRejected)))
					case let .temporarilyRejected(epoch):
						await send(.internal(.statusUpdate(
							.temporarilyRejected(remainingProcessingTime: Int(endEpoch - epoch.rawValue) * Self.epochDurationInMinutes)
						)))
					case .failed:
						await send(.internal(.statusUpdate(.failed)))
					}
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
		Task.detached { [intent = state.notarizedTX.intent] in
			@Dependency(\.transactionClient) var transactionClient
			@Dependency(\.accountPortfoliosClient) var accountPortfoliosClient
			@Dependency(\.onLedgerEntitiesClient) var onLedgerEntitiesClient
			@Dependency(\.cacheClient) var cacheClient

			let changedAccounts: [Profile.Network.Account.EntityAddress]?
			let resourceAddressesToRefresh: [Address]?
			do {
				let manifest = intent.manifest()

				let involvedAccounts = try await transactionClient.myInvolvedEntities(manifest)
				changedAccounts = involvedAccounts.accountsDepositedInto
					.union(involvedAccounts.accountsWithdrawnFrom)
					.map(\.address)

				let involvedAddresses = manifest.extractAddresses()
				/// Refresh the resources if an operation on resource pool is involved,
				/// reason being that contributing or withdrawing from a resource pool modifies the totalSupply
				if involvedAddresses.contains(where: \.key.isResourcePool) {
					/// A little bit too aggressive, as any other resource will also be refreshed.
					/// But at this stage we cannot determine(without making additional calls) the pool unit related fungible resource
					resourceAddressesToRefresh = involvedAddresses
						.filter { $0.key == .globalFungibleResourceManager || $0.key.isResourcePool }
						.values
						.flatMap(identity)
						.compactMap { try? $0.asSpecific() }
				} else {
					resourceAddressesToRefresh = nil
				}
			} catch {
				loggerGlobal.warning("Could get transactionClient.myInvolvedEntities: \(error.localizedDescription)")
				changedAccounts = nil
				resourceAddressesToRefresh = nil
			}

			if let resourceAddressesToRefresh {
				resourceAddressesToRefresh.forEach {
					cacheClient.removeFile(.onLedgerEntity(.resource($0.asGeneral)))
				}
			}

			if let changedAccounts {
				// FIXME: Ideally we should only have to call the cacheClient here
				// cacheClient.clearCacheForAccounts(Set(changedAccounts))
				_ = try await accountPortfoliosClient.fetchAccountPortfolios(changedAccounts, true)
			}
		}
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
