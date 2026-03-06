// MARK: - ___VARIABLE_featureName___

struct ___VARIABLE_featureName___: FeatureReducer {
	struct State: Hashable {}

	enum ViewAction: Equatable {
		case appeared
	}

	func reduce(into _: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .appeared:
			.none
		}
	}
}
