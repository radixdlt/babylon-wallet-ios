import FeaturePrelude

// MARK: - TransactionReviewGuarantees
public struct TransactionReviewGuarantees: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		public var transferAccounts: IdentifiedArrayOf<TransactionReviewAccount.State>

		public init(transferAccounts: IdentifiedArrayOf<TransactionReviewAccount.State>) {
			self.transferAccounts = transferAccounts
		}
	}

	public enum ViewAction: Sendable, Equatable {
		case infoTapped
		case closeTapped
		case increaseTapped(id: TransactionReview.Transfer.ID)
		case decreaseTapped(id: TransactionReview.Transfer.ID)
	}

	public enum DelegateAction: Sendable, Equatable {
		case dismiss
	}

	public init() {}

	public func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case .infoTapped:
			return .none
		case .closeTapped:
			return .send(.delegate(.dismiss))
		case let .increaseTapped(id: id):
//			guard let account =
			return .none
		case let .decreaseTapped(id: id):
			return .none
		}
	}
}
