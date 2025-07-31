// MARK: - ArculusFactorSourceAccess
@Reducer
struct ArculusFactorSourceAccess: Sendable, FeatureReducer {
	@ObservableState
	struct State: Sendable, Hashable {
		let factorSource: ArculusCardFactorSource
		var pinInput: ArculusPINInput.State = .init(shouldConfirmPIN: false)
	}

	typealias Action = FeatureAction<Self>

	enum ViewAction: Sendable, Hashable {
		case pinAdded(String)
	}

	@CasePathable
	enum ChildAction: Sendable, Hashable {
		case pinInput(ArculusPINInput.Action)
	}

	enum DelegateAction: Sendable, Hashable {
		case perform(PrivateFactorSource)
	}

	var body: some ReducerOf<Self> {
		Scope(state: \.pinInput, action: \.child.pinInput) {
			ArculusPINInput()
		}
		Reduce(core)
	}

	func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case let .pinAdded(pin):
			.send(.delegate(.perform(.arculusCard(state.factorSource, pin))))
		}
	}
}
