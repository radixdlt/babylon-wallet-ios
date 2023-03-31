import FeaturePrelude

// MARK: - TransactionReviewPresenting
public struct TransactionReviewProofs: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		public var proofs: IdentifiedArrayOf<TransactionReview.Dapp>

		public init(proofs: IdentifiedArrayOf<TransactionReview.Dapp>) {
			self.proofs = proofs
		}
	}

	public enum ViewAction: Sendable, Equatable {
		case infoTapped
		case proofTapped(id: TransactionReview.Dapp.ID)
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
