import ComposableArchitecture
import SwiftUI

// MARK: - Settings
public struct Settings: Sendable, FeatureReducer {
	public typealias Store = StoreOf<Self>

	public init() {}

	// MARK: State

	public struct State: Sendable, Hashable {
		@PresentationState
		public var destination: Destination.State?

		public var userHasNoP2PLinks: Bool? = nil
		public var securityProblems: [SecurityProblem] = []
		fileprivate var personas: [IdentityAddress] = []

		public init() {}
	}

	// MARK: Action

	public enum ViewAction: Sendable, Equatable {
		case task
		case addConnectorButtonTapped
		case securityCenterButtonTapped
		case personasButtonTapped
		case dappsButtonTapped
		case connectorsButtonTapped
		case preferencesButtonTapped
		case troubleshootingButtonTapped
		case debugButtonTapped
	}

	public enum InternalAction: Sendable, Equatable {
		case setP2PLinks(P2PLinks)
		case setSecurityProblems([SecurityProblem])
		case setPersonas([IdentityAddress])
	}

	public struct Destination: DestinationReducer {
		@CasePathable
		public enum State: Sendable, Hashable {
			case securityCenter(SecurityCenter.State)
			case manageP2PLinks(P2PLinksFeature.State)
			case authorizedDapps(AuthorizedDappsFeature.State)
			case personas(PersonasCoordinator.State)
			case preferences(Preferences.State)
			case troubleshooting(Troubleshooting.State)
			case debugSettings(DebugSettingsCoordinator.State)
		}

		@CasePathable
		public enum Action: Sendable, Equatable {
			case securityCenter(SecurityCenter.Action)
			case manageP2PLinks(P2PLinksFeature.Action)
			case authorizedDapps(AuthorizedDappsFeature.Action)
			case personas(PersonasCoordinator.Action)
			case preferences(Preferences.Action)
			case troubleshooting(Troubleshooting.Action)
			case debugSettings(DebugSettingsCoordinator.Action)
		}

		public var body: some ReducerOf<Self> {
			Scope(state: \.securityCenter, action: \.securityCenter) {
				SecurityCenter()
			}
			Scope(state: \.manageP2PLinks, action: \.manageP2PLinks) {
				P2PLinksFeature()
			}
			Scope(state: \.authorizedDapps, action: \.authorizedDapps) {
				AuthorizedDappsFeature()
			}
			Scope(state: \.personas, action: \.personas) {
				PersonasCoordinator()
			}
			Scope(state: \.preferences, action: \.preferences) {
				Preferences()
			}
			Scope(state: \.troubleshooting, action: \.troubleshooting) {
				Troubleshooting()
			}
			#if DEBUG
			Scope(state: \.debugSettings, action: \.debugSettings) {
				DebugSettingsCoordinator()
			}
			#endif
		}
	}

	// MARK: Reducer

	@Dependency(\.errorQueue) var errorQueue
	@Dependency(\.p2pLinksClient) var p2pLinksClient
	@Dependency(\.securityCenterClient) var securityCenterClient
	@Dependency(\.personasClient) var personasClient
	@Dependency(\.dismiss) var dismiss
	@Dependency(\.userDefaults) var userDefaults

	public var body: some ReducerOf<Self> {
		Reduce(core)
			.ifLet(destinationPath, action: /Action.destination) {
				Destination()
			}
	}

	private let destinationPath: WritableKeyPath<State, PresentationState<Destination.State>> = \.$destination

	public func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .task:
			return p2pLinksEffect()
				.merge(with: securityProblemsEffect())
				.merge(with: personasEffect())

		case .addConnectorButtonTapped:
			state.destination = .manageP2PLinks(.init(destination: .newConnection(.init())))
			return .none

		case .securityCenterButtonTapped:
			state.destination = .securityCenter(.init())
			return .none

		case .personasButtonTapped:
			state.destination = .personas(.init())
			return .none

		case .dappsButtonTapped:
			state.destination = .authorizedDapps(.init())
			return .none

		case .connectorsButtonTapped:
			state.destination = .manageP2PLinks(.init())
			return .none

		case .preferencesButtonTapped:
			state.destination = .preferences(.init())
			return .none

		case .troubleshootingButtonTapped:
			state.destination = .troubleshooting(.init())
			return .none

		case .debugButtonTapped:
			state.destination = .debugSettings(.init())
			return .none
		}
	}

	public func reduce(into state: inout State, internalAction: InternalAction) -> Effect<Action> {
		switch internalAction {
		case let .setP2PLinks(clients):
			state.userHasNoP2PLinks = clients.isEmpty
			return .none
		case let .setSecurityProblems(problems):
			state.securityProblems = problems
			return .none
		case let .setPersonas(personas):
			state.personas = personas
			return .none
		}
	}

	public func reduce(into state: inout State, presentedAction: Destination.Action) -> Effect<Action> {
		switch presentedAction {
		case .troubleshooting(.delegate(.goToAccountList)):
			.run { _ in await dismiss() }
		default:
			.none
		}
	}

	public func reduceDismissedDestination(into state: inout State) -> Effect<Action> {
		switch state.destination {
		case .manageP2PLinks:
			p2pLinksEffect()
		default:
			.none
		}
	}
}

// MARK: Private
extension Settings {
	private func p2pLinksEffect() -> Effect<Action> {
		.run { send in
			await send(.internal(.setP2PLinks(
				p2pLinksClient.getP2PLinks()
			)))
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

	private func personasEffect() -> Effect<Action> {
		.run { send in
			for try await personas in await personasClient.personas() {
				guard !Task.isCancelled else { return }
				await send(.internal(.setPersonas(personas.map(\.address))))
			}
		}
	}
}

extension Settings.State {
	public var personasSecurityProblems: [SecurityProblem] {
		securityProblems.filter {
			switch $0 {
			case .problem5, .problem6, .problem7:
				!personas.isEmpty
			case let .problem3(addresses), let .problem9(addresses):
				// Note: we don't care about `addresses.hiddenPersonas` as the `state.personas` will only have the visible ones.
				!Set(addresses.personas).isDisjoint(with: personas)
			}
		}
	}
}
