import ComposableArchitecture
import SwiftUI

// MARK: - AdvancedFeesCustomization
public struct AdvancedFeesCustomization: FeatureReducer {
	public struct State: Hashable, Sendable {
		public enum FocusField: Hashable, Sendable {
			case padding
			case tipPercentage
		}

		public var fees: TransactionFee.AdvancedFeeCustomization

		public var paddingAmount: String
		public var tipPercentage: String

		public var focusField: FocusField?

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
			state.fees.paddingFee = state.parsedPaddingFee ?? RETDecimal.zero()
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
	var parsedPaddingFee: RETDecimal? {
		paddingAmount.isEmpty ? RETDecimal.zero() : try? RETDecimal(formattedString: paddingAmount)
	}

	var parsedTipPercentage: UInt16? {
		tipPercentage.isEmpty ? .zero : UInt16(tipPercentage)
	}
}
