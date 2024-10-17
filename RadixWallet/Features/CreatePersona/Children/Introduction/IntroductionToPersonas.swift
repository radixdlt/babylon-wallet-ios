@Reducer
struct IntroductionToPersonas: Sendable, FeatureReducer {
	@ObservableState
	struct State: Sendable, Hashable {}

	typealias Action = FeatureAction<Self>

	enum ViewAction: Sendable, Equatable {
		case continueButtonTapped
	}

	enum DelegateAction: Sendable, Equatable {
		case done
	}

	init() {}

	var body: some ReducerOf<Self> {
		Reduce(core)
	}

	func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .continueButtonTapped:
			.send(.delegate(.done))
		}
	}
}
