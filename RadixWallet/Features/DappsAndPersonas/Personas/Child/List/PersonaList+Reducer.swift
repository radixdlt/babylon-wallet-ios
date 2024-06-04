import ComposableArchitecture
import Sargon
import SwiftUI

// MARK: - PersonaList
public struct PersonaList: Sendable, FeatureReducer {
	@Dependency(\.authorizedDappsClient) var authorizedDappsClient
	@Dependency(\.personasClient) var personasClient
	@Dependency(\.errorQueue) var errorQueue

	public struct State: Sendable, Hashable {
		public var personas: IdentifiedArrayOf<PersonaFeature.State>
		public let strategy: ReloadingStrategy

		public init(
			personas: IdentifiedArrayOf<PersonaFeature.State> = [],
			strategy: ReloadingStrategy = .all
		) {
			self.personas = personas
			self.strategy = strategy
		}

		public init(
			dApp: AuthorizedDappDetailed
		) {
			self.init(
				personas: dApp.detailedAuthorizedPersonas.map(PersonaFeature.State.init).asIdentified(),
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

	@CasePathable
	public enum ChildAction: Sendable, Equatable {
		case persona(id: Persona.ID, action: PersonaFeature.Action)
	}

	public enum DelegateAction: Sendable, Equatable {
		case createNewPersona
		case openDetails(Persona)
		case openSecurityCenter
	}

	public enum InternalAction: Sendable, Equatable {
		case personasLoaded(IdentifiedArrayOf<PersonaFeature.State>)
	}

	public init() {}

	public var body: some ReducerOf<Self> {
		Reduce(core)
			.forEach(\.personas, action: /Action.child .. ChildAction.persona) {
				PersonaFeature()
			}
	}

	public func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .task:
			.run { [strategy = state.strategy] send in
				for try await personas in await personasClient.personas() {
					guard !Task.isCancelled else { return }
					let ids = try await personaIDs(strategy) ?? OrderedSet(validating: personas.ids)
					let result = ids.compactMap { personas[id: $0] }.map(PersonaFeature.State.init)
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
			return OrderedSet(dApp.detailedAuthorizedPersonas.map(\.id))
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
		case let .persona(id, action: .delegate(delegateAction)):
			switch delegateAction {
			case .openDetails:
				.run { send in
					let persona = try await personasClient.getPersona(id: id)
					await send(.delegate(.openDetails(persona)))
				} catch: { error, _ in
					errorQueue.schedule(error)
				}
			case .openSecurityCenter:
				.send(.delegate(.openSecurityCenter))
			}

		case .persona:
			.none
		}
	}
}
