import ComposableArchitecture
import SwiftUI

// MARK: - PersonaList
public struct PersonaList: Sendable, FeatureReducer {
	@Dependency(\.authorizedDappsClient) var authorizedDappsClient
	@Dependency(\.personasClient) var personasClient
	@Dependency(\.errorQueue) var errorQueue

	public struct State: Sendable, Hashable {
		public var personas: IdentifiedArrayOf<PersonaReducer.State>
		public let strategy: ReloadingStrategy

		public init(
			personas: IdentifiedArrayOf<PersonaReducer.State> = [],
			strategy: ReloadingStrategy = .all
		) {
			self.personas = personas
			self.strategy = strategy
		}

		public init(
			dApp: Sargon.ProfileNetwork.AuthorizedDappDetailed
		) {
			self.init(
				personas: dApp.detailedAuthorizedPersonas.map(PersonaReducer.State.init).asIdentified(),
				strategy: .dApp(dApp.dAppDefinitionAddress)
			)
		}

		public enum ReloadingStrategy: Sendable, Hashable {
			case all
			case ids(OrderedSet<Persona.ID>)
			case dApp(AuthorizedDapp.ID)
		}
	}

	public enum ViewAction: Sendable, Equatable {
		case task
		case createNewPersonaButtonTapped
	}

	public enum ChildAction: Sendable, Equatable {
		case persona(id: Persona.ID, action: PersonaReducer.Action)
	}

	public enum DelegateAction: Sendable, Equatable {
		case createNewPersona
		case openDetails(Persona)
		case exportMnemonic(Persona)
	}

	public enum InternalAction: Sendable, Equatable {
		case personasLoaded(IdentifiedArrayOf<PersonaReducer.State>)
	}

	public init() {}

	public var body: some ReducerOf<Self> {
		Reduce(core)
			.forEach(\.personas, action: /Action.child .. ChildAction.persona) {
				PersonaReducer()
			}
	}

	public func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .task:
			.run { [strategy = state.strategy] send in
				for try await personas in await personasClient.personas() {
					guard !Task.isCancelled else { return }
					let ids = try await personaIDs(strategy) ?? personas.ids
					let result = ids.compactMap { personas[id: $0] }.map(PersonaReducer.State.init)
					guard result.count == ids.count else {
						throw UpdatePersonaError.personasMissingFromClient(ids.subtracting(result.map(\.id)))
					}
					await send(.internal(.personasLoaded(result.asIdentified())))
				}
			} catch: { error, _ in
				loggerGlobal.error("Failed to update personas from client, error: \(error)")
				errorQueue.schedule(error)
			}

		case .createNewPersonaButtonTapped:
			.send(.delegate(.createNewPersona))
		}
	}

	enum UpdatePersonaError: Error {
		case personasMissingFromClient(OrderedSet<Persona.ID>)
	}

	/// Returns the ids of personas to include under the given strategy. nil means that all ids should be included
	private func personaIDs(_ strategy: State.ReloadingStrategy) async throws -> OrderedSet<Persona.ID>? {
		switch strategy {
		case .all:
			return nil
		case let .ids(ids):
			return ids
		case let .dApp(dAppID):
			guard let dApp = try? await authorizedDappsClient.getDetailedDapp(dAppID) else { return [] }
			return dApp.detailedAuthorizedPersonas.ids
		}
	}

	public func reduce(into state: inout State, internalAction: InternalAction) -> Effect<Action> {
		switch internalAction {
		case let .personasLoaded(personas):
			state.personas = personas
			return .none
		}
	}

	public func reduce(into state: inout State, childAction: ChildAction) -> Effect<Action> {
		switch childAction {
		case .persona(id: let id, action: .delegate(.openDetails)):
			.run { send in
				let persona = try await personasClient.getPersona(id: id)
				await send(.delegate(.openDetails(persona)))
			}

		case .persona(id: let id, action: .delegate(.writeDownSeedPhrase)):
			.run { send in
				let persona = try await personasClient.getPersona(id: id)
				await send(.delegate(.exportMnemonic(persona)))
			}
		case .persona:
			.none
		}
	}
}
