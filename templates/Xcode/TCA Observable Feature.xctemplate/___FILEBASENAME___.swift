// MARK: - ___VARIABLE_featureName___
@Reducer
struct ___VARIABLE_featureName___: FeatureReducer {
	@ObservableState
	struct State: Hashable {
		init() {}
	}

	typealias Action = FeatureAction<Self>

	enum ViewAction: Equatable {
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
