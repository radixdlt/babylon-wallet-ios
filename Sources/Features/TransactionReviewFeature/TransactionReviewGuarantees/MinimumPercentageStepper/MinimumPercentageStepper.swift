import FeaturePrelude

// MARK: - MinimumPercentageStepper
public struct MinimumPercentageStepper: FeatureReducer {
	public struct State: Sendable, Hashable {
		public var value: BigDecimal
		var string: String

		var isValid: Bool {
			BigDecimal(validated: string) != nil
		}

		public init(value: BigDecimal) {
			let clamped = value.clamped.withScale(2).droppingTrailingZeros
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

	public func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case .increaseTapped:
			let value = (state.value + percentageDelta).clamped
			state.value = value
			state.string = value.formatWithoutRounding()

		case .decreaseTapped:
			let value = (state.value - percentageDelta).clamped
			state.value = value
			state.string = value.formatWithoutRounding()

		case let .stringEntered(string):
			state.string = string
			guard let value = BigDecimal(validated: string) else { return .none }
			state.value = value
		}

		return .send(.delegate(.valueChanged))
	}

	private let percentageDelta: BigDecimal = 0.1
}

extension BigDecimal {
	var clamped: BigDecimal {
		if self <= 0 {
			return 0
		} else if self >= 100 {
			return 100
		}

		return self
	}

	init?(validated string: String) {
		guard let value = try? BigDecimal(localizedFromString: string) else { return nil }
		guard value >= 0, value <= 100 else { return nil }
		self = value
	}
}

extension MinimumPercentageStepper.State {
	var disablePlus: Bool {
		value >= 100
	}

	var disableMinus: Bool {
		value <= 0
	}
}
