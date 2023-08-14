import EngineKit
import FeaturePrelude
import Foundation
import TransactionClient

public struct AdvancedCustomizationFees: FeatureReducer {
	public struct State: Hashable, Sendable {
		var fees: TransactionFee.AdvancedFeeCustomization

		var paddingAmountStr: String
		var tipPercentageStr: String

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
	}

	public func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case let .paddingAmountChanged(amount):
			state.paddingAmountStr = amount
			if let amount = try? BigDecimal(fromString: amount) {
				state.fees.paddingFee = amount
			}
			return .none
		case let .tipPercentageChanged(percentage):
			state.tipPercentageStr = percentage
			if let percentage = try? BigDecimal(fromString: percentage) {
				state.fees.tipPercentage = percentage
			}
			return .none
		}
	}
}
