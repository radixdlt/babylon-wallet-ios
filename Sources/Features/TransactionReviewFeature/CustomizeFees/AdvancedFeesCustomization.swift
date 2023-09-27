import EngineKit
import FeaturePrelude
import Foundation
import TransactionClient

// MARK: - AdvancedFeesCustomization
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
			self.paddingAmount = fees.paddingFee.formatted()
			self.tipPercentage = String(fees.tipPercentage)
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

	public func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case let .paddingAmountChanged(amount):
			state.paddingAmount = amount
			state.fees.updatePaddingFee(value: amount)
			return .send(.delegate(.updated(state.fees)))
		case let .tipPercentageChanged(percentage):
			state.tipPercentage = percentage
			state.fees.updateTipPercentage(value: percentage)
			return .send(.delegate(.updated(state.fees)))
		case let .focusChanged(field):
			state.focusField = field
			return .none
		}
	}
}

extension TransactionFee.AdvancedFeeCustomization {
	mutating func updatePaddingFee(value: String) {
		if value.isEmpty {
			paddingFee = .zero
		} else if let amount = try? RETDecimal(value: value) {
			paddingFee = amount
		}
	}

	mutating func updateTipPercentage(value: String) {
		if value.isEmpty {
			tipPercentage = .zero
		} else if let amount = UInt16(value) {
			tipPercentage = amount
		}
	}
}
