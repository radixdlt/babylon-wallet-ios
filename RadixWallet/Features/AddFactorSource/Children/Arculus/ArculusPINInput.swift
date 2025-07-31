// MARK: - ArculusCreatePIN
@Reducer
struct ArculusPINInput: Sendable, FeatureReducer {
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

		var isPINConfirmed: Bool? {
			guard shouldConfirmPIN else {
				return nil
			}

			if enteredPIN.count == pinLength, confirmedPIN.count == pinLength {
				return enteredPIN == confirmedPIN
			} else {
				return nil
			}
		}

		var pinInvalidHint: Hint.ViewState? {
			isPINConfirmed.flatMap { isConfirmed in
				if !isConfirmed {
					Hint.ViewState.error("PIN's do not match")
				} else {
					nil
				}
			}
		}

		var validatedPin: String? {
			if shouldConfirmPIN {
				isPINConfirmed.flatMap { isConfirmed in
					if isConfirmed {
						String(confirmedPIN)
					} else {
						nil
					}
				}
			} else {
				if enteredPIN.count == pinLength {
					String(enteredPIN)
				} else {
					nil
				}
			}
		}

		let shouldConfirmPIN: Bool
	}

	typealias Action = FeatureAction<Self>

	@CasePathable
	enum ViewAction: Sendable, Hashable {
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
