import FeaturePrelude

extension MinimumPercentageStepper.State {
	var isValid: Bool {
		value != nil
	}
}

// MARK: - MinimumPercentageStepper
public struct MinimumPercentageStepper: FeatureReducer {
	public struct State: Sendable, Hashable {
		public var value: RETDecimal?
		var string: String

		public init(value: RETDecimal) {
			let clamped = value.withScale(2).clamped.droppingTrailingZeros
			self.value = clamped
			self.string = clamped.formatWithoutRounding()
		}
	}

	public enum ViewAction: Sendable, Equatable {
		case increaseTapped
		case decreaseTapped
		case stringEntered(String)
	}

	public enum DelegateAction: Sendable, Equatable {
		case valueChanged
	}

	public init() {}

	public func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .increaseTapped:
			let value = state.value.map { $0 + percentageDelta } ?? 100
			let clamped = value.clamped.droppingTrailingZeros
			state.value = clamped
			state.string = clamped.formatWithoutRounding()

		case .decreaseTapped:
			let value = state.value.map { $0 - percentageDelta } ?? 0
			let clamped = value.clamped.droppingTrailingZeros
			state.value = clamped
			state.string = clamped.formatWithoutRounding()

		case let .stringEntered(string):
			state.string = string
			if string.isEmpty {
				state.value = 0
			} else if let value = try? RETDecimal(formattedString: string), value >= 0 {
				state.value = value.droppingTrailingZeros
			} else {
				state.value = nil
			}
		}

		return .send(.delegate(.valueChanged))
	}

	private let percentageDelta: RETDecimal = 0.1
}

extension MinimumPercentageStepper.State {
	var disableMinus: Bool {
		value.map { $0 <= 0 } ?? false
	}
}
