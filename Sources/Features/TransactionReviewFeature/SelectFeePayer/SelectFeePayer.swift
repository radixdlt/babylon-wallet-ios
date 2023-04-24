import FeaturePrelude
import TransactionClient

// MARK: - SelectFeePayer
public struct SelectFeePayer: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		public let feePayerCandidates: NonEmpty<IdentifiedArrayOf<FeePayerCandiate>>
		public var selectedPayerID: FeePayerCandiate.ID?
		public let fee: BigDecimal

		public init(
			candidates: NonEmpty<IdentifiedArrayOf<FeePayerCandiate>>,
			fee: BigDecimal
		) {
			self.feePayerCandidates = candidates
			self.fee = fee
		}
	}

	public enum ViewAction: Sendable, Equatable {
		case selectedPayer(id: FeePayerCandiate.ID?)
		case confirmedFeePayer(FeePayerCandiate)
	}

	public enum DelegateAction: Sendable, Equatable {
		case selectedFeePayer(FeePayerCandiate, fee: BigDecimal)
	}

	public init() {}

	public func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case let .selectedPayer(payerID):
			state.selectedPayerID = payerID
			return .none
		case let .confirmedFeePayer(payer):
			return .send(.delegate(.selectedFeePayer(payer, fee: state.fee)))
		}
	}
}
