import FeaturePrelude

// MARK: - TransactionReviewDappsUsed
public struct TransactionReviewDappsUsed: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		public var isExpanded: Bool
		public var dapps: IdentifiedArrayOf<TransactionReview.State.Dapp>?

		public init(isExpanded: Bool, dapps: IdentifiedArrayOf<TransactionReview.State.Dapp>?) {
			self.isExpanded = isExpanded
			self.dapps = dapps
		}
	}

	public enum ViewAction: Sendable, Equatable {
		case appeared
		case expandTapped
		case dappTapped(TransactionReview.State.Dapp.ID)
	}

	public init() {}

	public func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case .appeared:
			return .none
		case .expandTapped:
			state.isExpanded.toggle()
			return .none
		case let .dappTapped(id):
			print("Open dApp")
			return .none
		}
	}
}
