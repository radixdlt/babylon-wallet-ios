import FeaturePrelude

// MARK: - TransactionReviewGuarantees
public struct TransactionReviewGuarantees: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		public var transfers: IdentifiedArrayOf<FungibleTransfer>

		public init(transfers: IdentifiedArrayOf<FungibleTransfer>) {
			self.transfers = transfers
		}

		public struct FungibleTransfer: Identifiable, Sendable, Hashable {
			public var id: AccountAction { transfer.id }
			public let account: TransactionReview.Account
			public let transfer: TransactionReview.Transfer
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
