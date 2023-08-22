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

		var paddingAmount: String
		var tipPercentage: String

		var focusField: FocusField?

		init(
			fees: TransactionFee.AdvancedFeeCustomization
		) {
			self.fees = fees
			self.paddingAmount = fees.paddingFee.format()
			self.tipPercentage = fees.tipPercentage.format()
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
			state.paddingAmount = amount
			updateDecimalField(&state, field: \.fees.paddingFee, value: amount)
			return .send(.delegate(.updated(state.fees)))
		case let .tipPercentageChanged(percentage):
			state.tipPercentage = percentage
			updateDecimalField(&state, field: \.fees.tipPercentage, value: percentage)
			return .send(.delegate(.updated(state.fees)))
		case let .focusChanged(field):
			state.focusField = field
			return .none
		}
	}

	func updateDecimalField(
		_ state: inout State,
		field: WritableKeyPath<State, BigDecimal>,
		value: String
	) {
		if value.isEmpty {
			state[keyPath: field] = .zero
		} else if let amount = try? BigDecimal(fromString: value) {
			state[keyPath: field] = amount
		}
	}
}
