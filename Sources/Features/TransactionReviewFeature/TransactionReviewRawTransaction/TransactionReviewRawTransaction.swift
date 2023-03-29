import FeaturePrelude

// MARK: - TransactionReviewPresenting
public struct TransactionReviewRawTransaction: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		public var transaction: String

		public init(transaction: String) {
			self.transaction = transaction
		}
	}

	public enum ViewAction: Sendable, Equatable {
		case closeTapped
	}

	public enum DelegateAction: Sendable, Equatable {
		case dismiss
	}

	public init() {}

	public func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case .closeTapped:
			return .send(.delegate(.dismiss))
		}
	}
}
