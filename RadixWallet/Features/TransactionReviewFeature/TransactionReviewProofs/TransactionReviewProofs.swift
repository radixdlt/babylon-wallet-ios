import ComposableArchitecture
import SwiftUI

// MARK: - TransactionReviewProofs
public struct TransactionReviewProofs: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		public var proofs: IdentifiedArrayOf<TransactionReview.ProofEntity>

		public init(proofs: IdentifiedArrayOf<TransactionReview.ProofEntity>) {
			self.proofs = proofs
		}
	}

	public enum ViewAction: Sendable, Equatable {
		case infoTapped
		case proofTapped(id: TransactionReview.ProofEntity.ID)
	}

	public init() {}

	public func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .infoTapped:
			.none
		case let .proofTapped(id):
			// FIXME: Handle tap
			.none
		}
	}
}
