import ComposableArchitecture
import Sargon

// MARK: - ShieldsList
@Reducer
struct ShieldsList: FeatureReducer, Sendable {
	@ObservableState
	struct State: Hashable, Sendable {
		var shields: [SecurityStructureOfFactorSources] = []

		@Presents
		var destination: Destination.State? = nil
	}

	typealias Action = FeatureAction<Self>

	@CasePathable
	enum ViewAction: Equatable, Sendable {
		case task
		case createShieldButtonTapped
		case shieldTapped(SecurityStructureId)
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
			case applyShield(ApplyShield.Coordinator.State)
			case shieldTemplateDetails(ShieldTemplateDetails.State)
		}

		@CasePathable
		enum Action: Sendable, Equatable {
			case securityShieldsSetup(ShieldSetupCoordinator.Action)
			case applyShield(ApplyShield.Coordinator.Action)
			case shieldTemplateDetails(ShieldTemplateDetails.Action)
		}

		var body: some ReducerOf<Self> {
			Scope(state: \.securityShieldsSetup, action: \.securityShieldsSetup) {
				ShieldSetupCoordinator()
			}
			Scope(state: \.applyShield, action: \.applyShield) {
				ApplyShield.Coordinator()
			}
			Scope(state: \.shieldTemplateDetails, action: \.shieldTemplateDetails) {
				ShieldTemplateDetails()
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
			state.shields = try! SargonOS.shared.securityStructuresOfFactorSources()
			return .none
		case .createShieldButtonTapped:
			state.destination = .securityShieldsSetup(.init())
			return .none
		case let .shieldTapped(id):
			let structure = try! SargonOs.shared.securityStructureOfFactorSourcesFromSecurityStructureOfFactorSourceIds(structureOfIds:
				SargonOS.shared.securityStructureOfFactorSourceIdsBySecurityStructureId(shieldId: id)
			)
			state.destination = .shieldTemplateDetails(.init(structure: structure))
			return .none
		}
	}

	func reduce(into state: inout State, presentedAction: Destination.Action) -> Effect<Action> {
		switch presentedAction {
		case let .securityShieldsSetup(.delegate(.finished(securityStructure))):
			state.destination = .applyShield(.init(securityStructure: securityStructure))
			state.shields = try! SargonOS.shared.securityStructuresOfFactorSources()
			return .none
		case .applyShield(.delegate(.skipped)),
		     .applyShield(.delegate(.finished)):
			state.destination = nil
			return .none
		default:
			return .none
		}
	}

//	private func shieldsEffect() -> Effect<Action> {
//		.run { send in
	//            let shields = try await SargonOS.shared.securityStructuresOfFactorSources()
//			await send(.internal(.setShields(shields)))
//		} catch: { error, _ in
//			errorQueue.schedule(error)
//		}
//	}
}
