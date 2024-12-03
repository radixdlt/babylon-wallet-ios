extension PrepareFactors {
	@Reducer
	struct AddHardwareFactor: Sendable, FeatureReducer {
		@ObservableState
		struct State: Sendable, Hashable {
			init() {}
		}

		typealias Action = FeatureAction<Self>

		enum ViewAction: Sendable, Equatable {
			case addButtonTapped
		}

		enum DelegateAction: Sendable, Equatable {
			case addedFactorSource
		}

		var body: some ReducerOf<Self> {
			Reduce(core)
		}

		func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
			switch viewAction {
			case .addButtonTapped:
				// Present flow to add Ledger or Arculus
				.send(.delegate(.addedFactorSource))
			}
		}
	}
}
