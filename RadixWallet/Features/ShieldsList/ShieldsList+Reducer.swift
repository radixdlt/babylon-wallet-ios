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
			case applyShield(ApplyShield.Coordinator.State)
		}

		@CasePathable
		enum Action: Sendable, Equatable {
			case securityShieldsSetup(ShieldSetupCoordinator.Action)
			case changeMain(ChangeMainShield.Action)
			case applyShield(ApplyShield.Coordinator.Action)
		}

		var body: some ReducerOf<Self> {
			Scope(state: \.securityShieldsSetup, action: \.securityShieldsSetup) {
				ShieldSetupCoordinator()
			}
			Scope(state: \.changeMain, action: \.changeMain) {
				ChangeMainShield()
			}
			Scope(state: \.applyShield, action: \.applyShield) {
				ApplyShield.Coordinator()
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
		case let .securityShieldsSetup(.delegate(.finished(shieldID))):
			state.destination = .applyShield(.init(shieldID: shieldID))
			return shieldsEffect()
		case .changeMain(.delegate(.updated)):
			state.destination = nil
			return shieldsEffect()
		case .applyShield(.delegate(.skipped)),
		     .applyShield(.delegate(.finished)):
			state.destination = nil
			return .none
		default:
			return .none
		}
	}

	private func shieldsEffect() -> Effect<Action> {
		.run { send in
			let shields = try SargonOS.shared.securityStructuresOfFactorSources()
				.map {
					ShieldForDisplay(metadata: $0.metadata)
				}
			await send(.internal(.setShields(shields)))
		} catch: { error, _ in
			errorQueue.schedule(error)
		}
	}
}

// MARK: - ShieldForDisplay
// TODO: use Sargon model
struct ShieldForDisplay: Hashable, Sendable {
	let metadata: SecurityStructureMetadata
	let numberOfLinkedAccounts: Int = 3
	let numberOfLinkedPersonas: Int = 2

	let status: ShieldCardStatus

	var isMain: Bool {
		metadata.flags.contains(.main)
	}

	init(
		metadata: SecurityStructureMetadata,
		status: ShieldCardStatus = .notApplied
	) {
		self.metadata = metadata
		self.status = status
	}
}
