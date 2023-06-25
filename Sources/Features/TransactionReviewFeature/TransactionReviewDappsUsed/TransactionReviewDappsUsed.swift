import FeaturePrelude

// MARK: - TransactionReviewDappsUsed
public struct TransactionReviewDappsUsed: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		public var isExpanded: Bool
		public var dApps: IdentifiedArrayOf<TransactionReview.LedgerEntity>

		public init(isExpanded: Bool, dApps: IdentifiedArrayOf<TransactionReview.LedgerEntity>) {
			self.isExpanded = isExpanded
			self.dApps = dApps
		}
	}

	public enum ViewAction: Sendable, Equatable {
		case expandTapped
		case dappTapped(TransactionReview.LedgerEntity.ID)
	}

	public enum DelegateAction: Sendable, Equatable {
		case openDapp(TransactionReview.LedgerEntity.ID)
	}

	public init() {}

	public func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case .expandTapped:
			state.isExpanded.toggle()
			return .none

		case let .dappTapped(id):
			return .send(.delegate(.openDapp(id)))
		}
	}
}
