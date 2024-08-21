import ComposableArchitecture
import SwiftUI

// MARK: - ValidatedFeePayerCandidate
public struct ValidatedFeePayerCandidate: Sendable, Hashable, Identifiable {
	public var id: FeePayerCandidate.ID { candidate.id }
	public let candidate: FeePayerCandidate
	public let outcome: FeePayerValidationOutcome
}

// MARK: - SelectFeePayer
public struct SelectFeePayer: Sendable, FeatureReducer {
	public typealias FeePayerCandidates = NonEmpty<IdentifiedArrayOf<FeePayerCandidate>>

	public struct State: Sendable, Hashable {
		public let reviewedTransaction: ReviewedTransaction
		public var selectedFeePayer: ValidatedFeePayerCandidate?
		public let transactionFee: TransactionFee
		public var feePayerCandidates: Loadable<[ValidatedFeePayerCandidate]> = .idle

		public init(
			reviewedTransaction: ReviewedTransaction,
			selectedFeePayer: FeePayerCandidate?,
			transactionFee: TransactionFee
		) {
			self.reviewedTransaction = reviewedTransaction
			self.selectedFeePayer = selectedFeePayer.map { .init(candidate: $0, outcome: reviewedTransaction.validateFeePayer($0)) }
			self.transactionFee = transactionFee
		}
	}

	public enum ViewAction: Sendable, Equatable {
		case task
		case selectedFeePayer(ValidatedFeePayerCandidate?)
		case confirmedFeePayer(FeePayerCandidate)
		case pullToRefreshStarted
		case closeButtonTapped
	}

	public enum DelegateAction: Sendable, Equatable {
		case selected(FeePayerCandidate)
	}

	public enum InternalAction: Sendable, Equatable {
		case feePayerCandidatesLoaded(TaskResult<FeePayerCandidates>)
	}

	@Dependency(\.transactionClient) var transactionClient
	@Dependency(\.errorQueue) var errorQueue
	@Dependency(\.dismiss) var dismiss

	public init() {}

	public func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .task:
			state.feePayerCandidates = .loading
			return loadCandidates(refresh: false)

		case let .selectedFeePayer(candidate):
			state.selectedFeePayer = candidate
			return .none

		case let .confirmedFeePayer(payer):
			return .send(.delegate(.selected(payer)))

		case .pullToRefreshStarted:
			return loadCandidates(refresh: true)

		case .closeButtonTapped:
			return .run { _ in
				await dismiss()
			}
		}
	}

	public func reduce(into state: inout State, internalAction: InternalAction) -> Effect<Action> {
		switch internalAction {
		case let .feePayerCandidatesLoaded(.success(candidates)):
			let validated = candidates.rawValue.map { candidate in
				ValidatedFeePayerCandidate(
					candidate: candidate,
					outcome: state.reviewedTransaction.validateFeePayer(candidate)
				)
			}
			state.feePayerCandidates = .success(validated)
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
