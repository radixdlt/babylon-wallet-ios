import EngineKit
import FeaturePrelude
import Foundation
import TransactionClient

public struct AdvancedCustomizationFees: FeatureReducer {
	public struct State: Hashable, Sendable {
		var advancedCustomization: TransactionFee.AdvancedFeeCustomization

		init(
			advancedCustomization: TransactionFee.AdvancedFeeCustomization
		) {
			self.advancedCustomization = advancedCustomization
		}
	}

	public enum ViewAction: Equatable, Sendable {
		case paddingAmountChanged(String)
		case tipPercentageChanged(String)
	}

	public func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case let .paddingAmountChanged(amount):
			if let amount = try? BigDecimal(fromString: amount) {
				state.advancedCustomization.paddingFee = amount
			}
			return .none
		case let .tipPercentageChanged(percentage):
			if let percentage = try? BigDecimal(fromString: percentage) {
				state.advancedCustomization.tipPercentage = percentage
			}
			return .none
		}
	}
}
