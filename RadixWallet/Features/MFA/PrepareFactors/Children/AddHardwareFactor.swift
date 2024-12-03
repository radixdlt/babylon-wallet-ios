extension PrepareFactors {
	@Reducer
	struct AddHardwareFactor: Sendable, FeatureReducer {
		@ObservableState
		struct State: Sendable, Hashable {
			init() {}
		}

		typealias Action = FeatureAction<Self>

		enum ViewAction: Sendable, Equatable {
			case appeared
		}

		var body: some ReducerOf<Self> {
			Reduce(core)
		}

		func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
			switch viewAction {
			case .appeared:
				.none
			}
		}
	}
}
