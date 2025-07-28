// MARK: - ArculusCreatePIN
@Reducer
struct ArculusCreatePIN: Sendable, FeatureReducer {
	static let pinLength = 6

	@ObservableState
	struct State: Sendable, Hashable {
		var inputText: String = ""
		var enteredPIN: String.SubSequence {
			inputText.prefix(pinLength)
		}

		var confirmedPIN: String.SubSequence {
			if inputText.count > pinLength {
				let startIndex = inputText.index(inputText.startIndex, offsetBy: pinLength)
				return inputText[startIndex...]
			} else {
				return ""
			}
		}

		var isPINConfirmed: Bool {
			shouldConfirmPIN && enteredPIN == confirmedPIN
		}

		let shouldConfirmPIN: Bool
	}

	typealias Action = FeatureAction<Self>

	@CasePathable
	enum ViewAction: Sendable, Equatable {
		case appeared
		case enteredPINUpdated(String)
	}

	var body: some ReducerOf<Self> {
		Reduce(core)
	}

	func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .appeared:
			return .none
		case let .enteredPINUpdated(pin):
			guard pin.count <= (state.shouldConfirmPIN ? 2 * Self.pinLength : Self.pinLength) else {
				return .none
			}
			state.inputText = pin
			return .none
		}
	}
}
