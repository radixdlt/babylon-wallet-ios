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
		var problems: [SecurityProblem] = []

		public init(
			personas: IdentifiedArrayOf<PersonaFeature.State> = [],
			strategy: ReloadingStrategy = .all
		) {
			self.personas = personas
			self.strategy = strategy
		}

		public init(dApp: AuthorizedDappDetailed) {
			let personas = dApp.detailedAuthorizedPersonas.map { PersonaFeature.State(persona: $0, problems: []) }.asIdentified()
			self.init(personas: personas, strategy: .dApp(dApp.dAppDefinitionAddress))
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
		case setSecurityProblems([SecurityProblem])
	}

	@Dependency(\.securityCenterClient) var securityCenterClient

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
			personasEffect(state: state)
				.merge(with: securityProblemsEffect())

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
			state.personas.mutateAll { persona in
				// MB: Quick fix for concurrency issue caused by the await on the personasEffect.
				// Will work on better fix after release
				persona.securityProblemsConfig.update(problems: state.problems)
			}
			return .none

		case let .setSecurityProblems(problems):
			state.problems = problems
			state.personas.mutateAll { persona in
				persona.securityProblemsConfig.update(problems: problems)
			}
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

	private func personasEffect(state: State) -> Effect<Action> {
		.run { [strategy = state.strategy, problems = state.problems] send in
			for try await personas in await personasClient.personas() {
				guard !Task.isCancelled else { return }
				let ids = try await personaIDs(strategy) ?? OrderedSet(validating: personas.ids)
				let result = ids.compactMap { personas[id: $0] }.map { PersonaFeature.State(persona: $0, problems: problems) }
				guard result.count == ids.count else {
					throw UpdatePersonaError.personasMissingFromClient(ids.subtracting(result.map(\.id)))
				}
				await send(.internal(.personasLoaded(result.asIdentified())))
			}
		} catch: { error, _ in
			loggerGlobal.error("Failed to update personas from client, error: \(error)")
			errorQueue.schedule(error)
		}
	}

	private func securityProblemsEffect() -> Effect<Action> {
		.run { send in
			for try await problems in await securityCenterClient.problems() {
				guard !Task.isCancelled else { return }
				await send(.internal(.setSecurityProblems(problems)))
			}
		}
	}
}
