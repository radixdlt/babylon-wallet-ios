import FeaturePrelude

// MARK: - TransactionReviewProofs
public struct TransactionReviewProofs: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		public var proofs: IdentifiedArrayOf<TransactionReview.LedgerEntity>

		public init(proofs: IdentifiedArrayOf<TransactionReview.LedgerEntity>) {
			self.proofs = proofs
		}
	}

	public enum ViewAction: Sendable, Equatable {
		case infoTapped
		case proofTapped(id: TransactionReview.LedgerEntity.ID)
	}

	public init() {}

	public func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case .infoTapped:
			return .none
		case let .proofTapped(id):
			return .none
		}
	}
}
