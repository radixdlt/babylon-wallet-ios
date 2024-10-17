import ComposableArchitecture
import SwiftUI

extension MinimumPercentageStepper.State {
	var isValid: Bool {
		value != nil
	}
}

// MARK: - MinimumPercentageStepper
struct MinimumPercentageStepper: FeatureReducer {
	struct State: Sendable, Hashable {
		var value: Decimal192?
		var string: String

		init(value: Decimal192) {
			let clamped = value.clamped
			self.value = clamped
			// When first showing this view, we round the _displayed_ number, in case you don't touch it and return
			self.string = clamped.rounded(decimalPlaces: 2).formattedPlain()
		}
	}

	enum ViewAction: Sendable, Equatable {
		case increaseTapped
		case decreaseTapped
		case stringEntered(String)
	}

	enum DelegateAction: Sendable, Equatable {
		case valueChanged
	}

	init() {}

	func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .increaseTapped:
			let value = state.value.map { $0.floor(decimalPlaces: 0) + percentageDelta } ?? 100
			let clamped = value.clamped
			state.value = clamped
			state.string = clamped.formattedPlain()

		case .decreaseTapped:
			let value = state.value.map { $0.ceil(decimalPlaces: 0) - percentageDelta } ?? 0
			let clamped = value.clamped
			state.value = clamped
			state.string = clamped.formattedPlain()

		case let .stringEntered(string):
			state.string = string
			if string.isEmpty {
				state.value = 0
			} else if let value = try? Decimal192(formattedString: string), !value.isNegative {
				state.value = value
			} else {
				state.value = nil
			}
		}

		return .send(.delegate(.valueChanged))
	}

	private let percentageDelta: Decimal192 = 1
}

extension MinimumPercentageStepper.State {
	var disableMinus: Bool {
		value.map { $0 <= 0 } ?? false
	}
}
