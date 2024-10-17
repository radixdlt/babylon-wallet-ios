import ComposableArchitecture
import SwiftUI

// MARK: - AdvancedFeesCustomization
struct AdvancedFeesCustomization: FeatureReducer {
	struct State: Hashable, Sendable {
		enum FocusField: Hashable, Sendable {
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

	enum ViewAction: Equatable, Sendable {
		case paddingAmountChanged(String)
		case tipPercentageChanged(String)
		case focusChanged(State.FocusField?)
	}

	enum DelegateAction: Equatable, Sendable {
		case updated(TransactionFee.AdvancedFeeCustomization)
	}

	func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case let .paddingAmountChanged(amount):
			state.paddingAmount = amount
			state.fees.paddingFee = state.parsedPaddingFee ?? .zero
			return .send(.delegate(.updated(state.fees)))
		case let .tipPercentageChanged(percentage):
			state.tipPercentage = percentage
			state.fees.tipPercentage = state.parsedTipPercentage ?? .zero
			return .send(.delegate(.updated(state.fees)))
		case let .focusChanged(field):
			state.focusField = field
			return .none
		}
	}
}

extension AdvancedFeesCustomization.State {
	var parsedPaddingFee: Decimal192? {
		paddingAmount.isEmpty ? .zero : try? Decimal192(formattedString: paddingAmount)
	}

	var parsedTipPercentage: UInt16? {
		tipPercentage.isEmpty ? .zero : UInt16(tipPercentage)
	}
}
