@Reducer
struct RolesSetupCoordinator: Sendable, FeatureReducer {
	@ObservableState
	struct State: Sendable, Hashable {
		var path: Path.State = .regularAccessSetup(.init())
	}

	@Reducer(state: .hashable, action: .equatable)
	enum Path {
		case regularAccessSetup(RegularAccessSetup)
	}

	typealias Action = FeatureAction<Self>

	enum ViewAction: Sendable, Equatable {
		case completionButtonTapped
	}

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
			Path.regularAccessSetup(RegularAccessSetup())
		}
		Reduce(core)
	}

	func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .completionButtonTapped:
			.send(.delegate(.finished))
		}
	}

	func reduce(into state: inout State, childAction: ChildAction) -> Effect<Action> {
		switch childAction {
		case .path(.regularAccessSetup(.delegate(.finished))):
			.none
		default:
			.none
		}
	}
}
