import EngineKit
import FeaturePrelude
import Foundation
import TransactionClient

public struct AdvancedFeesCustomization: FeatureReducer {
	public struct State: Hashable, Sendable {
		public enum FocusField: Hashable, Sendable {
			case padding
			case tipPercentage
		}

		var fees: TransactionFee.AdvancedFeeCustomization

		var paddingAmountStr: String
		var tipPercentageStr: String

		var focusField: FocusField?

		init(
			fees: TransactionFee.AdvancedFeeCustomization
		) {
			self.fees = fees
			self.paddingAmountStr = fees.paddingFee.format()
			self.tipPercentageStr = fees.tipPercentage.format()
		}
	}

	public enum ViewAction: Equatable, Sendable {
		case paddingAmountChanged(String)
		case tipPercentageChanged(String)
		case focusChanged(State.FocusField?)
	}

	public enum DelegateAction: Equatable, Sendable {
		case updated(TransactionFee.AdvancedFeeCustomization)
	}

	public func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case let .paddingAmountChanged(amount):
			state.paddingAmountStr = amount
			if let amount = try? BigDecimal(fromString: amount) {
				state.fees.paddingFee = amount
			}
			return .send(.delegate(.updated(state.fees)))
		case let .tipPercentageChanged(percentage):
			state.tipPercentageStr = percentage
			if let percentage = try? BigDecimal(fromString: percentage) {
				state.fees.tipPercentage = percentage
			}
			return .send(.delegate(.updated(state.fees)))
		case let .focusChanged(field):
			state.focusField = field
			return .none
		}
	}
}
