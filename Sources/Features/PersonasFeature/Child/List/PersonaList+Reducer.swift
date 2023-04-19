import FeaturePrelude
import PersonasClient

// MARK: - PersonaList
public struct PersonaList: Sendable, FeatureReducer {
	@Dependency(\.personasClient) var personasClient

	public struct State: Sendable, Hashable {
		public var personas: IdentifiedArrayOf<Persona.State>
		public let strategy: ReloadingStrategy

		/// Load all personas from the profile
		public init() {
			self.personas = []
			self.strategy = .all
		}

		public init(
			personas: IdentifiedArrayOf<Persona.State> = [],
			strategy: ReloadingStrategy = .all
		) {
			self.personas = personas
			self.strategy = strategy
		}

		public init(
			dApp: Profile.Network.AuthorizedDappDetailed
		) {
			self.personas = .init(uniqueElements: dApp.detailedAuthorizedPersonas.map(Persona.State.init))
			self.strategy = .dApp(dApp.dAppDefinitionAddress)
		}

		public enum ReloadingStrategy: Sendable, Hashable {
			case all
			case dApp(Profile.Network.AuthorizedDapp.ID)
			case personas(OrderedSet<Profile.Network.Persona.ID>)
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

		case .createNewPersonaButtonTapped:
			return .send(.delegate(.createNewPersona))
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
