import FeaturePrelude

// MARK: - TransactionReviewPresenting
public struct TransactionReviewPresenting: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		public var dApps: IdentifiedArrayOf<TransactionReview.State.Dapp>

		public init(dApps: IdentifiedArrayOf<TransactionReview.State.Dapp>) {
			self.dApps = dApps
		}
	}

	public enum ViewAction: Sendable, Equatable {
		case infoTapped
		case dAppTapped(id: TransactionReview.State.Dapp.ID)
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
