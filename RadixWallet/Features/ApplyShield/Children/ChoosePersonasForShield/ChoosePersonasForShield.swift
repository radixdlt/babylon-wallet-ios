@Reducer
struct ChoosePersonasForShield: Sendable, FeatureReducer {
	@ObservableState
	struct State: Sendable, Hashable {
		var choosePersonas: ChoosePersonas.State
		var footerControlState: ControlState = .enabled
	}

	typealias Action = FeatureAction<Self>

	enum ViewAction: Sendable, Equatable {
		case continueButtonTapped([PersonaRow.State])
	}

	@CasePathable
	enum ChildAction: Sendable, Equatable {
		case choosePersonas(ChoosePersonas.Action)
	}

	enum DelegateAction: Sendable, Equatable {
		case finished([IdentityAddress])
	}

	var body: some ReducerOf<Self> {
		Scope(state: \.choosePersonas, action: \.child.choosePersonas) {
			ChoosePersonas()
		}
		Reduce(core)
	}

	func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case let .continueButtonTapped(selectedPersonas):
			let addresses = selectedPersonas.map(\.persona.address)
			return .send(.delegate(.finished(addresses)))
		}
	}
}
