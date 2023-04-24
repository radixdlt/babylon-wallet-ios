import FeaturePrelude
import TransactionClient

// MARK: - SelectFeePayer
public struct SelectFeePayer: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		public let feePayerCandidates: Set<FeePayerCandiate>
		public let fee: BigDecimal

		public init(
			candidates: Set<FeePayerCandiate>,
			fee: BigDecimal
		) {
			self.feePayerCandidates = candidates
			self.fee = fee
		}
	}

	public enum ViewAction: Sendable, Equatable {
		case appeared
	}

	public init() {}

	public func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case .appeared:
			return .none
		}
	}
}
