import ComposableArchitecture

@Reducer
struct SelectFactorSourcesCoordinator: Sendable, FeatureReducer {
	@ObservableState
	struct State: Sendable, Hashable {
		var path: Path.State
	}

	@Reducer(state: .hashable, action: .equatable)
	enum Path {
		case selectFactorSources(SelectFactorSources)
	}

	typealias Action = FeatureAction<Self>

	@CasePathable
	enum ChildAction: Sendable, Equatable {
		case path(Path.Action)
	}

	enum DelegateAction: Sendable, Equatable {
		case finished
		case push(Path.State)
	}

	var body: some ReducerOf<Self> {
		Scope(state: \.path, action: \.child.path) {
			Path.selectFactorSources(SelectFactorSources())
		}
		Reduce(core)
	}

	func reduce(into state: inout State, childAction: ChildAction) -> Effect<Action> {
		switch childAction {
		case .path(.selectFactorSources(.delegate(.finished))):
			.send(.delegate(.finished))
		default:
			.none
		}
	}
}
