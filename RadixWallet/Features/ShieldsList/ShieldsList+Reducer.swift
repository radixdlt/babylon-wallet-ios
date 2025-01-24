import ComposableArchitecture
import Sargon

// MARK: - ShieldsList
@Reducer
struct ShieldsList: FeatureReducer, Sendable {
	@ObservableState
	struct State: Hashable, Sendable {
		var shields: [ShieldForDisplay] = []

		@Presents
		var destination: Destination.State? = nil
	}

	typealias Action = FeatureAction<Self>

	@CasePathable
	enum ViewAction: Equatable, Sendable {
		case task
		case changeMainButtonTapped
		case createShieldButtonTapped
	}

	enum InternalAction: Equatable, Sendable {
		case setShields([ShieldForDisplay])
	}

	enum DelegateAction: Equatable, Sendable {
		case finished
	}

	struct Destination: DestinationReducer {
		@CasePathable
		enum State: Sendable, Hashable {
			case securityShieldsSetup(ShieldSetupCoordinator.State)
			case changeMain(ChangeMainShield.State)
		}

		@CasePathable
		enum Action: Sendable, Equatable {
			case securityShieldsSetup(ShieldSetupCoordinator.Action)
			case changeMain(ChangeMainShield.Action)
		}

		var body: some ReducerOf<Self> {
			Scope(state: \.securityShieldsSetup, action: \.securityShieldsSetup) {
				ShieldSetupCoordinator()
			}
			Scope(state: \.changeMain, action: \.changeMain) {
				ChangeMainShield()
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
			return shieldsEffect()
		case .changeMainButtonTapped:
			state.destination = .changeMain(.init(currentMain: state.main))
			return .none
		case .createShieldButtonTapped:
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
		case .securityShieldsSetup(.delegate(.finished)):
			state.destination = nil
			return shieldsEffect()
		case .changeMain(.delegate(.updated)):
			state.destination = nil
			return shieldsEffect()
		default:
			return .none
		}
	}

	private func shieldsEffect() -> Effect<Action> {
		.run { send in
			let shields = try SargonOS.shared.securityStructuresOfFactorSources()
				.map {
					if $0.metadata.displayName == "Test shield" {
						ShieldForDisplay(shield: $0, status: .applied, isMain: true)
					} else {
						ShieldForDisplay(shield: $0)
					}
				}
			await send(.internal(.setShields(shields)))
		} catch: { error, _ in
			errorQueue.schedule(error)
		}
	}
}

// MARK: - ShieldForDisplay
// TEMP
struct ShieldForDisplay: Hashable, Sendable {
	let id: SecurityStructureId
	let name: DisplayName
	let status: ShieldCardStatus
	let isMain: Bool

	init(
		shield: SecurityStructureOfFactorSources,
		status: ShieldCardStatus = .notApplied,
		isMain: Bool = false
	) {
		self.id = shield.metadata.id
		self.name = shield.metadata.displayName
		self.status = status
		self.isMain = isMain
	}
}
