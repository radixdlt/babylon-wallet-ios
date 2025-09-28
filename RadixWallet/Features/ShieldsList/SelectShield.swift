@Reducer
struct SelectShield: Sendable, FeatureReducer {
	@ObservableState
	struct State: Sendable, Hashable {
		var shields: [SecurityStructureOfFactorSources] = []
		var selected: SecurityStructureOfFactorSources?

		@Presents
		var destination: Destination.State? = nil
	}

	typealias Action = FeatureAction<Self>

	enum ViewAction: Sendable, Equatable {
		case task
		case selected(SecurityStructureOfFactorSources)
		case confirmButtonTapped(SecurityStructureOfFactorSources)
		case addShieldButtonTapped
	}

	enum InternalAction: Sendable, Equatable {
		case setShields([SecurityStructureOfFactorSources])
	}

	enum DelegateAction: Sendable, Equatable {
		case confirmed(SecurityStructureOfFactorSources)
	}

	struct Destination: DestinationReducer {
		@CasePathable
		enum State: Sendable, Hashable {
			case securityShieldsSetup(ShieldSetupCoordinator.State)
		}

		@CasePathable
		enum Action: Sendable, Equatable {
			case securityShieldsSetup(ShieldSetupCoordinator.Action)
		}

		var body: some ReducerOf<Self> {
			Scope(state: \.securityShieldsSetup, action: \.securityShieldsSetup) {
				ShieldSetupCoordinator()
			}
		}
	}

	var body: some ReducerOf<Self> {
		Reduce(core)
			.ifLet(destinationPath, action: \.destination) {
				Destination()
			}
	}

	private let destinationPath: WritableKeyPath<State, PresentationState<Destination.State>> = \.$destination

	@Dependency(\.errorQueue) var errorQueue

	func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .task:
			do {
				state.shields = try SargonOS.shared.securityStructuresOfFactorSources()
			} catch {
				errorQueue.schedule(error)
			}
			return .none

		case let .selected(shield):
			state.selected = shield
			return .none

		case let .confirmButtonTapped(shield):
			return .send(.delegate(.confirmed(shield)))

		case .addShieldButtonTapped:
			state.destination = .securityShieldsSetup(.init())
			return .none
		}
	}

	func reduce(into state: inout State, internalAction: InternalAction) -> Effect<Action> {
		switch internalAction {
		case let .setShields(shields):
			state.shields = shields
			return .none
		}
	}

	func reduce(into state: inout State, presentedAction: Destination.Action) -> Effect<Action> {
		switch presentedAction {
		case let .securityShieldsSetup(.delegate(.finished(structure))):
			state.shields.append(structure)
			state.selected = structure
			state.destination = nil
			return .none
		default:
			return .none
		}
	}
}
