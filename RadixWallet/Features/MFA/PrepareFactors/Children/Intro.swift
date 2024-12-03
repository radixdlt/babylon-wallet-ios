extension PrepareFactors {
	@Reducer
	struct Intro: Sendable, FeatureReducer {
		@ObservableState
		struct State: Sendable, Hashable {
			init() {}
		}

		typealias Action = FeatureAction<Self>

		enum ViewAction: Sendable, Equatable {
			case startButtonTapped
			case closeButtonTapped
		}

		enum DelegateAction: Sendable, Equatable {
			case start
			case dismiss
		}

		var body: some ReducerOf<Self> {
			Reduce(core)
		}

		func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
			switch viewAction {
			case .startButtonTapped:
				.send(.delegate(.start))
			case .closeButtonTapped:
				.send(.delegate(.dismiss))
			}
		}
	}
}
