// MARK: - PasswordFactorSourceAccess
@Reducer
struct PasswordFactorSourceAccess: Sendable, FeatureReducer {
	@ObservableState
	struct State: Sendable, Hashable {
		let factorSource: PasswordFactorSource
		var input: String = "" {
			didSet {
				showError = false
			}
		}

		var showError = false
	}

	typealias Action = FeatureAction<Self>

	@CasePathable
	enum ViewAction: Sendable, Hashable {
		case inputChanged(String)
		case confirmButtonTapped
	}

	enum DelegateAction: Sendable, Hashable {
		case inputtedPassword(String)
	}

	var body: some ReducerOf<Self> {
		Reduce(core)
	}

	func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case let .inputChanged(input):
			state.input = input
			return .none

		case .confirmButtonTapped:
			// TODO: Validate input matches password id
			if state.input.count < 5 {
				state.showError = true
				return .none
			} else {
				return .send(.delegate(.inputtedPassword(state.input)))
			}
		}
	}
}
