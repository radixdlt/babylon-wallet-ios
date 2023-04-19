import CreateEntityFeature
import FeaturePrelude
import PersonaDetailsFeature
import PersonasClient

// MARK: - PersonasCoordinator
public struct PersonasCoordinator: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		public var personaList: PersonaList.State

		@PresentationState
		public var createPersonaCoordinator: CreatePersonaCoordinator.State?

		@PresentationState
		public var personaDetails: PersonaDetails.State? = nil

		public var isFirstPersonaOnAnyNetwork: Bool? = nil

		public init(
			personaList: PersonaList.State = .init(),
			createPersonaCoordinator: CreatePersonaCoordinator.State? = nil,
			isFirstPersonaOnAnyNetwork: Bool? = nil
		) {
			self.personaList = personaList
			self.createPersonaCoordinator = createPersonaCoordinator
			self.isFirstPersonaOnAnyNetwork = isFirstPersonaOnAnyNetwork
		}
	}

	public enum ViewAction: Sendable, Equatable {
		case task
		case appeared
	}

	public enum InternalAction: Sendable & Equatable {
		case loadPersonasResult(TaskResult<IdentifiedArrayOf<Profile.Network.Persona>>)
		case isFirstPersonaOnAnyNetwork(Bool)
	}

	public enum ChildAction: Sendable, Equatable {
		case personaList(PersonaList.Action)

		case createPersonaCoordinator(PresentationAction<CreatePersonaCoordinator.Action>)
		case personaDetails(PresentationAction<PersonaDetails.Action>)
	}

	// PersonasFeature Coordinator State personaList createPersona isFirst OnAnyNetwork CreateEntity no Profile

	@Dependency(\.errorQueue) var errorQueue
	@Dependency(\.personasClient) var personasClient

	public init() {}

	public var body: some ReducerProtocolOf<Self> {
		Scope(state: \.personaList, action: /Action.child .. ChildAction.personaList) {
			PersonaList()
		}
		Reduce(core)
			.ifLet(\.$createPersonaCoordinator, action: /Action.child .. ChildAction.createPersonaCoordinator) {
				CreatePersonaCoordinator()
			}
			.ifLet(\.$personaDetails, action: /Action.child .. ChildAction.personaDetails) {
				PersonaDetails()
			}
	}

	public func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case .task:
			return .run { send in
				for try await personas in await personasClient.personas() {
					guard !Task.isCancelled else {
						return
					}
					print("•• personasClient.personas()")
					await send(.internal(.loadPersonasResult(.success(personas))))
				}
			} catch: { error, send in
				await send(.internal(.loadPersonasResult(.failure(error))))
			}

		case .appeared:
			print("•REMOVED• appeared")
			return checkIfFirstPersonaByUserEver()
		}
	}

	public func reduce(into state: inout State, internalAction: InternalAction) -> EffectTask<Action> {
		switch internalAction {
		case let .loadPersonasResult(.success(personas)):
			print("•• loadPersonasResult success")
//			state.personaList.personas = .init(uniqueElements: personas.map(Persona.State.init))
			return .none
		case let .isFirstPersonaOnAnyNetwork(isFirstPersonaOnAnyNetwork):
			state.isFirstPersonaOnAnyNetwork = isFirstPersonaOnAnyNetwork
			return .none
		case let .loadPersonasResult(.failure(error)):
			errorQueue.schedule(error)
			return .none
		}
	}

	public func reduce(into state: inout State, childAction: ChildAction) -> EffectTask<Action> {
		switch childAction {
		case .personaList(.delegate(.createNewPersona)):
			assert(state.isFirstPersonaOnAnyNetwork != nil, "Should have checked 'isFirstPersonaOnAnyNetwork' already")
			let isFirstOnThisNetwork = state.personaList.personas.count == 0
			let isFirstOnAnyNetwork = state.isFirstPersonaOnAnyNetwork ?? true

			state.createPersonaCoordinator = .init(
				config: .init(
					purpose: .newPersonaFromSettings(isFirst: isFirstOnThisNetwork)
				),
				displayIntroduction: { _ in
					isFirstOnAnyNetwork
				}
			)
			return .none

		case let .personaList(.delegate(.openDetails(persona))):
			state.personaDetails = PersonaDetails.State(.general(persona))
			return .none

		case .createPersonaCoordinator(.presented(.delegate(.dismissed))):
			state.createPersonaCoordinator = nil
			return .none

		case .createPersonaCoordinator(.presented(.delegate(.completed))):
			print("•REMAINS• createPersonaCoordinator(.presented(.delegate(.completed)))")
			state.createPersonaCoordinator = nil
			state.isFirstPersonaOnAnyNetwork = false
			return .none

		default:
			return .none
		}
	}
}

extension PersonasCoordinator {
	func checkIfFirstPersonaByUserEver() -> EffectTask<Action> {
		.task {
			let hasAnyPersonaOnAnyNetwork = await personasClient.hasAnyPersonaOnAnyNetwork()
			let isFirstPersonaOnAnyNetwork = !hasAnyPersonaOnAnyNetwork
			return .internal(.isFirstPersonaOnAnyNetwork(isFirstPersonaOnAnyNetwork))
		}
	}
}
