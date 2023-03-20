import FeaturePrelude

// MARK: - TransactionReviewNetworkFee
public struct TransactionReviewNetworkFee: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		public var fee: BigDecimal
		public var isCongested: Bool

		public init(fee: BigDecimal, isCongested: Bool) {
			self.fee = fee
			self.isCongested = isCongested
		}
	}

	public enum ViewAction: Sendable, Equatable {
		case infoTapped
		case customizeTapped
	}

	public init() {}

	public func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case .infoTapped:
			return .none
		case .customizeTapped:
			return .none
		}
	}
}
