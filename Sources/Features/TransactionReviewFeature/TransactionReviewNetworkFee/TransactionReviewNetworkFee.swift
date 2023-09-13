import FeaturePrelude
import TransactionClient

// MARK: - TransactionReviewNetworkFee
public struct TransactionReviewNetworkFee: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		public let reviewedTransaction: ReviewedTransaction

		public init(
			reviewedTransaction: ReviewedTransaction
		) {
			self.reviewedTransaction = reviewedTransaction
		}
	}

	public enum ViewAction: Sendable, Equatable {
		case infoTapped
		case customizeTapped
	}

	public enum DelegateAction: Sendable, Equatable {
		case showCustomizeFees
	}

	public init() {}

	public func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .infoTapped:
			return .none
		case .customizeTapped:
			return .send(.delegate(.showCustomizeFees))
		}
	}
}
