import FeaturePrelude
import SigningFeature
import TransactionClient

// MARK: - SelectFeePayer
public struct SelectFeePayer: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		public var feePayerSelection: FeePayerSelectionAmongstCandidates

		public init(
			feePayerSelection: FeePayerSelectionAmongstCandidates
		) {
			self.feePayerSelection = feePayerSelection
		}
	}

	public enum ViewAction: Sendable, Equatable {
		case selectedPayer(FeePayerCandidate?)
		case confirmedFeePayer(FeePayerCandidate)
	}

	public enum DelegateAction: Sendable, Equatable {
		case selected(FeePayerCandidate)
	}

	public init() {}

	public func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case let .selectedPayer(candidate):
			state.feePayerSelection.selected = candidate
			return .none

		case let .confirmedFeePayer(payer):
			return .send(.delegate(.selected(payer)))
		}
	}
}
