import ComposableArchitecture
import SwiftUI

// MARK: - TransactionReviewProofs
struct TransactionReviewProofs: Sendable, FeatureReducer {
	struct State: Sendable, Hashable {
		var proofs: IdentifiedArrayOf<TransactionReview.ProofEntity>

		init(proofs: IdentifiedArrayOf<TransactionReview.ProofEntity>) {
			self.proofs = proofs
		}
	}

	enum ViewAction: Sendable, Equatable {
		case infoTapped
		case proofTapped(TransactionReview.ProofEntity)
	}

	enum DelegateAction: Sendable, Equatable {
		case showAsset(TransactionReview.ProofEntity)
	}

	init() {}

	func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .infoTapped:
			.none
		case let .proofTapped(proof):
			.send(.delegate(.showAsset(proof)))
		}
	}
}
