// MARK: - ShieldTemplateDetails
@Reducer
struct ShieldTemplateDetails: Sendable, FeatureReducer {
	@ObservableState
	struct State: Sendable, Hashable {
		let structure: SecurityStructureOfFactorSources
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
