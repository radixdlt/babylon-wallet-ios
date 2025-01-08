// MARK: - ChooseFactorSourceKind
@Reducer
struct ChooseFactorSourceKind: Sendable, FeatureReducer {
	@ObservableState
	struct State: Sendable, Hashable {
		init() {}
	}

	typealias Action = FeatureAction<Self>

	enum ViewAction: Sendable, Equatable {
		case task
		case kindTapped(FactorSourceKind)
	}

	enum DelegateAction: Sendable, Equatable {
		case chosenKind(FactorSourceKind)
	}

	var body: some ReducerOf<Self> {
		Reduce(core)
	}

	func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .task:
			.none
		case let .kindTapped(kind):
			.send(.delegate(.chosenKind(kind)))
		}
	}
}
