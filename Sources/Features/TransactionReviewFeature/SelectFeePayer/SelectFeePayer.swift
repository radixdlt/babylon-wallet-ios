import FeaturePrelude
import SigningFeature
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
			self.selectedPayerID = candidates.first.id
		}
	}

	public enum ViewAction: Sendable, Equatable {
		case selectedPayer(id: FeePayerCandiate.ID?)
		case confirmedFeePayer(FeePayerCandiate)
	}

	public enum DelegateAction: Sendable, Equatable {
		case selected(FeePayerSelectionAmongstCandidates)
	}

	public init() {}

	public func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case let .selectedPayer(payerID):
			state.selectedPayerID = payerID
			loggerGlobal.critical("🔮 selected fee payer id: \(payerID)")
			return .none

		case let .confirmedFeePayer(payer):
			loggerGlobal.critical("🔮 confirmed fee payer: \(payer.account.address)")

			let selected = FeePayerSelectionAmongstCandidates(
				selected: payer,
				candidates: state.feePayerCandidates,
				fee: state.fee,
				selection: .selectedByUser
			)
			return .send(.delegate(.selected(selected)))
		}
	}
}
