import FeaturePrelude

// MARK: - TransactionReviewRawTransaction
public struct TransactionReviewRawTransaction: Sendable, FeatureReducer {
	@Dependency(\.dismiss) var dismiss

	public struct State: Sendable, Hashable {
		public var transaction: String

		public init(transaction: String) {
			self.transaction = transaction
		}
	}

	public enum ViewAction: Sendable, Equatable {
		case closeTapped
	}

	public init() {}

	public func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case .closeTapped:
			return .fireAndForget {
				await dismiss()
			}
		}
	}
}
