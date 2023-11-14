import ComposableArchitecture
import SwiftUI

// MARK: - SelectFeePayer
public struct SelectFeePayer: Sendable, FeatureReducer {
	public typealias FeePayerCandidates = NonEmpty<IdentifiedArrayOf<FeePayerCandidate>>

	public struct State: Sendable, Hashable {
		public var feePayer: FeePayerCandidate?
		public let transactionFee: TransactionFee
		public var feePayerCandidates: Loadable<FeePayerCandidates> = .idle

		public init(
			feePayer: FeePayerCandidate?,
			transactionFee: TransactionFee
		) {
			self.feePayer = feePayer
			self.transactionFee = transactionFee
		}
	}

	public enum ViewAction: Sendable, Equatable {
		case task
		case selectedPayer(FeePayerCandidate?)
		case confirmedFeePayer(FeePayerCandidate)
		case pullToRefreshStarted
	}

	public enum DelegateAction: Sendable, Equatable {
		case selected(FeePayerCandidate)
	}

	public enum InternalAction: Sendable, Equatable {
		case feePayerCandidatesLoaded(TaskResult<FeePayerCandidates>)
	}

	@Dependency(\.transactionClient) var transactionClient
	@Dependency(\.errorQueue) var errorQueue

	public init() {}

	public func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .task:
			state.feePayerCandidates = .loading
			return loadCandidates(refresh: false)

		case let .selectedPayer(candidate):
			state.feePayer = candidate
			return .none

		case let .confirmedFeePayer(payer):
			return .send(.delegate(.selected(payer)))

		case .pullToRefreshStarted:
			return loadCandidates(refresh: true)
		}
	}

	public func reduce(into state: inout State, internalAction: InternalAction) -> Effect<Action> {
		switch internalAction {
		case let .feePayerCandidatesLoaded(.success(candidates)):
			state.feePayerCandidates = .success(candidates)
			return .none
		case let .feePayerCandidatesLoaded(.failure(error)):
			errorQueue.schedule(error)
			return .none
		}
	}

	private func loadCandidates(refresh: Bool) -> Effect<Action> {
		.run { send in
			await send(.internal(.feePayerCandidatesLoaded(
				TaskResult {
					try await transactionClient.getFeePayerCandidates(refresh)
				}
			)))
		}
	}
}
