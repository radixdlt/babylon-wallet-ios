@Reducer
struct RolesSetupCoordinator: Sendable, FeatureReducer {
	@ObservableState
	struct State: Sendable, Hashable {
		var path: Path.State = .primaryRoleSetup(.init())

		@Presents
		var destination: Destination.State?
	}

	@Reducer(state: .hashable, action: .equatable)
	enum Path {
		case primaryRoleSetup(PrimaryRoleSetup)
		case recoveryRoleSetup(RecoveryRoleSetup)
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

	struct Destination: DestinationReducer {
		@CasePathable
		enum State: Sendable, Hashable {
			case chooseFactorSource(ChooseFactorSourceCoordinator.State)
		}

		@CasePathable
		enum Action: Sendable, Equatable {
			case chooseFactorSource(ChooseFactorSourceCoordinator.Action)
		}

		var body: some ReducerOf<Self> {
			Scope(state: \.chooseFactorSource, action: \.chooseFactorSource) {
				ChooseFactorSourceCoordinator()
			}
		}
	}

	var body: some ReducerOf<Self> {
		Scope(state: \.path, action: \.child.path) {
			Path.primaryRoleSetup(PrimaryRoleSetup())
		}
		Reduce(core)
			.ifLet(destinationPath, action: \.destination) {
				Destination()
			}
	}

	private let destinationPath: WritableKeyPath<State, PresentationState<Destination.State>> = \.$destination

	func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .completionButtonTapped:
			.send(.delegate(.finished))
		}
	}

	func reduce(into state: inout State, childAction: ChildAction) -> Effect<Action> {
		switch childAction {
		case let .path(.primaryRoleSetup(.delegate(.chooseFactorSource(context)))),
		     let .path(.recoveryRoleSetup(.delegate(.chooseFactorSource(context)))):
			state.destination = .chooseFactorSource(.init(context: context))
			return .none
		case .path(.primaryRoleSetup(.delegate(.finished))):
			return .send(.delegate(.push(.recoveryRoleSetup(.init()))))
		default:
			return .none
		}
	}

	func reduce(into state: inout State, presentedAction: Destination.Action) -> Effect<Action> {
		switch presentedAction {
		case .chooseFactorSource(.delegate(.finished)):
			state.destination = nil
			return .none
		default:
			return .none
		}
	}
}
