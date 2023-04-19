import AuthorizedDappsClient
import FeaturePrelude
import PersonasClient

// MARK: - PersonaList
public struct PersonaList: Sendable, FeatureReducer {
	@Dependency(\.authorizedDappsClient) var authorizedDappsClient
	@Dependency(\.personasClient) var personasClient

	public struct State: Sendable, Hashable {
		public var personas: IdentifiedArrayOf<Persona.State>
		public let strategy: ReloadingStrategy

		public init(
			dApp: Profile.Network.AuthorizedDappDetailed
		) {
			self.init(
				personas: .init(uniqueElements: dApp.detailedAuthorizedPersonas.map(Persona.State.init)),
				strategy: .dApp(dApp.dAppDefinitionAddress)
			)
		}

		public init(
			personas: IdentifiedArrayOf<Persona.State> = [],
			strategy: ReloadingStrategy = .all
		) {
			self.personas = personas
			self.strategy = strategy
		}

		public enum ReloadingStrategy: Sendable, Hashable {
			case all
			case ids(OrderedSet<Profile.Network.Persona.ID>)
			case dApp(Profile.Network.AuthorizedDapp.ID)
		}
	}

	public enum ViewAction: Sendable, Equatable {
		case task
		case createNewPersonaButtonTapped
	}

	public enum ChildAction: Sendable, Equatable {
		case persona(id: Profile.Network.Persona.ID, action: Persona.Action)
	}

	public enum DelegateAction: Sendable, Equatable {
		case createNewPersona
		case openDetails(Profile.Network.Persona)
	}

	public enum InternalAction: Sendable, Equatable {
		case personasLoaded(IdentifiedArrayOf<Persona.State>)
	}

	public init() {}

	public var body: some ReducerProtocolOf<Self> {
		Reduce(core)
			.forEach(\.personas, action: /Action.child .. ChildAction.persona) {
				Persona()
			}
	}

	public func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case .task:
			return .run { [strategy = state.strategy] send in
				for try await personas in await personasClient.personas() {
					print("•• Personas \(Task.isCancelled):", personas.map(\.displayName.rawValue))

					let ids = try await personaIDs(strategy) ?? personas.ids
					let result = ids.compactMap { personas[id: $0] }.map(Persona.State.init)
					await send(.internal(.personasLoaded(.init(uniqueElements: result))))
				}
				print("•• Personas \(Task.isCancelled): DONE")
			} catch: { _, _ in
			}

		case .createNewPersonaButtonTapped:
			return .send(.delegate(.createNewPersona))
		}
	}

	/// Returns the ids of personas to include under the given strategy. nil means that all ids should be included
	private func personaIDs(_ strategy: State.ReloadingStrategy) async throws -> OrderedSet<Profile.Network.Persona.ID>? {
		switch strategy {
		case .all:
			return nil
		case let .ids(ids):
			return ids
		case let .dApp(dAppID):
			return try await authorizedDappsClient.getDetailedDapp(dAppID).detailedAuthorizedPersonas.ids
		}
	}

	public func reduce(into state: inout State, internalAction: InternalAction) -> EffectTask<Action> {
		switch internalAction {
		case let .personasLoaded(personas):
			state.personas = personas
			return .none
		}
	}

	public func reduce(into state: inout State, childAction: ChildAction) -> EffectTask<Action> {
		switch childAction {
		case .persona(id: let id, action: .delegate(.openDetails)):
			return .task {
				let persona = try await personasClient.getPersona(id: id)
				return .delegate(.openDetails(persona))
			}

		case .persona:
			return .none
		}
	}
}
