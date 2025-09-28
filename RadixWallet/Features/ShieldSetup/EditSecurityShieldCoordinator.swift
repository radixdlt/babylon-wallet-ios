// MARK: - ShieldSetupCoordinator
@Reducer
struct EditSecurityShieldCoordinator: Sendable, FeatureReducer {
	@ObservableState
	struct State: Sendable, Hashable {
		@Shared(.shieldBuilder) var shieldBuilder

		var rolesSetup: RolesSetupCoordinator.State = .init()
		var path: StackState<Path.State> = .init()
	}

	@Reducer(state: .hashable, action: .equatable)
	enum Path {
		case rolesSetup(RolesSetupCoordinator)
	}

	typealias Action = FeatureAction<Self>

	enum ViewAction: Sendable, Equatable {
		case closeButtonTapped
	}

	@CasePathable
	enum ChildAction: Sendable, Equatable {
		case rolesSetup(RolesSetupCoordinator.Action)
		case path(StackActionOf<Path>)
	}

	enum DelegateAction: Equatable, Sendable {
		case updated
		case cancelled
	}

	var body: some ReducerOf<Self> {
		Scope(state: \.rolesSetup, action: \.child.rolesSetup) {
			RolesSetupCoordinator()
		}
		Reduce(core)
			.forEach(\.path, action: \.child.path)
	}

	func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .closeButtonTapped:
			.send(.delegate(.cancelled))
		}
	}

	func reduce(into state: inout State, childAction: ChildAction) -> Effect<Action> {
		switch childAction {
		case let .rolesSetup(.delegate(.push(path))), let .path(.element(id: _, action: .rolesSetup(.delegate(.push(path))))):
			state.path.append(.rolesSetup(.init(path: path)))
			return .none
		case .path(.element(id: _, action: .rolesSetup(.delegate(.finished)))):
			return .send(.delegate(.updated))
		default:
			return .none
		}
	}
}
