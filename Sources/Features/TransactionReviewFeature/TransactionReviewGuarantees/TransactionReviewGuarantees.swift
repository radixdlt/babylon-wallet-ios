import FeaturePrelude

// MARK: - TransactionReviewGuarantees
public struct TransactionReviewGuarantees: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		public var transfers: IdentifiedArrayOf<TransactionReview.Transfer>

		public init(transfers: IdentifiedArrayOf<TransactionReview.Transfer>) {
			self.transfers = transfers
		}
	}

	public enum ViewAction: Sendable, Equatable {
		case infoTapped
		case dAppTapped(id: TransactionReview.Dapp.ID)
	}

	public init() {}

	public func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case .infoTapped:
			return .none
		case let .dAppTapped(id):
			return .none
		}
	}
}
